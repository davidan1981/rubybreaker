#--
# This file contains the core of the runtime framework which injects the
# monitoring code into Breakable classes/modules and actually monitors the
# instances of those classes/modules at runtime. It also provides some utility
# functions for later use (after runtime).

dir = File.dirname(__FILE__) 
require_relative "type_placeholder"
require_relative "../context"
require_relative "../debug"
require_relative "pluggable"
require_relative "type_system"

module RubyBreaker

  module Runtime

    DEFAULT_TYPE_SYSTEM = TypeSystem.new

    # This class monitors method calls before and after. It simply reroutes
    # the responsibility to the appropriate pluggable type system which does
    # the actual work of gathering type information. 
    class Monitor 

      # attr_accessor :mod
      attr_accessor :pluggable

      public

      def initialize(mod, pluggable)
        # @mod = mod
        @pluggable = pluggable
      end

      # Starts monitoring of a method; it wraps each argument so that they
      # can gather type information in the callee.
      def monitor_before_method(obj, meth_info)
        @pluggable.before_method(obj, meth_info)
      end

      # This method is invoked after the actual method is invoked. 
      def monitor_after_method(obj, meth_info)
        @pluggable.after_method(obj, meth_info)
      end

    end

    # This class is a switch to turn on and off the type monitoring system.
    # It is important to turn off the monitor once the process is inside the
    # monitor; otherwise, it WILL fall into an infinite loop.
    class MonitorSwitch

      attr_accessor :switch

      def initialize(); @switch = true end

      def turn_on();
        Debug.msg("Switch turned on")
        @switch = true; 
      end

      def turn_off(); 
        Debug.msg("Switch turned off")
        @switch = false; 
      end

      def set_to(mode); @switch = mode; end
    end

    # TODO:For now, we use a global switch; but in future, a switch per
    # object should be used for multi-process apps. However, there is still
    # a concern for module tracking in which case, there isn't really a way
    # to do this unless we track with the process or some unique id for that
    # process.
    GLOBAL_MONITOR_SWITCH = MonitorSwitch.new 

    # This context is used for keeping track of context in the user code.
    # This will ignore the context within the RubyBreaker code, so it is
    # easy to pinpoint program locations without distraction from the
    # RubyBreaker code.
    CONTEXT = Context.new(ObjectPosition.new(self,"main"))

    # This module contains helper methods for monitoring objects and
    # modules.
    module MonitorUtils

      public

      # This will do the actual routing work for a particular "monitored"
      # method call.
      #
      # obj:: is the object receiving the message; is never wrapped object
      # meth_name:: is the original method name being called args:: is a
      # list of arguments for the original method call blk:: is the block
      # argument for the original method call
      #
      #-- 
      # NOTE: This method should not assume that obj is a monitored
      # object.  That is, no special method should be called to obj unless it
      # checks first.
      def self.route(obj,meth_name,*args,&blk)

        # remember the switch mode before turning it off
        switch = GLOBAL_MONITOR_SWITCH.switch

        # turn off the monitor so we do not fall into an infinite loop
        GLOBAL_MONITOR_SWITCH.turn_off()

        # use symbol instead of string throughout this code
        meth_name = :"#{meth_name}" 

        # first, get the context right
        # notice the argument 2 to the caller!
        #
        # CONTEXT.push(obj, meth_name, 
        #              Position.convert_caller_to_pos(caller(2)))
        CONTEXT.push(Position.convert_caller_to_pos(caller(2)))

        # this is what the renamed method
        stub_meth_name = get_alt_meth_name(meth_name) 

        Debug.msg("Route to #{stub_meth_name}",CONTEXT)

        # short-circuit if switch was off--i.e., no monitoring
        if !switch
          retval = obj.send(stub_meth_name.to_sym,*args,&blk)
          CONTEXT.pop() # do not forget to pop the context before returning
          return retval
        end

        is_obj_mod = (obj.class == Class or obj.class == Module)

        # from here, do more work for module monitoring
        mod = obj.class 

        # TODO:
        meta = false

        # mm = get_module_monitor(mod) unless is_obj_mod
        mm = Breakable::MONITOR_MAP[mod] if !is_obj_mod

        # There is something wrong if there isn't a module monitor
        # associated with the call.
        # raise Exception if mm == nil || !mm.inst_meths.include?(meth_name)

        meth_info = MethodInfo.new(meta, meth_name, args, blk, nil)

        mm.monitor_before_method(obj, meth_info)

        Debug.msg("monitor_before_method ended")

        # we are going to turn the switch back on
        GLOBAL_MONITOR_SWITCH.turn_on()

        # call the original method which was renamed
        retval = obj.send(stub_meth_name.to_sym, *meth_info.args,
                          &meth_info.blk)

        # turn it off
        GLOBAL_MONITOR_SWITCH.turn_off()

        meth_info.ret = retval
        mm.monitor_after_method(obj, meth_info)
        retval = meth_info.ret  # Return value may have been altered by the
                                # after_method monitoring code

        # things are done in this context. pop it off.
        CONTEXT.pop()

        # it is always the case that the switch was off when this particular
        # call was made. (Otherwise, it would have quit somewhere above
        GLOBAL_MONITOR_SWITCH.turn_on() 

        return retval # always return the return value
      end

      # This method returns the alternative (renamed) method name
      def self.get_alt_meth_name(meth_name)
        return "__#{meth_name}"
      end

      # This method returns the original method name
      def self.get_orig_meth_name(meth_name)
        return meth_name[2..-1]
      end

    end

    # This module installs a monitor in the object.
    module MonitorInstaller

      include MonitorUtils

      # returns true if the receiver is a module or a class
      def self.is_module?(recv)
        return recv.respond_to?(:class) && recv.kind_of?(Module)
      end

      # renames the method in essence; this method also "installs" the
      # module monitor for the class
      def self.rename_meth(recv,meth_name)
        alt_meth_name = MonitorUtils.get_alt_meth_name(meth_name)
        recv.module_eval("alias :\"#{alt_meth_name}\" :\"#{meth_name}\"")
        Debug.msg("Adding alternate method for #{meth_name}")
        recv.module_eval <<-EOF
          def #{meth_name}(*args, &blk)
            RubyBreaker::Runtime::MonitorUtils.route(self, 
                                                     "#{meth_name}",
                                                     *args,
                                                     &blk)
          end
        EOF
      end

      # Installs an module (class) monitor to the object.
      def self.install_module_monitor(mod,infer=false)
        Debug.short_msg("Installing module monitor for #{mod}")
        if infer
          Breakable::MONITOR_MAP[mod] = Monitor.new(mod, DEFAULT_TYPE_SYSTEM)
          Breakable::TYPE_PLACEHOLDER_MAP[mod] = TypePlaceholder.new
        end
        inst_meths = []
        meths = mod.instance_methods(false)
        meths.each do |m| 
          self.rename_meth(mod,m) 
        end
        Debug.feed_line()
      end

      def self.report(mod)
      end

    end

  end
end


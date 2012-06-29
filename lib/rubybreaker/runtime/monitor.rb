#--
# This file contains the core of the runtime framework which injects the
# monitoring code into breakable classes/modules and actually monitors the
# instances of those classes/modules at runtime. It also provides some utility
# functions for later use (after runtime).

dir = File.dirname(__FILE__) 
require_relative "util"
require_relative "../debug"
require_relative "type_system"

module RubyBreaker

  module Runtime

    # This hash maps a module to a nested hash that maps a method name to a
    # method type. This hash is shared between breakable modules/classes and
    # non-breakable modules/classes.
    TYPE_MAP = {} # module => {:meth_name => type}

    # This hash maps a (breakable) module to a type monitor
    MONITOR_MAP = {}  # module => monitor

    # The default type system for RubyBreaker
    DEFAULT_TYPE_SYSTEM = TypeSystem.new

    # This class monitors method calls before and after. It simply reroutes
    # the responsibility to the appropriate pluggable type system which does
    # the actual work of gathering type information. 
    class Monitor 

      attr_accessor :pluggable

      # This will do the actual routing work for a particular "monitored"
      # method call.
      #
      # route_type:: :break or :check
      # obj:: is the object receiving the message; is never wrapped object
      # meth_name:: is the original method name being called args:: is a
      # list of arguments for the original method call blk:: is the block
      # argument for the original method call
      #
      #-- 
      # NOTE: This method should not assume that obj is a monitored
      # object.  That is, no special method should be called to obj unless it
      # checks first.
      def self.route(route_type, obj, meth_name, *args, &blk)

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

        RubyBreaker.log("Route to #{stub_meth_name}", :debug, CONTEXT)

        # short-circuit if switch was off--i.e., no monitoring
        if !switch
          retval = obj.send(stub_meth_name.to_sym,*args,&blk)
          CONTEXT.pop() # do not forget to pop the context before returning
          return retval
        end

        is_obj_mod = (obj.class == Class or obj.class == Module)
        mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

        # mm = get_module_monitor(mod) unless is_obj_mod
        mm = MONITOR_MAP[mod] 

        # There is something wrong if there isn't a module monitor
        # associated with the call.
        # raise Exception if mm == nil || !mm.include?(meth_name)

        meth_info = MethodInfo.new(meth_name, args, blk, nil)

        begin
          case route_type
          when :break
            mm.break_before_method(obj, meth_info)
          when :check
            mm.check_before_method(obj, meth_info)
          end
        rescue ::Exception => e
          # Trap it, turn on the global monitor and then re-raise the
          # exception
          GLOBAL_MONITOR_SWITCH.turn_on()
          raise e
        end

        RubyBreaker.log("break_before_method ended")

        # we are going to turn the switch back on
        GLOBAL_MONITOR_SWITCH.turn_on()

        # call the original method which was renamed
        retval = obj.send(stub_meth_name.to_sym, *meth_info.args,
                          &meth_info.blk)

        # turn it off
        GLOBAL_MONITOR_SWITCH.turn_off()

        meth_info.ret = retval

        begin
          case route_type
          when :break
            mm.break_after_method(obj, meth_info)
          when :check
            mm.check_after_method(obj, meth_info)
          end
        rescue ::Exception => e
          # Trap it, turn on the global monitor and then re-raise the
          # exception
          GLOBAL_MONITOR_SWITCH.turn_on()
          raise e
        end

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

      def initialize(pluggable)
        @pluggable = pluggable
      end

      # This method is invoked before the original method is executed.
      def check_before_method(obj, meth_info)
        @pluggable.check_before_method(obj, meth_info)
      end

      # This method is invoked after the original method is executed.
      def check_after_method(obj, meth_info)
        @pluggable.check_after_method(obj, meth_info)
      end

      # This method is invoked before the original method is executed.
      def break_before_method(obj, meth_info)
        @pluggable.break_before_method(obj, meth_info)
      end

      # This method is invoked after the original method is executed.
      def break_after_method(obj, meth_info)
        @pluggable.break_after_method(obj, meth_info)
      end

    end

    # This class is a switch to turn on and off the type monitoring system.
    # It is important to turn off the monitor once the process is inside the
    # monitor; otherwise, it WILL fall into an infinite loop.
    class MonitorSwitch

      attr_accessor :switch

      def initialize(); @switch = true end

      def turn_on();
        RubyBreaker.log("Switch turned on")
        @switch = true; 
      end

      def turn_off(); 
        RubyBreaker.log("Switch turned off")
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

    # This module installs a monitor in the object.
    module MonitorInstaller

      # returns true if the receiver is a module or a class
      def self.is_module?(mod)
        return mod.respond_to?(:class) && mod.kind_of?(Module)
      end

      # renames the method in essence; this method also "installs" the
      # module monitor for the class
      def self.monkey_patch_meth(monitor_type, mod, meth_name)
        alt_meth_name = Monitor.get_alt_meth_name(meth_name)
        mod.module_eval("alias :\"#{alt_meth_name}\" :\"#{meth_name}\"")
        RubyBreaker.log("Adding alternate method for #{meth_name}")
        route_call = "RubyBreaker::Runtime::Monitor.route"
        mod.module_eval <<-EOF
          def #{meth_name}(*args, &blk)
            #{route_call}(:#{monitor_type}, self,"#{meth_name}",*args,&blk)
          end
        EOF
      end

      # Installs an module (class) monitor to the object. 
      def self.install_monitor(monitor_type, mod)

        RubyBreaker.log("Installing module monitor for #{mod}")

        # Do not re-install monitor if already done so.
        if MONITOR_MAP[mod] 
          RubyBreaker.log("Skip #{mod} as it has a monitor installed.")
          return
        end

        MONITOR_MAP[mod] = Monitor.new(DEFAULT_TYPE_SYSTEM)

        # Create the type map if it does not exist already. Remember, this
        # map could have been made by typesig().
        TYPE_MAP[mod] = {} unless TYPE_MAP[mod]

        # Get the list of instance methods but do not include inherited
        # methods. Those are part of the owner's not this module.
        meths = mod.instance_methods(false)  

        # See if any method is already documented (explicitly typesig'ed)
        doc_mt_map = Inspector.inspect_all(mod)
        doc_meths = doc_mt_map.keys

        meths.each do |m| 
          # Documented method will not be monkey-patched for "breaking"
          unless monitor_type == :break && doc_meths.include?(m)
            self.monkey_patch_meth(monitor_type, mod, m) 
          end
        end

      end

    end

  end
end


#--
# This program keeps track of every method call to a wrapped object. 

require_relative "../debug"

module RubyBreaker

  module Runtime

    # This constant is used to determine if an object is a wrapped object.
    WRAPPED_INDICATOR = :"__is_wrapped?__"

    # This class represents the shell object that wraps around another
    # object.  Note that it is a subclass of BasicObject to keep it really
    # concise. It also redirects the following methods (from BasicObject):
    #
    # !, !=, ==, equal?, eql?, __id__, object_id,
    # send, __send__, instance_eval, instance_exec
    #
    class ObjectWrapper < BasicObject

      def initialize(obj)
        @__rubybreaker_obj = obj
        nom_type = TypeDefs::NominalType.new(obj.class)
        @__rubybreaker_type = TypeDefs::FusionType.new(nom_type,[])
      end

      # This method returns the original object.
      def __rubybreaker_obj()
        return @__rubybreaker_obj
      end
      
      # This method returns the type gathered so far for this object.
      def __rubybreaker_type()
        return @__rubybreaker_type
      end

      # This method computes the wrap level of any given wrapped object. In
      # theory, this should always be 1. 
      #
      # Used for internal debugging purpose only
      def __rubybreaker_wrap_level() #:nodoc:
        val = 1
        if @__rubybreaker_obj.respond_to?(WRAPPED_INDICATOR)
          val += @__rubybreaker_obj.__rubybreaker_wrap_level
        end
        return val
      end

      #--
      # The following code generates the "serious problem" warning which is
      # suppressed by the hack using $VERBOSE. This is ok.  This meta
      # programming code block re-defines BasicObject's methods to redirect
      # to the actual object.
      [:"!", :"!=", :"==", :"equal?", :"eql?", :"__id__", :"object_id",
        :"send", :"__send__", :"instance_eval", :class,
        :"instance_exec"].each do |meth|

        orig_verbose = $VERBOSE
        $VERBOSE = nil

        eval <<-EOS

      def #{meth}(*args,&blk)
        self.method_missing(:"#{meth}", *args, &blk)
      end

        EOS

        $VERBOSE = orig_verbose

      end
      
      # Only behave differently if it's looking for +WRAPPED_INDICATOR+
      # method
      def respond_to?(mname)
        return true if mname.to_sym == WRAPPED_INDICATOR
        return @__rubybreaker_obj.respond_to?(mname)
      end

      # # Keep track of methods that MUST NOT take wrapped arguments.
      # WRAP_BLACKLIST = {
      #   ::Array => [:[], :[]=],
      #   ::Hash => [:[], :[]=],
      # }
      
      # This method missing method redirects all other method calls.
      def method_missing(mname,*args,&blk)
        if GLOBAL_MONITOR_SWITCH.switch

          # Be safe and turn the switch off
          GLOBAL_MONITOR_SWITCH.turn_off
          ::RubyBreaker.log("Object wrapper method_missing for #{mname} started")

          # Must handle send method specially (do not track them)
          if [:"__send__", :send].include?(mname)
            mname = args[0]
            args = args[1..-1]
          end
          @__rubybreaker_type.add_meth(mname)

          # If self is not subject to breaking, then no need to send the
          # wrapped arguments. This part is super IMPORTANT. Otherwise many
          # native code stuff won't work including Numeric#+.
          obj = self.__rubybreaker_obj
          is_obj_mod = (obj.class == ::Class or obj.class == ::Module)
          mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

          # # There are certain methods that should not take wrapped
          # # argument(s) whatsoever. Use WRAP_BLACKLIST for these.
          # if !MONITOR_MAP[mod] && WRAP_BLACKLIST[mod] &&
          #    WRAP_BLACKLIST[mod].include?(mname)
          #   args.map! do |arg|
          #     if arg.respond_to?(WRAPPED_INDICATOR)
          #       arg.__rubybreaker_obj
          #     else
          #       arg
          #     end
          #   end
          # end

          # Turn on the global switch again
          GLOBAL_MONITOR_SWITCH.turn_on

          # And call the original method 
          retval =  @__rubybreaker_obj.send(mname, *args, &blk)

          # # No need to wrap the object again...if it's wrapped already
          # unless retval.respond_to?(WRAPPED_INDICATOR)
          #   retval = ObjectWrapper.new(retval)
          # end
        else
          ::RubyBreaker.log("Object wrapper method_missing for #{mname} started")
          retval = @__rubybreaker_obj.send(mname, *args, &blk)
        end
        ::RubyBreaker.log("Object wrapper method_missing for #{mname} ended")
        return retval
      end
    end

  end

end

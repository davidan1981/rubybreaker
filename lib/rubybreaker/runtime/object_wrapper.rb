#--
# This program keeps track of every method call to a wrapped object. 

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

      #--
      # The following code generates the "serious problem" warning which is
      # suppressed by the hack using $VERBOSE. This is ok.  This meta
      # programming code block re-defines BasicObject's methods to redirect
      # to the actual object.
      [:"!", :"!=", :"==", :"equal?", :"eql?", :"__id__", :"object_id",
        :"send", :"__send__", :"instance_eval", 
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
      
      # This method missing method redirects all other method calls.
      def method_missing(mname,*args,&blk)
        Debug.msg("Method_missing for #{mname}")
        if GLOBAL_MONITOR_SWITCH.switch
          @__rubybreaker_type.add_meth(mname)
          retval =  @__rubybreaker_obj.send(mname,*args,&blk)
          retval = ObjectWrapper.new(retval)
        else
          retval = @__rubybreaker_obj.send(mname,*args,&blk)
        end
        return retval
      end
    end

  end

end

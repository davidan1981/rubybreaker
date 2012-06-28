#--
# This file contains the default type system for RubyBreaker. It uses
# subtyping defined in ../typing/subtyping.rb. It is not a constraint-based
# type system and does not check type errors statically. The main purpose of
# this type system is to give a readable type signature to every method in
# modules/classes specified for "breaking" and to type check documented
# methods of modules/classes specified for "checking".

require_relative "util"
require_relative "object_wrapper"
require_relative "../type"
require_relative "../typing"
require_relative "../debug"
require_relative "pluggable"

module RubyBreaker

  module Runtime

    # This is the default type system for RubyBreaker. It can be overridden
    # by a user specified type system. See +pluggable.rb+ for how this can
    # be done.
    class TypeSystem 

      include Pluggable # not needed but for the sake of documentation...
      include TypeDefs

      protected

      # Check if the object is wrapped by a monitor
      def is_object_wrapped?(obj)
        return obj.respond_to?(WRAPPED_INDICATOR)
      end

      # This method is a helper for computing the least upper bound. It
      # handles the case where existing method type is a method type (and
      # not a method list type). If there is no compatibility of the two
      # types, then it returns false.
      def lub_helper(exist_meth_type, new_meth_type)

        # most restrictive for the given test cases. 
        arg_types = []

        exist_meth_type.arg_types.each_with_index do |exist_arg_type, i|
          arg_type = nil
          new_arg_type = new_meth_type.arg_types[i]
          if !exist_arg_type 
            # nil means there hasn't been any type observed
            arg_type = new_arg_type
          elsif new_arg_type.subtype_of?(exist_arg_type) 
            arg_type = exist_arg_type
          elsif !exist_arg_type.subtype_of?(new_arg_type)
            # No subtype relation between them, so OR them
            arg_type = OrType.new([new_arg_type, exist_arg_type])
          end
          arg_types << arg_type
        end

        new_ret_type = new_meth_type.ret_type
        exist_ret_type = exist_meth_type.ret_type

        if !exist_ret_type
          ret_type = new_ret_type
          resolved = true
        elsif exist_ret_type.subtype_of?(new_ret_type) 
          ret_type = exist_ret_type
          resolved = true
        elsif new_ret_type.subtype_of?(exist_ret_type) 
          ret_type = new_ret_type
          resolved = true
        else
          resolved = false
        end
        
        if resolved
          exist_meth_type.arg_types = arg_types
          exist_meth_type.ret_type = ret_type      
        end 

        return resolved
      end

      # This method computes the least upper bound of the existing method
      # type and newly observed argument/block/return types. There are a few
      # cases to consider:
      #
      # If the existing type is a method list type, the new observed type
      # will be either "consolidated" into one of the method types in the
      # list or added to the list.
      #
      # If there is no compatibility between the existing method type and
      # the observed type, then the method type will be promoted to a method
      # list type. And the newly observed type will be added to the list.
      #
      # For each method type,
      #
      # It basically consolidates the existing type information for the
      # invoked method and the observed type.
      #
      # For arguments, we look for most general type that can handle all
      # types we have seen. This means we find the super type of all types
      # we have seen (excluding unknown types).
      # 
      # For return, we look for most specific type that can handle both
      # types.  Therefore, if two types have no subtype relation, we AND
      # them. But we do not allow AND types in the return type. We must turn
      # the method type to a method list type.
      #
      # obj:: the receive of the method call
      # meth_type_map:: a hash object that maps method names to method types 
      # meth_name:: the name of the method being invoked
      # retval:: the return value of the original method call
      # args:: the arguments
      # blk:: the block argument
      #
      def lub(obj, meth_type_map, meth_name, retval, *args, &blk)
        
        exist_meth_type = meth_type_map[meth_name.to_sym] 
        
        # Again, find the arity
        meth_obj = obj.method(Monitor.get_alt_meth_name(meth_name))
        arity = meth_obj.arity

        # Construct the newly observed method type first
        new_meth_type = MethodType.new(meth_name,[])
        args.each_with_index do |arg,idx|
          if is_object_wrapped?(arg)
            arg_type = arg.__rubybreaker_type
          else
            arg_type = NominalType.new(arg.class)
          end
          # Check if the last argument should be a variable length argument
          if arity < 0 && (idx + 1 == arity.abs)
            new_meth_type.arg_types << VarLengthType.new(arg_type)
            break
          end
          new_meth_type.arg_types << arg_type
        end

        if (obj == retval)
          # the return value is same as the message receiver. This means the
          # return value has the self type.
          SelfType.set_self(obj.class)
          ret_type = SelfType.new()
        else
          # Otherwise, construct a nominal type.
          ret_type = NominalType.new(retval.class)
        end
        new_meth_type.ret_type = ret_type

        resolved = false
        if exist_meth_type.instance_of?(MethodListType)
          exist_meth_type.types.each {|meth_type|
            resolved = lub_helper(meth_type, new_meth_type)
            break if resolved
          }
        else
          resolved = lub_helper(exist_meth_type, new_meth_type)
          if !resolved
            # Could not resolve the types, so promote the method type to a
            # method list type
            exist_meth_type = MethodListType.new([exist_meth_type])
            meth_type_map[meth_name.to_sym] = exist_meth_type
          end
        end 
        if !resolved
          exist_meth_type.types << new_meth_type
        end

      end

      # This method creates the prefix for the type error message.
      def type_error_msg_prefix(mod, meth_name)
        result = /#<Class:(.+)>/.match("#{mod}")
        prefix = result ? "#{result[1]}." : "#{mod}#"
        return "#{prefix}#{meth_name}"
      end

      public

      # This method is invoked before the original method is executed.
      def check_before_method(obj, meth_info)
        is_obj_mod = (obj.class == Class or obj.class == Module)
        mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

        meth_type_map = TYPE_MAP[mod]
        return unless meth_type_map

        # Let's take things out of the MethodInfo object
        meth_name = meth_info.meth_name
        args = meth_info.args
        blk = meth_info.blk
        ret = meth_info.ret

        # Get the registered method type for this method
        meth_type = meth_type_map[meth_name]

        args.each_with_index do |arg, i|
          arg_type = NominalType.new(arg.class)
          if !arg_type.subtype_of?(meth_type.arg_types[i])
            msg = type_error_msg_prefix(mod, meth_name) +
                  "'s #{Util.ordinalize(i+1)} argument " +
                  "does not have type #{arg_type.unparse()}."
            raise Errors::TypeError.new(msg)
          end
        end

      end

      # This method is invoked after the original method is executed.
      def check_after_method(obj, meth_info)
        is_obj_mod = (obj.class == Class or obj.class == Module)
        mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

        meth_type_map = TYPE_MAP[mod]
        return unless meth_type_map

        # Let's take things out of the MethodInfo object
        meth_name = meth_info.meth_name
        args = meth_info.args
        blk = meth_info.blk
        ret = meth_info.ret

        # Get the registered method type for this method
        meth_type = meth_type_map[meth_name]

        ret_type = NominalType.new(ret.class)
        if !meth_type.ret_type.subtype_of?(ret_type)
          msg = type_error_msg_prefix(mod, meth_name) +
                " return value does not have type #{ret_type.unparse()}."
          raise Errors::TypeError.new(msg)
        end
      end
      
      # This method occurs before every call to a "monitored" method in a
      # module/class specified for breaking. It wraps each argument with the
      # object wrapper so it can be tracked of the method calls. 
      def break_before_method(obj, meth_info)

        # Use the eigen class if the object is a module/class and use the
        # object's class otherwise.
        is_obj_mod = (obj.class == Class or obj.class == Module)
        mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

        meth_type_map = TYPE_MAP[mod]

        # Let's take things out of the MethodInfo object
        meth_name = meth_info.meth_name
        args = meth_info.args
        blk = meth_info.blk
        ret = meth_info.ret

        args = args.map do |arg|
          if arg.kind_of?(TrueClass) || arg.kind_of?(FalseClass)
            # XXX: would overrides resolve this issue?
            arg 
          else
            ObjectWrapper.new(arg)
          end
        end

        RubyBreaker.log("In module monitor_before #{meth_name}")
        
        meth_type = meth_type_map[meth_name]
        
        if meth_type
          # This means the method type has been created previously.
          unless (blk == nil && meth_type.blk_type == nil) &&
                 (!blk || blk.arity == meth_type.blk_type.arg_types.length)
            raise Errors::TypeError.new("Block usage is inconsistent")
          end
        else
          # No method type has been created for this method yet. Create a
          # blank method type (where each argument type, block type, and
          # return type are all nil).
          #
          # First, use the orignal method's arity to find out # of
          # arguments. 
          meth_obj = obj.method(Monitor.get_alt_meth_name(meth_name))
          arity = meth_obj.arity
          arg_types = [nil] * meth_obj.arity.abs 
          if blk
            # Do the same for the block too if there is one
            blk_arity = blk.arity
            blk_arg_types = [nil] * blk_artiy.abs
            blk_type = BlockType.new(blk_arg_types, nil, nil)
          else
            blk_type = nil
          end
          meth_type = MethodType.new(meth_name, arg_types, blk_type, nil)
          meth_type_map[meth_name] = meth_type
        end

        meth_info.args = args

      end

      # This method occurs after every call to a "monitored" method call of
      # a module/class specified for "breaking". It updates the type
      # information.
      def break_after_method(obj, meth_info)

        is_obj_mod = (obj.class == Class or obj.class == Module)
        mod = is_obj_mod ? Runtime.eigen_class(obj) : obj.class

        # Take things out
        meth_name = meth_info.meth_name
        retval = meth_info.ret
        args = meth_info.args
        blk = meth_info.blk

        RubyBreaker.log("In module monitor_after #{meth_name}")

        # Compute the least upper bound
        lub(obj, TYPE_MAP[mod],meth_name,retval,*args,&blk)

        if obj == retval  
          # It is possible that the method receiver is a wrapped object if
          # it is an argument to a method in the current call stack. So this
          # check is to return the wrapped object and not the stripped off
          # version. (Remember, == is overridden for the wrapped object.)
          meth_info.ret = obj
        end

      end

    end
  end

end

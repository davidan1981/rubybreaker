#--
# This file is the mechanism behind the default type system of RubyBreaker.
# Typing works as follows:
#
# In RubyBreaker, there are two *kinds* of modules (classes)--Broken and
# non-Broken. The former refers to modules that already have type
# information, and the latter refers to ones without prior type information.
# Although it might be optional as an add-on, RubyBreaker does not generate
# any constraint graph to resolve subtype relations. This is the main
# difference between Rubydust and RubyBreaker. 
#
# If a module is not broken but is breakable (i.e., monitored), then it is
# treated as non-Broken. At the end of the execution, the module will be
# Broken--i.e., its type information is now revealed. If the user wishes to
# use the result of the analysis, this type information will be documented
# and the module itself can be used as Broken in future execution. 
#
# Consider the following examples:
#
#   class Numeric
#     typesig("+(numeric) -> numeric")
#     ...
#   end
#
#   class A
#     include RubyBreaker::Breakable
#     def m(x,y)
#       return x+y
#     end
#   end
#
# a = A.new
# assert_equal(3,a.m(1,2))
#
# Type of A#m will be "m(fixnum[+],numeric) -> numeric". Note that the type
# signature for Numeric#+ is given by RubyBreaker in base.rb. The first
# argument of A#m gets fixnum[+] since x is a Numeric and was invoked +
# method. The second argument simply gets Numeric since no method was
# invoked on the object but + method takes a Numeric.
#
# The basis of RubyBreaker typing is object subtyping. It is object typing
# because RubyBreaker supports duck types and fusion types where individual
# methods can be specified in the type.
#

require_relative "rubytype"
require_relative "../type"

module RubyBreaker
  
  # This module contains subtyping logic used in RubyBreaker. See
  # _rubytype.rb_ for logic related to subclassing which is directly related
  # to pure Ruby types.
  module Typing 

    include TypeDefs

    private

    # This method determins if the module/class has its corresponding 
    def self.has_type_map?(mod)
      return Runtime::TYPE_MAP[mod] != nil
    end

    # Thie method checks if the module has all the methods specified in
    # meths array
    def self.module_has_methods?(mod, meths)
      has_all = true
      mod_meths = mod.instance_methods
      meths.each do |m|
        if !mod_meths.include?(m)
          has_all = false
          break
        end
      end
      return has_all
    end
    
    # This method checks if the duck type has all the methods specified in
    # meths array
    def self.duck_has_methods?(duck, meths)
      has_all = true
      meths.each do |m|
        if !duck.meth_names.include?(m)
          has_all = false
          break
        end 
      end
      return has_all
    end
    
    # This method checks if a duck type (LHS) is a subtype of the other
    # type. There are a few cases to consider:
    #
    #   If RHS is a nominal type, every method in RHS must exist in LHS.
    #   This is because the subtype has the same number of or more methods
    #   than supertype.
    #
    #   If RHS is a duck type OR a fusion type, every method in RHS must
    #   exist in LHS.
    #
    #   If RHS is an "or" type, LHS must be a subtype of one of RHS'es inner
    #   types.
    #
    #   All other cases would not satisfy this subtyping relationship.
    #
    def self.duck_subtype_rel?(lhs,rhs)
      return false unless lhs.kind_of?(DuckType)
      if rhs.instance_of?(NominalType) # Don't include self type
        # Ok, this is unlikely but we still do a check
        is_subtype = self.duck_has_methods?(lhs, rhs.mod.instance_methods)
      elsif rhs.kind_of?(DuckType) # duck type and fusion type
        is_subtype = self.duck_has_methods?(lhs, rhs.meth_names)
      elsif rhs.instance_of?(OrType) 
        is_subtype = false
        rhs.types.each {|rhs_inner_t|
          # Only one has to be in subtype relation
          if self.duck_subtype_rel?(lhs,rhs_inner_t)
            is_subtype = true
            break
          end
        }
      else
        is_subtype = false
      end
      return is_subtype
    end
    
    # Procedure subtype relation check is for both methods and blocks. A
    # typical "method" subtype is satified if
    #
    #   - Each argument in RHS is a subtype of its counterpart in LHS. This
    #     includes the block argument. It's called contra-variance.
    #   - The return in LHS is a subtype of its counterpart in RHS. It's
    #     called co-variance.
    #
    # Here is the explanation to why we do this:
    #
    #   Assume m1 <: m2 (i.e, m1 is a subtype of m2)
    #
    #   Then, any place where m2 is used, m1 should be able to replace m2.
    #   In other words, m1's arguments should accept more types than m2's
    #   arguments. On the other hand, m1's return should be more restrictive
    #   than m2's return to make sure it would work after the call. There it
    #   is, you just received a mini type systems class without paying
    #   thousands of dollars.
    #
    # This method also takes care of optional argument and variable length
    # argument. This method is the ONLY one that should handle those types.
    #
    def self.proc_subtype_rel?(lhs, rhs)

      # use kind_of? because method_subtype_rel? calls this method
      return false unless lhs.kind_of?(BlockType) & rhs.kind_of?(BlockType)

      is_subtype = true

      if lhs.arg_types.length != rhs.arg_types.length
        is_subtype = false
      # elsif !self.subtype_rel?(rhs.blk_type, lhs.blk_type)
      #   is_subtype = false
      elsif !self.subtype_rel?(lhs.ret_type, rhs.ret_type)
        is_subtype = false
      else

        # Subtyping with optional type and variable length type works as
        # follows:
        #
        # (x?) <: (x) since optional argument can replace original
        #             argument
        #
        # (x*) <: (x) for the same reason
        #
        # (x*) <: (x?) since LHS can have more arguments
        #

        is_subtype = true
        # check arguments
        rhs.arg_types.each_with_index {|rhs_arg,i|
          lhs_arg = lhs.arg_types[i]
          if lhs_arg.kind_of?(OptionalType) 
            lhs_arg = lhs_arg.type
            if rhs_arg.kind_of?(OptionalType)
              rhs_arg = rhs_arg.type
            elsif rhs_arg.kind_of?(VarLengthType)
              is_subtype = false
              break
            end
          elsif lhs_arg.kind_of?(VarLengthType)
            lhs_arg = lhs_arg.type
            if rhs_arg.kind_of?(OptionalType) ||
               rhs_arg.kind_of?(VarLengthType) 
              rhs_arg = rhs_arg.type
            end
          end
          if !self.subtype_rel?(rhs_arg, lhs_arg)
            is_subtype = false
            break
          end
        }
      end
      return is_subtype
    end
    
    # This method checks the subtype relation between two method types.
    # There are several cases to consider:
    # 
    #   Case 1: If RHS is a MethodListType, we give up. It is actually
    #           difficult to figure out the subtype relation in this case.
    #   Case 2: If LHS is a MethodListType, only one of them has to be in 
    #           subtype relation to RHS.
    #   Case 3: If both are Methods, then do a typical method subtype
    #           comparison.
    #
    # Note: See methodtypelist_subtype_rel? if LHS is a MethodListType.
    #
    def self.method_subtype_rel?(lhs,rhs)
      is_subtype = true
      # First check if LHS and RHS are either a method type or a method list
      # type. Otherwise, return false.
      if (!lhs.instance_of?(MethodType) && !lhs.instance_of?(MethodListType)) ||
         (!rhs.instance_of?(MethodType) && !rhs.instance_of?(MethodListType))
        is_subtype = false
      elsif lhs.instance_of?(MethodListType)
        # Every method type in LHS must be a subtype of RHS
        is_subtype = true
        lhs.types.each {|type|
          if !self.method_subtype_rel?(type,rhs)
            is_subtype = false
            break
          end
        }
      elsif rhs.instance_of?(MethodListType)
        # One of the RHS has to be a supertype
        is_subtype = false
        rhs.types.each {|type|
          if self.method_subtype_rel?(lhs,type)
            is_subtype = true
            break
          end
        }
      else # ok, both are MethodType        
        # Remember the contra-variance in arguments, co-variance in return
        if lhs.meth_name != rhs.meth_name 
          is_subtype = false
        else
          # re-use block subtype relation check
          is_subtype = self.proc_subtype_rel?(lhs, rhs)
        end
      end
      return is_subtype
    end
    
    # This method checks if each method in the subtype is indeed a subtype
    # of the counterpart in the supertype.
    def self.methods_subtype_rel?(sub_meth_types, super_meth_types)
      # wider means, a fewer number of methods
      return false unless sub_meth_types.size <= super_meth_types 
      is_subtype = true
      sub_meth_types.each_pair { |meth_name, sub_meth_type|
        super_meth_type = super_meth_types[meth_name]
        if super_meth_type == nil || 
           !method_subtype_rel?(sub_meth_type, super_meth_type)
          is_subtype = false
          break
        end
      }      
      return is_subtype
    end
    
    # This method determines if the fusion type (LHS) is a subtype of the
    # other type (RHS). There are many cases to consider:
    #
    #   If LHS is Broken, there are several cases to consider:
    #   
    #     If RHS is a nominal type, there are a few cases to consider:
    #
    #       If LHS is a subclass of RHS, then there is a subtype relation
    #
    #       If RHS is Broken, each method in RHS must be a supertype of the
    #         counterpart in LHS.
    #
    #       Otherwise, each in LHS must exist in RHS.
    #
    #     If RHS is a fusion type, ther eare a few cases to consider:
    #
    #       If LHS is a subclass of RHS, then LHS is a subtype
    #       
    #       If RHS is Broken, each method in RHS must be a supertype of the
    #         counterpart in LHS.
    #
    #       Otherwise, every method in RHS must exist in LHS.
    #
    #     If RHS is a duck type, then every method in RHS must exist in LHS.
    #
    #     Otherwise, there is no subtype relation.
    #
    #   If LHS is not Broken, subtyping satifies only when LHS has all
    #   methods in RHS
    #
    def self.fusion_subtype_rel?(lhs,rhs)
      return false unless lhs.kind_of?(FusionType)
      if self.has_type_map?(lhs.mod)
        if rhs.instance_of?(NominalType) # don't include self type
          if RubyTypeUtils.subclass_rel?(lhs.mod, rhs.mod)
            is_subtype = true
          elsif self.has_type_map?(rhs.mod)
            # then do a type check for each method
            lhs_meths = Inspect.inspect_all(lhs.mod)
            rhs_meths = Inspect.inspect_all(rhs.mod)
            is_subtype = self.methods_subtype_rel?(lhs_meths,rhs_meths)
          else 
            # if not, the only possible way is if lhs has all the rhs' methods
            is_subtype = self.duck_has_methods?(lhs, rhs.mod.instance_methods)
          end
        elsif rhs.instance_of?(FusionType)
          if RubyTypeUtils.subclass_rel?(lhs.mod, rhs.mod)
            is_subtype = true
          elsif self.has_type_map?(rhs.mod)
            # then do a type check for each method
            lhs_meths = Inspect.inspect_all(lhs.mod)
            rhs_meths = Inspect.inspect_meths(rhs.mod, lhs.meths.keys)
            is_subtype = self.methods_subtype_rel?(lhs_meths,rhs_meths)
          else
            is_subtype = self.duck_has_methods?(lhs, rhs.meth_names)
          end            
        elsif rhs.instance_of?(DuckType)
          is_subtype = self.duck_has_methods?(lhs, rhs.meth_names)
        else
          is_subtype = false
        end
      else
        # lhs is not broken, so only thing we can do is method check
        is_subtype = self.duck_subtype_rel?(lhs, rhs)
      end 
      return is_subtype
    end
    
    # Self type works exactly like nominal type except that, if RHS is a
    # self type, then only self type is allowed in LHS.
    #
    # For example, consider you are inside Fixnum
    #
    #   self <: Fixnum
    #   self <: Numeric
    #   self <: Object
    #   self <: self
    #
    #   but,
    #
    #   Fixnum !<: self
    #
    def self.self_subtype_rel?(lhs,rhs)
      self.nominal_subtype_rel?(lhs,rhs)
    end

    # This method checks the subtype relation when LHS is a nominal type.
    # There are several cases to consider:
    #
    #   my_class <: your_class  is true only if MyClass and YourClass have
    #                           (Ruby) subclass relationship.
    #
    #   my_class <: a[foo]      is true if
    #
    #     (1) MyClass is a subtype of A or
    #     (2) Both MyClass and A are Broken and every method in MyClass is a
    #         subtype of the counterpart method in A. (This should be rare).
    #         Or,
    #     (3) A are not Broken and MyClass has all methods of A.
    #   
    # 
    def self.nominal_subtype_rel?(lhs,rhs)
      return false unless lhs.kind_of?(NominalType) # Self type is a nominal type
      if rhs.instance_of?(SelfType)
        is_subtype = lhs.instance_of?(SelfType)
      elsif rhs.instance_of?(NominalType) # don't include self type
        is_subtype = RubyTypeUtils.subclass_rel?(lhs.mod, rhs.mod)
      elsif rhs.instance_of?(FusionType)
        # If RHS is a superclass or included module then true
        # If both LHS and RHS are Broken, do a subtype check on each method
        # If only RHS is broken, look at each method's type
        # If RHS is not broken, sorry no subtype relationship
        if RubyTypeUtils.subclass_rel?(lhs.mod, rhs.mod)
          is_subtype = true
        elsif self.has_type_map?(lhs.mod) && self.has_type_map?(rhs.mod)
          is_subtype = true
          lhs_methods = lhs.mod.instance_methods
          rhs.meth_names.each {|m| 
            lhs_m = Inspector.inspect_meth(lhs, m)
            rhs_m = Inspector.inspect_meth(rhs, m)
            if !meth_subtype_rel?(lhs_m, rhs_m)
              is_subtype = false
              break
            end
          }
        else
          is_subtype = self.module_has_methods?(lhs.mod, rhs.meth_names)
        end 
      elsif rhs.instance_of?(DuckType)
        # Do simple method existence check since there is no nominal type to
        # inspect.
        is_subtype = self.module_has_methods?(lhs.mod, rhs.meth_names)
      else
        # No other possibility of subtype relation
        is_subtype = false
      end 
      return is_subtype
    end

    # If OrType is on the LHS, the only possible subtype relation is if each
    # child type in OrType is a subtype of RHS. For example,
    #  
    #   numeric or string <: object
    #
    # is true only if numeric is subype of object and string is subtype of
    # object.
    # 
    def self.or_subtype_rel?(lhs,rhs)
      return false if !lhs.kind_of?(OrType)
      is_subtype = true
      # Each type in LHS has to be a subtype of RHS
      lhs.types.each do |t|
        if !self.subtype_rel?(t,rhs)
          is_subtype = false
          break
        end
      end
      return is_subtype
    end

    public
    
    # This method determines if one type is a subtype of another. This check
    # is for RubyBreaker defined types. See _TypeDefs_ module for more
    # detail.
    #
    # lhs:: The allegedly "subtype"
    # rhs:: The allegedly "supertype"
    #
    def self.subtype_rel?(lhs, rhs)

      # Don't even bother if they are same object or syntactically
      # equivalent. NOTE: would this really help improve performance???
      return true if (lhs.equal?(rhs) || lhs.eql?(rhs))

      # Break down the cases by what LHS is.
      is_subtype = false
      if lhs.instance_of?(NilType)
        is_subtype = rhs.instance_of?(NilType)
      elsif lhs.instance_of?(AnyType)
        is_subtype = true 
      elsif lhs.instance_of?(SelfType)
        is_subtype = self.self_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(NominalType)
        is_subtype = self.nominal_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(FusionType)
        is_subtype = self.fusion_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(DuckType)
        is_subtype = self.duck_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(MethodType)
        is_subtype = self.method_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(OrType)
        is_subtype = self.or_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(BlockType)
        is_subtype = self.proc_subtype_rel?(lhs,rhs)
      elsif lhs.instance_of?(MethodListType)
        is_subtype = self.method_subtype_rel?(lhs,rhs)
      end
      return is_subtype
    end

  end
  
  #--
  # Reopening the class to allow subtyping more accessible.
  class TypeDefs::Type

    # This is a shorthand for calling Typing.subtype_rel? 
    def subtype_of?(rhs)
      return Typing.subtype_rel?(self,rhs)
    end
  end

end


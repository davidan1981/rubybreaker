#--
# This file defines (almost) syntactic equivalences between types.

require_relative "../type"

module RubyBreaker
  
  # This module compares two RubyBreaker-defined types for the syntactic
  # equivalence.
  module TypeComparer

    include TypeDefs
    
    private
    
    # This method checks if two types are syntactically equivalent. The
    # order of method names do not matter.
    def self.duck_compare(lhs,rhs)
      is_equal = false
      if lhs.kind_of?(DuckType) && rhs.kind_of?(DuckType) &&
         lhs.meth_names.size == rhs.meth_names.size
        is_equal = true
        lhs.meth_names.each {|mname| 
          if !rhs.meth_names.include?(mname)
            is_equal = false
            break
          end
        }
      end 
      return is_equal
    end
    
    # This method compares two proc types.
    def self.proc_compare(lhs, rhs)
      is_equal = false
      if lhs.arg_types.size == rhs.arg_types.size
        is_equal = true
        # check arguments first
        lhs.arg_types.each_with_index do |atype,i|
          if !self.compare(atype,rhs.arg_types[i])
            is_equal = false
            break
          end
        end
        # check block types
        if lhs.blk_type && rhs.blk_type
          is_equal = is_equal && self.proc_compare(lhs.blk_type, rhs.blk_type)
        elsif lhs.blk_type || rhs.blk_type
          is_equal = false
        end
        is_equal = is_equal && self.compare(lhs.ret_type, rhs.ret_type)
      end 
      return is_equal
    end

    # This method determines if the type exists in the given type list.
    def self.type_in_types?(t, types)
      exist = false
      types.each do |t2|
        if self.compare(t, t2)
          exist = true
          break
        end
      end
      return exist
    end
    
    # This method compares two OR or MethodListType. The order of inner
    # types do not matter.
    #
    # XXX: Should the order not matter really?
    def self.or_compare(lhs,rhs)
      is_equal = false
      if lhs.class == rhs.class && lhs.types.size == rhs.types.size
        is_equal = true
        lhs.types.each { |t|
          if !self.type_in_types?(t, rhs.types)
            is_equal = false
            break
          end
        }
      end
      return is_equal
    end

    # This method compares a method list to another method list.
    def self.meth_list_compare(lhs, rhs)
      return self.or_compare(lhs, rhs)
    end
    
    public
    
    # This equal method determines whether two types are *syntactically*
    # equivalent. Note that this is NOT a type equivalent check.
    def self.compare(lhs,rhs)
      if lhs == rhs
        is_equal = true
      elsif lhs.class != rhs.class 
        is_equal = false
      elsif lhs.instance_of?(NominalType)
        is_equal = (lhs.mod == rhs.mod)
      elsif lhs.instance_of?(SelfType)
        is_equal = rhs.instance_of?(SelfType)
      elsif lhs.instance_of?(DuckType)
        is_equal = duck_compare(lhs,rhs)
      elsif lhs.instance_of?(FusionType)
        is_equal = self.compare(lhs.nom_type, rhs.nom_type)        
        if is_equal # do more testing
          is_equal = duck_compare(lhs,rhs)
        end
      elsif lhs.instance_of?(MethodType)
        is_equal = lhs.meth_name == rhs.meth_name
        if is_equal # then do more testing
          is_equal = self.proc_compare(lhs,rhs)
        end
      elsif lhs.instance_of?(BlockType)
        is_equal = self.proc_compare(lhs,rhs)
      elsif lhs.instance_of?(MethodListType)
        is_equal = self.meth_list_compare(lhs,rhs)
      elsif lhs.instance_of?(OrType)
        is_equal = self.or_compare(lhs,rhs)
      elsif lhs.instance_of?(VarLengthType)
        is_equal = rhs.instance_of?(VarLengthType) && 
                   self.compare(lhs.type, rhs.type)
      elsif lhs.instance_of?(OptionalType)
        is_equal = rhs.instance_of?(OptionalType) &&
                   self.compare(lhs.type, rhs.type)
      else
        is_equal = lhs.class == rhs.class
      end
      return is_equal
    end

  end

  class TypeDefs::Type

    # This method compares this object to another object syntactically.
    def eql?(other)
      TypeComparer.compare(self, other)
    end
  end 
end

#--
# This file defines Inspector which finds the type placeholder for a
# module.

require_relative "util"
require_relative "monitor"

module RubyBreaker

  module Runtime
  
    # This module inspects a Breakable module and retrieves type information
    # if there is any.
    module Inspector
      
      # This method inspects the module for specified method name. It
      # returns the method type or method list type for the given method. If
      # no method exists or if there is no type information for the method,
      # it returns nil
      def self.inspect_meth(mod, mname)
        mname = mname.to_sym 
        if Breakable::TYPE_PLACEHOLDER_MAP.has_key?(mod)
          placeholder = Breakable::TYPE_PLACEHOLDER_MAP[mod]
        elsif Broken::TYPE_PLACEHOLDER_MAP.has_key?(mod)
          placeholder = Broken::TYPE_PLACEHOLDER_MAP[mod]
        else
          # TODO
        end
        t = placeholder.meth_type_map[mname] if placeholder
        return t
      end

      # This method inspects the module for the specified class method name.
      # This is a shorthand for calling inspect_meth with the eigen class.
      def self.inspect_class_meth(mod, mname)
        eigen_class = Runtime.eigen_class(mod)
        return self.inspect_meth(eigen_class, mname)
      end
      
      # Similar to inspect_meth but returns a hash of (mname, mtype) pairs.
      def self.inspect_meths(mod, mnames)
        mtype_hash = {}
        mnames.each {|mname|
          mtype_hash[mname] = self.inspect_meth(mod, mname)
        }
        return mtype_hash
      end
      
      # This method inspects the module for all methods. It returns a Hash
      # containing (method name, method type) pairs.
      def self.inspect_all(mod)
        mtypes = {}
        mm = Breakable::TYPE_PLACEHOLDER_MAP[mod]
        if mm
          mm.meth_type_map.each_pair {|im,mtype|
            mtypes[im] = mtype if mtype 
          }
        end
        return mtypes
      end 
      
      
    end
  
  end
end

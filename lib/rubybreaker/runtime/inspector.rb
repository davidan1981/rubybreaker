#--
# This file defines the type inspector which fetches the type information
# gathered or documented in a class.

require_relative "util"
require_relative "monitor"

module RubyBreaker

  module Runtime
  
    # This module inspects type information gathered so far.
    module Inspector
      
      # This method inspects the module for the type of the specified
      # method.
      def self.inspect_meth(mod, mname)
        mname = mname.to_sym 
        t = TYPE_MAP[mod][mname] if TYPE_MAP.has_key?(mod)
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
        mm = TYPE_MAP[mod]
        mm.each_pair {|im,mtype| mtypes[im] = mtype if mtype } if mm
        return mtypes
      end 
      
    end
  
  end
end

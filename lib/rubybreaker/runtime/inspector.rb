#--
# This file defines Inspector which finds the type placeholder for a
# module.

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
        if mod.included_modules.include?(Breakable)
          placeholder = Breakable::TYPE_PLACEHOLDER_MAP[mod]
        elsif mod.included_modules.include?(Broken)
          placeholder = Broken::TYPE_PLACEHOLDER_MAP[mod]
        else
          # TODO
        end
        t = placeholder.inst_meths[mname] if placeholder
        return t
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
        # mm = MonitorUtils.get_module_monitor(mod)
        mm.inst_meths.each_pair {|im,mtype|
          mtypes[im] = mtype if mtype 
        }
        return mtypes
      end 
      
      
    end
  
  end
end

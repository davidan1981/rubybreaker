#--
# This file provides utility functions that deal with actual Ruby types 
# directly. Subclass/submodule relationship is based on the inclusion of
# the class or the module...and not the true (theoretical) subtype 
# relationship.

module RubyBreaker
  
  module RubyTypeUtils
    
    # Checks if lhs is a sub-module of rhs
    def self.submodule_rel?(lhs,rhs)
      # both lhs and rhs must be modules
      if lhs == rhs 
        return true
      else
        lhs.included_modules.each {|m|
          return true if self.submodule_rel?(m,rhs)
        }
      end 
      return false
    end
    
    # Checks if lhs is a subclass of rhs
    def self.subclass_rel?(lhs, rhs)
      return false unless lhs.kind_of?(Class)
      if lhs == rhs
        return true
      elsif lhs == BasicObject 
        # lhs != rhs and no more to look upward, so quit 
        return false
      elsif rhs.instance_of?(Module)
        # lhs != rhs and rhs is a module, so lhs must have a parent module 
        # that is a subclass of rhs
        lhs.included_modules.each {|m|
          return true if self.submodule_rel?(m,rhs)
        }
      else
        # then rhs is a class, so just go up as a class
        return self.subclass_rel?(lhs.superclass, rhs)
      end
      return false
    end
    
  end
  
end

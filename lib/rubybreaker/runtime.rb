#--
# This file defines Breakable and Broken module. Breakable module makes the
# hosting module (and class) subject to type monitoring. Broken module makes
# type information of the hosting module accessible.

require_relative "runtime/overrides"
require_relative "runtime/typesig_parser"
require_relative "runtime/monitor"
require_relative "runtime/inspector"

module RubyBreaker

  # Broken takes higher precedence than Breakable. Once a module is
  # "declared" to be Broken, it cannot be Breakable. 
  #
  # TODO: In future, there will be a hybrid of two to allow documenting of
  #       methods that are newly introduced in a broken class/module.

  # This array lists modules/classes that will be monitored.
  BREAKABLE = []

  # This array lists "broken" classes--i.e., with type signatures
  BROKEN = []

  # This module should be included in classes or modules that you want to
  # monitor during runtime. The concept is that once a Breakable module is
  # monitored and its type documentation is generated, the module now becomes
  # a Broken module. The actual implementation is a simple trigger that 
  # queues the target module into the list of modules to monitor. The queued
  # modules are then modified to be monitored dynamically.
  module Breakable

    TYPE_PLACEHOLDER_MAP = {} # module => type_placeholder
    MONITOR_MAP = {}          # module => monitor

    # when this module is included, simply keep track of this module so we
    # can start monitoring
    def self.included(mod)
      BREAKABLE << mod
    end

  end
 
  # This module is included for "broken" classes.
  module Broken

    include TypeDefs
    include Runtime

    TYPE_PLACEHOLDER_MAP = {} # module => type_placeholder
 
    # This module will be "extended" to the meta class of the class that 
    # includes Broken module. This allows the meta class to call 'typesig' 
    # method to parse the type signature dynamically.
    # 
    # Usage:
    #   Class A
    #     include RubyBreaker::Broken
    #
    #     typesig("foo(fixnum) -> fixnum")
    #     def foo(x) ... end
    #   end
    #
    module BrokenMeta

      include TypeDefs
      include Runtime

      # This method can be used at the meta level of the target module to
      # specify the type of a method.
      def typesig(str)
        t = TypeSigParser.parse(str)
        placeholder = TYPE_PLACEHOLDER_MAP[self]
        if placeholder
          meth_type = placeholder.inst_meths[t.meth_name]
          if meth_type
            # TODO: make a method list
            if meth_type.instance_of?(MethodListType)
              meth_type.types << t
            else
              # then upgrade it
              placeholder.inst_meths[t.meth_name] = MethodListType.new([meth_type, t])
            end
          else
            placeholder.inst_meths[t.meth_name] = t
          end
        end
        return t
      end
   
    end
   
    # This method is triggered when Broken module is included. This just 
    # extends BrokenMeta into the target module so "typesig" method can be
    # called from the meta level of the module.
    def self.included(mod)

      # Add to the list of broken modules
      BROKEN << mod

      # This MUST BE set for self type to work in type signatures
      SelfType.set_self(mod) 

      # Create if there is no type placeholder for this module yet
      placeholder = TYPE_PLACEHOLDER_MAP[mod] 
      if !placeholder 
        placeholder = TypePlaceholder.new()
        TYPE_PLACEHOLDER_MAP[mod] = placeholder
      end
      mod.extend(BrokenMeta)
    end
    
  end

end

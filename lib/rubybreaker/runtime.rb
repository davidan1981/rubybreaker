#--
# This file provides two methods breakable() and broken() that declares a
# module/class to be monitored
require "set"
require_relative "runtime/overrides"
require_relative "runtime/typesig_parser"
require_relative "runtime/typesig_unparser"
require_relative "runtime/monitor"
require_relative "runtime/inspector"

module RubyBreaker

  module Runtime

    # This set keeps track of modules/classes that will be monitored.
    # *DEPRECATED* : Use +breakable+ method instead.
    BREAKABLES = Set.new 

    # This hash maps a module to a nested hash that maps a method name to a
    # method type. This hash is shared between breakable modules/classes and
    # non-breakable modules/classes.
    TYPE_MAP = {} # module => {:meth_name => type}

    # This hash maps a (breakable) module to a type monitor
    MONITOR_MAP = {}  # module => monitor

    # This set lists modules/classes that are actually instrumented with a
    # monitor.
    INSTALLED = Set.new

    # This method installs a monitor for each breakable module. 
    # *DEPRECATED*: Use +breakable()+ method instead.
    def self.instrument() 
      BREAKABLES.each do |mod|
        # Duplicate checks in place in these calls.
        MonitorInstaller.install_module_monitor(mod)
        INSTALLED << mod
      end
    end

    # This method modifies specified modules/classes at the very moment
    # (instead of registering them for later).
    def self.breakable(*mods)
      mods.each do |mod|
        case mod
        when Array
          self.breakable(*mod)
        when Module, Class
          MonitorInstaller.install_module_monitor(mod)
          eigen_class = self.eigen_class(mod)
          MonitorInstaller.install_module_monitor(eigen_class)
          INSTALLED << mod << eigen_class
        when String, Symbol
          begin
            # Get the actual module and install it right now
            mod = eval("#{mod}", TOPLEVEL_BINDING)
            self.breakable(mod) if mod
          rescue NameError => e
            RubyBreaker.error("#{mod} cannot be found.")
          end
        else
          RubyBreaker.error("You must specify a module/class or its name.")
        end
      end
    end
  end

  # *DEPRECATED*: Use +RubyBreaker.run()+ to indicate the point of entry.
  def self.monitor()
  end

  # This method just redirects to Runtime's method.
  def self.breakable(*mods)
    Runtime.breakable(*mods)
  end

  # *DEPRECATED*: Use +Runtime.breakable()+ or +RubyBreaker.run()+ method
  #               instead.
  module Breakable  
    def self.included(mod)
      Runtime::BREAKABLES << mod << Runtime.eigen_class(mod)
    end
  end

  # *DEPRECATED*: It has no effect.
  module Broken 
    def self.included(mod)
      # Runtime.broken(mod)
    end
  end
end

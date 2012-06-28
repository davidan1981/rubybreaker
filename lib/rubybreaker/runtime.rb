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

  # This module contains things that are needed at runtime.
  module Runtime

    # This set keeps track of modules/classes that will be monitored.
    # *DEPRECATED* : Use +breakable+ method instead.
    BREAKABLES = Set.new 

    private

    # Instruments the monitor to the specified modules/classes. 
    #
    # TODO: monitor_type is currently not in use. Plan on using it in future
    #       to do type checker instrumentation
    def self.install(monitor_type=:break, *mods)
      mods.each do |mod|
        case mod
        when Array
          self.install(monitor_type, *mod)
        when Module, Class
          # Install both instance and its eigen class
          MonitorInstaller.install_monitor(monitor_type, mod)
          eigen_class = self.eigen_class(mod)
          MonitorInstaller.install_monitor(monitor_type, eigen_class)
        when String, Symbol
          begin
            # Get the actual module and install it right now
            mod = eval("#{mod}", TOPLEVEL_BINDING)
            self.install(monitor_type, mod) if mod
          rescue NameError => e
            RubyBreaker.error("#{mod} cannot be found.")
          end
        else
          RubyBreaker.error("You must specify a module/class or its name.")
        end
      end
    end

    public

    # This method instruments the specified modules/classes at the time of
    # the call so they are monitored for type documentation.
    def self.break(*mods)
      self.install(:break, *mods)
    end

    # This method instruments the specified modules/classes at the time of
    # the call so that they are type checked during runtime.
    def self.check(*mods)
      self.install(:check, *mods)
    end

    # This method installs a monitor for each breakable module. 
    # *DEPRECATED*: Use +breakable()+ method instead.
    def self.instrument() 
      BREAKABLES.each do |mod|
        # Duplicate checks in place in these calls.
        MonitorInstaller.install_monitor(:break, mod)
      end
    end

    # This method modifies specified modules/classes at the very moment
    # (instead of registering them for later).
    # *DEPRECATED*: Use +break()+ method instead
    def self.breakable(*mods)
      self.install(:break, *mods)
    end

  end

  # *DEPRECATED*: Use +RubyBreaker.run()+ to indicate the point of entry.
  def self.monitor()
  end

  # This method just redirects to Runtime's method.
  # *DEPRECATED*: Use +RubyBreaker.break()+ to indicate the point of entry.
  def self.breakable(*mods)
    Runtime.breakable(*mods)
  end

  # This method just redirects to Runtime's method.
  def self.break(*mods)
    Runtime.break(*mods)
  end

  def self.check(*mods)
    Runtime.check(*mods)
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

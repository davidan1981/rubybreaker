#-
# This file contains utility functions that are useful for the Runtime
# Library.

module RubyBreaker

  module Runtime

    private

    # This returns the eigen class of the given module.
    def self.eigen_class(mod)
      return mod.module_eval("class << self; self end")
    end

  end

end

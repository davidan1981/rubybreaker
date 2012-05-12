#--
# This file defines the placeholder for types which will be tracked by
# two (global) constant--one for Breakable and the other for Broken.

module RubyBreaker

  module Runtime

    # This class is a placeholder for method types
    class TypePlaceholder

      # This accessor sets/gets instance method map
      attr_accessor :inst_meths  # method name => method type

      # This accessor sets/gets module method map (XXX: not used)
      attr_accessor :mod_meths

      def initialize()
        @inst_meths = {}
        @mod_meths = {}
      end

    end

  end

end

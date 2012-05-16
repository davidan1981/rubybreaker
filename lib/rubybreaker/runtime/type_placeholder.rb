#--
# This file defines the placeholder for types which will be tracked by
# two (global) constant--one for Breakable and the other for Broken.

module RubyBreaker

  module Runtime

    # This class is a placeholder for method types
    class TypePlaceholder

      # This accessor sets/gets instance method map
      attr_accessor :meth_type_map  # method name => method type

      def initialize()
        @meth_type_map = {}
      end

    end

  end

end

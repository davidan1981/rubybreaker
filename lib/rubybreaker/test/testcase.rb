#--
# This file overrides the test case behavior to work with RubyBreaker behind
# the scene without requiring the user to modify the code.

# Do this only if Test::Unit is defined
if defined?(Test) && defined?(Test::Unit)

  # This class is patched to run RubyBreaker along with the test cases.
  class Test::Unit::TestCase #:nodoc:

    # Save the original constructor method.
    alias :__rubybreaker_initialize :initialize #:nodoc:

    # This method overrides the original constructor to run RubyBreaker before
    # calling the original constructor.
    def initialize(*args, &blk) #:nodoc:
      RubyBreaker.run()
      return send(:__rubybreaker_initialize, *args, &blk)
    end

  end
end


#--
# This file overrides the test case behavior to work with RubyBreaker behind
# the scene without requiring the user to modify the code.

require "test/unit"

# This class is patched to run RubyBreaker along with the test cases.
class Test::Unit::TestCase

  # Save the original constructor method.
  alias :__rubybreaker_initialize :initialize

  # This method overrides the original constructor to run RubyBreaker before
  # calling the original constructor.
  def initialize(*args, &blk)
    RubyBreaker::Main.run_as_testcase()
    return send(:__rubybreaker_initialize, *args, &blk)
  end

end


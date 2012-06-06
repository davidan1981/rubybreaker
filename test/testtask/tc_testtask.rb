require "test/unit"
require "rubybreaker"

class RubyBreakerTestTaskTest < Test::Unit::TestCase

  def test_breakable()
    SampleClassA.new.foo(2)
    t = RubyBreaker::Runtime::Inspector.inspect_meth(SampleClassA, :foo)
    str = t.unparse()
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

end


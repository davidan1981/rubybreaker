require "test/unit"
require_relative "sample"
require "rubybreaker"

class SampleClassB # re-opening
  typesig("foo(fixnum[to_s]) -> string")
end

class RubyBreakerTestTaskTest < Test::Unit::TestCase

  def test_breakable()
    SampleClassA.new.foo(2)
    t = RubyBreaker::Runtime::Inspector.inspect_meth(SampleClassA, :foo)
    str = t.unparse()
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

  def test_broken()
    t = RubyBreaker::Runtime::Inspector.inspect_meth(SampleClassB, :foo)
    str = t.unparse()
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

end


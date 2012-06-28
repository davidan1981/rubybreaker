require "test/unit"
require_relative "sample"
require "rubybreaker"

class SampleClassB # re-opening
  typesig("foo(fixnum[to_s]) -> string")
  typesig("bar(fixnum) -> string")
end

class RubyBreakerTestTaskTest < Test::Unit::TestCase
  include RubyBreaker

  def test_break()
    SampleClassA.new.foo(2)
    t = Runtime::Inspector.inspect_meth(SampleClassA, :foo)
    str = t.unparse()
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

  def test_documented()
    t = Runtime::Inspector.inspect_meth(SampleClassB, :foo)
    str = t.unparse()
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

  def test_type_checking()
    b = SampleClassB.new
    assert_nothing_thrown do 
      b.foo(1)
    end
    assert_raise Errors::TypeError do
      b.bar(:"1")
    end
  end

end


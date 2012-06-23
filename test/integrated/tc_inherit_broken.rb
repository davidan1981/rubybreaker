require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedInheritBrokenTest < Test::Unit::TestCase
  include RubyBreaker

  class A
    typesig("foo(fixnum[to_s]) -> string")
    def foo(x); x.to_s end
  end

  class B < A
    def bar(x); foo(x) end
  end

  def setup()
    RubyBreaker.break(B)
  end

  def test_both
    b = B.new
    b.bar(1)
    b_meth_type = Runtime::Inspector.inspect_meth(B, :bar)
    str = RubyBreaker::TypeUnparser.unparse(b_meth_type)
    assert_equal("bar(fixnum[to_s]) -> string", str)
  end

end



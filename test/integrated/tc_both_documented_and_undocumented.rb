require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedBothDocumentedAndUndocumented < Test::Unit::TestCase
  include RubyBreaker

  class A
    typesig("foo(fixnum[to_s]) -> string") 
    def foo(x); x.to_s end
    def bar(x); x.to_sym end
  end

  def setup
    RubyBreaker.break(A)
  end

  def test_both_documented_and_undocumented
    A.new.bar("abc")
    a_foo_meth_type = Runtime::Inspector.inspect_meth(A, :foo)
    a_bar_meth_type = Runtime::Inspector.inspect_meth(A, :bar)
    str = RubyBreaker::TypeUnparser.unparse(a_foo_meth_type)
    assert_equal("foo(fixnum[to_s]) -> string", str)
    str = RubyBreaker::TypeUnparser.unparse(a_bar_meth_type)
    assert_equal("bar(string[to_sym]) -> symbol", str)
  end

end

require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedClassMethodsTest < Test::Unit::TestCase
  include RubyBreaker

  class A
    def self.foo(x); x.to_s end
  end

  class B
    class << self
      typesig("bar(fixnum[+]) -> string")
      def bar(x); x.to_s end
    end
  end

  def setup()
    RubyBreaker.break(A)
    RubyBreaker.check(B)
  end

  def test_class_methods
    A.foo(1)
    a_foo_meth_type = Runtime::Inspector.inspect_class_meth(A, :foo)
    str = RubyBreaker::TypeUnparser.unparse(a_foo_meth_type)
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

  def test_documented_class_methods
    b_bar_meth_type = Runtime::Inspector.inspect_class_meth(B, :bar)
    str = RubyBreaker::TypeUnparser.unparse(b_bar_meth_type)
    assert_equal("bar(fixnum[+]) -> string", str)
  end

  def test_type_checking
    assert_nothing_thrown do
      B.bar(1)
    end
    assert_raise Errors::TypeError do
      B.bar(:abc)
    end
  end

end


require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedClassMethodsTest < Test::Unit::TestCase
  include RubyBreaker

  class A
    def self.foo(x); x.to_s end
  end

  class B
    class << self
      typesig("bar(fixnum[to_s]) -> string")
      def bar(x); x.to_s end
    end
  end

  def setup()
    RubyBreaker.break(A, B)
  end

  def test_class_methods
    A.foo(1)
    a_foo_meth_type = Runtime::Inspector.inspect_class_meth(A, :foo)
    str = RubyBreaker::TypeUnparser.unparse(a_foo_meth_type)
    assert_equal("foo(fixnum[to_s]) -> string", str)
  end

  def test_broken_class_methods
    b_bar_meth_type = Runtime::Inspector.inspect_class_meth(B, :bar)
    str = RubyBreaker::TypeUnparser.unparse(b_bar_meth_type)
    assert_equal("bar(fixnum[to_s]) -> string", str)
  end

end


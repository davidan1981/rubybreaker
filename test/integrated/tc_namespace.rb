require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedNamespaceTest < Test::Unit::TestCase
  include RubyBreaker
  include RubyBreaker::TestCase

  class A < String
    class C < String
      class D < String
        class E < String
        end
      end
      class F
      end
    end
  end

  class B
    include RubyBreaker::Breakable
    def foo(x); x.to_s end
    def bar(x); x.to_s end
    def baz(x); x.to_s end
  end

  def test_namspace_b_foo
    a = A.new
    b = B.new
    b.foo(a)
    meth_type = Runtime::Inspector.inspect_meth(B, :foo)
    str = RubyBreaker::TypeUnparser.unparse(meth_type)
    # puts str
    assert_equal("foo(integrated_namespace_test/a[to_s]) -> string", str, "B#foo failed.")
  end
  
  def test_namspace_b_foo_nested
    a = A::C.new
    b = B.new
    b.bar(a)
    meth_type = Runtime::Inspector.inspect_meth(B, :bar)
    str = RubyBreaker::TypeUnparser.unparse(meth_type)
    # puts str
    assert_equal("bar(integrated_namespace_test/a/c[to_s]) -> string", str, "B#bar failed.")
  end
  
  def test_namespace_e_baz
    e = A::C::D::E.new
    b = B.new
    b.baz(e)
    meth_type = Runtime::Inspector.inspect_meth(B, :baz)
    str = meth_type.unparse(:namespace => A::C::F)
    assert_equal("baz(d/e[to_s]) -> string", str, "B#baz failed.")
  end
  
end


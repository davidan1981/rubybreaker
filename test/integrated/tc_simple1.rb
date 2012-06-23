require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedSimpleTest < Test::Unit::TestCase
  include RubyBreaker

  class A

    def foo(x)
      x.to_s
    end
    
    def bar(x,y)
      x.to_s
      x.size
      y.size
    end
    
    def baz(x,b)
      if b
        x.size
      else
        x.to_s
      end
    end

    def bazz()
      self
    end

  end

  class B
    typesig("baz(string[size], true_class) -> fixnum")
    typesig("baz(string[to_s], false_class) -> string")
    def baz(x,b); end
  end

  def setup()
    RubyBreaker.break(A)
  end

  def test_simple1_a_foo
    a = A.new
    a.foo("test_simple1 >> string")
    meth_type = Runtime::Inspector.inspect_meth(A, :foo)
    str = RubyBreaker::TypeUnparser.unparse(meth_type)
    # puts str
    assert_equal("foo(string[to_s]) -> string", str, "A#foo failed.")
  end
  
  def test_simple1_a_bar
    a = A.new
    a.bar("str1","str2")
    meth_type = Runtime::Inspector.inspect_meth(A, :bar)
    str = RubyBreaker::TypeUnparser.unparse(meth_type)
    # puts str
    assert_equal("bar(string[size, to_s], string[size]) -> fixnum", str, 
                  "A#bar failed.")   
  end
  
  def test_simple1_a_baz
    a = A.new
    a.baz("str1",true)
    a.baz("str2",false)
    a_meth_type = Runtime::Inspector.inspect_meth(A, :baz)
    b_meth_type = Runtime::Inspector.inspect_meth(B, :baz)
    assert(RubyBreaker::Typing.subtype_rel?(a_meth_type, b_meth_type))
    assert(RubyBreaker::Typing.subtype_rel?(b_meth_type, a_meth_type))
  end

  def test_simple1_a_bazz
    a = A.new
    a.bazz()
    a_meth_type = Runtime::Inspector.inspect_meth(A, :bazz)
    assert(a_meth_type.ret_type.eql?(SelfType.new()))
  end
end

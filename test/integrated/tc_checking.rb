require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedCheckingTest < Test::Unit::TestCase
  include RubyBreaker

  class A

    typesig("f1(fixnum) -> string")
    def f1(x); x.to_s end

    typesig("f2(fixnum[to_s]) -> string")
    def f2(x); x.to_s end

    typesig("g2([to_s]) -> string")
    def g2(x); x.to_s end

    typesig("f3(fixnum[foo, to_s]) -> string")
    def f3(x); x.to_s end

    typesig("f4(fixnum) -> fixnum")
    def f4(x); x.to_s end

    typesig("f5(fixnum, fixnum) -> fixnum")
    def f5(x,y); x+y end

    typesig("f6(fixnum, fixnum?, fixnum*) -> fixnum")
    def f6(x, y=1, *z)
      z = eval(z.join("+"))
      x + y + (z ? z : 0)
    end

  end

  def setup()
    RubyBreaker.check(A)
  end

  def test_nominal()
    a = A.new
    assert_nothing_thrown do
      a.f1(2)
    end
    assert_raise RubyBreaker::Errors::ArgumentTypeError do
      a.f1("2")
    end 
  end

  def test_arity()
    a = A.new
    assert_raise Errors::ArityError do
      a.f1(1, 2)
    end
    assert_nothing_thrown do
      a.f6(1, 2)
      a.f6(1, 2, 3)
      a.f6(1, 2, 3, 4)
      a.f6(1, 2, 3, 4, 5)
    end
  end

  def test_duck()
    a = A.new
    assert_nothing_thrown do
      a.g2(2)
      a.g2("2")
    end
  end

  def test_fusion()
    a = A.new
    assert_nothing_thrown do
      a.f2(2)
      a.f3(2) # This will pass too
    end
    assert_raise RubyBreaker::Errors::ArgumentTypeError do
      a.f3("2")
    end 
  end

  def test_ret()
    a = A.new
    assert_raise RubyBreaker::Errors::ReturnTypeError do
      a.f4(2)
    end
  end

  def test_two_fixnums()
    a = A.new
    assert_nothing_thrown do
      a.f5(1, 2)
    end
    assert_raise RubyBreaker::Errors::ArgumentTypeError do
      a.f5("1", 2)
    end
    assert_raise RubyBreaker::Errors::ArgumentTypeError do
      a.f5(1, "2")
    end
  end

end

require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedOriginalBehaviorTest < Test::Unit::TestCase
  include RubyBreaker

  class A

    def foo(x, y)
      x + y.__rubybreaker_obj
    end

    def bar(x)
      if x
        2
      else
        3
      end
    end

    def baz()
      raise "error"
    end

  end

  def setup()
    RubyBreaker.break(A)
  end

  def test_plus()
    a = A.new
    x = 1
    y = 2
    z = a.foo(x, y)
    assert_equal(3, z)
    x = "1"
    y = "2"
    z = a.foo(x, y)
    assert_equal("12",z)
  end

  def test_boolean()
    a = A.new
    x = true
    y = a.bar(x)
    assert_equal(2, y)
    x = false
    y = a.bar(x)
    assert_equal(3, y)
  end

  def test_nil()
    a = A.new
    x = nil
    y = a.bar(x)
    assert_equal(3, y)
  end

  def test_error()
    a = A.new
    assert_raise RuntimeError do
      a.baz()
    end
  end

end


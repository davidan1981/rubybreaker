require "test/unit"
require_relative "../../lib/rubybreaker/runtime"

class ObjectWrapperTest < Test::Unit::TestCase
  include RubyBreaker

  def foo(x)
    x.to_s
    x.to_f
  end

  def bar(x)
    x.to_s
    x.to_s
    x.to_f
    x.to_s
  end

  def test_empty()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    type = wrapped_x.__rubybreaker_type()
    str = TypeUnparser.unparse(type)
    assert_equal("fixnum[]",str)
  end

  def test_simple_foo()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    Runtime::GLOBAL_MONITOR_SWITCH.turn_on()
    foo(wrapped_x)
    Runtime::GLOBAL_MONITOR_SWITCH.turn_off()
    type = wrapped_x.__rubybreaker_type()
    str = TypeUnparser.unparse(type)
    assert_equal("fixnum[to_f, to_s]",str)
  end

  def test_simple_bar()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    Runtime::GLOBAL_MONITOR_SWITCH.turn_on()
    bar(wrapped_x)
    Runtime::GLOBAL_MONITOR_SWITCH.turn_off()
    type = wrapped_x.__rubybreaker_type()
    str = TypeUnparser.unparse(type)
    assert_equal("fixnum[to_f, to_s]",str)
  end

  def test_object_id()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    bar(wrapped_x)
    assert_equal(x.object_id, wrapped_x.object_id)
  end

  def test_equalities_fixnum()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(42 == wrapped_x)
    assert(wrapped_x == 42)
    assert(42.equal?(wrapped_x)) # try 42.equal?(42) in irb, it will work!
    assert(wrapped_x.equal?(42))
    assert(42.eql?(wrapped_x))
    assert(wrapped_x.eql?(42))
    assert_equal(42, wrapped_x)
    assert_equal(42, wrapped_x)
  end

  def test_equalities_string()
    x = "42"
    y = "42"
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y == wrapped_x)
    assert(wrapped_x == y)
    assert(!y.equal?(wrapped_x)) # try "42".equal?("42") in irb, it will fail
    assert(wrapped_x.equal?(y))
    assert(y.eql?(wrapped_x))
    assert(wrapped_x.eql?(y))
    assert_equal(y, wrapped_x)
    assert_equal(y, wrapped_x)
  end

  def test_equalities_symbol()
    x = :"42"
    y = :"42"
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y == wrapped_x)
    assert(wrapped_x == y)
    assert(y.equal?(wrapped_x)) # try :"42".equal?(:"42") in irb, it will work
    assert(wrapped_x.equal?(y))
    assert(y.eql?(wrapped_x))
    assert(wrapped_x.eql?(y))
    assert_equal(y, wrapped_x)
    assert_equal(y, wrapped_x)
  end

  def test_equalities_array()
    x = [1,2]
    y = [1,2]
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y == wrapped_x)
    assert(wrapped_x == y)
    assert(!y.equal?(wrapped_x))
    assert(wrapped_x.equal?(y))
    assert(y.eql?(wrapped_x))
    assert(wrapped_x.eql?(y))
    assert_equal(y, wrapped_x)
    assert_equal(y, wrapped_x)
  end

  def test_inequalities_array()
    x = [1,2]
    y = [1,3]
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y != wrapped_x)
    assert(wrapped_x != y)
    assert(!y.equal?(wrapped_x))
    assert(!wrapped_x.equal?(y))
    assert(!y.eql?(wrapped_x))
    assert(!wrapped_x.eql?(y))
    assert_not_equal(y, wrapped_x)
    assert_not_equal(y, wrapped_x)
  end

  def test_equalities_hash()
    x = { :a => 1, :b => 2}
    y = { :a => 1, :b => 2}
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y == wrapped_x)
    assert(wrapped_x == y)
    assert(!y.equal?(wrapped_x)) 
    assert(wrapped_x.equal?(y))
    assert(y.eql?(wrapped_x))
    assert(wrapped_x.eql?(y))
    assert_equal(y, wrapped_x)
    assert_equal(y, wrapped_x)
  end

  def test_inequalities_hash()
    x = { :a => 1, :b => 2}
    y = { :a => 1, :b => 3}
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(y != wrapped_x)
    assert(wrapped_x != y)
    assert(!y.equal?(wrapped_x)) 
    assert(!wrapped_x.equal?(y))
    assert(!y.eql?(wrapped_x))
    assert(!wrapped_x.eql?(y))
    assert_not_equal(y, wrapped_x)
    assert_not_equal(y, wrapped_x)
  end
end

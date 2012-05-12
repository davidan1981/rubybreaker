dir = File.dirname(__FILE__)
require "test/unit"
require "#{dir}/../../lib/rubybreaker/runtime"

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

  def test_equal()
    x = 42
    wrapped_x = Runtime::ObjectWrapper.new(x)
    assert(wrapped_x == wrapped_x)
    assert(wrapped_x.equal?(wrapped_x))
    assert(wrapped_x.eql?(wrapped_x))
    assert(42 == wrapped_x)
    assert(wrapped_x == 42)
    assert(42.equal?(wrapped_x))
    assert(wrapped_x.equal?(42))
    assert(42.eql?(wrapped_x))
    assert(wrapped_x.eql?(42))
    assert_equal(42, wrapped_x)
    assert_equal(42, wrapped_x)
  end

end

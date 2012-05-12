# This test verifies type signature parser for RubyBreaker. 

dir = File.dirname(__FILE__)

require "test/unit"
require "#{dir}/../../lib/rubybreaker/runtime"

class TypeSigTest < Test::Unit::TestCase
  include RubyBreaker
  
  class A
    include RubyBreaker::Broken
    typesig("foo(fixnum) -> fixnum")
    typesig("bar(fixnum) -> self")
  end

  def test_typesig_a_foo
    foo_type = Runtime::Inspector.inspect_meth(TypeSigTest::A,:foo)
    foo_type_str = TypeUnparser.unparse(foo_type)
    assert_equal("foo(fixnum) -> fixnum", foo_type_str,
                 "foo(fixnum) -> fixnum failed")
  end

  def test_typesig_a_bar
    bar_type = Runtime::Inspector.inspect_meth(TypeSigTest::A,:bar)
    bar_type_str = TypeUnparser.unparse(bar_type)
    assert_equal(A, bar_type.ret_type.mod)
    assert_equal("bar(fixnum) -> self", bar_type_str,
                 "bar(fixnum) -> self failed")
  end


end

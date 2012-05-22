# This test verifies handling of namespace in parsing types.
require "test/unit"
require_relative "../../lib/rubybreaker/type"

class TypeNamespaceTest < Test::Unit::TestCase

  include RubyBreaker

  class A
  end

  def setup
    @parser = Runtime::TypeSigParser::PARSER
  end
  
  def teardown
  end

  def test_namespace_1
    t1 = @parser.parse("foo(type_namespace_test/a[to_s]) -> string").value
    str = t1.unparse(:style => :camelize)
    assert_equal("foo(TypeNamespaceTest::A[to_s]) -> String", str)
  end
  
end

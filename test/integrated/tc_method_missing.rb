require "test/unit"
require_relative "../../lib/rubybreaker"

class IntegratedMethodMissingTest < Test::Unit::TestCase
  include RubyBreaker
  include RubyBreaker::TestCase

  class A
    include RubyBreaker::Breakable

    def method_missing(mname, *args, &blk)
      method_name = mname.to_s
      return method_name + "_" + args.join("_") 
    end

  end

  # TODO: This must be fixed once variable length argument type is supported
  # in auto-documentation.
  def test_a_foo
    a = A.new
    a.foo(1,2)
    meth_type = Runtime::Inspector.inspect_meth(A, :method_missing)
    str = RubyBreaker::TypeUnparser.unparse(meth_type)
    # puts str
    assert_equal("method_missing(symbol[to_s], fixnum[to_s], fixnum[to_s]) -> string", str, "A#foo failed.")
  end
  
end


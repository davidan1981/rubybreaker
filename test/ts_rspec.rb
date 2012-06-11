require "rspec"
require_relative "../lib/rubybreaker"

class RSpecTestA
  def foo(x); x.to_s end
end

class RSpecTestB
  typesig("foo(fixnum[to_s]) -> string")
end

describe "RSpec Test" do

  before do 
    RubyBreaker.breakable(RSpecTestA)
  end

  describe RSpecTestA do
    it "should return a string of number" do
      a = RSpecTestA.new
      a.foo(1)
      a_foo_type = RubyBreaker::Runtime::Inspector.inspect_meth(RSpecTestA, :foo)
      str = a_foo_type.unparse()
      str.should == "foo(fixnum[to_s]) -> string"
    end
  end

  describe RSpecTestB do
    it "should return the documented type of B#foo" do
      b_foo_type = RubyBreaker::Runtime::Inspector.inspect_meth(RSpecTestB, :foo)
      str = b_foo_type.unparse()
      str.should == "foo(fixnum[to_s]) -> string"
    end
  end

end


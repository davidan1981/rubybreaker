# This test verifies type signature parser for RubyBreaker. 

dir = File.dirname(__FILE__)

require "test/unit"
require "#{dir}/../../lib/rubybreaker/type"

class ComparerTest < Test::Unit::TestCase

  include RubyBreaker

  # This function is a helper to compose an error message for comparison
  # test.
  def msg(lhs,rhs,should_fail=false)
    subtype = TypeUnparser.unparse(lhs)
    supertype = TypeUnparser.unparse(rhs)
    str = "#{subtype} = #{supertype}"
    if should_fail
      str = str + " did not fail"
    else
      str = str + " failed"
    end
    return str
  end
  
  def test_nil_any
    t1 = NilType.new()
    t2 = AnyType.new()
    t3 = NilType.new()
    assert(!t1.eql?(t2), msg(t1,t2,true))
    assert(!t2.eql?(t1), msg(t2,t1,true))
    assert(t1.eql?(t3), msg(t1,t3))
    assert(t3.eql?(t1), msg(t3,t1))
  end

  def test_nominal
    t1 = NominalType.new(Fixnum)
    t2 = NominalType.new(Numeric)
    t3 = NominalType.new(String)
    t4 = NominalType.new(String)
    assert(!t1.eql?(t2), msg(t1, t2, true))
    assert(!t1.eql?(t3), msg(t1, t3, true))
    assert(!t2.eql?(t3), msg(t2, t3, true))
    assert(t3.eql?(t4), msg(t3, t4))
  end

  def test_optional_varlength
    t1 = NominalType.new(Fixnum)
    t2 = NominalType.new(Numeric)
    t3 = NominalType.new(String)
    t4 = OptionalType.new(t1)
    t5 = OptionalType.new(t1)
    t6 = OptionalType.new(t2)
    t7 = OptionalType.new(t3)
    t8 = VarLengthType.new(t1)
    t9 = VarLengthType.new(t1)
    t10 = VarLengthType.new(t2)
    t11 = VarLengthType.new(t3)
    assert(t4.eql?(t5), msg(t4, t5))
    assert(!t4.eql?(t6), msg(t4, t6, true))
    assert(t8.eql?(t9), msg(t8, t9))
    assert(!t8.eql?(t10), msg(t8, t10, true))
    assert(!t7.eql?(t11), msg(t7, t11, true))
  end

	def test_self
		t1 = SelfType.new()
		t2 = SelfType.new()
		t3 = NominalType.new(Fixnum)
		assert(t1.eql?(t2), msg(t1, t2))
		assert(!t1.eql?(t3), msg(t1, t3, true))
	end

  def test_duck
    t1 = DuckType.new([:foo, :bar])
    t2 = DuckType.new([:bar, :foo])
    t3 = DuckType.new([:foo, :bar, :baz])
    t4 = DuckType.new([:bar])
    assert(t1.eql?(t2), msg(t1, t2))
    assert(!t1.eql?(t3), msg(t1, t3, true))
    assert(!t1.eql?(t4), msg(t1, t4, true))
  end

  def test_fusion
    t1 = FusionType.new(NominalType.new(Fixnum), [:to_s, :to_f])
    t2 = FusionType.new(NominalType.new(Fixnum), [:to_f, :to_s])
		t3 = FusionType.new(NominalType.new(String), [:to_s, :to_f])
		t4 = DuckType.new([:to_s, :to_f])
		t5 = NominalType.new(Fixnum)
		assert(t1.eql?(t2), msg(t1, t2))
		assert(!t1.eql?(t3), msg(t1, t3, true))
		assert(!t1.eql?(t4), msg(t1, t4, true))
		assert(!t1.eql?(t5), msg(t1, t5, true))
  end

	def test_block_no_arg
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = BlockType.new([],nil,t1) 
		t5 = BlockType.new([],nil,t2)
		t6 = BlockType.new([],nil,t3)
		assert(t4.eql?(t5), msg(t4, t5))
		assert(!t4.eql?(t6), msg(t4, t6, true))
	end
  
	def test_block_one_arg
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = BlockType.new([t1],nil,t3) 
		t5 = BlockType.new([t2],nil,t3)
		t6 = BlockType.new([],nil,t3)
		assert(t4.eql?(t5), msg(t4, t5))
		assert(!t4.eql?(t6), msg(t4, t6, true))
	end

	def test_block_more_args
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = OptionalType.new(NominalType.new(Object))
		t5 = VarLengthType.new(NominalType.new(String))
		t6 = NominalType.new(BasicObject)
		t7 = BlockType.new([t1,t4,t5],nil,t3)
    t8 = BlockType.new([t2,t4,t5],nil,t3)
    t9 = BlockType.new([t1,t5,t4],nil,t3)
    t10 = BlockType.new([t1,t4],nil,t3)
    t11 = BlockType.new([],nil,t3)
    t12 = BlockType.new([t1,t4,t5],BlockType.new([t1,t4,t5],nil,t3),t3)
    assert(t7.eql?(t8), msg(t7, t8))
    assert(!t7.eql?(t9), msg(t7, t9, true))
    assert(!t7.eql?(t10), msg(t7, t10, true))
    assert(!t7.eql?(t11), msg(t7, t11, true))
    assert(!t7.eql?(t12), msg(t7, t12, true))
	end

	def test_method_no_arg
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = MethodType.new(:foo,[],nil,t1) 
		t5 = MethodType.new(:foo,[],nil,t2)
		t6 = MethodType.new(:bar,[],nil,t2)
		t7 = MethodType.new(:foo,[],nil,t3)
		assert(t4.eql?(t5), msg(t4, t5))
		assert(!t4.eql?(t6), msg(t4, t6, true))
		assert(!t4.eql?(t7), msg(t4, t7, true))
	end
  
	def test_method_one_arg
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = MethodType.new(:foo, [t1],nil,t3) 
		t5 = MethodType.new(:foo, [t2],nil,t3)
		t6 = MethodType.new(:foo, [],nil,t3)
		assert(t4.eql?(t5), msg(t4, t5))
		assert(!t4.eql?(t6), msg(t4, t6, true))
	end

	def test_method_one_arg_with_blk
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = BlockType.new([t1],nil,t3) 
		t5 = BlockType.new([t2],nil,t3)
		t6 = BlockType.new([],nil,t3)
    t7 = MethodType.new(:foo, [t1], t4, t3)
    t8 = MethodType.new(:foo, [t2], t5, t3)
    t9 = MethodType.new(:bar, [t1], t4, t3)
    t10 = MethodType.new(:foo, [t1], t6, t3)
		assert(t7.eql?(t8), msg(t7, t8))
		assert(!t7.eql?(t9), msg(t7, t9, true))
		assert(!t7.eql?(t10), msg(t7, t10, true))
	end

	def test_method_more_args
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = OptionalType.new(NominalType.new(Object))
		t5 = VarLengthType.new(NominalType.new(String))
		t6 = NominalType.new(BasicObject)
		t7 = MethodType.new(:foo, [t1,t4,t5],nil,t3)
    t8 = MethodType.new(:foo, [t2,t4,t5],nil,t3)
    t9 = MethodType.new(:foo, [t1,t5,t4],nil,t3)
    t10 = MethodType.new(:foo, [t1,t4],nil,t3)
    t11 = MethodType.new(:foo, [],nil,t3)
    t12 = MethodType.new(:foo, [t1,t4,t5],BlockType.new([t1,t4,t5],nil,t3),t3)
    assert(t7.eql?(t8), msg(t7, t8))
    assert(!t7.eql?(t9), msg(t7, t9, true))
    assert(!t7.eql?(t10), msg(t7, t10, true))
    assert(!t7.eql?(t11), msg(t7, t11, true))
    assert(!t7.eql?(t12), msg(t7, t12, true))
	end

  def test_method_lists
		t1 = NominalType.new(String)
		t2 = NominalType.new(String)
		t3 = NominalType.new(Fixnum)
		t4 = MethodType.new(:foo,[],nil,t1) 
		t5 = MethodType.new(:foo,[],nil,t2)
		t6 = MethodType.new(:bar,[],nil,t2)
		t7 = MethodType.new(:foo,[],nil,t3)
    t8 = MethodListType.new([t4,t6])
    t9 = MethodListType.new([t5,t7])
    assert(!t8.eql?(t9), msg(t8, t9, true))
  end

end

dir = File.dirname(__FILE__)
require "test/unit"
require "#{dir}/../../lib/rubybreaker/type"
require "#{dir}/../../lib/rubybreaker/typing"

class TypingTest < Test::Unit::TestCase

  include RubyBreaker

  class A
    typesig("foo(fixnum) -> fixnum")
    typesig("bar(fixnum) {|fixnum| -> string} -> string")
    typesig("baz(fixnum, string?) -> fixnum")
    typesig("bazz(fixnum, string*) -> fixnum")
  end

  # This function is a helper to compose an error message for subtyping
  # test.
  def msg(lhs,rhs,should_fail=false)
    subtype = lhs.unparse()
    supertype = rhs.unparse()
    str = "#{subtype} <: #{supertype}"
    if should_fail
      str = str + " did not fail"
    else
      str = str + " failed"
    end
    return str
  end

  def test_any()
    t1 = AnyType.new
    t2 = NilType.new
    assert(t1.subtype_of?(t2), msg(t1,t2))
    assert(!t2.subtype_of?(t1), msg(t2,t1,true))
  end 

  def test_nil()
    t1 = NilType.new
    t2 = NilType.new
    t3 = NominalType.new(Fixnum)
    assert(t1.subtype_of?(t2), msg(t1,t2))
    assert(t2.subtype_of?(t1), msg(t1,t2))
    assert(!t3.subtype_of?(t2), msg(t3,t2,true))
    assert(!t2.subtype_of?(t3), msg(t3,t2,true))
  end

  def test_nominal()
    t1 = NominalType.new(Fixnum)
    t2 = NominalType.new(Numeric)
    t3 = NominalType.new(Object)
    t4 = NominalType.new(String)
    assert(t1.subtype_of?(t2), msg(t1,t2))
    assert(!t2.subtype_of?(t1), msg(t2,t1,true))
    assert(t1.subtype_of?(t3), msg(t1,t3))
    assert(!t3.subtype_of?(t1), msg(t3,t1,true))
    assert(!t1.subtype_of?(t4), msg(t1,t4,true))
    assert(!t4.subtype_of?(t1), msg(t4,t1,true))
  end

  def test_self()
    SelfType.set_self(Fixnum)
    t1 = SelfType.new()
    t2 = SelfType.new()
    SelfType.set_self(String)
    t3 = SelfType.new()
    t4 = NominalType.new(Numeric)
    t5 = NominalType.new(String)
    t6 = DuckType.new([:to_s])
    assert(t1.subtype_of?(t2), msg(t1,t2))
    assert(t2.subtype_of?(t1), msg(t2,t1))
    assert(t1.subtype_of?(t3), msg(t1, t3))
    assert(t3.subtype_of?(t1), msg(t3, t1))
    assert(t1.subtype_of?(t4), msg(t1, t4))
    assert(!t4.subtype_of?(t1), msg(t4, t1, true))
    assert(!t1.subtype_of?(t5), msg(t1, t5, true))
    assert(!t5.subtype_of?(t1), msg(t5, t1, true))
    assert(t1.subtype_of?(t6), msg(t1, t5))
    assert(!t6.subtype_of?(t1), msg(t5, t1, true))
  end

  def test_duck_types_id()
    t1 = DuckType.new([:foo,:baz]) 
    t2 = DuckType.new([:baz,:foo])
    assert(t1.subtype_of?(t2),msg(t1,t2))
  end

  def test_duck_types()
    t1 = DuckType.new([:foo,:bar,:baz])
    t2 = DuckType.new([:foo,:baz]) 
    assert(t1.subtype_of?(t2),msg(t1,t2))
    assert(!t2.subtype_of?(t1),msg(t2,t1,true))
  end

  def test_fusion_types()
    t1 = FusionType.new(NominalType.new(Fixnum), [:to_s, :to_f])
    t2 = FusionType.new(NominalType.new(Fixnum), [:to_f, :to_s])
    t3 = FusionType.new(NominalType.new(String), [:to_s, :to_f])
    assert(t1.subtype_of?(t2), msg(t1, t2))
    assert(t2.subtype_of?(t1), msg(t1, t2))
    # XXX: The following assert will succeed because Fixnum and String are
    # not "broken" at this point.
    assert(t1.subtype_of?(t3), msg(t1, t3, true))
  end

  def test_duck_fusion_types()
    t1 = DuckType.new([:to_s, :to_f])
    t2 = FusionType.new(NominalType.new(Fixnum), [:to_f, :to_s])
    # Again, this works because Fixnum is not "broken" yet 
    assert(t1.subtype_of?(t2), msg(t1, t2))
    assert(t2.subtype_of?(t1), msg(t1, t2))
  end
  
  def test_duck_nominal_types()
    t1 = DuckType.new([:to_s, :to_f])
    t2 = NominalType.new(Fixnum)
    t3 = NominalType.new(Symbol)
    assert(!t1.subtype_of?(t2), msg(t1, t2, true))
    assert(!t1.subtype_of?(t3), msg(t1, t3, true))
    assert(t2.subtype_of?(t1), msg(t2, t1))
    assert(!t3.subtype_of?(t1), msg(t3, t1, true))
  end

  def test_nominal_and_other_types()
    t1 = NominalType.new(Fixnum)
    t2 = FusionType.new(NominalType.new(Fixnum), [:to_s, :to_f])
    t3 = FusionType.new(NominalType.new(String), [:to_s, :to_f])
    t4 = DuckType.new([:to_s, :to_f])
    t5 = DuckType.new([:to_s, :to_f, :foo])
    assert(t1.subtype_of?(t2), msg(t1, t2))
    assert(!t2.subtype_of?(t1), msg(t2, t1, true))
    assert(t1.subtype_of?(t3), msg(t1, t3))
    assert(!t3.subtype_of?(t1), msg(t3, t1, true))
    assert(t1.subtype_of?(t4), msg(t1, t4))
    assert(!t4.subtype_of?(t1), msg(t4, t1, true))
    assert(!t1.subtype_of?(t5), msg(t1, t5, true))
    assert(!t5.subtype_of?(t1), msg(t5, t1, true))
  end

  def test_blk_types_id()
    t1 = NominalType.new(Fixnum)
    t2 = NominalType.new(String)
    t3 = BlockType.new([t1],nil,t2)
    t4 = BlockType.new([t1],nil,t2)
    assert(t3.subtype_of?(t4),msg(t3,t4))
    assert(t4.subtype_of?(t3),msg(t4,t3))
  end

  def test_blk_types_no_blk_ret_type_diff()
    t1 = NominalType.new(Fixnum)
    t2 = NominalType.new(String)
    t3 = NominalType.new(Fixnum)
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_blk_types_no_blk_one_arg()
    t1 = NominalType.new(Object)
    t2 = NominalType.new(String)
    t3 = NominalType.new(Fixnum)
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_blk_types_no_blk_opt_arg()
    t1 = OptionalType.new(NominalType.new(Object))
    t2 = NominalType.new(String)
    t3 = NominalType.new(Fixnum)
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_blk_types_no_blk_both_opt_arg()
    t1 = OptionalType.new(NominalType.new(Object))
    t2 = NominalType.new(String)
    t3 = OptionalType.new(NominalType.new(Fixnum))
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_blk_types_no_blk_varlen_arg()
    t1 = VarLengthType.new(NominalType.new(Object))
    t2 = NominalType.new(String)
    t3 = NominalType.new(Fixnum)
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_blk_types_no_blk_both_varlen_arg()
    t1 = VarLengthType.new(NominalType.new(Object))
    t2 = NominalType.new(String)
    t3 = VarLengthType.new(NominalType.new(Fixnum))
    t4 = NominalType.new(Object)
    t5 = BlockType.new([t1],nil,t2)
    t6 = BlockType.new([t3],nil,t4)
    assert(t5.subtype_of?(t6),msg(t5,t6))
    assert(!t6.subtype_of?(t5),msg(t6,t5,true))
  end

  def test_broken_nominal()
  end

end

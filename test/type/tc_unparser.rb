# This test verifies type unparser for RubyBreaker types.

dir = File.dirname(__FILE__)
require "test/unit"
require "#{dir}/../../lib/rubybreaker/type"

class UnparserTest < Test::Unit::TestCase

  include RubyBreaker
  
  class A; end
  class B; end
  class C; end
  class D; end
  class E; end

  def test_nil_type()
    t1 = NilType.new
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("nil",str1.strip())
  end

  def test_any_type()
    t1 = AnyType.new
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("?",str1.strip())
  end

  def test_nominal_type()
    t1 = NominalType.new(A)
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("a",str1)
  end

  def test_self_type()
    t1 = SelfType.new()
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("self", str1)
  end

  def test_opt_type()
    t1 = NominalType.new(A)
    t2 = OptionalType.new(t1)
    str2 = TypeUnparser.unparse(t2)
    # puts str1
    assert_equal("a?",str2)
  end

  def test_opt_or_type()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = OrType.new([t1, t2])
    t4 = OptionalType.new(t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str1
    assert_equal("(a || b)?",str4)
  end

  def test_star_type()
    t1 = NominalType.new(A)
    t2 = VarLengthType.new(t1)
    str2 = TypeUnparser.unparse(t2)
    # puts str1
    assert_equal("a*",str2)
  end

  def test_star_duck_type()
    t1 = DuckType.new([:foo, :bar])
    t2 = VarLengthType.new(t1)
    str2 = TypeUnparser.unparse(t2)
    # puts str1
    assert_equal("[bar, foo]*",str2)
  end

  def test_star_fusion_type()
    t1 = FusionType.new(NominalType.new(A), [:foo, :bar])
    t2 = VarLengthType.new(t1)
    str2 = TypeUnparser.unparse(t2)
    # puts str1
    assert_equal("a[bar, foo]*",str2)
  end

  def test_star_or_type()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = OrType.new([t1, t2])
    t4 = VarLengthType.new(t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str1
    assert_equal("(a || b)*",str4)
  end

  def test_duck_type()
    t1 = DuckType.new(["+"])
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("[+]",str1)
  end
  
  def test_duck_type_more_meths()
    t1 = DuckType.new(["+","foo","bar"])
    str1 = TypeUnparser.unparse(t1)
    #puts str1
    assert_equal("[+, bar, foo]",str1)
  end

  def test_duck_type_symbolic_meths()
    t1 = DuckType.new(["+","-","[]","[]="])
    str1 = TypeUnparser.unparse(t1)
    #puts str1
    assert_equal("[+, -, [], []=]",str1)
  end

  def test_fusion_type()
    t1 = FusionType.new(NominalType.new(A), ["+"])
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("a[+]",str1)
  end

  def test_fusion_type_more_meths()
    t1 = FusionType.new(NominalType.new(A), ["+","foo","bar"])
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("a[+, bar, foo]",str1)
  end
  
  def test_fusion_type_symbolic_meths()
    t1 = FusionType.new(NominalType.new(A), ["+","-","[]","[]="])
    str1 = TypeUnparser.unparse(t1)
    # puts str1
    assert_equal("a[+, -, [], []=]",str1)
  end

  def test_or_type()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = OrType.new([t1,t2])
    str3 = TypeUnparser.unparse(t3)
    # puts str3
    assert_equal("a || b", str3)
  end

  def test_or_type_more_types()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = OrType.new([t1,t2,t3])
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("a || b || c", str4)
  end

  def test_block_type_no_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = BlockType.new([t1],nil,t2)
    str3 = TypeUnparser.unparse(t3)
    # puts str3
    assert_equal("|a| -> b",str3)
  end

  def test_block_type_more_args_no_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = BlockType.new([t1,t2],nil,t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("|a, b| -> c",str4)
  end
  
  def test_block_type_ret_self()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = SelfType.new()
    t4 = BlockType.new([t1,t2],nil,t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("|a, b| -> self",str4)
  end

  def test_block_type()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = NominalType.new(D)
    t5 = BlockType.new([t1],BlockType.new([t2],nil,t3),t4)
    str5 = TypeUnparser.unparse(t5)
    # puts str5
    assert_equal("|a| {|b| -> c} -> d",str5)
  end
  
  def test_block_type_more_args()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = NominalType.new(D)
    t5 = NominalType.new(E)
    t6 = BlockType.new([t1,t2],BlockType.new([t3],nil,t4),t5)
    str6 = TypeUnparser.unparse(t6)
    # puts str5
    assert_equal("|a, b| {|c| -> d} -> e",str6)
  end 

  def test_block_type_or_args()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = NominalType.new(D)
    t5 = NominalType.new(E)
    t6 = BlockType.new([OrType.new([t1,t2])],BlockType.new([t3],nil,t4),t5)
    str6 = TypeUnparser.unparse(t6)
    # puts str5
    assert_equal("|a || b| {|c| -> d} -> e",str6)
  end

  def test_method_type_no_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = MethodType.new("m",[t1],nil,t2)
    str3 = TypeUnparser.unparse(t3)
    # puts str3
    assert_equal("m(a) -> b", str3)
  end
  
  def test_method_type_symbolic_methname()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = MethodType.new("==",[t1],nil,t2)
    str3 = TypeUnparser.unparse(t3)
    # puts str3
    assert_equal("==(a) -> b", str3)
  end

  def test_method_type_more_args_no_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = MethodType.new("m",[t1,t2],nil,t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("m(a, b) -> c", str4)
  end

  def test_method_type_ret_self()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = SelfType.new()
    t4 = MethodType.new("m",[t1,t2],nil,t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("m(a, b) -> self", str4)
  end

  def test_method_type_or_args_no_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = MethodType.new("m",[OrType.new([t1,t2])],nil,t3)
    str4 = TypeUnparser.unparse(t4)
    # puts str3
    assert_equal("m(a || b) -> c", str4)
  end

  def test_method_type_with_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = NominalType.new(D)
    t5 = MethodType.new("m",[t1],BlockType.new([t2],nil,t3),t4)
    str5 = TypeUnparser.unparse(t5)
    # puts str5
    assert_equal("m(a) {|b| -> c} -> d", str5)
  end

  def test_method_type_more_args_with_blk()
    t1 = NominalType.new(A)
    t2 = NominalType.new(B)
    t3 = NominalType.new(C)
    t4 = NominalType.new(D)
    t5 = NominalType.new(E)
    t6 = MethodType.new("m",[t1,t2],BlockType.new([t3],nil,t4),t5)
    str6 = TypeUnparser.unparse(t6)
    # puts str5
    assert_equal("m(a, b) {|c| -> d} -> e", str6)
  end
end

# This test verifies type signature parser for RubyBreaker. 

dir = File.dirname(__FILE__)

require "test/unit"
require "#{dir}/../../lib/rubybreaker/type"

class GrammarTest < Test::Unit::TestCase

  include RubyBreaker
  
  def setup
    @parser = Runtime::TypeSigParser::PARSER
  end
  
  def teardown
  end

  def test_symbol_method_names
    meth_names = [:"===", :"<=>", :"[]=", 
                  :"==", :"!=", :"<<", :">>", :"[]", :"**",
                  :"<=", :">=", :"-@", :"=~", 
                  :"<", :">", :"&", :"|", :"*", :"/",
                  :"%", :"+", :"-", :"^"] 
    meth_names.each do |meth_name|
      type = @parser.parse("#{meth_name}() -> basic_object").value
      str = TypeUnparser.unparse(type)
      assert_equal("#{meth_name}() -> basic_object", str)
    end
  end
  
  def test_method_type_no_arg_no_blk
    type = @parser.parse("foo() -> basic_object").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() -> basic_object", str)
  end
  
  def test_method_type_nil_ret
    type = @parser.parse("foo() -> nil").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() -> nil", str)
  end
  
  def test_method_type_self_ret
    type = @parser.parse("foo() -> self").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() -> self", str)
  end

  def test_method_type_any_type1
    type = @parser.parse("foo() -> ?").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() -> ?", str)
  end
  
  # def test_method_type_any_type2
  #   type = @parser.parse("foo() -> []").value
  #   str = TypeUnparser.unparse(type)
  #   #puts str
  #   assert_equal("foo() -> ?", str)
  # end
  
  def test_method_type_one_arg_no_blk
    type = @parser.parse("foo(fixnum) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum) -> fixnum",str)
  end
  
  def test_method_type_two_args_no_blk
    type = @parser.parse("foo(fixnum,string) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum, string) -> fixnum",str)
  end
  
  def test_method_type_or_args_no_blk
    type = @parser.parse("foo(fixnum || string) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum || string) -> fixnum",str)
  end

  def test_method_type_one_arg_empty_blk
    type = @parser.parse("foo(fixnum) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum) -> fixnum",str)
  end

  def test_method_type_opt_arg_empty_blk
    type = @parser.parse("foo(fixnum?) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    assert_equal("foo(fixnum?) -> fixnum",str)
  end

  def test_method_type_opt_or_arg_empty_blk
    type = @parser.parse("foo((fixnum || string)?) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    assert_equal("foo((fixnum || string)?) -> fixnum",str)
  end

  def test_method_type_varlen_or_arg_empty_blk
    type = @parser.parse("foo((fixnum || string)*) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    assert_equal("foo((fixnum || string)*) -> fixnum",str)
  end

  def test_method_type_opt_args_empty_blk
    type = @parser.parse("foo(string, symbol?, fixnum?) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    assert_equal("foo(string, symbol?, fixnum?) -> fixnum",str)
  end
  
  def test_method_type_varlen_arg_empty_blk
    type = @parser.parse("foo(fixnum*) { } -> fixnum").value
    str = TypeUnparser.unparse(type)
    assert_equal("foo(fixnum*) -> fixnum",str)
  end

  def test_method_type_opt_args_varlen_arg_empty_blk
    sig = "foo(string, symbol?, fixnum?, string*) { } -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    assert_equal("foo(string, symbol?, fixnum?, string*) -> fixnum",str)
  end

  def test_method_type_one_arg_blk
    type = @parser.parse("foo(fixnum) {|fixnum| -> string} -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum) {|fixnum| -> string} -> fixnum",str)
  end

  def test_method_type_blk_two_args
    sig = "foo() {|fixnum,string| -> string} -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() {|fixnum, string| -> string} -> fixnum",str)
  end
  
  def test_method_blk_two_args
    sig = "foo(fixnum) {|fixnum,float| -> string} -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum) {|fixnum, float| -> string} -> fixnum",str)  
  end
  
  def test_method_type_blk_three_args_opt_args
    sig = "foo() {|fixnum,string?, float?| -> string} -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() {|fixnum, string?, float?| -> string} -> fixnum",str)
  end

  def test_method_type_blk_three_args_varlen_arg
    sig = "foo() {|fixnum,string, float*| -> string} -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() {|fixnum, string, float*| -> string} -> fixnum",str)
  end

  def test_method_type_blk_three_args_opt_varlen_args
    sig = "foo() {|fixnum,string?, float*| -> string} -> fixnum"
    type = @parser.parse(sig).value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() {|fixnum, string?, float*| -> string} -> fixnum",str)
  end

  def test_method_duck_arg
    type = @parser.parse("foo([m1]) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo([m1]) -> fixnum",str)    
  end

  def test_method_duck_arg_more_methods
    type = @parser.parse("foo([m1,m2,m3?]) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo([m1, m2, m3?]) -> fixnum",str)    
  end
  
  def test_method_fusion_arg
    type = @parser.parse("foo(fixnum[to_s]) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum[to_s]) -> fixnum",str)    
  end
  
  def test_method_fusion_arg_more_methods
    type = @parser.parse("foo(fixnum[to_s,to_i]) -> fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum[to_i, to_s]) -> fixnum",str)    
  end
  
  def test_space_around
    type = @parser.parse("    foo() -> nil ").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo() -> nil", str)
  end

  def test_multi_line_1
    type = @parser.parse("foo(fixnum[to_s,to_i]) -> 
                          fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum[to_i, to_s]) -> fixnum",str)    
  end

  def test_multi_line_2
    type = @parser.parse("foo(fixnum[to_s,
                                     to_i]) 
                          -> 
                          fixnum").value
    str = TypeUnparser.unparse(type)
    #puts str
    assert_equal("foo(fixnum[to_i, to_s]) -> fixnum",str)    
  end

  def test_parse_fail_no_methname
    type = @parser.parse("() -> nil")
    assert_equal(nil, type, "Type signature without a method name")
  end

end 

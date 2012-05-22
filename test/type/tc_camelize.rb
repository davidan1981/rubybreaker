# This test verifies type unparser for RubyBreaker types.
require "test/unit"
require_relative "../../lib/rubybreaker/type"

class UnparserCamelizeTest < Test::Unit::TestCase

  include RubyBreaker
  
  class CamelizedClassName; end

  def test_camelize_type()
    t1 = NominalType.new(CamelizedClassName)
    str1 = t1.unparse({:style => :camelize, :namespace => UnparserCamelizeTest})
    # puts str1
    assert_equal("CamelizedClassName",str1.strip())
  end

  def test_camelize_no_namespace_type()
    t1 = NominalType.new(CamelizedClassName)
    str1 = t1.unparse({:style => :camelize, :namespace => UnparserCamelizeTest})
    # puts str1
    assert_equal("CamelizedClassName",str1.strip())
  end
end

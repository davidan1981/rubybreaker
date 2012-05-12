dir = File.dirname(__FILE__)
require "test/unit"
require "#{dir}/../../lib/rubybreaker/typing"


class RubyTypeTest < Test::Unit::TestCase

  module M1
  end
  
  module M2
    include M1
  end
  
  module M3
    include M2
  end
  
  module M4
  end
  
  module M5
    include M2
    include M4
  end
  
  include RubyBreaker
  
  def test_subclass_1
    cls1 = Fixnum
    cls2 = Numeric
    assert(RubyTypeUtils.subclass_rel?(cls1,cls2))
    assert(!RubyTypeUtils.subclass_rel?(cls2,cls1))
  end
  
  def test_subclass_2
    cls1 = String
    cls2 = Fixnum
    assert(!RubyTypeUtils.subclass_rel?(cls1,cls2))
    assert(!RubyTypeUtils.subclass_rel?(cls2,cls1))
  end
  
  def test_subclass_3
    cls1 = Array
    mod1 = Enumerable
    assert(RubyTypeUtils.subclass_rel?(cls1,mod1))
    assert(!RubyTypeUtils.submodule_rel?(mod1,cls1))
  end
  
  def test_subclass_4
    assert(!RubyTypeUtils.submodule_rel?(M1,M2))
    assert(RubyTypeUtils.submodule_rel?(M2,M1))
    assert(RubyTypeUtils.submodule_rel?(M3,M1))
    assert(!RubyTypeUtils.submodule_rel?(M1,M3))
    assert(RubyTypeUtils.submodule_rel?(M5,M1))
    assert(RubyTypeUtils.submodule_rel?(M5,M2))
    assert(!RubyTypeUtils.submodule_rel?(M5,M3))
    assert(RubyTypeUtils.submodule_rel?(M5,M4))
  end

  
  
end

#--
# This file contains methods that need to override the existing ones to
# accommodate the object wrapper. The main issue arises when a wrapped
# object is compared against a non-wrapped object in either direction. Going
# from a wrapped object, this issue is resolved by overriding the comparison
# operators, but going from a non-wrapped object, the override has to
# happen on the non-wrapped side. This file is for those overrides.
#
# XXX: THIS FILE NEEDS A LOT OF WORK!!! 
#

require_relative "object_wrapper"

module RubyBreaker

  module Runtime

    # This constant holds the string used internally by RubyBreaker to
    # indicate overridden methods.
    OVERRIDE_PREFIX = "__rubybreaker"

    # Prohibit these module/class+method from being overriden
    BLACKLIST = {
      String => [:to_s, :<<, :concat, :gsub],
    }

  end

end

# TODO: More IO related stuff need to be overriden!
[Kernel, IO].each do |mod|

  [:"puts", :"putc", :"printf", :print].each do |meth_name|

    mod.module_eval <<-EOS

    alias :"#{RubyBreaker::Runtime::OVERRIDE_PREFIX}_#{mod.object_id}_#{meth_name}" :"#{meth_name}"

    EOS

    mod.module_eval <<-EOS

    def #{meth_name}(*args)
      args = args.map do |arg|
        if arg.respond_to?(RubyBreaker::Runtime::WRAPPED_INDICATOR)
          arg.__rubybreaker_obj
        else
          arg
        end
      end
      send(:"#{RubyBreaker::Runtime::OVERRIDE_PREFIX}_#{mod.object_id}_#{meth_name}",*args)
    end

    EOS
  
  end

end

[Symbol, Numeric, Fixnum, Float, Integer, Bignum, String].each do |mod|
  mod.instance_methods(false).each do |meth_name|
    black_list = RubyBreaker::Runtime::BLACKLIST
    next if black_list[mod] && black_list[mod].include?(meth_name)
    alias_name = "#{RubyBreaker::Runtime::OVERRIDE_PREFIX}_#{mod.object_id}" +
                 "_#{meth_name}"
    mod.module_eval <<-EOS

    alias :"#{alias_name}" :"#{meth_name}"

    def #{meth_name}(*args)
      args = args.map do |arg|
        if arg.respond_to?(RubyBreaker::Runtime::WRAPPED_INDICATOR)
          arg.__rubybreaker_obj
        else
          arg
        end
      end
      send(:"#{RubyBreaker::Runtime::OVERRIDE_PREFIX}_#{mod.object_id}_#{meth_name}",*args)
    end

    EOS
  end
end

# TODO: add more modules here as necessary!
[Object, Enumerable, Array, Hash].each do |mod| 

  [:"==", :equal?, :eql?].each do |meth_name|

    # Create a unique alias name for each module. (It causes some issue when
    # not done this way.)
    alias_name = "RubyBreaker::Runtime::OVERRIDE_PREFIX_#{mod.object_id}" +
                 "_#{meth_name}"

    mod.module_eval <<-EOS

  alias :"#{alias_name}" :"#{meth_name}"

  def #{meth_name}(other)
    if other.respond_to?(RubyBreaker::Runtime::WRAPPED_INDICATOR)
      other = other.__rubybreaker_obj
    end
    return self.send(:"#{alias_name}",other)
  end

    EOS

  end

end





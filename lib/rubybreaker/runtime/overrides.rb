#--
# This file contains methods that need to override the existing ones to
# accommodate the object wrapper.

require_relative "object_wrapper"

module RubyBreaker

  module Runtime

    # This constant holds the string used internally by RubyBreaker to
    # indicate overridden methods.
    OVERRIDE_PREFIX = "__rubybreaker_"

  end

end


class Numeric

  [:"==", :equal?, :eql?].each do |m|

    eval <<-EOS

  alias :"#{RubyBreaker::Runtime::OVERRIDE_PREFIX}#{m}" :"#{m}"
  def #{m}(other)
    if other.respond_to?(RubyBreaker::Runtime::WRAPPED_INDICATOR)
      other = other.__rubybreaker_obj
    end
    return self.send(:"#{RubyBreaker::Runtime::OVERRIDE_PREFIX}#{m}", other)
  end

    EOS

  end

end





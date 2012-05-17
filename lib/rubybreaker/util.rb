#--
# This file contains utility functions that are useful for RubyBreaker. They
# may have been taken from other sources.

module RubyBreaker

  module Utilities

    # File activesupport/lib/active_support/inflector/methods.rb, line 48
    def self.underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
    
    # File activesupport/lib/active_support/inflector/methods.rb
    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else  
        lower_case_and_underscored_word.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
      end   
    end    

  end

  # http://mentalized.net/journal/2010/04/02/suppress_warnings_from_ruby/
  module Kernel
    def suppress_warning
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = original_verbosity
      return result
    end
  end
end

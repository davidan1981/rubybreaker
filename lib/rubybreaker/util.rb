#--
# This file contains utility functions that are useful for RubyBreaker. They
# may have been taken from other sources.

module RubyBreaker

  # This module has utility functions that are useful across all components
  # in the project.
  module Util

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

    # Below classes are used for internal testing 
    
    class ::SampleClassA
      def foo(x); x.to_s end
    end

    class ::SampleClassB
      def foo(x); x.to_s end
    end

  end

end

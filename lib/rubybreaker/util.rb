#--
# This file contains utility functions that are useful for RubyBreaker. They
# may have been taken from other sources.

module RubyBreaker

  # This module has utility functions that are useful across all components
  # in the project.
  module Util

    def self.uneigen(mod_str)
      result = /^#<Class:(.+)>#/.match(mod_str)
      if result 
        return result[0]
      else
        return mod_str
      end
    end

    # File lib/active_support/inflector.rb, line 295
    def self.ordinalize(number)
      if (11..13).include?(number.to_i % 100)
        "#{number}th"
      else
        case number.to_i % 10
          when 1; "#{number}st"
          when 2; "#{number}nd"
          when 3; "#{number}rd"
          else    "#{number}th"
        end
      end
    end

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

end

#--
# This program parses a type signature given by the Ruby programmer in the
# RubyBreaker type format.

require "treetop"
require_relative "../type"

module RubyBreaker

  module Runtime
  
    module TypeSigParser
      
      Treetop.load "#{File.dirname(__FILE__)}/../type/type_grammar"
      PARSER = TypeGrammarParser.new
    
      public
          
      # This is a simple redirecting method for parsing type signature. The
      # only special thing about this method is that, if there are multiple
      # lines in the signature, it will look at each line and construct a
      # MethodListType to represent the intersection type.
      def self.parse(str)

        meth_types = []
        
        # Get caller information and set the global location 
        my_caller = caller[1]
        if my_caller
          file,line,junk = my_caller.split(":")
          Position.set(file,line,-1)
        end

        return PARSER.parse(str).value
        
      rescue => e
        
        puts e
        
      end
      
    end

  end
  
end

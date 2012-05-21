#--
# This file mimics the Ruby testing framework. This is provided so that
# RubyBreaker can be used seamlessly with the traditional Ruby framework
# (supposedly :) ).

module RubyBreaker

  # This module overrides the normal behavior of Ruby Stdlib's TestCase
  # class. 
  module TestCase

    def self.__rubybreaker_setup()
      Main.setup()
    end

    def self.__rubybreaker_teardown()
      # Main.output()
    end

    def self.included(mod)

      # hack to insert RubyBreaker's own setup and teardown methods
      mod.module_eval <<-EOS

      alias :__run :run

      def run(*args,&blk)
        RubyBreaker::TestCase.__rubybreaker_setup()
        __run(*args,&blk)
        RubyBreaker::TestCase.__rubybreaker_teardown()
      end

      EOS

    end
  end
end


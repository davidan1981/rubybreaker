#--
# This file is for debugging RubyBreaker.

require "prettyprint"
require_relative "context"

module RubyBreaker

  # This module is for internal purpose only - to help ourselves find bugs
  # and fix them with more informative error messages.
  module Debug

    OUTPUT = ""

    def self.msg(text,context=nil)
      return unless RubyBreaker::OPTIONS[:debug]
      pp = PrettyPrint.new(OUTPUT)
      msg = "[DEBUG] #{text}"
      if context
        context.format_with_msg(pp,msg)
      else
        pp.text(msg,79)
        pp.breakable()
      end
      pp.flush
      puts OUTPUT
      OUTPUT.replace("")
    end

    def self.short_msg(text)
      return unless RubyBreaker::OPTIONS[:debug]
      msg = "[DEBUG] #{text}"
      print msg
    end

    def self.token(msg)
      return unless RubyBreaker::OPTIONS[:debug]
      print msg
    end

    def self.feed_line()
      return unless RubyBreaker::OPTIONS[:debug]
      puts ""
    end

  end

end

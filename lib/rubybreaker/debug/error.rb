#--
# This file defines various errors that are used by RubyBreaker both
# internally and externally.

module RubyBreaker

  # This module contains errors used by RubyBreaker.
  module Errors

    ########### INTERNAL ERRORS

    # This class is a base class for any internal errors. It should be used to
    # inform the faults within the program and not related to user programs.
    class InternalError < ::Exception
      def initialize(msg)
        @level = :FATAL if @level == nil 
        msg = "[#{@level}] #{msg} at #{@pos}" 
        super(msg)
      end
    end

    # This error is thrown when a type is constructed with invalid elements.
    class InvalidTypeConstruction < InternalError
    end 

    # This error is thrown when a subtype check is not even appropriate for
    # two given types. It should NOT BE USED for any check failures. 
    class InvalidSubtypeCheck < InternalError
      def initialize(msg,pos=nil)
        @level = :FATAL
        @pos = pos ? pos : Position.convert_caller_to_pos(caller(1))
        super("InvalidSubtypingCheck: #{msg}")
      end
    end

    ########### USER ERRORS

    # This class is a base class for any user errors. Unlike internal error,
    # it should use a Context to inform the source of the error rather than a
    # Position since user errors tend to generate over multiple points in the
    # program.
    class UserError < ::Exception
      
      def initialize(msg, ctx=nil)
        super(msg)
        @ctx = ctx
      end

    end

    class TypeError < UserError
    end

    class SubtypeFailure < TypeError
    end

  end

end

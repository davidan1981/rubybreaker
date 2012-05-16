#--
# This file contains a module that explains what is eligible to be a
# pluggable type system (or anything really). (Think of AOP but for metod
# calls only.)

module RubyBreaker

  module Runtime

    # This class has information (and data) of the method being called. Used
    # by Pluggable and Monitor
    class MethodInfo

      attr_accessor :meth_name
      attr_accessor :args
      attr_accessor :blk
      attr_accessor :ret

      def initialize(meth_name, args, blk, ret)
        @meth_name = meth_name
        @args = args
        @blk = blk
        @ret = ret
      end

    end

    # Any Pluggable module can be "plugged" into the RubyBreaker monitoring
    # system. For example, if you write your own type system for
    # RubyBreaker, you can include this module to use it instead of the
    # default type system that comes with RubyBreaker.
    module Pluggable

      # This method will be invoked right before the actual method is
      # invoked.
      #
      # obj:: the receiver of the method call (message)
      # method_info:: a MethodInfo object containing the method call
      #               information
      def before_method_call(obj, meth_info)
      end

      # This method will be invoked right after the actual method is
      # invoked.
      #
      # obj:: the receiver of the method call (message)
      # method_info:: a MethodInfo object containing the method call
      #               information
      def after_method_call(obj, meth_info)
      end

    end
  end

end

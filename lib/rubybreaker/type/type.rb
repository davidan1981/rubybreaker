#--
# This file contains the type structure used in RubyBreaker. Here we list 
# types that are used (allowed) in RubyBreaker:
# 
#   AnyType          represents basically any type in Ruby
#   NilType          represents a nil object
#   SelfType         represents "self"--the current object
#   NominalType      represents an object 
#   DuckType         represents a partial object (a collection of methods)
#   FusionType       represents an object along with a set of methods
#   MethodType       represents a method
#   BlockType        represents a block
#   OrType           represents one of the many objects (i.e, OR)
#   OptionalType     represents an optional argument type
#   VarLengthType    represents a variable length argument type
#   MethodListType   represents one or more methods
#

require_relative "../util"
require_relative "../context.rb"

module RubyBreaker

  # This module contains all RubyBreaker type definitions. This module has
  # to be included to the module if you want to work with the type
  # definitions that RubyBreaker provides (unless you want to add TypeDefs
  # namespace in the module).
  module TypeDefs

    # This class is a catch-all. The constructor of this class must be
    # called from children via super() in order to assign the position field
    # variable.
    #
    # The optional arguments are args[0] = file name args[1] = line number
    #
    #   args[2] = column position
    #   
    #   or
    #   
    #   args[0] = a Position, ObjectPosition, or Context object
    #
    class Type

      # Speficies the context of the type. 
      attr_accessor :ctx    

      def initialize(*args)
        case args[0]
        when Context
          @ctx = args[0]
        when Position
          @ctx = Context.new(args[0])
        when ObjectPosition
          @ctx = Context.new(args[0])
        else
          file = args[0]
          line = args[1]
          col = args[2]
          pos = Position.new(file,line,col)
          @ctx = Context.new(pos)
        end
      end
    end

    # This type can represent any object
    class AnyType < Type
      def initialize(*args)
        super(*args)
      end
    end

    # This type represents a nil
    class NilType < Type
      def initialize(*args)
        super(*args)
      end
    end
    
    # This class represents a concrete object like a Numeric or String. It 
    # stores the actual module in the instance variable @mod. 
    class NominalType < Type

      # This accessor points to the actual module
      attr_accessor :mod

      def initialize(mod=nil,*args)
        super(*args)
        @mod = mod
      end
    end

    # This type represents the self type. Note that this is a subclass of
    # Nominal Type. It works just like nominal type except that it also points
    # to the current object! See subtyping.rb for more detail on how this
    # would impact typing.
    class SelfType < NominalType

      # This is a setter method for class variable mod. 
      # NOTE: It is set every time Broken module is included.
      def self.set_self(mod)
        @@mod = mod
      end

      # This is a getter method for class variable mod. 
      def self.get_self(mod)
        @@mod = mod
      end

      def initialize(*args)
        # NOTE: @@mod is not required in general, but for typing it is a must.
        super(@@mod, *args)
      end
    end

    # This class represents any object with certain methods
    # Usage: [m1,m2,...] where m1...mn are method names
    class DuckType < Type

      # This accessor sets/gets method names in the duck type.
      attr_accessor :meth_names

      def initialize(meth_names=[],*args)
        super(*args)
        @meth_names = meth_names.map!{|n| n.to_sym}
      end
      def add_meth(meth_name)
        @meth_names << meth_name.to_sym if !@meth_names.include?(meth_name)
      end
    end

    # This class represents any object that has certain methods whose types
    # are same as the given nominal type's counterparts.
    # Usage: nominal_type[m1,m2,...]
    class FusionType < DuckType

      # This accessor sets/gets the nominal type to which the method names
      # are bound.
      attr_accessor :nom_type

      def initialize(nom_type,meth_names=[],*args)
        super(meth_names,*args)
        @nom_type = nom_type
      end

      # This method gets the actual module of the nominal type for this
      # fusion type. This is a shorthand for t1.nom_type.mod().
      def mod()
        return @nom_type.mod
      end
    end

    # This class represents a block (in a method). It has zero or more argument 
    # types, nested block type (optional), and a return type.
    class BlockType < Type

      # This accessor sets/gets the argument types for this block type.
      attr_accessor :arg_types

      # This accessor sets/gets the block type for this block type.
      attr_accessor :blk_type

      # This accessor sets/gets the return type for this block type.
      attr_accessor :ret_type

      def initialize(arg_types=[],blk_type=nil,ret_type=nil,*args)
        super(*args)
        @arg_types = arg_types
        @blk_type = blk_type
        @ret_type = ret_type
      end
    end

    # This class represents a method and is essentially same as block type 
    # except the method name.
    class MethodType < BlockType

      # This accessor sets/gets the method name for this method type.
      attr_accessor :meth_name

      def initialize(meth_name,arg_types=[],blk_type=nil,ret_type=nil,*args)
        super(arg_types,blk_type,ret_type,*args)
        @meth_name = meth_name.to_sym
      end
    end

    # This class respresents an optional argument type
    class OptionalType < Type

      # This accessor sets/gets the inner type of this optional type.
      attr_accessor :type

      def initialize(type,*args)
        super(*args)
        @type = type
      end
    end

    # This class represents a variable-length argument type
    class VarLengthType < Type

      # This accessor sets/gets the inner type of this variable length
      # argument type.
      attr_accessor :type

      def initialize(type,*args)
        super(*args)
        @type = type
      end
    end 

    # This class represents one of many types
    class OrType < Type

      # This accessor sets/gets the inner types of this "or" type.
      attr_accessor :types

      def initialize(types=[],*args)
        super(*args)
        @types = types
      end
    end

    # This class represents multiple method types.
    class MethodListType < Type

      # This accessor sets/gets the method types.
      attr_accessor :types

      def initialize(types=[],*args)
        super(*args)
        @types = types
      end
    end

  end

  # Include the module right away
  include TypeDefs

end


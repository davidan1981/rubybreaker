#--
# This file defines code location as well as runtime location and context
# which is made up of one or more locations.

require "prettyprint"

module RubyBreaker

  # This class represents a position of the type acquired from either the
  # type signature or code during runtime. It can also be used for internal
  # error checking or debuging purpose.
  class Position
    
    attr_accessor :file
    attr_accessor :line
    attr_accessor :col
    attr_accessor :method
    
    @@file = ""
    @@line = -1
    @@col = -1
    
    def initialize(file="",line=-1,col=-1,meth="")
      @file = file
      @line = line
      @col = col
      @method = meth
    end

    def to_s()
      return "#{@file}:(#{@line},#{@col}):in #{@method}"
    end
    
    # This class method is to set the current parsing position.
    def self.set(file,line,col)
      @@file = file
      @@line = line
      @@col = col
    end
    
    # This class method returns a new position object for the current
    # parsing position.
    def self.get()
      return Position.new(@@file,@@line,@@col)
    end

    # This class method is a utility function to convert a string in the
    # caller() array.
    def self.convert_caller_to_pos(caller_ary, idx=0)
      tokens = caller_ary[idx].split(":")
      return self.new(tokens[0],tokens[1],-1,tokens[2]) # no col 
    end
  end

  # This class represents a position with respect to an object and the name
  # of a method being invoked.
  class ObjectPosition
    attr_accessor :obj
    attr_accessor :meth_name

    def initialize(obj, meth_name)
      @obj = obj
      @meth_name = meth_name
    end 

    def to_s()
      m_delim = @obj.kind_of?(Module) ? "." : "#"
      return "> #{@obj.class}#{m_delim}#{@meth_name}"
    end
  end

  # This class represents a context which consists of one or more positions.
  # A position can refer to a physical file/line position or a virtual
  # position with respect to an object. A context is commonly used to
  # represent a chain of positions for types.
  class Context

    attr_accessor :pos   # location is either Position or ObjectPosition
    attr_accessor :child

    def initialize(pos)
      @pos = pos
      @child = nil
    end

    def push(pos)
      if @child 
        @child.push(pos)
      else
        @child = Context.new(pos)
      end
    end

    def pop
      if @child && @child.child
        @child.pop
      elsif @child
        @child = nil
      else 
        # root; don't do anything
      end
    end

    def format_with_msg(pp,msg="")
      pp.text(@pos.to_s)
      pp.breakable()
      if @child
        pp.group(2) { 
          pp.breakable()
          @child.format_with_msg(pp,msg)
        }
      elsif msg != ""
        pp.group(2) do
          pp.breakable()
          pp.text("> #{msg}",79)
        end
      end
    end

  end

end

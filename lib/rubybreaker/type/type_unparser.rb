#--
# This file contains the type unparser for the type structure used in
# RubyBreaker. No visitor pattern is used due to its "functional" element.
# Instead, it will rely on type matches and work each type in a conditional
# statement. 

require_relative "type"

module RubyBreaker

  # This module prints the RubyBreaker types in a user-friendly way.
  module TypeUnparser

    include TypeDefs

    private

    # This method is used to determine if the inner type of +t+ should be
    # wrapped around a parenthesis. This is for optional type and variable
    # length type.
    def self.peek_and_unparse_pp_inner_type(pp,t)
      if t.type.kind_of?(OrType)
        pp.text("(")
        self.unparse_pp(pp,t.type)
        pp.text(")")
      else
        self.unparse_pp(pp,t.type)
      end
    end

    # This method unparses an object type (a duck type or fusion type)
    def self.unparse_pp_object_type(pp,t)
      pp.text("[#{t.meth_names.sort.join(", ")}]")
    end

    # This recursive method unparses a RubyBreaker type using the pretty
    # print method.
    def self.unparse_pp(pp,t)
      if t.instance_of?(NominalType)
        tname = Utilities.underscore(t.mod)
        tokens = tname.split("/")        
        tname = tokens.last if tokens.size > 1
        pp.text(tname)
			elsif t.instance_of?(SelfType)
				pp.text("self")
      elsif t.instance_of?(DuckType)
        unparse_pp_object_type(pp,t)
      elsif t.instance_of?(FusionType)
        unparse_pp(pp,t.nom_type)
        unparse_pp_object_type(pp,t)
      elsif t.instance_of?(MethodType)
        pp.text("#{t.meth_name}(")
        t.arg_types.each_with_index do |arg_type,i|
          unparse_pp(pp,arg_type)
          if i < t.arg_types.size - 1
            pp.text(",")
            pp.fill_breakable()
          end 
        end
        pp.text(")")
        pp.fill_breakable()
        if t.blk_type
          pp.text("{")
          unparse_pp(pp,t.blk_type)
          pp.text("}")
          pp.fill_breakable()
        end
        pp.text("->")
        pp.fill_breakable()
        unparse_pp(pp,t.ret_type)
      elsif t.instance_of?(BlockType)
        pp.text("|")
        t.arg_types.each_with_index do |arg_type,i|
          unparse_pp(pp,arg_type)
          if i < t.arg_types.size - 1
            pp.text(",")
            pp.fill_breakable()
          end 
        end
        pp.text("|")
        pp.fill_breakable()
        if t.blk_type
          pp.text("{")
          unparse_pp(pp,t.blk_type)
          pp.text("}")
          pp.fill_breakable()
        end
        pp.text("->")
        pp.fill_breakable()
        unparse_pp(pp,t.ret_type)
      elsif t.instance_of?(MethodListType)
        t.types.each_with_index do |typ,i|
          unparse_pp(pp,typ)
          if i < t.types.size - 1 
            pp.fill_breakable()
          end
        end
      elsif t.instance_of?(OrType)
        t.types.each_with_index do |typ,i|
          unparse_pp(pp,typ)
          if i < t.types.size - 1
            pp.text(" ||")
            pp.fill_breakable()
          end
        end
      elsif t.instance_of?(OptionalType)
        peek_and_unparse_pp_inner_type(pp,t)
        pp.text("?")
      elsif t.instance_of?(VarLengthType)
        peek_and_unparse_pp_inner_type(pp,t)
        pp.text("*")
      elsif t.instance_of?(NilType)
        pp.text("nil")
      elsif t.instance_of?(AnyType)
        pp.text("?")
      else
      end
    end

    public

    # This method is used to display any RubyBreaker type in a user-friendly
    # way using the pretty print method. 
    def self.unparse(t)
      str = ""
      pp = PrettyPrint.new(str)
      self.unparse_pp(pp,t)
      pp.flush
      return str.strip()
    end
  end

  class TypeDefs::Type

    # This method unparses the type using the pretty print method.
    def unparse()
      TypeUnparser.unparse(self)
    end
  end

end


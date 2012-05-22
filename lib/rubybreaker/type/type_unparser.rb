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

    # This method resolves the mod_name's namespace with respect to the
    # namespace. For example, if the current namespace is
    # 
    # A::B
    #
    # and the given module is A::B::C::D, then we show
    #
    # C::D
    #
    #
    # If the current namespace is
    #
    # A::B::C
    #
    # and the given module is A::B::D::E, then we show
    #
    # D::E
    #
    def self.resolve_namespace(namespace, mod_name)
      return mod_name if namespace == nil || namespace.empty?
      if mod_name.start_with?(namespace)
        pattern = "^#{namespace}::"
        return mod_name.sub(/#{pattern}/, "")
      end
      tokens = namespace.split("::")
      return mod_name if tokens.size <= 1
      return self.resolve_namespace(tokens[0..-2].join("::"), mod_name)
    end

    # This method is used to determine if the inner type of +t+ should be
    # wrapped around a parenthesis. This is for optional type and variable
    # length type.
    def self.peek_and_unparse_pp_inner_type(pp, t, opts={})
      if t.type.kind_of?(OrType)
        pp.text("(")
        self.unparse_pp(pp, t.type, opts)
        pp.text(")")
      else
        self.unparse_pp(pp, t.type, opts)
      end
    end

    # This method unparses an object type (a duck type or fusion type)
    def self.unparse_pp_object_type(pp,t)
      pp.text("[#{t.meth_names.sort.join(", ")}]")
    end

    # This recursive method unparses a RubyBreaker type using the pretty
    # print method.
    def self.unparse_pp(pp, t, opts={})
      if t.instance_of?(NominalType)
        if opts[:namespace] && opts[:namespace].name
          # resolve the namespace for the module/class given the current
          # namespace
          mod_name = self.resolve_namespace(opts[:namespace].name, t.mod.name)
        else
          mod_name = t.mod.name
        end
        unless opts[:style] == :camelize
          tname = Util.underscore(mod_name)
        else
          tname = mod_name
        end
        # tokens = tname.split("/")        
        # tname = tokens.last if tokens.size > 1
        pp.text(tname)
      elsif t.instance_of?(SelfType)
        pp.text("self")
      elsif t.instance_of?(DuckType)
        unparse_pp_object_type(pp,t)
      elsif t.instance_of?(FusionType)
        unparse_pp(pp, t.nom_type, opts)
        unparse_pp_object_type(pp,t)
      elsif t.instance_of?(MethodType)
        pp.text("#{t.meth_name}(")
        t.arg_types.each_with_index do |arg_type,i|
          unparse_pp(pp, arg_type, opts)
          if i < t.arg_types.size - 1
            pp.text(",")
            pp.fill_breakable()
          end 
        end
        pp.text(")")
        pp.fill_breakable()
        if t.blk_type
          pp.text("{")
          unparse_pp(pp, t.blk_type, opts)
          pp.text("}")
          pp.fill_breakable()
        end
        pp.text("->")
        pp.fill_breakable()
        unparse_pp(pp, t.ret_type, opts)
      elsif t.instance_of?(BlockType)
        pp.text("|")
        t.arg_types.each_with_index do |arg_type,i|
          unparse_pp(pp, arg_type, opts)
          if i < t.arg_types.size - 1
            pp.text(",")
            pp.fill_breakable()
          end 
        end
        pp.text("|")
        pp.fill_breakable()
        if t.blk_type
          pp.text("{")
          unparse_pp(pp, t.blk_type, opts)
          pp.text("}")
          pp.fill_breakable()
        end
        pp.text("->")
        pp.fill_breakable()
        unparse_pp(pp, t.ret_type, opts)
      elsif t.instance_of?(MethodListType)
        t.types.each_with_index do |typ,i|
          unparse_pp(pp, typ, opts)
          if i < t.types.size - 1 
            pp.fill_breakable()
          end
        end
      elsif t.instance_of?(OrType)
        t.types.each_with_index do |typ,i|
          unparse_pp(pp, typ, opts)
          if i < t.types.size - 1
            pp.text(" ||")
            pp.fill_breakable()
          end
        end
      elsif t.instance_of?(OptionalType)
        peek_and_unparse_pp_inner_type(pp, t, opts)
        pp.text("?")
      elsif t.instance_of?(VarLengthType)
        peek_and_unparse_pp_inner_type(pp, t, opts)
        pp.text("*")
      elsif t.instance_of?(NilType)
        pp.text("nil")
      elsif t.instance_of?(AnyType)
        pp.text("?")
      else
      end
    end

    public

    # This method unparses the RubyBreaker type according to the specified
    # options.
    #
    # t:: RubyBreaker type
    # opts:: 
    #
    def self.unparse(t, opts={})
      str = ""
      pp = PrettyPrint.new(str)
      self.unparse_pp(pp, t, opts)
      pp.flush
      return str.strip()
    end
  end

  class TypeDefs::Type

    # This method is a shorthand for calling TypeUnparser.unparse(t). 
    def unparse(opts={})
      TypeUnparser.unparse(self, opts)
    end
  end

end


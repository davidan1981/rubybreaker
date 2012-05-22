require "prettyprint"
require_relative "../type"

module RubyBreaker

  module Runtime

    module TypesigUnparser

      include TypeDefs

      # This array lists monitored modules/classes that are outputed.
      DOCUMENTED = []

      # Pretty prints type information for methods
      def self.pp_methods(pp, meth_type_map, opts={})
        meth_type_map.each { |meth_name, meth_type|
          case meth_type
          when MethodType
            pp.breakable()
            pp.text("typesig(\"")
            TypeUnparser.unparse_pp(pp, meth_type, opts)
            pp.text("\")")
          when MethodListType
            meth_type.types.each { |real_meth_type|
              pp.breakable()
              pp.text("typesig(\"")
              TypeUnparser.unparse_pp(pp, real_meth_type, opts)
              pp.text("\")")
            }
          else
            # Can't happen
          end
        }
      end

      # Pretty prints type information for the module/class
      def self.pp_module(pp, mod, opts={})
        # Skip it if we already have seen it
        return if DOCUMENTED.include?(mod) || mod.to_s[0..1] == "#<"

        # Remember that we have documented this module/class
        DOCUMENTED << mod  

        # Get the method type mapping
        meth_type_map = Inspector.inspect_all(mod)

        # Check if this module is a class
        keyword = mod.instance_of?(Class) ? "class" : "module"
        
        pp.text("#{keyword} #{mod.to_s}", 80)
        pp.nest(2) do 
          pp.breakable("")
          pp.text("include RubyBreaker::Broken", 80)

          # See if there is any class method to show
          eigen = Runtime.eigen_class(mod)
          if !DOCUMENTED.include?(eigen)
            DOCUMENTED << eigen
            eigen_meth_type_map = Inspector.inspect_all(eigen)
            if eigen_meth_type_map.size > 0 
              pp.breakable()
              pp.text("class << self", 80)
              pp.nest(2) do
                self.pp_methods(pp, eigen_meth_type_map, :namespace => eigen)
              end
              pp.breakable()
              pp.text("end", 80)
            end
          end

          self.pp_methods(pp, meth_type_map, :namespace => mod)

        end
        pp.breakable() 
        pp.text("end",80)
        pp.breakable()
      end

      def self.unparse(mod, opts={})
        str = ""
        pp = PrettyPrint.new(str)
        self.pp_module(pp, mod, opts)
        pp.flush
        return str
      end

    end

  end

end

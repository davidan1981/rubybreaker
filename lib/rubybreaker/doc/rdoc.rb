require "yaml"
require_relative "../type"

module RubyBreaker

  # This module has functionalities that are necessary for supporting RDoc
  # output
  module RDocSupport #:nodoc:

    include TypeDefs

    # This array keeps track of modules/classes whose type information is
    # documented.
    DOCUMENTED = {} # module => method map

    # This method exports the RubyBreaker output into a yaml file.
    def self.export_to_yaml(yaml_file, breakable_modules, broken_modules)
      hash = {
        breakable: breakable_modules,
        broken: broken_modules
      }
      File.open(yaml_file, "w") do |f|
        f.puts YAML.dump(hash)
      end
    end

    # This method imports the RubyBreaker output from a yaml file.
    def self.import_from_yaml(yaml_file)
      File.open(yaml_file, "r") do |f|
        raw = f.read
        hash = YAML.to_hash(raw)
      end
    end

  end

end

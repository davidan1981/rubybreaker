require "rake"

Gem::Specification.new do |spec|
  spec.date = Time.now
  spec.author = "Jong-hoon (David) An"
  spec.bindir = "bin"
  spec.executable = "rubybreaker"
  spec.add_dependency("treetop")
  spec.description = "RubyBreaker is a dynamic type documentation tool for Ruby."
  spec.email = "rubybreaker@gmail.com"
  spec.files = FileList['lib/**/*', 'bin/**/*', '[A-Z]*', 'test/**/*', 'webpage/**/*'].to_a
  spec.files.reject! {|fn| fn.include?("idraw")}
  spec.has_rdoc = true
  spec.rdoc_options << "-x" << "lib/rubybreaker/rubylib/*.rb" <<
                       "-x" << "lib/rubybreaker/type/type_grammar.rb" <<
                       "lib"
  spec.license = "BSD"
  spec.name = "rubybreaker"
  spec.summary = "Break Ruby types"
  spec.version = "0.0.1"
  spec.require_path = "lib"
end

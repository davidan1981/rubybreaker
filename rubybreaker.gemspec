require "rake"
require "rubygems/version"

Gem::Specification.new do |spec|
  spec.date = Time.now
  spec.author = "Jong-hoon (David) An"
  spec.bindir = "bin"
  spec.executable = "rubybreaker"
  spec.add_dependency("treetop")
  spec.description = "RubyBreaker is a dynamic type documentation tool for Ruby. " +
                     "It dynamically instruments code, monitors objects during execution, " +
                     "and generates type documentation based on the profiled information. " +
                     "In other words, RubyBreaker \"breaks\" Ruby code out of its " +
                     "obscurity and wildness (as in \"code breaking\" or \"horse breaking\") " +
                     "by auto-documenting type information."
  spec.email = "rubybreaker@gmail.com"
  spec.files = FileList['lib/**/*', 'bin/**/*', '[A-Z]*', 'test/**/*', 'webpage/**/*'].to_a
  spec.files.reject! {|fn| fn.include?("idraw")}
  spec.has_rdoc = true
  spec.rdoc_options = ["README.md", "TUTORIAL.md", "TOPICS.md", "ABOUT.md"]
  spec.license = "BSD"
  spec.name = "rubybreaker"
  spec.summary = "Dynamic Type Documentation Tool for Ruby"
  spec.version = Gem::Version.create(File.read("VERSION"))
  spec.require_path = "lib"
  spec.homepage = "http://github.com/rockalizer/rubybreaker"
end

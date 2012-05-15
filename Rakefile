# This program runs tasks to generate RubyBreaker type parser and performs
# unit tests on individual modules in RubyBreaker.

require "rake"
require "rake/testtask"
require "rdoc/task"
require "rake/clean"

begin 
  require "rdiscount"   # used to generate the doc html page
rescue LoadError => e
  puts "[WARNING] No rdiscount is installed."
end

# Use rake/clean to remove generated files
CLEAN.concat(FileList["html", 
                      "rubybreaker-*.gem",
                      "webpage/index.html", 
                      "lib/rubybreaker/type/type_grammar.rb"
                     ])

# If no task specified, do test
task :default => [:test]

desc "Do all"
task :all => [:parser, :test, :rdoc, :webpage, :gem] do |t|
end

desc "Generate gemspec"
task :gem do |t|
  sh "gem build rubybreaker.gemspec"
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files.exclude("lib/rubybreaker/rubylib/*.rb", "lib/rubybreaker/type/type_grammar.rb")
end

desc "Generate the webpage"
task :webpage do |t|
  break unless defined?(RDiscount)
  dir = File.dirname(__FILE__)
  readme_md = "#{dir}/README.md"
  output = "#{dir}/webpage/index.html"
  body = RDiscount.new(File.read(readme_md)).to_html
  header = File.read("#{dir}/webpage/header.html")
  footer = File.read("#{dir}/webpage/footer.html")
  html = header + body + footer
  File.open(output, "w") { |f| f.write(html) }
end

desc "Generate parser"
task :parser do |t|
  # XXX: This is not really needed, would it perform better?
  # sh "tt -f #{File.dirname(__FILE__)}/lib/rubybreaker/type/type_grammar.treetop"
end

desc "Run basic tests"
Rake::TestTask.new("test") do |t|
  dir = File.dirname(__FILE__)
  t.libs << "lib"
  t.test_files = FileList["test/*.rb"]
end


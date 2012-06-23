# This program runs tasks to generate RubyBreaker type parser and performs
# unit tests on individual modules in RubyBreaker.

require "rake"
require "rake/testtask"
require "rdoc/task"
require "rake/clean"
require_relative "lib/rubybreaker/task"

begin 
  require "rdiscount"   # used to generate the doc html page
rescue LoadError => e
  puts "[WARNING] No rdiscount is installed on this computer."
end

begin 
  require 'rspec/core/rake_task'
rescue LoadError => e
  puts "[WARNING] No rspec-core is installed on this computer."
end

# This method generates html pages with header and footer.
def gen_page(md_file, html_file)
  dir = File.dirname(__FILE__)
  header = File.read("#{dir}/webpage/header.html")
  footer = File.read("#{dir}/webpage/footer.html")
  body = RDiscount.new(File.read(md_file)).to_html
  html = header + body + footer
  File.open(html_file, "w") { |f| f.write(html) }
end

# Use rake/clean to remove generated files
CLEAN.concat(FileList["webpage/rdoc", 
                      "rubybreaker-*.gem",
                      "webpage/index.html",
                      "*.rubybreaker.rb",
                      "lib/rubybreaker/type/type_grammar.rb"])

# If no task specified, do test
task :default => [:test, :testtask_test]

# The complete list of tasks
all_tasks = [:parser, 
             :test, 
             :testtask_test,
             :rspec, 
             :rdoc, 
             :webpage, 
             :gem]

# Remove rspec if RSpec is not defined (rspec is not installed)
all_tasks.delete(:rspec) if !defined?(RSpec)

desc "Do all"
task :all => all_tasks 

desc "Generate gemspec"
task :gem do |t|
  sh "gem build rubybreaker.gemspec"
end

desc "Generate RDoc"
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = "#{File.dirname(__FILE__)}/webpage/rdoc"
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files.exclude("lib/rubybreaker/type/type_grammar.rb")
  rd.options << "README.md" << "TUTORIAL.md"
end

desc "Generate the webpage"
task :webpage do |t|
  if defined?(RDiscount)
    dir = File.dirname(__FILE__)
    gen_page("#{dir}/README.md","#{dir}/webpage/index.html")
    gen_page("#{dir}/TUTORIAL.md","#{dir}/webpage/tutorial.html")
    gen_page("#{dir}/TOPICS.md","#{dir}/webpage/topics.html")
    gen_page("#{dir}/ABOUT.md","#{dir}/webpage/about.html")
  end
end

desc "Generate parser"
task :parser do |t|
  # XXX: This is not really needed, would it perform better?
  # sh "tt -f #{File.dirname(__FILE__)}/lib/rubybreaker/type/type_grammar.treetop"
end

desc "Run basic tests"
Rake::TestTask.new(:"test") do |t|
  dir = File.dirname(__FILE__)
  t.libs << "lib"
  test_files = FileList["test/ts_*.rb"]
  test_files.exclude("test/ts_rspec.rb")
  test_files.exclude("test/ts_testtask.rb")
  t.test_files = test_files
end

desc "Run rubybreaker testtask test"
Rake::RubyBreakerTestTask.new(:"testtask_test") do |t|
  t.libs << "lib" << "test/tc_testtask/sample.rb"
  t.test_files = ["test/testtask/tc_testtask.rb"]
  t.break = ["SampleClassA"]
end

if defined?(RSpec)
  desc "Run RSpec test"
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.pattern = ["test/ts_rspec.rb"]
    t.fail_on_error = false
  end
end



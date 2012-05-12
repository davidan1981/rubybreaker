# This program runs tasks to generate RubyBreaker type parser and performs
# unit tests on individual modules in RubyBreaker.

require "rake"
require "rake/testtask"
require "rdoc/task"

begin 
  require "rdiscount"   # used to generate the doc html page
rescue LoadError => e
  puts "[WARNING] No rdiscount is installed."
end

# If no task specified, do test
task :default => [:test]

desc "Do all"
task :all => [:parser, :test, :rdoc, :webpage, :gem] do |t|
end

desc "Clean"
task :clean do |t|
  sh 'rm -r -f html'
  sh 'rm webpage/index.html'
  sh 'rm lib/rubybreaker/type/type_grammar.rb'
end

desc "Generate gemspec"
task :gem do |t|
  sh "gem build rubybreaker.gemspec"
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files.exclude("lib/rubybreaker/rubylib/*.rb", "lib/rubybreaker/type/type_grammar.rb")
end

# desc "Generate RDoc"
# task :doc do |t|
#   sh "rdoc -x lib/rubybreaker/rubylib -x lib/rubybreaker/type/type_grammar lib"
# end

desc "Generate the webpage"
task :webpage do |t|
  break unless defined?(RDiscount)
  dir = File.dirname(__FILE__)
  readme_md = "#{dir}/README.md"
  output = "#{dir}/webpage/index.html"
  body = RDiscount.new(File.read(readme_md)).to_html
#   header = <<-EOS
# <html>
# <head>
#   <title>RubyBreaker</title>
#   <LINK REL=StyleSheet HREF="rubybreaker.css" TYPE="text/css">
# 	<script type="text/javascript" src="generated_toc.js">  </script>
# </head>
# <body onLoad="createTOC()">
#   <center>
# 	<div id="content">
# 		<div id="logo">
# 			<img src="images/logo.png" border="0">
# 		</div>
# 		<hr />
# 		<div id="generated-toc"></div>
#   EOS
#  footer = <<-EOS
# 	</div>
#   </center>
# </body>
# </html>
#   EOS
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


require "ostruct"
require "optparse"
require "rake/testtask"
require "yaml"
require "tempfile"

module Rake

  # This class can be used as a replacement for Rake::TestTask. It is a
  # subclass of Rake::TestTask and maintains additional information for
  # running RubyBreaker as a Rake test task. 
  #
  # For example, the following shows how to run RubyBreaker in a test task:
  #
  # desc "Run testtask test"
  # Rake::RubyBreakerTestTask.new(:"testtask_test") do |t|
  #   t.libs << "lib"
  #   t.test_files = ["test/testtask/tc_testtask.rb"]
  #   t.break = ["SampleClassA"]
  # end
  #
  class RubyBreakerTestTask < Rake::TestTask

    # List of modules/classes to break
    attr_accessor :break

    # List of modules/classes to check
    attr_accessor :check

    # RubyBreaker options
    attr_accessor :rubybreaker_opts

    # DEPRECATED accessor override
    def breakable(); @break end

    # DEPRECATED accessor override
    def breakable=(*args); self.break(*args) end

    # This overrides the testtask's constructor. In addition to the original
    # behavior, it keeps track of RubyBreaker options and store them in a
    # yaml file.
    def initialize(taskname="", *args, &blk)

      # Initialize extra instance variables
      @rubybreaker_opts = []
      @break = nil
      @check = nil

      # Call the original constructor first
      super(taskname, *args, &blk)

      # Parse the RubyBreaker options
      case @rubybreaker_opts
      when Array
        opts = @rubybreaker_opts
      when String
        opts = @rubybreaker_opts.split(" ").select {|v| v != ""}
      else
        opts = []
      end

      # Construct the task configuration hash
      config = {
        :name => taskname,
        :rubybreaker_opts => opts,
        :break => [], # Set doesn't work well with YAML; just use an array
        :check => [],
        :test_files => @test_files,
      }

      # This allows a bulk declaration of Breakable modules/classes
      @break.each { |b| config[:break] << b } if @break
      @check.each { |c| config[:check] << c } if @check

      # This code segment is a clever way to store yaml data in a ruby file
      # that reads its own yaml data after __END__ when loaded.
      code_data = <<-EOS
require "yaml"
f = File.new(__FILE__, "r")
while !(f.readline.match("^__END__.*$"))
  # do nothing
end
data = f.read
$__rubybreaker_task = YAML.load(data)
__END__
#{YAML.dump(config)}
      EOS

      tmp_path = ""
      # Tests are run different processes, so we must export this
      # information to an external yaml file.
      f = Tempfile.new(["#{taskname}",".rb"]) 
      tmp_path = f.path
      f.write(code_data)
      f.close()

      # Inject the -r option to load this yaml file
      if @ruby_opts && @ruby_opts.empty?
        @ruby_opts << "-r" << tmp_path
      else
        @ruby_opts = ["-r", tmp_path]
      end

      return self
    end

  end

end

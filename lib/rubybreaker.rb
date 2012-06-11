#--
# This library dynamically profiles and resolves the type information
# observed at runtime and generates type annotation at the end.  It can be
# run as either a stand-alone script or as a Ruby library. 

require "set"
require "optparse"
require_relative "rubybreaker/debug"
require_relative "rubybreaker/runtime"
require_relative "rubybreaker/test"

# RubyBreaker is a dynamic instrumentation and monitoring tool that
# generates type documentation for Ruby programs. 
module RubyBreaker
  include TypeDefs
  include Runtime

  # Options for RubyBreaker
  OPTIONS = {
    :debug     => false,       # in debug mode?
    :style     => :underscore, # type signature style-underscore or camelize
    :io_file   => nil,         # generate input/output other than default?
    :append    => false,       # append to the input file (if there is)?
    :stdout    => false,       # also display on the screen?
    :verbose   => false,       # in RubyBreaker.verbose mode?
    :save_output  => true,     # save output to a file?
    :prog_file    => nil,      # INTERNAL USE ONLY
  }

  # This option parser may be used for the command-line mode or for the
  # library mode when used with Rakefile. See rubybreaker/task.rb for how
  # this can be used in the latter.
  OPTION_PARSER = OptionParser.new do |opts|

    opts.banner = "Usage: #{File.basename(__FILE__)} [options] prog[.rb]" 

    opts.on("--debug", "Run in debug mode") do 
      OPTIONS[:debug] = true
    end

    opts.on("--style STYLE", "Select type signature style - underscore or camelize") do |v|
      OPTIONS[:style] = v.downcase.to_sym
    end

    opts.on("--io-file FILE","Specify I/O file") do |f|
      OPTIONS[:io_file] = f
    end

    opts.on("--save-output", "Save output to file") do b|
      OPTIONS[:save_output] = b
    end

    opts.on("-s","--[no-]stdout","Show output on screen") do |b|
      OPTIONS[:stdout] = b
    end

    opts.on("-a", "--[no-]append", "Append output to input file") do |b|
      OPTIONS[:append] = b
    end

    opts.on("-v","--verbose","Show messages in detail") do
      OPTIONS[:verbose] = true
    end

    opts.on("-h","--help","Show this help text") do 
      puts opts
      exit
    end

  end

  # This constant contains the copyright information.
  COPYRIGHT = "Copyright (c) 2012 Jong-hoon (David) An. All Rights Reserved."

  # Extension used for files that contain RubyBreaker task information
  TASK_EXTENSION = "rb"

  # Extension used for files that contain type information in YAML format
  YAML_EXTENSION = "yaml"

  # Extension used for files that contain type information in Ruby format
  IO_EXTENSION = "rubybreaker.rb"

  private

  # This method determines if RubyBreaker is running as a task.
  def self.running_as_task?(); return $__rubybreaker_task != nil end

  # This method returns the task currently being run.
  def self.task(); return $__rubybreaker_task end

  # This method loads the IO file by loading it.
  def self.load_input(fname)
    return fname
    eval "load \"#{fname}\"", TOPLEVEL_BINDING
    RubyBreaker.verbose("RubyBreaker input file #{fname} is loaded")
  end

  # This method will generate the output to the given filename.
  def self.output(fname)

    RubyBreaker.verbose("Generating type documentation")

    code = ""

    # Document each module that was monitored.
    INSTALLED.each { |mod| 
      str = Runtime::TypeSigUnparser.unparse(mod) 
      code << str
      print str if OPTIONS[:stdout] # display on the screen if requested
    }

    if fname && OPTIONS[:save_output]
      # Check if the file already exists--that is, if it was used for input
      io_exist = File.exists?(fname)
      RubyBreaker.verbose("Saving it to #{fname}")
      # Append the result to the input file (or create a new file)
      fmode = OPTIONS[:append] ? "a" : "w"
      open(fname, fmode) do |f|
        # When append, do not write the header
        unless OPTIONS[:append] 
          f.puts "# This file is auto-generated by RubyBreaker" 
        end
        # But time stamp always
        f.puts "# Last modified: #{Time.now}"
        f.puts "require \"rubybreaker\"" unless OPTIONS[:append] 
        f.print code
      end
    end

    RubyBreaker.verbose("Done generating type documentation")
  end

  # This method finds the IO file for this run. It is either specified in
  # io-file option or using the program name or the task name.
  def self.io_file(prog_or_task)
    if OPTIONS[:io_file]
      fname = OPTIONS[:io_file]
    elsif prog_or_task
      fname = "#{File.basename(prog_or_task.to_s, ".rb")}.#{IO_EXTENSION}"
    end
    return nil unless fname
    fname = File.absolute_path(fname) 
    return fname
  end

  public

  # This method runs RubyBreaker for a particular test case (class). This
  # is a bit different from running RubyBreaker as a shell program. 
  def self.run(*mods)
    RubyBreaker.setup_logger() unless RubyBreaker.defined_logger?()

    # Task based run should use the rubybreaker options same as in shell
    # mode. So, parse the options first.
    if self.running_as_task?() # running in task mode
      RubyBreaker.verbose("Running RubyBreaker within a testcase")
      task = self.task
      OPTION_PARSER.parse(*task[:rubybreaker_opts])
      Runtime.breakable(*task[:breakable])
      task_name = task[:name]
      RubyBreaker.verbose("Done reading task information")
      io_file = self.io_file(task_name)
    elsif OPTIONS[:prog_file] # running in shell mode 
      Runtime.breakable(*mods)
      io_file = self.io_file(OPTIONS[:prog_file])
    else
      # Otherwise, assume there are no explicit IO files.
    end
    self.load_input(io_file)

    # The following is deprecated but doing this for backward compatibility
    Runtime.instrument()

    # At the end, we WILL generate an output of the type information.
    at_exit { self.output(io_file) }
  end
  
end

# This method is available by default.
module Kernel

  def typesig(str)
    _TypeDefs = RubyBreaker::TypeDefs

    # This MUST BE set for self type to work in type signatures.
    _TypeDefs::SelfType.set_self(self) 

    t = RubyBreaker::Runtime::TypeSigParser.parse(str)
    t_map = RubyBreaker::Runtime::TYPE_MAP[self]

    # If the type map doesn't exist, create it on the fly. Now this module
    # is broken!
    if !t_map
      t_map = {}
      RubyBreaker::Runtime::TYPE_MAP[self] = t_map
    end

    meth_type = t_map[t.meth_name]
    if meth_type
      if meth_type.instance_of?(_TypeDefs::MethodListType)
        meth_type.types << t
      else
        # then promote it to a method list type
        t_map[t.meth_name] = _TypeDefs::MethodListType.new([meth_type, t])
      end
    else
      t_map[t.meth_name] = t
    end
    return t
  end
end


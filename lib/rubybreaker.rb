#--
# This library dynamically profiles and resolves the type information
# observed at runtime and generates type annotation at the end.  It can be
# run as either a stand-alone script or as a Ruby library. 

require_relative "rubybreaker/debug"
require_relative "rubybreaker/runtime"
require_relative "rubybreaker/test"

# RubyBreaker is a dynamic instrumentation and monitoring tool that
# documents type information automatically.
module RubyBreaker

  # This constant contains the copyright information.
  COPYRIGHT = "Copyright (c) 2012 Jong-hoon (David) An. All Rights Reserved."

  # Options for RubyBreaker
  OPTIONS = {
    :debug => false,               # in debug mode?
    :verbose => false,             # in RubyBreaker.verbose mode?
    :mode => :lib,                 # bin or lib?
    :io_file => nil,               # generate input/output other than default?
    :append => true,               # append to the input file (if there is)?
    :stdout => true,               # also display on the screen?
    :rubylib => true,              # include core ruby library documentation?
    :file => nil,                  # the input Ruby program (as typed by the user)
  }

  # This array lists modules/classes that are actually instrumented with a
  # monitor.
  INSTALLED = []
  
  # This array lists monitored modules/classes that are outputed.
  DOCUMENTED = []

  # Extension used by RubyBreaker for output/input
  EXTENSION = "rubybreaker"

  # This module has a set of entry points to the program and misc. methods
  # for running RubyBreaker.
  module Main

    include TypeDefs
    include Runtime

    public

    # This method is the trigger point to install a monitor in each
    # module/class.
    def self.setup()

      BREAKABLE.each do |mod|

        # Remember, RubyBreaker now supports a hybrid of Breakable and
        # Broken module. Just check if the module has already been
        # instrumented.
        unless INSTALLED.include?(mod) 
          MonitorInstaller.install_module_monitor(mod)
          INSTALLED << mod
        end

      end

      # At the end, we generate an output of the type information.
      at_exit do 
        self.output
      end

    end

    # Reads the input file if specified or exists
    def self.input()
      return unless OPTIONS[:io_file] && File.exist?(OPTIONS[:io_file])
      RubyBreaker.verbose("RubyBreaker input file exists...loading")
      eval "load \"#{OPTIONS[:io_file]}\"", TOPLEVEL_BINDING
    end

    # Pretty prints type information for methods
    def self.pp_methods(pp, meth_type_map)
      meth_type_map.each { |meth_name, meth_type|
        case meth_type
        when MethodType
          pp.breakable()
          pp.text("typesig(\"")
          TypeUnparser.unparse_pp(pp,meth_type)
          pp.text("\")")
        when MethodListType
          meth_type.types.each { |real_meth_type|
            pp.breakable()
            pp.text("typesig(\"")
            TypeUnparser.unparse_pp(pp,real_meth_type)
            pp.text("\")")
          }
        else
          # Can't happen
        end
      }
    end

    # Pretty prints type information for the module/class
    def self.pp_module(pp, mod)
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
              self.pp_methods(pp, eigen_meth_type_map)
            end
            pp.breakable()
            pp.text("end", 80)
          end
        end
        self.pp_methods(pp, meth_type_map)

      end
      pp.breakable() 
      pp.text("end",80)
      pp.breakable()
    end

    # This method will generate the output.
    def self.output()

      RubyBreaker.verbose("Generating type documentation")

      io_exist = OPTIONS[:io_file] && File.exist?(OPTIONS[:io_file])

      str = ""
      pp = PrettyPrint.new(str)

      # Document each module that was monitored
      INSTALLED.each { |mod| self.pp_module(pp, mod) }
      pp.flush

      # First, display the result on the stdout if set
      print str if OPTIONS[:stdout]

      # If this was a library mode run, exit now. 
      return if OPTIONS[:mode] == :lib

      # Append the result to the input file (or create a new file)
      open(OPTIONS[:io_file],"a") do |f|
        unless io_exist 
          f.puts "# This file is auto-generated by RubyBreaker"
          f.puts "require \"rubybreaker\""
        end
        f.puts str
      end

      RubyBreaker.verbose("Done generating type documentation")
    end

    # This method will run do things in the following order:
    #
    #   * Checks to see if the user program and an input file exists
    #   * Loads the documentation for Ruby Core Library (TODO)
    #   * Reads the input type documentation if any
    #   * Reads (require's) the user program
    #
    def self.run()

      RubyBreaker.setup_logger()
      RubyBreaker.verbose("Running RubyBreaker")

      # First, take care of the program file.
      argv0 = OPTIONS[:file]
      prog_file = argv0
      prog_file = File.expand_path(prog_file)

      # It is ok to omit .rb extension. So try to see if prog_file.rb exists
      if !File.exist?(prog_file) && !File.extname(prog_file) == ".rb" 
        prog_file = "#{prog_file}.rb"
      end 

      if !File.exist?(prog_file)
        fatal("#{argv0} is an invalid file.")
        exit(1)
      end

      # Then, input/output file if specified
      if !OPTIONS[:io_file] || OPTIONS[:io_file].empty?
        OPTIONS[:io_file] = "#{File.basename(argv0, ".rb")}.#{EXTENSION}"
      end
      OPTIONS[:io_file] = File.absolute_path(OPTIONS[:io_file])

      if OPTIONS[:rubylib]
        RubyBreaker.verbose("Loading RubyBreaker's Ruby Core Library documentation")
        # Load the core library type documentation
        eval("require \"rubybreaker/rubylib\"", TOPLEVEL_BINDING)
      end

      # Read the input file first (as it might contain type documentation
      # already)
      Main.input()

      # Finally, require the program file! Let it run! Wheeee!
      eval("require '#{prog_file}'", TOPLEVEL_BINDING)

      RubyBreaker.verbose("Done running the input program")

    end

  end

  # This is the manual indicator for the program entry point. It simply
  # redirects to the monitor setup code.
  def self.monitor()
    Main.setup()
  end

end


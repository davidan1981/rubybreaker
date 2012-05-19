#-
# This file contains the debug module which is exclusively used by
# RubyBreaker internally.
#
require "prettyprint"
require "logger"
require_relative "context"

module RubyBreaker

  # This sets up the logger for debugging RubyBreaker
  def self.setup_logger #:nodoc:
    return if defined?(LOGGER)
    out = if (defined?(OPTIONS) && !OPTIONS[:file].empty?)
          then "#{OPTIONS[:file]}.log"
          else STDOUT
          end
    const_set(:LOGGER, Logger.new(out))
    LOGGER.level = Logger::DEBUG
  end

  # This method will display verbose message. It is not for debugging but to
  # inform users of each stage in the analysis.
  def self.verbose(str, &blk)
    return unless defined?(OPTIONS) && (OPTIONS[:verbose] || OPTIONS[:debug])
    if blk
      msg = yield
      msg = "#{str} : #{msg}" if str
    else
      msg = str
    end
    STDOUT.puts msg if OPTIONS[:verbose]
    LOGGER.info msg if OPTIONS[:debug]
  end

  # This method is for reporting an error to the user. It will immediately
  # show the error message but also log it.
  def self.error(err, level=:error, &blk)
    msg = err.to_s
    msg = "#{msg} : #{yield}" if blk
    STDOUT.puts "[#{level.to_s.upcase}] #{msg}"
    LOGGER.send(level, msg) if defined?(OPTIONS) && OPTIONS[:debug]
  end

  # This method logs a non-error (or error) message but with the provided
  # context.
  def self.log(str, level=:debug, context=nil, &blk)
    return unless defined?(OPTIONS) && OPTIONS[:debug]
    msg = str.to_s
    msg = "#{msg} : #{yield}" if blk
    if context
      output = ""
      pp = PrettyPrint.new(output)
      context.format_with_msg(pp,msg)
      pp.flush
      msg = output
    end
    LOGGER.send(level, msg) 
  end

end

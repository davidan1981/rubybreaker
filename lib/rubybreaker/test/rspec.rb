#-
# This file overrides the describe method of RSpec to call the RubyBreaker
# setup first.

RUBYBREAKER_RSPEC_PREFIX = "__rubybreaker"

if defined?(RSpec)
  alias :"#{RUBYBREAKER_RSPEC_PREFIX}_describe" :describe
end

def describe(*args,&blk)
  RubyBreaker::Main.setup if defined?(RubyBreaker) 
  send(:"#{RUBYBREAKER_RSPEC_PREFIX}_describe", *args, &blk)
end


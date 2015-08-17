require 'pry'
require 'timecop'

require File.join(File.dirname(__FILE__), "..", "lib", "threasy")

def async(timeout = 10)
  t = Thread.new do
    Thread.stop
  end
  yield -> { t.wakeup }
  raise "Time limit exceeded" unless t.join(10)
end

# Threasy.config.logger.level = Logger::DEBUG

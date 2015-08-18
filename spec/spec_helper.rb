$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'timecop'
require 'threasy'

def async(timeout = 10)
  t = Thread.new do
    Thread.stop
  end
  yield -> { t.wakeup }
  raise "Example's time limit exceeded" unless t.join(20)
end

Threasy.config.max_sleep = 0.1

# Threasy.config.logger.level = Logger::DEBUG

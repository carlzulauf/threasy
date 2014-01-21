require "logger"
require "singleton"

require "threasy/version"
require "threasy/config"
require "threasy/work"
require "threasy/schedule"

module Threasy
  def self.config
    yield Config.instance if block_given?
    Config.instance
  end

  def self.logger
    config.logger
  end

  def self.work
    Work.instance
  end

  def self.enqueue(*args, &block)
    work.enqueue *args, &block
  end

  def self.schedules
    Schedule.instance
  end

  def self.schedule(*args, &block)
    schedules.add *args, &block
  end
end

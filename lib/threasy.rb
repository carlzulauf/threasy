require "logger"

require "threasy/version"
require "threasy/config"
require "threasy/work"
require "threasy/schedule"
require "threasy/schedule/entry"

module Threasy
  def self.config
    @@config ||= Config.new
    yield @@config if block_given?
    @@config
  end

  def self.logger
    config.logger
  end

  def self.work
    config.work ||= Work.new
  end

  def self.enqueue(*args, &block)
    work.enqueue *args, &block
  end

  def self.schedules
    config.schedule ||= Schedule.new(work)
  end

  def self.schedule(*args, &block)
    schedules.add *args, &block
  end
end

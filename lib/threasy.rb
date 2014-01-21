require "logger"
require "singleton"

require "threasy/version"
require "threasy/config"
require "threasy/work"

module Threasy
  def self.config
    yield Config.instance if block_given?
    Config.instance
  end

  def self.logger
    config.logger
  end
end

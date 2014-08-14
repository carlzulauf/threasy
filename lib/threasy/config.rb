module Threasy
  class Config
    include Singleton

    attr_accessor :work, :schedule, :max_workers
    attr_writer :logger

    def initialize
      self.max_workers = 5
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap{|l| l.level = Logger::INFO }
    end
  end
end

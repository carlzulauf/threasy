module Threasy
  class Config
    attr_accessor :work, :schedule
    attr_accessor :min_workers, :max_workers, :max_sleep, :max_overdue
    attr_writer :logger

    def initialize
      self.min_workers  = 1
      self.max_workers  = 4
      self.max_sleep    = 60.0
      self.max_overdue  = 300.0
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end
  end
end

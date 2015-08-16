module Threasy
  class Config
    attr_accessor :work, :schedule, :max_workers, :max_sleep, :max_overdue
    attr_writer :logger

    def initialize
      self.max_workers  = 5
      self.max_sleep    = 60.0
      self.max_overdue  = 300.0
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end
  end
end

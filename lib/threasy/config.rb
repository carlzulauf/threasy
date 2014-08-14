module Threasy
  class Config
    include Singleton

    attr_accessor :max_workers, :max_sleep
    attr_writer :logger

    def initialize
      # maximum size of thread pool
      self.max_workers = 5

      # maximum seconds schedule watcher will sleep before checking schedule
      self.max_sleep   = 300 # 5 minutes
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap{|l| l.level = Logger::INFO }
    end
  end
end

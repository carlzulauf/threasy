module Threasy
  class Schedule
    include Singleton
    include Enumerable

    def initialize
      @semaphore = Mutex.new
      @schedules = []
      @watcher = Thread.new{ watch }
    end

    def add(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      job = block_given? ? block : args.first
      add_entry Entry.new(job, options)
    end

    def add_entry(entry)
      sync do
        @schedules << entry
        @schedules.sort_by!(&:at)
      end
      tickle_watcher
      entry
    end

    def remove_entry(entry)
      sync{ @schedules.delete entry }
    end

    def tickle_watcher
      @watcher.wakeup if @watcher.stop?
    end

    def sync
      @semaphore.synchronize{ yield }
    end

    def entries
      @schedules
    end

    def each
      entries.each {|entry| yield entry }
    end

    def clear
      sync{ @schedules.clear }
    end

    def watch
      loop do
        Thread.stop if @schedules.empty?
        entries_due.each do |entry|
          log.debug "Adding scheduled job to work queue"
          entry.work!
          add_entry entry if entry.repeat?
        end
        next_job = @schedules.first
        if next_job && next_job.future?
          seconds = next_job.at - Time.now
          log.debug "Schedule watcher sleeping for #{seconds} seconds"
          sleep seconds
        end
      end
    end

    def entries_due
      [].tap do |entries|
        sync do
          while @schedules.first && @schedules.first.due?
            entries << @schedules.shift
          end
        end
      end
    end

    def count
      @schedules.count
    end

    def log
      Threasy.logger
    end

    class Entry
      attr_accessor :job, :at, :repeat

      def initialize(job, options = {})
        self.job = job
        self.repeat = options[:every]
        seconds = options.fetch(:in){ repeat || 60 }
        self.at = options.fetch(:at){ Time.now + seconds }
      end

      def repeat?
        !! repeat
      end

      def due?
        Time.now > at
      end

      def future?
        ! due?
      end

      def work!
        Threasy.enqueue job
        self.at = at + repeat if repeat?
      end

      def remove
        Schedule.instance.remove_entry self
      end
    end
  end
end

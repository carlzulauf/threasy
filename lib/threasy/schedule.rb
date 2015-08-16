module Threasy
  class Schedule
    include Enumerable

    attr_reader :schedules, :watcher

    def initialize(work = nil)
      @work = work
      @semaphore = Mutex.new
      @schedules = []
      @watcher = Thread.new{ watch }
    end

    def add(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      job = block_given? ? block : args.first
      add_entry Entry.new(self, job, options)
    end

    def add_entry(entry)
      sync do
        schedules << entry
        schedules.sort_by!(&:at)
      end
      tickle_watcher
      entry
    end

    def work
      @work ||= Threasy.work
    end

    def remove_entry(entry)
      sync { schedules.delete entry }
    end

    def tickle_watcher
      watcher.wakeup if watcher.stop?
    end

    def sync
      @semaphore.synchronize { yield }
    end

    def each
      schedules.each { |entry| yield entry }
    end

    def clear
      log.debug "Clearing schedules"
      sync { schedules.clear }
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
          seconds = [next_job.at - Time.now, max_sleep].min
          log.debug "Schedule watcher sleeping for #{seconds} seconds"
          sleep seconds
        end
      end
    end

    def entries_due
      [].tap do |entries|
        sync do
          while schedules.first && schedules.first.due?
            entries << schedules.shift
          end
        end
      end
    end

    def count
      schedules.count
    end

    def log
      Threasy.logger
    end

    def max_sleep
      Threasy.config.max_sleep
    end

    class Entry
      attr_accessor :schedule, :job, :at, :repeat

      def initialize(schedule, job, options = {})
        self.schedule = schedule
        self.job = job
        self.repeat = options[:every]
        seconds = options.fetch(:in) { repeat || 60 }
        self.at = options.fetch(:at) { Time.now + seconds }
      end

      def repeat?
        !! repeat
      end

      def once?
        ! repeat?
      end

      def due?
        Time.now > at
      end

      def future?
        ! due?
      end

      def overdue
        Time.now - at
      end

      def max_overdue
        Threasy.config.max_overdue
      end

      def work!
        if once? || overdue < max_overdue
          schedule.work.enqueue job
        end
        self.at = at + repeat if repeat?
      end

      def remove
        schedule.remove_entry self
      end
    end
  end
end

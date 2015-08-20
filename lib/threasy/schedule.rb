module Threasy
  class Schedule
    # = Threasy::Schedule
    #
    # Class that manages a "schedule".
    #
    # A "schedule" is a collection of jobs, some one-time, some repeating,
    # that execute at specific times.
    #
    # `Threasy::Schedule` maintains an ordered list of jobs, sorted by which
    # jobs are up "next".
    #
    # The `watcher` thread periodically wakes up, finds jobs that need to be
    # worked, and enqueues them into the `work` queue.
    #
    # The `work` queue defaults to the default `Threasy::Work` instance, but
    # can be any object that responds to `enqueue` and accepts your job objects.
    #
    # == Example
    #
    #     schedule = Threasy::Schedule.new
    #     schedule.add(MyJob.new(1,2,3), in: 1.hour, every: 0.5.days)
    include Enumerable

    attr_reader :schedules, :watcher

    # Creates new `Threasy::Schedule` instance
    #
    # === Parameters
    #
    # * `work` - Optional. Usually a `Threasy::Work` instance.
    #            Defaults to `Threasy.work`
    def initialize(work = nil)
      @work = work
      @semaphore = Mutex.new
      @schedules = []
      @watcher = Thread.new{ watch }
    end

    # Schedule a job
    #
    # === Examples
    #
    #     schedule = Threasy::Schedule.new(work: Threasy::Work.new)
    #
    #     # Schedule blocks
    #     schedule.add(in: 5.min) { do_some_background_work }
    #
    #     # Schedule job objects compatible with the `work` queue
    #     schedule.add(BackgroundJob.new(some: data), every: 1.hour)
    #
    #     # Enqueue strings that can be evals to a job object
    #     schedule.add("BackgroundJob.new", every: 1.day)
    #
    # === Parameters
    #
    # * `job` - Job object which responds to `perform` or `call`
    # * `options`
    #   * `every: n` - If present, job is repeated every `n` seconds
    #   * `in: n` - `n` seconds until job is executed
    #   * `at: Time` - Time to execute job at
    # * `&block` - Job block
    #
    # Must have either a `job` object or job `&block` present.
    #
    # === Returns
    #
    # * `Threasy::Schedule::Entry` if job was successfully added to schedule
    # * `nil` if job was for the past
    def add(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      job = block_given? ? block : args.first
      entry = Entry.new job, {schedule: self}.merge(options)
      add_entry entry if entry.future?
    end

    # Add a `Threasy::Schedule::Entry` object to `schedules`
    def add_entry(entry)
      sync do
        schedules << entry
        schedules.sort_by!(&:at)
      end
      tickle_watcher
      entry
    end

    # Returns the current work queue
    def work
      @work ||= Threasy.work
    end

    def remove_entry(entry)
      sync { schedules.delete entry }
    end

    # Wakes up the watcher thread if its sleeping
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

    # Used by the watcher thread to find jobs that are due, add them to the
    # `work` queue, re-sort the schedule, and attempt to sleep until the next
    # job is due.
    def watch
      loop do
        Thread.stop if schedules.empty?
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

    # Pop entries off the schedule that are due
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
  end
end

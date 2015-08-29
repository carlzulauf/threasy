module Threasy
  class Schedule::Entry
    # = Schedule Entry
    #
    # Represents a single entry in a schedule.
    #
    # Class is responsible for keeping track of the timing and recurrance of
    # a the supplied `job` object.
    #
    # Entry instances are usually created by a `Threasy::Schedule` instance
    # and should not be created by hand.
    #
    # See `Threasy::Schedule#add`
    attr_accessor :schedule, :work, :job, :at, :repeat, :times

    def initialize(job, options = {})
      self.schedule = options.fetch(:schedule) { Threasy.schedules }
      self.work     = options.fetch(:work) { schedule.work }
      self.job      = job
      self.repeat   = options[:every]
      seconds       = options.fetch(:in) { repeat || 60 }
      self.at       = options.fetch(:at) { Time.now + seconds }
      self.times    = options[:times]
    end

    def repeat?
      repeat && times_remaining?
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
        work.enqueue(job) if times_remaining?
        self.times -= 1 unless times.nil?
      end

      self.at = at + repeat if repeat?
    end

    def times_remaining?
      times.nil? || times > 0
    end

    def remove
      schedule.remove_entry self
    end
  end
end

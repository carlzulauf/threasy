module Threasy
  class Schedule::Entry
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

require "logger"
require "thread"
require "timeout"
require "set"

require "threasy/version"
require "threasy/config"
require "threasy/work"
require "threasy/schedule"
require "threasy/schedule/entry"

module Threasy
  # Returns default instance of `Threasy::Config`.
  #
  # Can be used with a block for changing multiple configs.
  #
  #     Threasy.config do |c|
  #       c.max_sleep   = 10.minutes
  #       c.max_overdue = 1.hour
  #     end
  #
  # ==== Parameters
  #
  # * `&block` - Optional block that will be yielded the config object
  #
  # ==== Returns
  #
  # * `Threasy::Config` instance
  def self.config
    @@config ||= Config.new
    yield @@config if block_given?
    @@config
  end

  # Shortcut for `Threasy::Config#logger`
  def self.logger
    config.logger
  end

  # Shortcut for default `Threasy::Work` instance.
  #
  # === Returns
  #
  # * `Threasy::Work` instance
  def self.work
    config.work ||= Work.new
  end

  # Shortcut to enqueue work into default `Threasy::Work` instance.
  #
  # === Examples
  #
  #     # Enqueue blocks
  #     Threasy.enqueue { do_some_background_work }
  #
  #     # Enqueue objects that respond to `perform` or `call`
  #     Threasy.enqueue BackgroundJob.new(some: data)
  #
  #     # Enqueue strings that can be evals to an object
  #     Threasy.enqueue("BackgroundJob.new")
  #
  def self.enqueue(*args, &block)
    work.enqueue *args, &block
  end

  # Shortcut for default `Threasy::Schedule` instance.
  #
  # === Returns
  #
  # * `Threasy::Schedule` instance
  def self.schedules
    config.schedule ||= Schedule.new(work)
  end

  # Shortcut to schedule work with the default `Threasy::Schedule` instance.
  #
  # === Examples
  #
  #     # Schedule blocks
  #     Threasy.schedule(in: 5.min) { do_some_background_work }
  #
  #     # Schedule job objects that respond to `perform` or `call`
  #     Threasy.schedule(BackgroundJob.new(some: data), every: 1.hour)
  #
  #     # Schedule strings that can be evals to a job object
  #     Threasy.schedule("BackgroundJob.new", every: 1.day)
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
  def self.schedule(*args, &block)
    schedules.add *args, &block
  end
end

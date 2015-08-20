# Threasy [![Build Status][travis-image]][travis-link]

[travis-image]: https://secure.travis-ci.org/carlzulauf/threasy.png?branch=master
[travis-link]: http://travis-ci.org/carlzulauf/threasy

Dead simple in-process threaded background job solution.

Includes scheduling for jobs in the future and/or recurring jobs.

Work waiting to be processed is stored in a thread-safe `Queue` and worked on by a small pool of worker threads.

### What to expect

* Dead simple-ness
* Ability to queue or schedule ruby blocks for asynchronus execution
* Extremely light-weight
* No dependencies (outside ruby stdlib)
* Portable: jruby, rubinius, and MRI
* Good performance
* Thread-safe
* Great solution for low to medium traffic single instance apps
* Ability to conserve memory on small VMs by doing as much in a single process as possible
* Plays nice with threaded or single process rack servers (puma, thin, rainbows)

### What __not__ to expect

* Failed job retrying/recovery (might be added, but just logs failures for now)
* Good solution for large scale deployments
* Avoidance of GIL contention issues in MRI during non-blocking jobs
* Plays nice with forking or other multi-process rack servers (passenger, unicorn)

## Installation

Add this line to your application's Gemfile:

    gem 'threasy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install threasy

## Usage

### `Threasy.enqueue`

```ruby
# Use a block
Threasy.enqueue { puts "This will happen in the background" }

# Use an object that responds to `perform` or `call`
Threasy.enqueue MyJob.new(1,2,3)
```

Jobs are placed in a work queue. Worker threads are spun up to process jobs as the queue grows.

### `Threasy.schedule`

Puts a job onto the schedule. Once the scheduler sees a job is due for processessing, it is enqueued into the work queue to be processed like any other job.

Available options:

* `:every`: number of seconds between repetition. Can be combined with `:at` or `:in`.
* `:in`: number of seconds until job is (next) triggered.
* `:at`: `Time` job is (next) triggered.

Example:

```ruby
# Use a block
Threasy.schedule(:in => 5.minutes) { puts "In the background, 5 minutes from now" }

# Use an job object
Threasy.schedule(MyJob.new(1,2,3), every: 5.minutes)
```

### `Threasy.schedules`

Returns the default instance of [`Threasy::Schedule`][schedule], which manages scheduled jobs.

### `Threasy.work`

Returns the default instance of [`Threasy::Work`][work], which manages the work queue and worker threads.

### `Threasy.config`

Returns the default instance of [`Threasy::Config`][config], which manages runtime configuration options.

`Threasy.config` can also accept a block and will yield the [`Threasy::Config`][config] instance.

```ruby
Threasy.config do |c|
  c.max_sleep   = 5.minutes
  c.max_overdue = 1.hour
  c.max_workers = 8
end
```

[schedule]: lib/threasy/schedule.rb
[work]:     lib/threasy/work.rb
[config]:   lib/threasy/config.rb

## Contributing

1. Fork it ( http://github.com/carlzulauf/threasy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

module Threasy
  class Work
    # = Threasy::Work
    #
    # Class to manage the work queue.
    #
    # An instance of `Threasy::Work` will manage a pool of worker threads and
    # a queue of jobs. As the job queue grows, new worker threads are created
    # process the jobs. When the Queue remains empty, worker threads are culled.
    #
    # == Example
    #
    #     work = Threasy::Work.new
    #     work.enqueue { puts "Hello from the background!" }
    #     # Outputs: Hello from the background!
    attr_reader :queue, :pool

    def initialize
      @queue = TimeoutQueue.new
      @pool = Set.new
      @semaphore = Mutex.new
      min_workers.times { add_worker }
    end

    # Enqueue a job into the work queue
    #
    # === Examples
    #
    #     work = Threasy::Work.new
    #
    #     # Enqueue blocks
    #     work.enqueue { do_some_background_work }
    #
    #     # Enqueue job objects that respond to `perform` or `call`
    #     work.enqueue BackgroundJob.new(some: data)
    #
    #     # Enqueue string that evals to a job object
    #     Threasy.enqueue("BackgroundJob.new")
    #
    def enqueue(*args, &block)
      args.unshift(block) if block_given?
      queue.push(args).tap { check_workers }
    end

    alias_method :enqueue_block, :enqueue

    def sync(&block)
      @semaphore.synchronize &block
    end

    def grab
      queue.pop
    end

    def min_workers
      Threasy.config.min_workers
    end

    def max_workers
      Threasy.config.max_workers
    end

    def check_workers
      sync do
        pool_size = pool.size
        log "Checking workers. Pool: #{pool_size} (min: #{min_workers}, max: #{max_workers})"
        if pool_size < max_workers
          add_worker if pool_size == 0 || queue.size > max_workers
        end
      end
    end

    def add_worker
      log "Adding new worker to pool"
      worker = Worker.new(self, pool.size)
      pool.add worker
      worker.work
    end

    def clear
      queue.clear
    end

    def log(msg)
      Threasy.logger.debug msg
    end

    class Worker
      def initialize(work, id)
        @work = work
        @id = id
      end

      def work
        @thread = Thread.start do
          loop do
            if args = @work.grab
              job = args.shift
              log.debug "Worker ##{@id} has grabbed a job"
              begin
                job = eval(job) if job.kind_of?(String)
                job.respond_to?(:perform) ? job.perform(*args) : job.call(*args)
              rescue Exception => e
                log.error %|Worker ##{@id} error: #{e.message}\n#{e.backtrace.join("\n")}|
              end
            elsif @work.pool.size > @work.min_workers
              @work.sync { @work.pool.delete self }
              break
            end
          end
        end
      end

      def log
        Threasy.logger
      end
    end

    class TimeoutQueue
      include Timeout

      def initialize
        @queue = Queue.new
      end

      def push(item)
        @queue << item
        true
      end

      def pop(seconds = 5)
        timeout(seconds) { @queue.pop }
      rescue Timeout::Error
        nil
      end

      def size
        @queue.size
      end

      def clear
        @queue.clear
      end
    end
  end
end

module Threasy
  class Work
    include Singleton

    attr_reader :queue, :pool

    def initialize
      @queue = TimeoutQueue.new
      @pool = Set.new
    end

    def enqueue(job = nil, &block)
      queue.push(block_given? ? block : job).tap{ check_workers }
    end

    alias_method :enqueue_block, :enqueue

    def grab
      queue.pop
    end

    def max_workers
      Threasy.config.max_workers
    end

    def check_workers
      pool_size = pool.size
      queue_size = queue.size
      log "Checking workers. Pool: #{pool_size}, Max: #{max_workers}, Queue: #{queue_size}"
      if pool_size < max_workers
        add_worker if pool_size == 0 || queue_size > max_workers
      end
    end

    def add_worker
      log "Adding new worker to pool"
      Worker.new(pool.size).work(self)
    end

    def log(msg)
      Threasy.logger.debug msg
    end

    class Worker
      def initialize(id)
        @id = id
      end

      def work(work)
        Thread.start do
          work.pool.add Thread.current
          while job = work.grab
            log.debug "Worker ##{@id} has grabbed a job"
            begin
              job.respond_to?(:perform) ? job.perform : job.call
            rescue Exception => e
              log.error %|Worker ##{@id} error: #{e.message}\n#{e.backtrace.join("\n")}|
            end
          end
          log.debug "Worker ##{@id} removing self from pool"
          work.pool.delete Thread.current
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

module GDK
  class LogTailer
    def initialize(log_path)
      @log_path = log_path
      @mutex = Mutex.new
      @pid = nil
      @want_shutdown = false
    end

    def run
      stat = File.stat(@log_path)
      Thread.new { monitor(@log_path, stat.dev, stat.ino) }

      loop do
        return if want_shutdown?

        my_pid = spawn('tail', '-f', @log_path)
        synchronize(true) do
          @pid = my_pid
        end

        Process.wait(my_pid)
      end
    end

    def want_shutdown?
      synchronize(true) { @want_shutdown }
    end

    # We can't use the mutex in a signal handler, so we have an option to bypass it.
    def shutdown(use_mutex=true)
      synchronize(use_mutex) { @want_shutdown = true }
      stop_tail(use_mutex)
    end

    private

    def synchronize(use_mutex)
      if use_mutex
        @mutex.synchronize { yield }
      else
        yield
      end
    end

    def monitor(log_path, dev, ino)
      loop do
        stat = File.stat(log_path)

        if dev != stat.dev || ino != stat.ino
          stop_tail
          dev = stat.dev
          ino = stat.ino
        end

        sleep 1
      end
    end

    def stop_tail(use_mutex=true)
      synchronize(use_mutex) do
        return unless @pid

        Process.kill('TERM', @pid)
      rescue Errno::ESRCH
      end
    end
  end
end

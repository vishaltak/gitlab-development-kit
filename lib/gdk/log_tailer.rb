module GDK
  class LogTailer
    def initialize(log_path)
      @log_path = log_path
      @mutex = Mutex.new
      @pid = nil
      @want_shutdown = false
    end

    def run
      # This thread will poll @log_path with stat to look for a change in file
      # device number / inode number.
      Thread.new { monitor(@log_path) }

      loop do
        return if want_shutdown?

        current_tail_pid = nil
        synchronize do
          current_tail_pid = spawn('tail', '-f', @log_path)
          @pid = current_tail_pid
        end

        Process.wait(current_tail_pid) # Blocks until tail is terminated
      end
    end

    def want_shutdown?
      synchronize { @want_shutdown }
    end

    def shutdown
      synchronize { @want_shutdown = true }
      stop_tail
    end

    private

    def synchronize
      @mutex.synchronize { yield }
    end

    def monitor(log_path)
      stat = File.stat(log_path)
      dev = stat.dev
      ino = stat.ino

      loop do
        sleep 1

        stat = File.stat(log_path)

        if dev != stat.dev || ino != stat.ino
          stop_tail
          dev = stat.dev
          ino = stat.ino
        end
      end
    end

    def stop_tail
      synchronize do
        return unless @pid

        Process.kill('TERM', @pid)
      rescue Errno::ESRCH
      end
    end
  end
end

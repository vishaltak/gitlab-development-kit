module GDK
  class LogTailer
    Inode = Struct.new(:dev, :ino)

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
    rescue => ex
      print_exception(ex)
    end

    def shutdown
      synchronize { @want_shutdown = true }
      stop_tail
    end

    private

    def print_exception(ex)
      warn "#{self.class}: fatal: #{ex}"
    end

    def want_shutdown?
      synchronize { @want_shutdown }
    end

    def synchronize
      @mutex.synchronize { yield }
    end

    def monitor(log_path)
      previous_inode = inode(log_path)

      loop do
        sleep 1

        current_inode = inode(log_path)

        if current_inode != previous_inode
          stop_tail
          previous_inode = current_inode
        end
      end
    rescue => ex
      print_exception(ex)

      shutdown # Make sure that #run gets unblocked and returns
    end

    def inode(path)
      st = File.stat(path)
      Inode.new(st.dev, st.ino)
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

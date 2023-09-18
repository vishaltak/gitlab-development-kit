# frozen_string_literal: true

require 'concurrent'
require 'open3'
require 'io/wait'

# Controls execution of commands delegated to the running shell
class Shellout
  attr_reader :args, :opts

  DEFAULT_EXECUTE_DISPLAY_OUTPUT = true
  DEFAULT_EXECUTE_RETRY_ATTEMPTS = 0
  DEFAULT_EXECUTE_RETRY_DELAY_SECS = 2
  BLOCK_SIZE = 1024

  ShelloutBaseError = Class.new(StandardError)
  ExecuteCommandFailedError = Class.new(ShelloutBaseError)
  StreamCommandFailedError = Class.new(ShelloutBaseError)

  def initialize(*args, **opts)
    @args = args.flatten
    @opts = opts
  end

  def command
    @command ||= args.join(' ')
  end

  def execute(display_output: true, display_error: true, retry_attempts: DEFAULT_EXECUTE_RETRY_ATTEMPTS, retry_delay_secs: DEFAULT_EXECUTE_RETRY_DELAY_SECS)
    retried ||= false
    GDK::Output.debug("command=[#{command}], opts=[#{opts}], display_output=[#{display_output}], retry_attempts=[#{retry_attempts}]")

    display_output ? stream : try_run
    GDK::Output.debug("result: success?=[#{success?}], stdout=[#{read_stdout}], stderr=[#{read_stderr}]")

    raise ExecuteCommandFailedError unless success?

    if retried
      retry_success_message = "'#{command}' succeeded after retry."
      GDK::Output.success(retry_success_message)
    end

    self
  rescue StreamCommandFailedError, ExecuteCommandFailedError
    error_message = "'#{command}' failed."

    if (retry_attempts -= 1).negative?
      GDK::Output.error(error_message) if display_error

      self
    else
      retried = true
      error_message += " Retrying in #{retry_delay_secs} secs.."
      GDK::Output.error(error_message) if display_error

      sleep(retry_delay_secs)
      retry
    end
  end

  # Executes the command while printing the output from both stdout and stderr
  #
  # This command will stream each individual character from a separate thread
  # making it possible to visualize interactive progress bar.
  def stream(extra_options = {})
    @stdout_str = ''
    @stderr_str = ''
    exit_flag = Concurrent::AtomicBoolean.new(false)

    # Inspiration: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    Open3.popen3(*args, opts.merge(extra_options)) do |stdin, stdout, stderr, thread|
      # Create a thread to read from $stdin and write to stdin of the process
      thread_stdin(exit_flag, stdin)

      @status = print_output_from_thread(thread, stdout, stderr)
    end

    read_stdout
  rescue Errno::ENOENT => e
    print_err(e.message)
    raise StreamCommandFailedError, e
  ensure
    exit_flag.value = false
  end

  def readlines(limit = -1)
    @stdout_str = ''
    @stderr_str = ''
    lines = []

    Open3.popen2(*args, opts) do |_stdin, stdout, thread|
      stdout.each_line do |line|
        lines << line.chomp if limit == -1 || lines.count < limit
      end

      thread.join
      @status = thread.value
    end

    @stdout_str = lines.join("\n")

    lines
  end

  def run
    capture
    read_stdout
  end

  def try_run
    capture(err: '/dev/null')
    read_stdout
  rescue Errno::ENOENT
    ''
  end

  def read_stdout
    clean_string(@stdout_str.to_s.chomp)
  end

  def read_stderr
    clean_string(@stderr_str.to_s.chomp)
  end

  # Return whether last run command was successful (exit 0)
  #
  # @return [Boolean] whether last run command was successful
  def success?
    return false unless @status

    @status.success?
  end

  # Exit code from last run command
  #
  # @return [Integer] exit code
  def exit_code
    return nil unless @status

    @status.exitstatus
  end

  private

  def print_output_from_thread(thread, stdout, stderr)
    threads = Array(thread)
    threads << thread_read(stdout, method(:print_out))
    threads << thread_read(stderr, method(:print_err))
    threads.each(&:join)
    thread.value
  end

  def clean_string(str)
    str.sub(/\r\e/, '').chomp
  end

  def capture(extra_options = {})
    @stdout_str, @stderr_str, @status = Open3.capture3(*args, opts.merge(extra_options))
  end

  def thread_stdin(exit_flag, stdin)
    Thread.new do
      until exit_flag.value
        input = $stdin.gets
        if input.nil?
          exit_flag = true
        else
          stdin.puts input.chomp
        end
      end
    end
  end

  def thread_read(io, meth)
    Thread.new do
      until io.eof?
        ready = io.wait_readable

        meth.call(io.read_nonblock(BLOCK_SIZE)) if ready
      end
    end
  end

  def print_out(msg)
    @stdout_str += msg
    GDK::Output.print(msg)
  end

  def print_err(msg)
    @stderr_str += msg
    GDK::Output.print(msg, stderr: true)
  end
end

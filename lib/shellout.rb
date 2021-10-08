# frozen_string_literal: true

require 'open3'

class Shellout
  attr_reader :args, :opts

  DEFAULT_EXECUTE_DISPLAY_OUTPUT = true
  DEFAULT_EXECUTE_RETRY_ATTEMPTS = 0
  DEFAULT_EXECUTE_RETRY_DELAY_SECS = 2

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

  def execute(display_output: true, retry_attempts: DEFAULT_EXECUTE_RETRY_ATTEMPTS, retry_delay_secs: DEFAULT_EXECUTE_RETRY_DELAY_SECS)
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
      GDK::Output.error(error_message)
      self
    else
      retried = true
      error_message += " Retrying in #{retry_delay_secs} secs.."
      GDK::Output.error(error_message)

      sleep(retry_delay_secs)
      retry
    end
  end

  def stream(extra_options = {})
    @stdout_str = ''
    @stderr_str = ''

    # Inspiration: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    Open3.popen3(*args, opts.merge(extra_options)) do |_stdin, stdout, stderr, thread|
      @status = print_output_from_thread(thread, stdout, stderr)
    end

    read_stdout
  rescue Errno::ENOENT => e
    print_err(e.message)
    raise StreamCommandFailedError, e
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

  def success?
    return false unless @status

    @status.success?
  end

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

  def thread_read(io, meth)
    Thread.new do
      io.each_line { |line| meth.call(line) }
    end
  end

  def print_out(msg)
    @stdout_str += msg
    GDK::Output.puts(msg)
  end

  def print_err(msg)
    @stderr_str += msg
    GDK::Output.puts(msg, stderr: true)
  end
end

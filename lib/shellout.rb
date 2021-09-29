# frozen_string_literal: true

require 'open3'

class Shellout
  attr_reader :args, :opts

  def initialize(*args, **opts)
    @args = args.flatten
    @opts = opts
  end

  def execute(display_output: true, silent: false, allow_fail: false)
    GDK::Output.debug("args=[#{args}], opts=[#{opts}], display_output=[#{display_output}], silent=[#{silent}], allow_fail=[#{allow_fail}]")

    display_output ? stream : try_run

    GDK::Output.debug("result: stdout=[#{clean_string(read_stdout)}], stderr=[#{clean_string(read_stderr)}]")

    unless success?
      message = "ERROR: Command '#{args.join(' ')}' failed."
      raise(message) unless allow_fail

      unless silent
        GDK::Output.warn(message)
        GDK::Output.warn(read_stdout) unless read_stdout.empty?
        GDK::Output.warn(read_stderr) unless read_stderr.empty?
      end
    end

    self
  end

  def stream(extra_options = {})
    @stdout_str = ''
    @stderr_str = ''

    # Inspiration: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    Open3.popen3(*args, opts.merge(extra_options)) do |_stdin, stdout, stderr, thread|
      threads = Array(thread)
      threads << thread_read(stdout, method(:print_out))
      threads << thread_read(stderr, method(:print_err))

      threads.each(&:join)

      @status = thread.value
    end

    read_stdout
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
    @stdout_str.to_s.chomp
  end

  def read_stderr
    @stderr_str.to_s.chomp
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

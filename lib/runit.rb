# frozen_string_literal: true

require_relative 'shellout'
require_relative 'runit/config'
require_relative 'gdk/log_tailer'

module Runit
  IGNORE_FOREMAN_FILE = '.ignore-foreman'

  def self.start_runsvdir
    Dir.chdir($gdk_root)

    no_foreman_running!
    runit_installed!

    Runit::Config.new($gdk_root).render

    # It is important that we use an absolute path with `runsvdir`: this
    # allows us to distinguish processes belonging to different GDK
    # installations on the same machine.
    args = ['runsvdir', '-P', File.join($gdk_root, 'services')]
    return if runsvdir_running?(args.join(' '))

    Process.fork do
      Dir.chdir('/')
      Process.setsid

      # Cargo-culting the use of 395 periods from omnibus-gitlab.
      # https://gitlab.com/gitlab-org/omnibus-gitlab/blob/5dfdcafa30ad6e203a04a917f180b630d5121cf6/config/templates/runit/runsvdir-start.erb#L42
      spawn(*args, 'log: ' + '.' * 395, in: '/dev/null', out: '/dev/null', err: '/dev/null')
    end
  end

  def self.no_foreman_running!
    return if File.exist?(IGNORE_FOREMAN_FILE)
    return if Shellout.new(%w[pgrep foreman]).run.empty?

    abort <<~MESSAGE

      ERROR: It looks like 'gdk run' is running somewhere. You cannot
      use 'gdk start' and 'gdk run' at the same time.

      Please stop 'gdk run' with Ctrl-C.

      (If this is a false alarm, run 'touch #{IGNORE_FOREMAN_FILE}' and try again.)
    MESSAGE
  end

  def self.runsvdir_running?(cmd)
    pgrep = Shellout.new(%w[pgrep runsvdir]).run
    return if pgrep.empty?

    pids = pgrep.split("\n").map { |str| Integer(str) }
    pids.any? do |pid|
      Shellout.new(%W[ps -o args= -p #{pid}]).run.start_with?(cmd + ' ')
    end
  end

  def self.runit_installed!
    return unless Shellout.new(%w[which runsvdir]).run.empty?

    abort <<~MESSAGE

      ERROR: gitlab-development-kit requires Runit to be installed.
      You can install Runit with:

        #{runit_instructions}

    MESSAGE
  end

  def self.runit_instructions
    if File.executable?('/usr/local/bin/brew') # Homebrew
      'brew install runit'
    elsif File.executable?('/opt/local/bin/port') # MacPorts
      'sudo port install runit'
    elsif File.executable?('/usr/bin/apt') # Debian / Ubuntu
      'sudo apt install runit'
    else
      '(no copy-paste Runit installation snippet available for your OS)'
    end
  end

  def self.sv(cmd, services)
    Dir.chdir($gdk_root)
    start_runsvdir
    services = service_args(services)
    services.each { |svc| wait_runsv!(svc) }
    exec('sv', cmd, *services)
  end

  def self.service_args(services)
    return Dir['./services/*'].sort if services.empty?

    services.flat_map do |svc|
      case svc
      when 'rails'
        Dir['./services/rails-*'].sort
      when 'tunnel'
        Dir['./services/tunnel_*'].sort
      else
        File.join('./services', svc)
      end
    end
  end

  def self.wait_runsv!(dir)
    abort "unknown runit service: #{dir}" unless File.directory?(dir)

    50.times do
      begin
        open(File.join(dir, 'supervise/ok'), File::WRONLY|File::NONBLOCK).close
      rescue
        sleep 0.1
        next
      end
      return
    end

    abort "timeout waiting for runsv in #{dir}"
  end

  def self.tail(services)
    Dir.chdir($gdk_root)

    tails = log_files(services).map { |log| GDK::LogTailer.new(log) }

    %w[INT TERM].each do |sig|
      trap(sig) { tails.each { |t| t.shutdown(false) } }
    end

    wait = Thread.new { sleep }
    tails.each do |tail|
      Thread.new do
        tail.run
        wait.kill
      end
    end

    wait.join
    tails.each { |t| t.shutdown }
    exit
  end

  def self.log_files(services)
    return Dir['log/*/current'] if services.empty?

    services.flat_map do |svc|
      case svc
      when 'rails'
        Dir['./log/rails-*/current']
      when 'tunnel'
        Dir['./log/tunnel_*/current']
      else
        File.join('log', svc, 'current')
      end
    end
  end
end

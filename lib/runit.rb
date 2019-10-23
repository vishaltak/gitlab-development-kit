# frozen_string_literal: true

require_relative 'shellout'
require_relative 'runit/config'

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
    res = system('sv', cmd, *services)
    display_ready_message if cmd == 'status'
    res
  end

  def self.gdk_config
    @gdk_config ||= GDK::Config.new
  end

  def self.display_ready_message
    puts <<~EOS

    INFO: #{rails_url} #{overall_status_message}
    EOS
  end

  def self.overall_status_message
    gitlab_ready? ? 'is ready!' : 'is not ready...'
  end

  def self.gitlab_ready?
    case Net::HTTP.get_response(URI.parse(rails_sign_in_url))
    when Net::HTTPSuccess, Net::HTTPFound
      true
    else
      false
    end
  rescue
    false
  end

  def self.rails_url_scheme
    gdk_config.https? ? 'https' : 'http'
  end

  def self.rails_url
    url = "#{rails_url_scheme}://#{gdk_config.hostname}"
    url = "#{url}:#{gdk_config.port}" unless [80, 443].include?(gdk_config.port)
    url
  end

  def self.rails_sign_in_url
    "#{rails_url}/#{gdk_config.hostname}/users/sign_in"
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

    tails = log_files(services).map { |log| spawn('tail', '-f', log) }

    %w[INT TERM].each do |sig|
      trap(sig) { kill_processes(tails) }
    end

    wait = Thread.new { sleep }
    tails.each do |tail|
      Thread.new do
        Process.wait(tail)
        wait.kill
      end
    end

    wait.join
    kill_processes(tails)
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

  def self.kill_processes(pids)
    pids.each do |pid|
      begin
        Process.kill('TERM', pid)
      rescue Errno::ESRCH
      end
    end
  end
end

# frozen_string_literal: true

# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require 'securerandom'
require_relative 'runit'
autoload :Shellout, 'shellout'

module GDK
  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.match?(/bsd/) ? 'gmake' : 'make'

  # dependencies are always declared via autoload
  # this allows for any dependent project require only `lib/gdk`
  # and load only what it really needs
  autoload :Shellout, 'shellout'
  autoload :Output, 'gdk/output'
  autoload :Env, 'gdk/env'
  autoload :Config, 'gdk/config'
  autoload :Command, 'gdk/command'
  autoload :Dependencies, 'gdk/dependencies'
  autoload :Diagnostic, 'gdk/diagnostic'
  autoload :Services, 'gdk/services'
  autoload :ErbRenderer, 'gdk/erb_renderer'
  autoload :Logo, 'gdk/logo'
  autoload :Postgresql, 'gdk/postgresql'
  autoload :PostgresqlGeo, 'gdk/postgresql_geo'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  # rubocop:disable Metrics/AbcSize
  def self.main # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if !install_root_ok? && ARGV.first != 'reconfigure'
      puts <<~GDK_MOVED
        According to #{ROOT_CHECK_FILE} this gitlab-development-kit
        installation was moved. Run 'gdk reconfigure' to update hard-coded
        paths.
      GDK_MOVED
      return false
    end

    validate_yaml!

    case subcommand = ARGV.shift
    when 'run'
      abort <<~GDK_RUN_NO_MORE
        'gdk run' is no longer available; see doc/runit.md.

        Use 'gdk start', 'gdk stop', and 'gdk tail' instead.
      GDK_RUN_NO_MORE
    when 'install'
      install
    when 'update'
      update_result = update
      return false unless update_result

      if config.gdk.experimental.auto_reconfigure?
        reconfigure
      else
        update_result
      end
    when 'diff-config'
      GDK::Command::DiffConfig.new.run

      true
    when 'config'
      config_command = ARGV.shift
      abort 'Usage: gdk config get slug.of.the.conf.value' if config_command != 'get' || ARGV.empty?

      begin
        puts config.dig(*ARGV)
        true
      rescue GDK::ConfigSettings::SettingUndefined
        abort "Cannot get config for #{ARGV.join('.')}"
      end
    when 'reconfigure'
      reconfigure
    when 'psql'
      pg_port = config.postgresql.port
      args = ARGV.empty? ? ['-d', 'gitlabhq_development'] : ARGV

      exec('psql', '-h', GDK.root.join('postgresql').to_s, '-p', pg_port.to_s, *args, chdir: GDK.root)
    when 'redis-cli'
      exec('redis-cli', '-s', config.redis_socket.to_s, *ARGV, chdir: GDK.root)
    when 'env'
      GDK::Env.exec(ARGV)
    when 'status'
      exit(Runit.sv(subcommand, ARGV))
    when 'start'
      exit(start(ARGV))
    when 'restart'
      exit(restart(ARGV))
    when 'stop'
      if ARGV.empty?
        # Runit.stop will stop all services and stop Runit (runsvdir) itself.
        # This is only safe if all services are shut down; this is why we have
        # an integrated method for this.
        Runit.stop
        exit
      else
        # Stop the requested services, but leave Runit itself running.
        exit(Runit.sv('force-stop', ARGV))
      end
    when 'tail'
      Runit.tail(ARGV)
    when 'thin'
      # We cannot use Runit.sv because that calls Kernel#exec. Use system instead.
      system('gdk', 'stop', 'rails-web')
      exec(
        { 'RAILS_ENV' => 'development' },
        *%W[bundle exec thin --socket=#{config.gitlab.__socket_file} start],
        chdir: GDK.root.join('gitlab')
      )
    when 'doctor'
      GDK::Command::Doctor.new.run
      true
    when /-{0,2}help/, '-h', nil
      GDK::Command::Help.new.run
      true
    else
      GDK::Output.notice "gdk: #{subcommand} is not a gdk command."
      GDK::Output.notice "See 'gdk help' for more detail."
      false
    end
  end
  # rubocop:enable Metrics/AbcSize

  def self.config
    @config ||= GDK::Config.new
  end

  def self.puts_separator(msg = nil)
    puts '-------------------------------------------------------'
    return unless msg

    puts msg
    puts_separator
  end

  def self.display_help_message
    puts_separator <<~HELP_MESSAGE
      You can try the following that may be of assistance:

      - Run 'gdk doctor'.
      - Visit the troubleshooting documentation:
        https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/troubleshooting.md.
      - Visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues to
        see if there are known issues.
    HELP_MESSAGE
  end

  def self.install_root_ok?
    expected_root = GDK.root.join(ROOT_CHECK_FILE).read.chomp
    Pathname.new(expected_root).realpath == GDK.root
  rescue StandardError => e
    warn e
    false
  end

  # Return the path to the GDK base path
  #
  # @return [Pathname] path to GDK base directory
  def self.root
    Pathname.new($gdk_root || Pathname.new(__dir__).parent) # rubocop:disable Style/GlobalVars
  end

  def self.make(*targets)
    sh = Shellout.new(MAKE, targets, chdir: GDK.root)
    sh.stream
    sh.success?
  end

  # Called when running `gdk start`
  def self.start(argv)
    result = Runit.sv('start', argv)
    # Only print if run like `gdk start`, not e.g. `gdk start rails-web`
    print_url_ready_message if argv.empty?

    result
  end

  # Called when running `gdk restart`
  def self.restart(argv)
    result = Runit.sv('force-restart', argv)
    # Only print if run like `gdk restart`, not e.g. `gdk restart rails-web`
    print_url_ready_message if argv.empty?

    result
  end

  # Called when running `gdk install`
  def self.install
    result = make('install', *ARGV)

    unless result
      GDK::Output.error('Failed to install.')
      display_help_message
    end

    result
  end

  # Called when running `gdk update`
  def self.update
    make('self-update')

    result = make('self-update', 'update')

    unless result
      GDK::Output.error('Failed to update.')
      display_help_message
    end

    result
  end

  # Called when running `gdk reconfigure`
  def self.reconfigure
    remember!(GDK.root)

    result = make('reconfigure')

    unless result
      GDK::Output.error('Failed to reconfigure.')
      display_help_message
    end

    result
  end

  def self.print_url_ready_message
    GDK::Output.puts
    GDK::Output.notice("GitLab available at #{config.__uri} shortly.")
    GDK::Output.notice("GitLab Kubernetes Agent Server available at #{config.gitlab_k8s_agent.__url_for_agentk}.") if config.gitlab_k8s_agent?
  end

  def self.validate_yaml!
    config.validate!
    nil
  rescue StandardError => e
    GDK::Output.error("Your gdk.yml is invalid.\n\n")
    GDK::Output.puts(e.message, stderr: true)
    abort
  end
end

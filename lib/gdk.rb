# frozen_string_literal: true

# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require 'securerandom'
require_relative 'runit'

autoload :Asdf, 'asdf'
autoload :Shellout, 'shellout'

# GitLab Development Kit
module GDK
  StandardErrorWithMessage = Class.new(StandardError)
  HookCommandError = Class.new(StandardError)

  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'
  SUBCOMMANDS_NOT_REQUIRING_YAML_VALIDATION = %w[version].freeze

  DIFFABLE_FILES = %w[
    clickhouse/config.d/data-paths.xml
    clickhouse/config.d/gdk.xml
    clickhouse/config.d/logger.xml
    clickhouse/config.d/openssl.xml
    clickhouse/config.d/user-directories.xml
    clickhouse/config.xml
    clickhouse/users.d/gdk.xml
    clickhouse/users.xml
    consul/config.json
    gdk.example.yml
    gitaly/gitaly.config.toml
    gitaly/praefect.config.toml
    gitlab-pages/gitlab-pages.conf
    gitlab-runner-config.toml
    gitlab-shell/config.yml
    gitlab/config/cable.yml
    gitlab/config/database.yml
    gitlab/config/gitlab.yml
    gitlab/config/puma.rb
    gitlab/config/redis.cache.yml
    gitlab/config/redis.queues.yml
    gitlab/config/redis.rate_limiting.yml
    gitlab/config/redis.repository_cache.yml
    gitlab/config/redis.sessions.yml
    gitlab/config/redis.shared_state.yml
    gitlab/config/redis.trace_chunks.yml
    gitlab/config/resque.yml
    gitlab/config/session_store.yml
    gitlab/workhorse/config.toml
    nginx/conf/nginx.conf
    openssh/sshd_config
    pgbouncers/pgbouncer-replica-1.ini
    pgbouncers/pgbouncer-replica-2-1.ini
    pgbouncers/pgbouncer-replica-2-2.ini
    pgbouncers/pgbouncer-replica-2.ini
    pgbouncers/userlist.txt
    Procfile
    prometheus/prometheus.yml
    redis/redis.conf
    registry/config.yml
    support/makefiles/Makefile.config.mk
  ].freeze

  # dependencies are always declared via autoload
  # this allows for any dependent project require only `lib/gdk`
  # and load only what it really needs
  autoload :Announcement, 'gdk/announcement'
  autoload :Announcements, 'gdk/announcements'
  autoload :Backup, 'gdk/backup'
  autoload :Clickhouse, 'gdk/clickhouse'
  autoload :Command, 'gdk/command'
  autoload :Config, 'gdk/config'
  autoload :ConfigType, 'gdk/config_type'
  autoload :ConfigSettings, 'gdk/config_settings'
  autoload :Dependencies, 'gdk/dependencies'
  autoload :Diagnostic, 'gdk/diagnostic'
  autoload :Env, 'gdk/env'
  autoload :ErbRenderer, 'gdk/erb_renderer'
  autoload :Hooks, 'gdk/hooks'
  autoload :HTTPHelper, 'gdk/http_helper'
  autoload :Logo, 'gdk/logo'
  autoload :Machine, 'gdk/machine'
  autoload :Output, 'gdk/output'
  autoload :OutputBuffered, 'gdk/output_buffered'
  autoload :PortManager, 'gdk/port_manager'
  autoload :Postgresql, 'gdk/postgresql'
  autoload :PostgresqlUpgrader, 'gdk/postgresql_upgrader'
  autoload :Project, 'gdk/project'
  autoload :PostgresqlGeo, 'gdk/postgresql_geo'
  autoload :Services, 'gdk/services'
  autoload :Shellout, 'shellout'
  autoload :TestURL, 'gdk/test_url'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    subcommand = ARGV.shift
    validate_yaml! unless SUBCOMMANDS_NOT_REQUIRING_YAML_VALIDATION.include?(subcommand)

    exit(::GDK::Command::COMMANDS[subcommand].call.new.run(ARGV)) if ::GDK::Command::COMMANDS.key?(subcommand)

    case subcommand
    when 'status'
      exit(GDK::Command::Status.new.run(ARGV))
    when 'start'
      exit(GDK::Command::Start.new.run(ARGV))
    when 'restart'
      exit(GDK::Command::Restart.new.run(ARGV))
    when 'stop'
      exit(GDK::Command::Stop.new.run(ARGV))
    when /-{0,2}version/
      GDK::Command::Version.new.run(ARGV)
    when /-{0,2}help/, '-h', nil
      GDK::Command::Help.new.run(ARGV)
    else
      all_commands = ::GDK::Command::COMMANDS.keys + %w[status start restart stop]
      suggestions = DidYouMean::SpellChecker.new(dictionary: all_commands).correct(subcommand)
      message = ["#{subcommand} is not a GDK command"]

      if suggestions.any?
        message << ', did you mean - '
        message << suggestions.map { |suggestion| "'gdk #{suggestion}'" }.join(' or ')
        message << '?'
      else
        message << '.'
      end

      GDK::Output.warn message.join
      GDK::Output.puts

      GDK::Output.info "See 'gdk help' for more detail."
      false
    end
  end

  def self.config
    @config ||= GDK::Config.new
  end

  def self.puts_separator(msg = nil)
    GDK::Output.puts('-------------------------------------------------------')
    return unless msg

    GDK::Output.puts(msg)
    puts_separator
  end

  # Return the path to the GDK base path
  #
  # @return [Pathname] path to GDK base directory
  def self.root
    Pathname.new($gdk_root || Pathname.new(__dir__).parent) # rubocop:disable Style/GlobalVars
  end

  def self.template_root
    Pathname.new(File.expand_path(File.join(__dir__, '..', 'support', 'templates')))
  end

  def self.make(*targets, env: {})
    sh = Shellout.new(MAKE, targets, chdir: GDK.root, env: env)
    sh.stream
    sh.success?
  end

  def self.validate_yaml!
    config.validate!
    nil
  rescue StandardError => e
    GDK::Output.error("Your gdk.yml is invalid.\n\n")
    GDK::Output.puts(e.message, stderr: true)
    abort('')
  end
end

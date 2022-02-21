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
  HookCommandError = Class.new(StandardError)

  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'
  # TODO: Touching .gdk-install-root will be redundant shortly.
  ROOT_CHECK_FILE = '.gdk-install-root' unless defined?(ROOT_CHECK_FILE)

  # dependencies are always declared via autoload
  # this allows for any dependent project require only `lib/gdk`
  # and load only what it really needs
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
  autoload :Output, 'gdk/output'
  autoload :OutputBuffered, 'gdk/output_buffered'
  autoload :Postgresql, 'gdk/postgresql'
  autoload :Project, 'gdk/project'
  autoload :PostgresqlGeo, 'gdk/postgresql_geo'
  autoload :Services, 'gdk/services'
  autoload :Shellout, 'shellout'
  autoload :TestURL, 'gdk/test_url'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    validate_yaml!

    subcommand = ARGV.shift

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
      GDK::Output.warn "#{subcommand} is not a GDK command."

      all_commands = ::GDK::Command::COMMANDS.keys + %w[status start restart stop]
      suggestions = DidYouMean::SpellChecker.new(dictionary: all_commands).correct(subcommand)

      if suggestions.any?
        prefix = 'Did you mean?  '

        GDK::Output.warn prefix + suggestions.shift

        suggestions.each do |suggestion|
          GDK::Output.warn ' ' * prefix.length + suggestion
        end

        GDK::Output.puts
      end

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

  def self.make(*targets)
    Shellout.new(MAKE, targets, chdir: GDK.root).execute.success?
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

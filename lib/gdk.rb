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
  HookCommandError = Class.new(StandardError)

  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'

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
  autoload :HTTPHelper, 'gdk/http_helper'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  # rubocop:disable Metrics/AbcSize
  def self.main # rubocop:disable Metrics/CyclomaticComplexity
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
      GDK::Command::Run.new.run(ARGV)
    when 'install'
      GDK::Command::Install.new.run(ARGV)
    when 'update'
      GDK::Command::Update.new.run(ARGV)
    when 'diff-config'
      GDK::Command::DiffConfig.new.run(ARGV)
    when 'config'
      GDK::Command::Config.new.run(ARGV)
    when 'reconfigure'
      GDK::Command::Reconfigure.new.run(ARGV)
    when 'reset-data'
      GDK::Command::ResetData.prompt_and_run
    when 'psql'
      GDK::Command::Psql.new.run(ARGV)
    when 'psql-geo'
      GDK::Command::PsqlGeo.new.run(ARGV)
    when 'redis-cli'
      GDK::Command::RedisCLI.new.run(ARGV)
    when 'env'
      GDK::Env.exec(ARGV)
    when 'status'
      exit(GDK::Command::Status.new.run(ARGV))
    when 'start'
      exit(GDK::Command::Start.new.run(ARGV))
    when 'restart'
      exit(GDK::Command::Restart.new.run(ARGV))
    when 'stop'
      exit(GDK::Command::Stop.new.run(ARGV))
    when 'tail'
      Runit.tail(ARGV)
    when 'thin'
      GDK::Command::Thin.new.run(ARGV)
    when 'doctor'
      GDK::Command::Doctor.new.run(ARGV)
    when 'measure'
      GDK::Command::MeasureUrl.new.run(ARGV)
    when 'measure-workflow'
      GDK::Command::MeasureWorkflow.new.run(ARGV)
    when 'pristine'
      GDK::Command::Pristine.new.run(ARGV)
    when /-{0,2}help/, '-h', nil
      GDK::Command::Help.new.run(ARGV)
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
    GDK::Output.puts('-------------------------------------------------------')
    return unless msg

    GDK::Output.puts(msg)
    puts_separator
  end

  def self.display_help_message
    puts_separator <<~HELP_MESSAGE
      You can try the following that may be of assistance:

      - Run 'gdk doctor'.

      - Visit the troubleshooting documentation:
        https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/troubleshooting.md.
      - Visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues to
        see if there are known issues.

      - Run 'gdk reset-data' if appropriate.
      - Run 'gdk pristine' which will restore your GDK to a pristine state.
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

  def self.execute_hooks(hooks, description)
    hooks.each do |cmd|
      execute_hook_cmd(cmd, description)
    end

    true
  end

  def self.execute_hook_cmd(cmd, description)
    GDK::Output.abort("Cannot execute '#{description}' hook '#{cmd}' as it's invalid") unless cmd.is_a?(String)

    GDK::Output.info("#{description} hook -> #{cmd}")

    sh = Shellout.new(cmd, chdir: GDK.root)
    sh.stream

    raise HookCommandError, "'#{cmd}' has exited with code #{sh.exit_code}." unless sh.success?

    true
  rescue HookCommandError, Errno::ENOENT => e
    GDK::Output.abort(e.message)
  end

  def self.with_hooks(hooks, name)
    execute_hooks(hooks[:before], "#{name}: before")
    result = block_given? ? yield : true
    execute_hooks(hooks[:after], "#{name}: after")

    result
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

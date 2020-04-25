# frozen_string_literal: true

# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require_relative 'runit'
autoload :Shellout, 'shellout'

module GDK
  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.match?(/bsd/) ? 'gmake' : 'make'

  # dependencies are always declared via autoload
  # this allows for any dependent project require only `lib/gdk`
  # and load only what it really needs
  autoload :Output, 'gdk/output'
  autoload :Env, 'gdk/env'
  autoload :Config, 'gdk/config'
  autoload :Command, 'gdk/command'
  autoload :Dependencies, 'gdk/dependencies'
  autoload :Diagnostic, 'gdk/diagnostic'
  autoload :ErbRenderer, 'gdk/erb_renderer'
  autoload :Logo, 'gdk/logo'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    if !install_root_ok? && ARGV.first != 'reconfigure'
      puts <<-GDK_MOVED.gsub(/^\s+\|/, '')
        |According to #{ROOT_CHECK_FILE} this gitlab-development-kit
        |installation was moved. Run 'gdk reconfigure' to update hard-coded
        |paths.
      GDK_MOVED
      return false
    end

    case subcommand = ARGV.shift
    when 'run'
      abort <<~GDK_RUN_NO_MORE
        'gdk run' is no longer available; see doc/runit.md.

        Use 'gdk start', 'gdk stop', and 'gdk tail' instead.
      GDK_RUN_NO_MORE
    when 'install'
      exec(MAKE, *ARGV, chdir: GDK.root)
    when 'update'
      # Otherwise we would miss it and end up in a weird state.
      puts "-------------------------------------------------------"
      puts "Running `make self-update`.."
      puts "-------------------------------------------------------"
      puts "Running separately in case the Makefile is updated.\n"
      system(MAKE, 'self-update', chdir: GDK.root)

      puts "\n-------------------------------------------------------"
      puts "Running `make self-update update`.."
      puts "-------------------------------------------------------"
      exec(MAKE, 'self-update', 'update', chdir: GDK.root)
    when 'diff-config'
      GDK::Command::DiffConfig.new.run

      true
    when 'config'
      config_command = ARGV.shift
      abort 'Usage: gdk config get slug.of.the.conf.value' if config_command != 'get' || ARGV.empty?

      begin
        puts Config.new.dig(*ARGV)
        true
      rescue GDK::ConfigSettings::SettingUndefined
        abort "Cannot get config for #{ARGV.join('.')}"
      end
    when 'reconfigure'
      remember!(GDK.root)
      exec(MAKE, 'touch-examples', 'unlock-dependency-installers', 'postgresql-sensible-defaults', 'all', chdir: GDK.root)
    when 'psql'
      pg_port = Config.new.postgresql.port
      args = ARGV.empty? ? ['-d', 'gitlabhq_development'] : ARGV

      exec('psql', '-h', GDK.root.join('postgresql').to_s, '-p', pg_port.to_s, *args, chdir: GDK.root)
    when 'redis-cli'
      exec('redis-cli', '-s', GDK::Config.new.redis_socket.to_s, *ARGV, chdir: GDK.root)
    when 'env'
      GDK::Env.exec(ARGV)
    when 'start', 'status'
      exit(Runit.sv(subcommand, ARGV))
    when 'restart'
      exit(Runit.sv('force-restart', ARGV))
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
        *%W[bundle exec thin --socket=#{GDK.root}/gitlab.socket start],
        chdir: GDK.root.join('gitlab')
      )
    when 'doctor'
      GDK::Command::Doctor.new.run
      true
    when /-{0,2}help/, '-h'
      GDK::Command::Help.new.run
      true
    else
      GDK::Output.notice "gdk: #{subcommand} is not a gdk command."
      GDK::Output.notice "See 'gdk help' for more detail."
      false
    end
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
end

# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

require_relative '../shellout'
require_relative 'output'

module GDK
  class ErbRenderer
    attr_reader :source, :target

    def initialize(source, target, args = {})
      @source = source
      @target = target
      @args = args
    end

    def render!(target = @target)
      return if warn_not_applied_if_target_protected?

      str = File.read(source)
      # A trim_mode of '-' allows omitting empty lines with <%- -%>
      result = ERB.new(str, trim_mode: '-').result_with_hash(@args)

      File.write(target, result)
    rescue GDK::ConfigSettings::UnsupportedConfiguration => e
      GDK::Output.abort("#{e.message}.")
      false
    end

    def safe_render!
      return if warn_not_applied_if_target_protected?

      temp_file = Tempfile.open(target)
      render!(temp_file.path)

      if File.exist?(target)
        return if FileUtils.identical?(target, temp_file.path)

        warn_changes!(temp_file.path)
        backup!
        warn_overwritten!
      end

      FileUtils.mkdir_p(File.dirname(target)) # Ensure target's directory exists
      FileUtils.mv(temp_file.path, target)
    rescue GDK::ConfigSettings::UnsupportedConfiguration => e
      GDK::Output.abort("#{e.message}.")
      false
    ensure
      temp_file&.close
    end

    private

    def warn_changes!(temp_file)
      diff = Shellout.new(%W[git --no-pager diff --no-index #{colors_arg} -u #{target} #{temp_file}]).readlines[4..]
      return unless diff

      GDK::Output.puts
      GDK::Output.info("'#{target}' has incoming changes:")

      diff_output = <<~DIFF_OUTPUT
        -------------------------------------------------------------------------------------------------------------
        #{diff.join("\n")}

        -------------------------------------------------------------------------------------------------------------
      DIFF_OUTPUT

      GDK::Output.puts(diff_output, stderr: true)
    end

    def target_protected?
      config.config_file_protected?(target)
    end

    def warn_not_applied_if_target_protected?
      return false unless target_protected?

      GDK::Output.warn("Changes to '#{target}' not applied because it's protected in gdk.yml.")
      true
    end

    def warn_overwritten!
      GDK::Output.warn "'#{target}' has been overwritten. To recover the previous version, run:"
      GDK::Output.puts <<~OVERWRITTEN

        #{backup.recover_cmd_string}
        If you want to protect this file from being overwritten, see:
        https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md#overwriting-configuration-files
        -------------------------------------------------------------------------------------------------------------
      OVERWRITTEN
    end

    def backup
      @backup ||= Backup.new(target)
    end

    def backup!
      backup.backup!(advise: false)
    end

    def colors?
      @colors ||= Shellout.new('tput colors').try_run.chomp.to_i >= 8
    end

    def colors_arg
      '--color' if colors?
    end

    def config
      @args[:config] || raise(::ArgumentError, "'args' argument should have ':config' key")
    end
  end
end

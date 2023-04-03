# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

require_relative '../shellout'
require_relative 'output'

module GDK
  class ErbRenderer
    attr_reader :source, :target

    def initialize(source, target, **args)
      @source = source
      @target = target
      @args = args.merge(config: config)
    end

    def safe_render!
      return unless should_render?(target)

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

    def render!(target = @target)
      return unless should_render?(target)

      str = File.read(source)
      # A trim_mode of '-' allows omitting empty lines with <%- -%>
      result = ERB.new(str, trim_mode: '-').result_with_hash(@args)

      File.write(target, result)
    rescue GDK::ConfigSettings::UnsupportedConfiguration => e
      GDK::Output.abort("#{e.message}.")
      false
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

    def target_protected?(target_file)
      # We need to pass in target_file because #render! can potentially override
      # @target
      config.config_file_protected?(target_file)
    end

    def should_render?(target)
      # if the target is _not_ protected, no need to check any further
      return true unless target_protected?(target)

      if File.exist?(target)
        GDK::Output.warn("Changes to '#{target}' not applied because it's protected in gdk.yml.")

        false
      else
        GDK::Output.warn("Creating missing protected file '#{target}'.")

        true
      end
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
      if colors?
        '--color'
      else
        '--no-color'
      end
    end

    def config
      @config ||= GDK.config
    end
  end
end

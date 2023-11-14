# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'

module GDK
  module Templates
    # ErbRenderer is responsible for rendering templates and providing
    # them access to configuration data
    class ErbRenderer
      attr_reader :source, :target, :locals

      # Initialize the renderer providing source, target and local variables
      #
      # @param [String] source
      # @param [String] target
      # @param [Hash] locals variables available inside the template
      def initialize(source, target, **locals)
        @source = source
        @target = target
        @locals = locals.merge(config: GDK.config)
      end

      # The safe render take extra steps to avoid unrecoverable changes:
      # - Render the new content to a temporary file
      # - Display a diff of the changes
      # - Make a timestamped backup of the target file
      # - Provide instructions on how to restore previous changes
      # - Move the temporary file to replace the old one
      def safe_render!
        return unless should_render?(target)

        temp_file = Tempfile.create(target)
        File.write(temp_file.path, render_to_string)

        if File.exist?(target)
          return if FileUtils.identical?(target, temp_file.path)

          display_changes!(temp_file.path)
          backup!
          warn_overwritten!
        end

        FileUtils.mkdir_p(File.dirname(target)) # Ensure target's directory exists
        FileUtils.mv(temp_file.path, target)
      ensure
        temp_file&.close
      end

      # Render template into target file
      def render!
        return unless should_render?(target)

        FileUtils.mkdir_p(File.dirname(target)) # Ensure target's directory exists
        File.write(target, render_to_string)
      end

      # Render template and return its content
      #
      # @return [String] Rendered content
      def render_to_string
        raise ArgumentError, "file not found in: #{source}" unless File.exist?(source)

        template = File.read(source)

        erb = ERB.new(template, trim_mode: '-') # A trim_mode of '-' allows omitting empty lines with <%- -%>
        erb.location = source.to_s # define the file location so errors can point to the right file
        erb.result_with_hash(locals)
      rescue GDK::ConfigSettings::UnsupportedConfiguration => e
        GDK::Output.abort("#{e.message}.", e)
      end

      private

      # Compare and display changes between content on temporary file and existing target
      #
      # @param [File] temp_file
      def display_changes!(temp_file)
        cmd = %W[git --no-pager diff --no-index #{git_color_args} -u #{target} #{temp_file}]
        diff = Shellout.new(cmd).readlines[4..]
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
        GDK.config.config_file_protected?(target_file)
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

      def git_color_args
        if colors?
          '--color'
        else
          '--no-color'
        end
      end
    end
  end
end

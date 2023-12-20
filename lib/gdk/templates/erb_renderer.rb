# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'tempfile'
require 'json'

module GDK
  module Templates
    # ErbRenderer is responsible for rendering templates and providing
    # them access to configuration data
    class ErbRenderer
      attr_reader :source, :context

      # Initialize the renderer providing source, target and local variables
      #
      # @param [Pathname] source
      # @param [Hash] **locals variables available inside the template
      def initialize(source, **locals)
        @source = ensure_pathname(source)
        @context = ::GDK::Templates::Context.new(**locals)
      end

      # The safe render take extra steps to avoid unrecoverable changes:
      # - Render the new content to a temporary file
      # - Display a diff of the changes
      # - Make a timestamped backup of the target file
      # - Provide instructions on how to restore previous changes
      # - Move the temporary file to replace the old one
      #
      # @param [Pathname] target
      def safe_render!(target)
        target = ensure_pathname(target)

        return unless should_render?(target)

        temp_file = Tempfile.create(target.to_s)
        File.write(temp_file.path, render_to_string)

        if target.exist?
          return if FileUtils.identical?(target, temp_file.path)

          display_changes!(temp_file.path, target)
          backup = perform_backup!(target)
          warn_overwritten!(backup)
        end

        FileUtils.mkdir_p(target.dirname) # Ensure target's directory exists
        FileUtils.mv(temp_file.path, target)
      ensure
        temp_file&.close
      end

      # Render template into target file
      #
      # @param [Pathname] target
      def render(target)
        target = ensure_pathname(target)

        return unless should_render?(target)

        FileUtils.mkdir_p(target.dirname) # Ensure target's directory exists
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
        erb.result(@context.context_bindings)
      rescue GDK::ConfigSettings::UnsupportedConfiguration => e
        GDK::Output.abort("#{e.message}.", e)
      end

      private

      # Compare and display changes between existing and newly rendered content
      #
      # @param [File] new_temporary_file
      # @param [File] existing_file
      def display_changes!(new_temporary_file, existing_file)
        cmd = %W[git --no-pager diff --no-index #{git_color_args} -u #{existing_file} #{new_temporary_file}]
        diff = Shellout.new(cmd).readlines[4..]
        return unless diff

        GDK::Output.puts
        GDK::Output.info("'#{relative_path(existing_file)}' has incoming changes:")

        diff_output = <<~DIFF_OUTPUT
          -------------------------------------------------------------------------------------------------------------
          #{diff.join("\n")}

          -------------------------------------------------------------------------------------------------------------
        DIFF_OUTPUT

        GDK::Output.puts(diff_output, stderr: true)
      end

      def target_protected?(target)
        GDK.config.config_file_protected?(relative_path(target))
      end

      def should_render?(target)
        # if the target is _not_ protected, no need to check any further
        return true unless target_protected?(target)

        if File.exist?(target)
          GDK::Output.warn("Changes to '#{relative_path(target)}' not applied because it's protected in gdk.yml.")

          false
        else
          GDK::Output.warn("Creating missing protected file '#{relative_path(target)}'.")

          true
        end
      end

      def warn_overwritten!(backup)
        GDK::Output.warn "'#{backup.relative_source_file}' has been overwritten. To recover the previous version, run:"
        GDK::Output.puts <<~OVERWRITTEN

          #{backup.recover_cmd_string}
          If you want to protect this file from being overwritten, see:
          https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md#overwriting-configuration-files
          -------------------------------------------------------------------------------------------------------------
        OVERWRITTEN
      end

      # Perform a backup of given file target
      #
      # @param [String] target file that will be back up
      # @return [GDK::Backup]
      def perform_backup!(target)
        Backup.new(target).tap { |backup| backup.backup!(advise: false) }
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

      def relative_path(target)
        return target unless target.absolute?

        target.relative_path_from(GDK.root)
      end

      def ensure_pathname(path)
        path.is_a?(Pathname) ? path : Pathname.new(path)
      end
    end
  end
end

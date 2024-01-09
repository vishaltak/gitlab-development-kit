# frozen_string_literal: true

module GDK
  module Execute
    # Rake adapter to execute tasks in GDK or Gitlab rails environment
    class Rake
      attr_reader :tasks

      # @param [Array<String>] *tasks a list of tasks to be executed
      def initialize(*tasks)
        @tasks = tasks
      end

      # Execute rake tasks in the GDK root folder and environment
      #
      # @param [Array] *args any arg that Shellout#execute accepts
      def execute_in_gdk(**)
        @shellout = Shellout.new(rake_command, chdir: GDK.root).execute(**)

        self
      end

      # Execute rake tasks in the `gitlab` rails environment
      #
      # @param [Array] *args any arg that Shellout#execute accepts
      def execute_in_gitlab(**)
        if bundler_available?
          Bundler.with_unbundled_env do
            @shellout = Shellout.new(rake_command, chdir: GDK.config.gitlab.dir).execute(**)
          end
        else
          @shellout = Shellout.new(rake_command, chdir: GDK.config.gitlab.dir).execute(**)
        end

        self
      end

      # Return whether the execution was a success or not
      #
      # @return [Boolean] whether the execution was a success
      def success?
        @shellout&.success?
      end

      private

      # Return a list of commands necessary to execute `rake`
      #
      # It takes into consideration whether `asdf` environment is required
      #
      # @return [Array<String (frozen)>] array of commands to be used by Shellout
      def rake_command
        cmd = %w[bundle exec rake] + tasks
        cmd = %w[asdf exec] + cmd if GDK::Dependencies.asdf_available?
        cmd
      end

      def bundler_available?
        defined? Bundler
      end
    end
  end
end

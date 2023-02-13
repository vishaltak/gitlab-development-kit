# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    # Handles `gdk reset-data` command execution
    class ResetData < BaseCommand
      def run(_ = [])
        return false unless continue?
        return false unless stop_and_backup!

        reset_data!
      end

      private

      def stop_and_backup!
        Runit.stop(quiet: true)

        return true if backup_data

        GDK::Output.error('Failed to backup data.')
        display_help_message

        false
      end

      def reset_data!
        if GDK.make('ensure-databases-running', 'reconfigure')
          GDK::Output.notice('Successfully reset data!')
          GDK::Command::Start.new.run
        else
          GDK::Output.error('Failed to reset data.')
          display_help_message

          false
        end
      end

      def continue?
        GDK::Output.warn("We're about to remove _all_ (GitLab and praefect) PostgreSQL data, Rails uploads and git repository data.")
        GDK::Output.warn("Backups will be made in '#{GDK.root.join('.backups')}', just in case!")

        return true if ENV.fetch('GDK_RESET_DATA_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

        GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def backup_data
        move_postgres_data && move_redis_dump_rdb && move_rails_uploads && move_git_repository_data
      end

      def current_timestamp
        @current_timestamp ||= Time.now.strftime('%Y-%m-%d_%H.%M.%S')
      end

      def create_directory(directory)
        directory = gdk_root_pathed(directory)
        Dir.mkdir(directory) unless directory.exist?

        true
      rescue Errno::ENOENT => e
        GDK::Output.error("Failed to create directory '#{directory}' - #{e}")
        false
      end

      def backup_path(message, *path)
        path_to_backup = gdk_backup_pathed_timestamped(*path)
        path = gdk_root_pathed(*path)
        return true unless path.exist?

        GDK::Output.notice("Moving #{message} from '#{path}' to '#{path_to_backup}/'")

        # Ensure the base path exists
        FileUtils.mkdir_p(path_to_backup.dirname)
        FileUtils.mv(path, path_to_backup)

        true
      rescue SystemCallError => e
        GDK::Output.error("Failed to rename path '#{path}' to '#{path_to_backup}/' - #{e}")
        false
      end

      def gdk_backup_pathed_timestamped(*path)
        path = path.flatten
        path[-1] = "#{path[-1]}.#{current_timestamp}"
        GDK.root.join('.backups', *path)
      end

      def gdk_root_pathed(*path)
        GDK.root.join(*path.flatten)
      end

      def move_postgres_data
        backup_path('PostgreSQL data', %w[postgresql data])
      end

      def move_redis_dump_rdb
        backup_path('redis dump.rdb', %w[redis dump.rdb])
      end

      def move_rails_uploads
        backup_path('Rails uploads', %w[gitlab public uploads])
      end

      def move_git_repository_data
        backup_path('git repository data', 'repositories') &&
          restore_repository_data_dir &&
          backup_path('more git repository data', 'repository_storages')
      end

      def restore_repository_data_dir
        sh = Shellout.new('git restore repositories', chdir: GDK.root)
        sh.try_run
        sh.success?
      end

      def touch_file(file)
        FileUtils.touch(file)
        true
      rescue SystemCallError
        false
      end
    end
  end
end

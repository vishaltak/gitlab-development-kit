# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reset-data` command execution
    class ResetData
      def self.prompt_and_run
        GDK::Output.warn("We're about to remove PostgreSQL data, Rails uploads and git repository data.")
        accepted = GDK::Output.prompt('Are you sure? [y/N]')
        return false unless accepted.match?(/\Ay(?:es)*\z/i)

        new.run
      end

      def run
        GDK.remember!(GDK.root)
        Runit.stop

        unless backup_data
          GDK::Output.error('Failed to backup data.')
          GDK.display_help_message
          return false
        end

        # reset data
        if GDK.make
          GDK::Output.notice('Successfully reset data!')
          GDK.start([])
        else
          GDK::Output.error('Failed to reset data.')
          GDK.display_help_message
          false
        end
      end

      private

      def backup_data
        move_postgres_data && move_rails_uploads && move_git_repository_data
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

      def backup_directory(message, directory)
        new_directory = gdk_root_pathed_timestamped(directory)
        directory = gdk_root_pathed(directory)
        return true unless directory.exist?

        GDK::Output.notice("Moving #{message} from '#{directory}' to '#{new_directory}'")
        File.rename(directory, new_directory)

        true
      rescue SystemCallError => e
        GDK::Output.error("Failed to rename directory '#{directory}' to '#{new_directory}' - #{e}")
        false
      end

      def gdk_root_pathed_timestamped(path)
        gdk_root_pathed("#{path}.#{current_timestamp}")
      end

      def gdk_root_pathed(path)
        GDK.root.join(path)
      end

      def move_postgres_data
        backup_directory('PostgreSQL data', 'postgresql/data')
      end

      def move_rails_uploads
        backup_directory('Rails uploads', 'gitlab/public/uploads')
        create_directory('gitlab/public/uploads')
      end

      def move_git_repository_data
        backup_directory('git repository data', 'repositories') && \
          fix_repository_data_gitkeep_file
      end

      def fix_repository_data_gitkeep_file
        return false unless create_directory('repositories')

        repositories_gitkeep_file = gdk_root_pathed('repositories').join('.gitkeep')
        timestamped_repositories_gitkeep_file = gdk_root_pathed_timestamped('repositories').join('.gitkeep')

        timestamped_repositories_gitkeep_file.unlink if timestamped_repositories_gitkeep_file.exist?
        touch_file(repositories_gitkeep_file)
      end

      def touch_file(file)
        File.open(file, 'w') {}
        true
      rescue SystemCallError
        false
      end
    end
  end
end

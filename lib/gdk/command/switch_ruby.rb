# frozen_string_literal: true

module GDK
  module Command
    class SwitchRuby < BaseCommand
      def run(args = [])
        current_version = GDK::Dependencies::GitlabVersions.new.ruby_version
        new_version = args.first

        if new_version.nil?
          GDK::Output.info('Please specify ruby version')
          return true
        end

        if new_version == current_version
          GDK::Output.info("You're already using Ruby #{current_version}")
          return true
        end

        GDK::Output.info("Changing ruby version from #{current_version} to #{new_version}")

        write_gitlab_local_file('.ruby-version', new_version)
        # sh = Shellout.new(cmd, chdir: GDK.root)
        # shellout = Shellout.new(cmd)
        # shellout.run

        GDK::Output.info("gdk install")
        # GDK::Command::Install.new.run
        shellout = Shellout.new("gdk update", chdir: GDK.root)
        shellout.stream

        return true
      end

      private

      # Write content to file in `gitlab` folder
      #
      # @param [String] filename
      # @content [String] file content
      # @return [String,False] version or false
      def write_gitlab_local_file(filename, content)
        file = GDK.root.join('gitlab', filename)

        File.open(file, 'w') { |f| f.write(content) }
      end
    end
  end
end

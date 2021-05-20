# frozen_string_literal: true

require 'pathname'

module GDK
  class Backup
    SourceFileOutsideOfGdk = Class.new(StandardError)

    attr_reader :source_file

    def self.backup_root
      GDK.root.join('.backups')
    end

    def initialize(source_file)
      @source_file = Pathname.new(source_file.to_s).realpath

      validate!
    end

    def backup!(copy: true, advise: true)
      ensure_backup_directory_exists
      make_backup_of_source_file(copy)
      advise_user if advise

      true
    end

    def destination_file
      @destination_file ||= begin
        backup_root.join("#{relative_source_file.to_s.gsub('/', '__')}.#{Time.now.strftime('%Y%m%d%H%M%S')}")
      end
    end

    def relative_source_file
      @relative_source_file ||= source_file.relative_path_from(GDK.root)
    end

    def relative_destination_file
      @relative_destination_file ||= destination_file.relative_path_from(GDK.root)
    end

    private

    def validate!
      raise SourceFileOutsideOfGdk unless source_file.to_s.start_with?(GDK.root.to_s)

      true
    end

    def backup_root
      @backup_root ||= self.class.backup_root
    end

    def ensure_backup_directory_exists
      backup_root.mkpath
    end

    def advise_user
      GDK::Output.info("A backup of '#{relative_source_file}' has been made at '#{relative_destination_file}'.")
    end

    def make_backup_of_source_file(copy)
      action = copy ? :cp : :mv
      FileUtils.public_send(action, source_file.to_s, destination_file.to_s) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end

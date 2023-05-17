# frozen_string_literal: true

module GDK
  # Utility functions related to GDK dependencies
  module Dependencies
    autoload :Checker, 'gdk/dependencies/checker'
    autoload :GitlabVersions, 'gdk/dependencies/gitlab_versions'

    MissingDependency = Class.new(StandardError)

    # Is Homebrew available?
    #
    # @return boolean
    def self.homebrew_available?
      executable_exist?('brew')
    end

    # Is MacPorts available?
    #
    # @return boolean
    def self.macports_available?
      executable_exist?('port')
    end

    # Is Debian / Ubuntu APT available?
    #
    # @return boolean
    def self.linux_apt_available?
      executable_exist?('apt')
    end

    # Is Asdf is available and correctly setup?
    #
    # @return boolean
    def self.asdf_available?
      executable_exist?('asdf') && ENV.values_at('ASDF_DATA_DIR', 'ASDF_DIR').compact.any?
    end

    # Search on PATH or default locations for provided binary and return its fullpath
    #
    # @param [String] binary name
    # @return [String] full path to the binary file
    def self.find_executable(binary)
      executable_file = proc { |name| next name if File.file?(name) && File.executable?(name) }

      # Retrieve PATH from ENV or use a fallback
      path = ENV['PATH']&.split(File::PATH_SEPARATOR) || %w[/usr/local/bin /usr/bin /bin]

      # check binary against each PATH
      path.each do |dir|
        file = File.expand_path(binary, dir)

        return file if executable_file.call(file)
      end

      nil
    end

    # Check whether provided binary name exists on PATH or default locations
    #
    # @param [String] binary name
    def self.executable_exist?(name)
      !!find_executable(name)
    end
  end
end

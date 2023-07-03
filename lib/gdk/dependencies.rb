# frozen_string_literal: true

module GDK
  # Utility functions related to GDK dependencies
  module Dependencies
    autoload :Checker, 'gdk/dependencies/checker'
    autoload :GitlabVersions, 'gdk/dependencies/gitlab_versions'
    autoload :PostgreSQL, 'gdk/dependencies/postgresql'

    MissingDependency = Class.new(StandardError)

    # Is Homebrew available?
    #
    # @return boolean
    def self.homebrew_available?
      Utils.executable_exist?('brew')
    end

    # Is MacPorts available?
    #
    # @return boolean
    def self.macports_available?
      Utils.executable_exist?('port')
    end

    # Is Debian / Ubuntu APT available?
    #
    # @return boolean
    def self.linux_apt_available?
      Utils.executable_exist?('apt')
    end

    # Is Asdf is available and correctly setup?
    #
    # @return boolean
    def self.asdf_available?
      return false if config.asdf.opt_out?

      Utils.executable_exist?('asdf') || ENV.values_at('ASDF_DATA_DIR', 'ASDF_DIR').compact.any?
    end

    # Is rtx available?
    #
    # @return [Boolean]
    def self.rtx_available?
      Utils.executable_exist?('rtx')
    end

    def self.config
      GDK.config
    end
  end
end

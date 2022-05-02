# frozen_string_literal: true

require 'mkmf'

MakeMakefile::Logging.quiet = true
MakeMakefile::Logging.logfile(File::NULL)

module GDK
  module Dependencies
    autoload :Checker, 'gdk/dependencies/checker'
    autoload :GitlabVersions, 'gdk/dependencies/gitlab_versions'

    MissingDependency = Class.new(StandardError)

    # Homebrew
    def self.homebrew_available?
      !!MakeMakefile.find_executable('brew')
    end

    # MacPorts
    def self.macports_available?
      !!MakeMakefile.find_executable('port')
    end

    # Debian / Ubuntu APT
    def self.linux_apt_available?
      !!MakeMakefile.find_executable('apt')
    end
  end
end

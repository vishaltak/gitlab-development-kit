# frozen_string_literal: true

require 'lib/gdk/dependencies'
require 'lib/helpers/output_helpers'

module Helpers
  class DependenciesFinder
    extend OutputHelpers

    # @param required_version string with the required ruby version
    def self.check_ruby_version!(required_version)
      return unless required_version != RUBY_VERSION

      warn("You're using Ruby version #{RUBY_VERSION}.")
      warn("However we recommend using Ruby version #{required_version} for this repository.")
      notice("Press <ENTER> to continue installation or <CTRL-C> to abort")
      gets
    end

    def self.require_yarn_available!
      return if Gdk::Dependencies.command_present?('syarn')

      error('Yarn executable was not detected in the system.')
      notice("Download Yarn at https://yarnpkg.com/en/docs/install")
      exit 1
    end

    def self.ensure_bundler_available!
      return if Gdk::Dependencies.command_present?('bundle')

      notice("Installing 'bundler' from rubygems")
      system('gem install bundler')
    end
  end
end

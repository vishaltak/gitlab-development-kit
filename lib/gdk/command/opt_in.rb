# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class OptIn < BaseCommand
      def run(_ = [])
        filepath = GDK.root.join('.opt-in')

        puts 'Please enter your GitLab username or leave blank to keep data anonymous:'
        username = $stdin.gets

        File.write(filepath, username)

        puts 'Error tracking and analytic data will now be collected.'

        true
      end
    end
  end
end

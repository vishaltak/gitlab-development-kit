# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class OptOut < BaseCommand
      def run(_ = [])
        filepath = GDK.root.join('.opt-in')
        FileUtils.rm_f(filepath)

        puts 'Error tracking and analytic data will no longer be collected.'

        true
      end
    end
  end
end

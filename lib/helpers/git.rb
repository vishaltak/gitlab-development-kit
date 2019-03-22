# frozen_string_literal: true

require 'lib/helpers/output_helpers'

module Helpers
  class Git
    extend OutputHelpers

    # @param [String] repository
    # @param [String] dest_path
    def clone(repository, dest_path)
      if File.exist?(dest_path)
        puts "Repository already exist"
        return
      end
      `git clone #{repository} #{dest_path}`
    end
  end
end

# frozen_string_literal: true

require 'lib/helpers/output_helpers'

module Helpers
  class Git
    extend OutputHelpers

    # @param [String] repository
    # @param [String] dest_path
    # @param [Integer] depth number of commits to shallow clone, or nil to do a full clone
    def self.clone_repo(repository, dest_path, depth: 1)
      if File.exist?(dest_path)
        puts "Repository already exist"

        return
      end

      `git clone #{convert_depth_arg(depth)} #{repository} #{dest_path}`
    end

    def self.convert_depth_arg(depth)
      "--depth=#{depth}" if depth
    end
  end
end

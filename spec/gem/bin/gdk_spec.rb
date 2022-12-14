# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gdk' do
  describe 'version' do
    let!(:gdk_bin_full_path) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'gem', 'bin', 'gdk')) }

    context 'within a GDK directory' do
      it 'returns version including git SHA' do
        git_sha = `git rev-parse --short HEAD`.chomp

        expect(`#{gdk_bin_full_path} version`).to eql("GitLab Development Kit 0.2.16 (#{git_sha})\n")
      end
    end
  end
end

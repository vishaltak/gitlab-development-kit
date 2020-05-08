# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Runit::Config do
  let(:tmp_root) { File.expand_path('../../../tmp', __dir__) }
  let(:gdk_root) { Dir.mktmpdir(nil, tmp_root) }

  subject { described_class.new(gdk_root) }

  after do
    FileUtils.rm_rf(gdk_root)
  end

  describe '#stale_service_links' do
    it 'removes unknown symlinks from the services directory' do
      services_dir = File.join(gdk_root, 'services')
      enabled_service_names = %w[svc1 svc2]

      FileUtils.mkdir_p(services_dir)

      (enabled_service_names + %w[stale]).each do |entry|
        File.symlink('/tmp', File.join(services_dir, entry))
      end

      FileUtils.touch(File.join(services_dir, 'should-be-ignored'))

      expect(subject.stale_service_links(enabled_service_names)).to eq([File.join(services_dir, 'stale')])
    end
  end
end

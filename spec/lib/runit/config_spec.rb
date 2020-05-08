# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Runit::Config do
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
      all_services = %w[svc1 svc2 stale]

      enabled_services = enabled_service_names.map { |name| Runit::Config::Service.new(name, '/usr/bin/false') }

      FileUtils.mkdir_p(services_dir)

      all_services.each do |entry|
        File.symlink('/tmp', File.join(services_dir, entry))
      end

      FileUtils.touch(File.join(services_dir, 'should-be-ignored'))

      stale_collection = [File.join(services_dir, 'stale')]
      expect(subject.stale_service_links(enabled_services)).to eq(stale_collection)
    end
  end

  describe '#run_env', :aggregate_failures do
    it 'memoize output from generate_run_env' do
      expect(subject).to receive(:generate_run_env).once.and_call_original

      2.times { subject.run_env }
    end

    it 'exports GITLAB_TRACING related env variables when jaeger is enabled' do
      yaml = {
        'tracer' => {
          'jaeger' => {
            'enabled' => true
          }
        }
      }
      stub_gdk_yaml(yaml)

      expect(subject.run_env).to match(/GITLAB_TRACING=/)
      expect(subject.run_env).to match(/GITLAB_TRACING_URL=/)
    end

    it 'doesnt include GITLAB_TRACING related env variables when jaeger is disabled' do
      expect(subject.run_env).not_to match(/GITLAB_TRACING=/)
      expect(subject.run_env).not_to match(/GITLAB_TRACING_URL=/)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Modules::Registry do
  let(:storage_path_fake) { '/some/fake/path' }
  let(:storage_path_double) { instance_double(Pathname, to_s: storage_path_fake) }
  let(:host_fake) { 'fakehost' }

  let(:config_yml_fake) { '/tmp/registry/config.yml' }
  let(:config_yml_double) { instance_double(Pathname, to_s: config_yml_fake) }

  let(:docker_certs_d_path_double) { double }
  let(:docker_certs_ca_crt_path_double) { double }

  let(:shellout_double) { instance_double(Shellout, execute: true) }

  let(:localhost_key_fake) { '/tmp/registry/localhost.key' }
  let(:localhost_key_path_double) { instance_double(Pathname, to_s: localhost_key_fake, exist?: true) }

  let(:localhost_crt_fake) { '/tmp/registry/localhost.crt' }
  let(:localhost_crt_path_double) { instance_double(Pathname, to_s: localhost_crt_fake) }

  let(:registry_host_key_fake) { '/tmp/registry/localhost.key' }
  let(:registry_host_key_path_double) { instance_double(Pathname, to_s: registry_host_key_fake, exist?: true) }

  let(:registry_host_crt_fake) { '/tmp/registry/localhost.crt' }
  let(:registry_host_crt_path_double) { instance_double(Pathname, to_s: registry_host_crt_fake) }

  let(:yaml) do
    {
      '__openssl_bin_path' => '/some/bin/openssl',
      'registry' => {
        'host' => host_fake,
        'storage_path' => storage_path_fake,
        'config_yml' => config_yml_fake,
        'localhost_key_path' => localhost_key_fake,
        'localhost_crt_path' => localhost_crt_fake,
        'registry_host_key_path' => registry_host_key_fake,
        'registry_host_crt_path' => registry_host_crt_fake
      }
    }
  end

  let(:gdk_config) { stub_gdk_yaml(yaml) }

  let(:gdk_config_registry_double) do
    double( # rubocop:disable RSpec/VerifiedDoubles
      host: host_fake,
      storage_path: storage_path_double,
      config_yml: config_yml_double,
      localhost_key_path: localhost_key_path_double,
      localhost_crt_path: localhost_crt_path_double,
      registry_host_key_path: registry_host_key_path_double,
      registry_host_crt_path: registry_host_crt_path_double,
      __docker_certs_d_path: docker_certs_d_path_double,
      __docker_certs_ca_crt_path: docker_certs_ca_crt_path_double
    )
  end

  subject { described_class.new }

  before do
    allow(gdk_config).to receive(:registry).and_return(gdk_config_registry_double)
  end

  describe '#setup' do
    it 'makes registry storage path, creates config.yml and generates localhost.(key|crt)' do
      expect(storage_path_double).to receive(:mkpath)
      expect(subject).to receive(:generate_file_if_not_exist).with(config_yml_double, 'registry/config.yml', 'config.rake')
      allow(localhost_key_path_double).to receive(:exist?).and_return(false)
      expect(Shellout).to receive(:new).with(%(/some/bin/openssl req -new -subj "/CN=127.0.0.1/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "#{localhost_key_fake}" -out "#{localhost_crt_fake}" -addext "subjectAltName=DNS:#{host_fake})).and_return(shellout_double)
      expect(localhost_key_path_double).to receive(:chmod).with(0o600)

      subject.setup
    end
  end

  describe '#trust', :hide_stdout do
    it 'generates registry_host_key.(key|crt), makes Docker certs.d path and copies in registry_host_key.(key|crt)' do
      allow(registry_host_key_path_double).to receive(:exist?).and_return(false)
      expect(Shellout).to receive(:new).with(%(/some/bin/openssl req -new -subj "/CN=#{host_fake}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "#{registry_host_key_fake}" -out "#{registry_host_crt_fake}" -addext "subjectAltName=DNS:#{host_fake}")).and_return(shellout_double)
      expect(registry_host_key_path_double).to receive(:chmod).with(0o600)
      expect(docker_certs_d_path_double).to receive(:mkpath)
      allow(docker_certs_ca_crt_path_double).to receive(:exist?).and_return(true)
      expect(docker_certs_ca_crt_path_double).to receive(:delete)
      expect(FileUtils).to receive(:cp).with(registry_host_crt_path_double, docker_certs_ca_crt_path_double)

      subject.trust
    end
  end
end

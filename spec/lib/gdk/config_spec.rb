# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Config do
  let(:nginx_enabled) { false }
  let(:group_saml_enabled) { false }
  let(:protected_config_files) { [] }
  let(:overwrite_changes) { false }
  let(:omniauth_config) { { 'group_saml' => { 'enabled' => group_saml_enabled } } }
  let(:yaml) do
    {
      'gdk' => { 'protected_config_files' => protected_config_files, 'overwrite_changes' => overwrite_changes },
      'nginx' => { 'enabled' => nginx_enabled },
      'hostname' => 'gdk.example.com',
      'omniauth' => omniauth_config
    }
  end

  let(:default_config) { described_class.new }

  subject(:config) { described_class.new(yaml: yaml) }

  before do
    # Ensure a developer's local gdk.yml does not affect tests
    allow_any_instance_of(GDK::ConfigSettings).to receive(:read!).and_return(nil)
  end

  describe 'common' do
    describe 'ca_path' do
      it 'is not set by default' do
        expect(config.common.ca_path).to be('')
      end
    end
  end

  describe '__architecture' do
    it 'returns x86_64' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('x86_64')

      expect(config.__architecture).to eq('x86_64')
    end
  end

  describe '__platform' do
    let(:host_os) { nil }

    before do
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
    end

    context 'when macOS' do
      let(:host_os) { 'Darwin' }

      it 'returns macos' do
        expect(config.__platform).to eq('macos')
      end
    end

    context 'when Linux' do
      let(:host_os) { 'Linux' }

      it 'returns linux' do
        expect(config.__platform).to eq('linux')
      end
    end

    context 'when neither macOS of Linux' do
      let(:host_os) { 'NotSure' }

      it 'returns unknown' do
        expect(config.__platform).to eq('unknown')
      end
    end
  end

  describe '__uri' do
    context 'for defaults' do
      it 'returns http://gdk.example.com:3000' do
        expect(config.__uri.to_s).to eq('http://gdk.example.com:3000')
      end
    end

    context 'when port is set to 1234' do
      it 'returns http://gdk.example.com:1234' do
        yaml['port'] = '1234'

        expect(config.__uri.to_s).to eq('http://gdk.example.com:1234')
      end
    end

    context 'when a relative_url_root is set' do
      it 'returns http://gdk.example.com:3000/gitlab' do
        yaml['relative_url_root'] = '/gitlab/'

        expect(config.__uri.to_s).to eq('http://gdk.example.com:3000/gitlab')
      end
    end

    context 'when https is enabled' do
      before do
        yaml['https'] = { 'enabled' => true }
      end

      it 'returns https://gdk.example.com:3000' do
        expect(config.__uri.to_s).to eq('https://gdk.example.com:3000')
      end

      context 'and port is set to 443' do
        it 'returns https://gdk.example.com/' do
          yaml['port'] = '443'

          expect(config.__uri.to_s).to eq('https://gdk.example.com')
        end
      end
    end
  end

  describe 'elasticsearch' do
    let(:checksum) { 'e7c22b994c59d9cf2b48e549b1e24666636045930d3da7c1acb299d1c3b7f931f94aae41edda2c2b207a36e10f8bcb8d45223e54878f5b316e7ce3b6bc019629' }

    describe '#enabled' do
      it 'defaults to false' do
        expect(config.elasticsearch.enabled).to eq(false)
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'elasticsearch' => { 'enabled' => true } }
        end

        it 'returns true' do
          expect(config.elasticsearch.enabled).to eq(true)
        end
      end
    end

    describe '#version' do
      it 'has a default value' do
        expect(config.elasticsearch.version).to match(/\d.\d.\d/)
      end

      context 'when specified in config file' do
        let(:version) { '7.8.0' }
        let(:yaml) do
          { 'elasticsearch' => { 'version' => version } }
        end

        it 'returns the version from the config file' do
          expect(config.elasticsearch.version).to eq(version)
        end
      end
    end

    describe '#mac_checksum' do
      it 'has a default value' do
        expect(config.elasticsearch.mac_checksum).to match(/[a-f0-9]{128}/)
      end

      context 'when specified in config file' do
        let(:yaml) do
          { 'elasticsearch' => { 'mac_checksum' => checksum } }
        end

        it 'returns the version from the config file' do
          expect(config.elasticsearch.mac_checksum).to eq(checksum)
        end
      end
    end

    describe '#linux_checksum' do
      it 'has a default value' do
        expect(config.elasticsearch.linux_checksum).to match(/[a-f0-9]{128}/)
      end

      context 'when specified in config file' do
        let(:yaml) do
          { 'elasticsearch' => { 'linux_checksum' => checksum } }
        end

        it 'returns the version from the config file' do
          expect(config.elasticsearch.linux_checksum).to eq(checksum)
        end
      end
    end
  end

  describe 'workhorse' do
    describe '#__active_host' do
      it 'returns the configured hostname' do
        expect(config.workhorse.__active_host).to eq(config.hostname)
      end
    end

    describe '#__listen_address' do
      it 'is set to ip and port' do
        expect(config.workhorse.__listen_address).to eq('gdk.example.com:3000')
      end
    end
  end

  describe '#__active_port' do
    context 'when nginx is not enabled' do
      it 'returns 3000' do
        expect(config.workhorse.__active_port).to eq(3000)
      end
    end

    context 'when nginx is enabled' do
      let(:nginx_enabled) { true }

      it 'returns 3333' do
        expect(config.workhorse.__active_port).to eq(3333)
      end
    end
  end

  describe '#dump!' do
    before do
      stub_pg_bindir
    end

    it 'successfully dumps the config' do
      expect do
        expect(config.dump!).to be_a_kind_of(Hash)
      end.not_to raise_error
    end

    it 'does not dump options intended for internal use only' do
      expect(config).to respond_to(:__uri)
      expect(config.dump!).not_to include('__uri')
    end

    it 'does not dump options based on question mark convenience methods' do
      expect(config.gdk).to respond_to(:debug?)
      expect(config.gdk.dump!).not_to include('debug?')
    end
  end

  describe '#validate!' do
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('gdk.example.yml').and_return(raw_yaml)
    end

    context 'when gdk.yml is valid' do
      let(:raw_yaml) { "---\ngdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.new.gdk.validate!).to be_nil
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug" }

      it 'raises an exception' do
        expect { described_class.new.gdk.validate! }.to raise_error(/undefined method `fetch' for "debug":String/)
      end
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug: fals" }

      it 'raises an exception' do
        expect { described_class.new.gdk.validate! }.to raise_error(/Value 'fals' for gdk.debug is not a valid bool/)
      end
    end
  end

  describe '#username' do
    before do
      allow(Etc).to receive_message_chain(:getpwuid, :name) { 'iamfoo' }
    end

    it 'returns the short login name of the current process uid' do
      expect(config.username).to eq('iamfoo')
    end
  end

  describe '#praefect' do
    describe '#database' do
      let(:yaml) do
        {
          'praefect' => {
            'node_count' => 3,
            'database' => {
              'host' => 'localhost',
              'port' => 1234
            }
          }
        }
      end

      describe '#host' do
        it { expect(default_config.praefect.database.host).to eq(default_config.postgresql.dir.to_s) }

        context 'for a non-Geo setup' do
          it 'returns configured value' do
            expect(config.praefect.database.host).to eq('localhost')
          end
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'returns configured value' do
            expect(config.praefect.database.host).to eq('/home/git/gdk/postgresql-geo')
          end
        end
      end

      describe '#port' do
        it { expect(default_config.praefect.database.port).to eq(5432) }

        context 'for a non-Geo setup' do
          it 'returns configured value' do
            expect(config.praefect.database.port).to eq(1234)
          end
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'returns configured value' do
            expect(config.praefect.database.port).to eq(5431)
          end
        end
      end

      describe '#__storages' do
        it 'has defaults' do
          expect(default_config.praefect.__nodes.length).to eq(1)
          expect(default_config.praefect.__nodes[0].__storages.length).to eq(1)
          expect(default_config.praefect.__nodes[0].__storages[0].name).to eq('praefect-internal-0')
          expect(default_config.praefect.__nodes[0].__storages[0].path).to eq(Pathname.new('/home/git/gdk/repositories'))
        end

        it 'returns the configured value' do
          expect(config.praefect.__nodes.length).to eq(3)

          expect(config.praefect.__nodes[0].__storages.length).to eq(1)
          expect(config.praefect.__nodes[0].__storages[0].name).to eq('praefect-internal-0')
          expect(config.praefect.__nodes[0].__storages[0].path).to eq(Pathname.new('/home/git/gdk/repositories'))

          expect(config.praefect.__nodes[1].__storages.length).to eq(1)
          expect(config.praefect.__nodes[1].__storages[0].name).to eq('praefect-internal-1')
          expect(config.praefect.__nodes[1].__storages[0].path).to eq(Pathname.new('/home/git/gdk/repository_storages/praefect-gitaly-1/praefect-internal-1'))

          expect(config.praefect.__nodes[2].__storages.length).to eq(1)
          expect(config.praefect.__nodes[2].__storages[0].name).to eq('praefect-internal-2')
          expect(config.praefect.__nodes[2].__storages[0].path).to eq(Pathname.new('/home/git/gdk/repository_storages/praefect-gitaly-2/praefect-internal-2'))
        end
      end
    end
  end

  describe '#postgresql' do
    let(:yaml) do
      {
        'postgresql' => {
          'host' => 'localhost',
          'port' => 1234,
          'geo' => {
            'host' => 'geo',
            'port' => 5678
          }
        }
      }
    end

    describe '#host' do
      it { expect(default_config.postgresql.host).to eq(default_config.postgresql.dir.to_s) }

      it 'returns configured value' do
        expect(config.postgresql.host).to eq('localhost')
      end
    end

    describe '#port' do
      it { expect(default_config.postgresql.port).to eq(5432) }

      it 'returns configured value' do
        expect(config.postgresql.port).to eq(1234)
      end
    end

    describe '#geo' do
      describe '#host' do
        it { expect(default_config.postgresql.host).to eq(default_config.postgresql.dir.to_s) }

        it 'returns configured value' do
          expect(config.postgresql.geo.host).to eq('geo')
        end
      end

      describe '#port' do
        it { expect(default_config.postgresql.geo.port).to eq(5431) }

        it 'returns configured value' do
          expect(config.postgresql.geo.port).to eq(5678)
        end
      end
    end
  end

  describe '#gitaly' do
    let(:praefect_enabled) { false }
    let(:storage_count) { 3 }
    let(:yaml) do
      {
        'gitaly' => {
          'storage_count' => storage_count
        },
        'praefect' => {
          'enabled' => praefect_enabled
        }
      }
    end

    describe '#enabled' do
      context 'when praefect is disabled' do
        let(:storage_count) { 1 }

        it { expect(config.gitaly).to be_enabled }
      end

      context 'when praefect is enabled' do
        let(:praefect_enabled) { true }

        context 'when there is 1 storage' do
          let(:storage_count) { 1 }

          it { expect(config.gitaly).not_to be_enabled }
        end

        context 'when there is more than 1 storage' do
          it { expect(config.gitaly).to be_enabled }
        end
      end
    end

    describe '#__storages' do
      it 'has defaults' do
        expect(default_config.gitaly.__storages.length).to eq(1)
        expect(default_config.gitaly.__storages[0].name).to eq('default')
        expect(default_config.gitaly.__storages[0].path).to eq(Pathname.new('/home/git/gdk/repositories'))
      end

      it 'returns the configured value' do
        expect(config.gitaly.__storages.length).to eq(3)
        expect(config.gitaly.__storages[0].name).to eq('default')
        expect(config.gitaly.__storages[0].path).to eq(Pathname.new('/home/git/gdk/repositories'))
        expect(config.gitaly.__storages[1].name).to eq('gitaly-1')
        expect(config.gitaly.__storages[1].path).to eq(Pathname.new('/home/git/gdk/repository_storages/gitaly/gitaly-1'))
        expect(config.gitaly.__storages[2].name).to eq('gitaly-2')
        expect(config.gitaly.__storages[2].path).to eq(Pathname.new('/home/git/gdk/repository_storages/gitaly/gitaly-2'))
      end
    end

    describe 'auth_token' do
      it 'is not set by default' do
        expect(config.gitaly.auth_token).to be('')
      end
    end
  end

  context 'geo' do
    describe '#enabled' do
      it 'returns false be default' do
        expect(config.geo.enabled?).to be false
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'geo' => { 'enabled' => true } }
        end

        it 'returns true' do
          expect(config.geo.enabled?).to be true
        end
      end
    end

    describe '#secondary?' do
      it 'returns false be default' do
        expect(config.geo.secondary?).to be false
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'geo' => { 'secondary' => true } }
        end

        it 'returns true' do
          expect(config.geo.secondary?).to be true
        end
      end
    end

    describe '#registry_replication' do
      describe '#enabled' do
        it 'returns false be default' do
          expect(config.geo.registry_replication.enabled).to be false
        end

        context 'when enabled in config file' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "enabled" => true } }
            }
          end

          it 'returns true' do
            expect(config.geo.registry_replication.enabled).to be true
          end
        end
      end

      describe '#primary_api_url' do
        it 'returns default URL' do
          expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5000')
        end

        context 'when URL is specified' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "primary_api_url" => 'http://localhost:5001' } }
            }
          end

          it 'returns URL from configuration file' do
            expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5001')
          end
        end
      end
    end
  end

  describe '#config_file_protected?' do
    subject { config.config_file_protected?('foobar') }

    context 'with full wildcard protected_config_files' do
      let(:protected_config_files) { ['*'] }

      it 'returns true' do
        expect(config.config_file_protected?('foobar')).to eq(true)
      end

      context 'but legacy overwrite_changes set to true' do
        let(:overwrite_changes) { true }

        it 'returns false' do
          expect(config.config_file_protected?('foobar')).to eq(false)
        end
      end
    end
  end

  describe 'runner' do
    before do
      allow_any_instance_of(GDK::ConfigSettings).to receive(:read!).with(config.runner.config_file) { file_contents }
    end

    describe '#extra_hosts' do
      it 'returns []' do
        expect(config.runner.extra_hosts).to eq([])
      end
    end

    describe '#bin' do
      it 'returns gitlab-runner' do
        found = find_executable('gitlab-runner')
        path = found || '/usr/local/bin/gitlab-runner'
        expect(config.runner.bin).to eq(Pathname.new(path))
      end
    end

    context 'when config_file exists' do
      let(:file_contents) do
        <<~CONTENTS
          concurrent = 1
          check_interval = 0

          [session_server]
            session_timeout = 1800

          [[runners]]
            name = "MyRunner"
            url = "http://example.com"
            token = "XXXXXXXXXX"
            executor = "docker"
            [runners.custom_build_dir]
            [runners.docker]
              tls_verify = false
              image = "ruby:2.6"
              privileged = false
              disable_entrypoint_overwrite = false
              oom_kill_disable = false
              disable_cache = false
              volumes = ["/cache"]
              shm_size = 0
            [runners.cache]
              [runners.cache.s3]
              [runners.cache.gcs]
        CONTENTS
      end

      it 'returns true' do
        expect(config.runner.enabled).to be true
      end
    end

    context 'when config_file does not exist' do
      let(:file_contents) { nil }

      it 'returns false' do
        expect(config.runner.enabled).to be false
      end
    end
  end

  describe '#listen_address' do
    it 'returns 127.0.0.1 by default' do
      expect(config.listen_address).to eq('127.0.0.1')
    end
  end

  describe 'gitlab' do
    describe '#dir' do
      it 'returns the GitLab directory' do
        expect(config.gitlab.dir).to eq(Pathname.new('/home/git/gdk/gitlab'))
      end
    end

    describe '#cache_classes' do
      it 'returns if Ruby classes should be cached' do
        expect(config.gitlab.cache_classes).to be(false)
      end
    end

    describe 'rails' do
      describe '#__socket_file' do
        it 'returns the GitLab socket path' do
          expect(config.gitlab.rails.__socket_file).to eq(Pathname.new('/home/git/gdk/gitlab.socket'))
        end
      end

      describe '#__socket_file_escaped' do
        it 'returns the GitLab socket path CGI escaped' do
          expect(config.gitlab.rails.__socket_file_escaped.to_s).to eq('%2Fhome%2Fgit%2Fgdk%2Fgitlab.socket')
        end
      end

      describe '#listen_settings' do
        it 'defaults to UNIX socket' do
          expect(config.gitlab.rails.address).to eq('')
          expect(config.gitlab.rails.__bind).to eq('unix:///home/git/gdk/gitlab.socket')
          expect(config.gitlab.rails.__workhorse_url).to eq('/home/git/gdk/gitlab.socket')
          expect(config.gitlab.rails.__listen_settings.__protocol).to eq('unix')
          expect(config.gitlab.rails.__listen_settings.__address).to eq('/home/git/gdk/gitlab.socket')
          expect(config.workhorse.__listen_settings.__type).to eq('authSocket')
          expect(config.workhorse.__listen_settings.__address).to eq('/home/git/gdk/gitlab.socket')
        end
      end

      context 'with TCP address' do
        before do
          yaml['gitlab'] = {
            'rails' => {
              'address' => 'localhost:3443'
            }
          }
        end

        it 'sets listen_settings to HTTP port' do
          expect(config.gitlab.rails.address).to eq('localhost:3443')
          expect(config.gitlab.rails.__bind).to eq('tcp://localhost:3443')
          expect(config.gitlab.rails.__workhorse_url).to eq('http://localhost:3443')
          expect(config.gitlab.rails.__listen_settings.__protocol).to eq('tcp')
          expect(config.gitlab.rails.__listen_settings.__address).to eq('localhost:3443')
          expect(config.workhorse.__listen_settings.__type).to eq('authBackend')
          expect(config.workhorse.__listen_settings.__address).to eq('http://localhost:3443')
        end
      end

      describe 'sherlock' do
        it 'is disabled by default' do
          expect(config.gitlab.rails.sherlock).to be(false)
        end
      end
    end

    describe 'actioncable' do
      describe '#__socket_file' do
        it 'returns the GitLab socket path' do
          expect(config.gitlab.actioncable.__socket_file).to eq(Pathname.new('/home/git/gdk/gitlab.socket'))
        end

        context 'when ActionCable in-app mode is disabled' do
          let(:yaml) do
            {
              'action_cable' => { 'in_app' => false }
            }
          end

          it 'returns the GitLab ActionCable socket path' do
            expect(config.gitlab.actioncable.__socket_file).to eq(Pathname.new('/home/git/gdk/gitlab.actioncable.socket'))
          end
        end
      end
    end
  end

  describe 'k8s_agent' do
    describe 'enabled' do
      it 'is disabled by default' do
        expect(config.gitlab_k8s_agent.enabled).to be(false)
      end
    end

    describe 'auto_update' do
      it 'is enabled by default' do
        expect(config.gitlab_k8s_agent.auto_update).to be(true)
      end
    end
  end

  describe 'nginx' do
    describe '#__listen_address' do
      let(:yaml) do
        {
          'port' => 1234,
          'nginx' => { 'listen' => 'localhost' }
        }
      end

      it 'is set to ip and port' do
        expect(config.nginx.__listen_address).to eq('localhost:1234')
      end
    end

    describe '#__request_buffering_off_routes' do
      it 'has some defailt routes' do
        expected_routes = [
          '/api/v\d/jobs/\d+/artifacts$',
          '\.git/git-receive-pack$',
          '\.git/gitlab-lfs/objects',
          '\.git/info/lfs/objects/batch$'
        ]

        expect(config.nginx.__request_buffering_off_routes).to eq(expected_routes)
      end
    end
  end

  describe 'gitlab_elasticsearch_indexer' do
    describe '#__dir' do
      it 'returns the GitLab directory' do
        expect(config.gitlab_elasticsearch_indexer.__dir).to eq(Pathname.new('/home/git/gdk/gitlab-elasticsearch-indexer'))
      end
    end
  end

  describe 'load_balancing' do
    it 'disabled by default' do
      expect(config.load_balancing.enabled).to be false
    end
  end

  describe 'webpack' do
    describe '#incremental' do
      it 'is false by default' do
        expect(config.webpack.incremental).to be false
      end
    end

    describe '#vendor_dll' do
      it 'is false by default' do
        expect(config.webpack.vendor_dll).to be false
      end
    end

    describe '#static' do
      it 'is false by default' do
        expect(config.webpack.static).to be false
      end
    end

    describe '#sourcemaps' do
      it 'is true by default' do
        expect(config.webpack.sourcemaps).to be true
      end
    end

    describe '#live_reload' do
      context 'when https is disabled' do
        before do
          yaml['https'] = { 'enabled' => false }
        end

        it 'is true' do
          expect(config.webpack.live_reload).to be true
        end
      end

      context 'when https is enabled' do
        before do
          yaml['https'] = { 'enabled' => true }
        end

        it 'is false' do
          expect(config.webpack.live_reload).to be false
        end
      end
    end
  end

  describe 'action_cable' do
    describe '#in_app' do
      it 'is true by default' do
        expect(config.action_cable.in_app).to be true
      end
    end

    describe '#worker_pool_size' do
      it 'returns 4 by deftault' do
        expect(config.action_cable.worker_pool_size).to eq 4
      end
    end
  end

  describe 'registry' do
    describe 'image' do
      context 'when no image is specified' do
        it 'returns the default image' do
          expect(config.registry.image).to eq('registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v2.9.1-gitlab')
        end
      end
    end

    describe '#api_host' do
      it 'returns the default hostname' do
        expect(config.registry.api_host).to eq('gdk.example.com')
      end
    end

    describe '#listen_address' do
      it 'returns 127.0.0.1 by default' do
        expect(config.registry.listen_address).to eq('127.0.0.1')
      end
    end
  end

  describe 'object_store' do
    describe '#host' do
      it 'returns the default hostname' do
        expect(config.object_store.host).to eq('127.0.0.1')
      end
    end

    describe '#connection' do
      context 'default settings' do
        let(:default_connection) do
          {
            'provider' => 'AWS',
            'aws_access_key_id' => 'minio',
            'aws_secret_access_key' => 'gdk-minio',
            'region' => 'gdk',
            'endpoint' => "http://127.0.0.1:9000",
            'path_style' => true
          }
        end

        it 'returns the default Minio connection parameters' do
          expect(config.object_store.connection).to eq(default_connection)
        end
      end

      context 'with external S3 provider' do
        let(:s3_connection) do
          {
            'provider' => 'AWS',
            'aws_access_key_id' => 'test_access_key',
            'aws_secret_access_key' => 'secret'
          }
        end

        before do
          yaml.merge!(
            {
              'object_store' => {
                'enabled' => true,
                'connection' => s3_connection
              }
            }
          )
        end

        it 'configures the S3 provider' do
          expect(config.object_store.enabled?).to be true
          expect(config.object_store.connection).to eq(s3_connection)
        end
      end
    end
  end

  describe 'omniauth' do
    context 'defaults' do
      it 'returns false' do
        expect(config.omniauth.google_oauth2.enabled).to eq('')
        expect(config.omniauth.group_saml.enabled).to be false
        expect(config.omniauth.github.enabled).to be false
      end
    end

    context 'when group SAML is disabled' do
      it 'returns false' do
        expect(config.omniauth.group_saml.enabled).to be false
      end
    end

    context 'when group SAML is enabled' do
      let(:group_saml_enabled) { true }

      it 'returns true' do
        expect(config.omniauth.group_saml.enabled).to be true
      end
    end

    context 'when GitHub is enabled' do
      let(:omniauth_config) { { 'github' => { 'enabled' => true, 'client_id' => '12345', 'client_secret' => 'mysecret' } } }

      it 'returns true' do
        expect(config.omniauth.github.enabled).to be true
        expect(config.omniauth.github.client_id).to eq('12345')
        expect(config.omniauth.github.client_secret).to eq('mysecret')
      end
    end
  end

  describe 'pages' do
    describe '#host' do
      context 'when host is not specified' do
        it 'returns the default hostname' do
          expect(config.gitlab_pages.host).to eq('127.0.0.1.nip.io')
        end
      end

      context 'when host is specified' do
        let(:yaml) do
          {
            'gitlab_pages' => { 'host' => 'pages.localhost' }
          }
        end

        it 'returns the configured hostname' do
          expect(config.gitlab_pages.host).to eq('pages.localhost')
        end
      end
    end

    describe '#port' do
      context 'when port is not specified' do
        it 'returns the default port' do
          expect(config.gitlab_pages.port).to eq(3010)
        end
      end

      context 'when port is specified' do
        let(:yaml) do
          {
            'gitlab_pages' => { 'port' => 5555 }
          }
        end

        it 'returns the configured port' do
          expect(config.gitlab_pages.port).to eq(5555)
        end
      end
    end

    describe '#__uri' do
      it 'returns 127.0.0.1.nip.io:3010' do
        expect(config.gitlab_pages.__uri.to_s).to eq('127.0.0.1.nip.io:3010')
      end
    end
  end

  describe 'prometheus' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.prometheus.enabled).to eq(false)
      end
    end

    describe '#port' do
      it 'defaults to 9090' do
        expect(config.prometheus.port).to eq(9090)
      end
    end

    describe '#gitaly_exporter_port' do
      it 'defaults to 9236' do
        expect(config.prometheus.gitaly_exporter_port).to eq(9236)
      end
    end

    describe '#praefect_exporter_port' do
      it 'defaults to 10101' do
        expect(config.prometheus.praefect_exporter_port).to eq(10101)
      end
    end

    describe '#sidekiq_exporter_port' do
      it 'defaults to' do
        expect(config.prometheus.sidekiq_exporter_port).to eq(3807)
      end
    end
  end

  describe 'grafana' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.grafana.enabled).to eq(false)
        expect(config.grafana.enabled?).to eq(false)
      end
    end

    describe '#port' do
      it 'defaults to 4000' do
        expect(config.grafana.port).to eq(4000)
      end
    end
  end

  describe 'gdk' do
    describe '#runit_wait_secs' do
      it 'is 10 secs by default' do
        expect(config.gdk.runit_wait_secs).to eq(10)
      end
    end

    describe '#start_hooks' do
      describe '#before' do
        it 'is an empty array by default' do
          expect(config.gdk.start_hooks.before).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'start_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.gdk.start_hooks.before).to eq(['uptime'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.gdk.start_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'start_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.gdk.start_hooks.after).to eq(['uptime'])
          end
        end
      end
    end

    describe '#stop_hooks' do
      describe '#before' do
        it 'is an empty array by default' do
          expect(config.gdk.stop_hooks.before).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'stop_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.gdk.stop_hooks.before).to eq(['uptime'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.gdk.stop_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'stop_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.gdk.stop_hooks.after).to eq(['uptime'])
          end
        end
      end
    end

    describe '#update_hooks' do
      describe '#before' do
        it 'has spring stop || true hook by default' do
          expect(config.gdk.update_hooks.before).to eq(['cd gitlab && bin/spring stop || true'])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'update_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'has spring stop || true hook and then our hooks also' do
            expect(config.gdk.update_hooks.before).to eq(['cd gitlab && bin/spring stop || true', 'uptime'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.gdk.update_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'gdk' => { 'update_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.gdk.update_hooks.after).to eq(['uptime'])
          end
        end
      end
    end
  end
end

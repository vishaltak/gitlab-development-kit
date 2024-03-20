# frozen_string_literal: true

require 'fileutils'
require 'gitlab-sdk'
require 'sentry-ruby'
require 'snowplow-tracker'

# rubocop:disable RSpec/ExpectInHook
RSpec.describe GDK::Telemetry do
  describe '.with_telemetry' do
    let(:command) { 'test_command' }
    let(:args) { %w[arg1 arg2] }
    let(:telemetry_enabled) { true }

    let(:client) { double('Client') } # rubocop:todo RSpec/VerifiedDoubles

    before do
      expect(described_class).to receive_messages(telemetry_enabled?: telemetry_enabled)
      expect(described_class).to receive(:with_telemetry).and_call_original

      allow(GDK).to receive_message_chain(:config, :telemetry, :username).and_return('testuser')
      allow(GDK).to receive_message_chain(:config, :telemetry, :platform).and_return('native')
      allow(described_class).to receive_messages(client: client)

      stub_const('ARGV', args)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not track telemetry and directly yields the block' do
        expect { |b| described_class.with_telemetry(command, &b) }.to yield_control
      end
    end

    it 'tracks the finish of the command' do
      expect(client).to receive(:identify).with('testuser')
      expect(client).to receive(:track).with(a_string_starting_with('Finish'), hash_including(:duration, :platform))

      described_class.with_telemetry(command) { true }
    end

    context 'when the block returns false' do
      it 'tracks the failure of the command' do
        expect(client).to receive(:identify).with('testuser')
        expect(client).to receive(:track).with(a_string_starting_with('Failed'), hash_including(:duration, :platform))

        described_class.with_telemetry(command) { false }
      end
    end
  end

  describe '.client' do
    before do
      described_class.instance_variable_set(:@client, nil)

      stub_env('GITLAB_SDK_APP_ID', 'app_id')
      stub_env('GITLAB_SDK_HOST', 'https://collector')

      allow(GitlabSDK::Client).to receive_messages(new: mocked_client)
    end

    after do
      described_class.instance_variable_set(:@client, nil)
    end

    let(:mocked_client) { instance_double(GitlabSDK::Client) }

    it 'initializes the gitlab sdk client with the correct configuration' do
      expect(SnowplowTracker::LOGGER).to receive(:level=).with(Logger::WARN)
      expect(GitlabSDK::Client).to receive(:new).with(app_id: 'app_id', host: 'https://collector').and_return(mocked_client)

      described_class.client
    end

    context 'when client is already initialized' do
      before do
        described_class.instance_variable_set(:@client, mocked_client)
      end

      it 'returns the existing client without reinitializing' do
        expect(GitlabSDK::Client).not_to receive(:new)
        expect(described_class.client).to eq(mocked_client)
      end
    end
  end

  describe '.init_sentry' do
    let(:config) { instance_double(Sentry::Configuration) }

    it 'initializes the sentry client with expected values' do
      allow(Sentry).to receive(:init).and_yield(config)

      expect(config).to receive(:dsn=).with('https://glet_1a56990d202783685f3708b129fde6c0@observe.gitlab.com:443/errortracking/api/v1/projects/48924931')
      expect(config).to receive(:breadcrumbs_logger=).with([:sentry_logger])
      expect(config).to receive(:traces_sample_rate=).with(1.0)
      expect(config).to receive_message_chain(:logger, :level=).with(Logger::WARN)

      described_class.init_sentry
    end
  end

  describe '.telemetry_enabled?' do
    [true, false].each do |value|
      context "when #{value}" do
        it "returns #{value}" do
          expect(GDK).to receive_message_chain(:config, :telemetry, :enabled).and_return(value)

          expect(described_class.telemetry_enabled?).to eq(value)
        end
      end
    end
  end

  describe '.update_settings' do
    before do
      expect(FileUtils).to receive(:touch)
      expect(GDK.config).to receive(:save_yaml!)
    end

    context 'when username is not .' do
      let(:username) { 'testuser' }

      it 'updates the settings with the provided username and enables telemetry' do
        expect(GDK.config).to receive(:bury!).with('telemetry.enabled', true)
        expect(GDK.config).to receive(:bury!).with('telemetry.username', username)

        described_class.update_settings(username)
      end
    end

    context 'when username is .' do
      let(:username) { '.' }

      it 'updates the settings with an empty username and disables telemetry' do
        expect(GDK.config).to receive(:bury!).with('telemetry.enabled', false)
        expect(GDK.config).to receive(:bury!).with('telemetry.username', '')

        described_class.update_settings(username)
      end
    end
  end

  describe '.capture_exception' do
    let(:telemetry_enabled) { true }

    before do
      expect(described_class).to receive_messages(telemetry_enabled?: telemetry_enabled)

      allow(described_class).to receive(:capture_exception).and_call_original
      allow(described_class).to receive(:init_sentry)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not capture the exception' do
        expect(Sentry).not_to receive(:capture_exception)

        described_class.capture_exception('Test error')
      end
    end

    context 'when given an exception' do
      let(:exception) { StandardError.new('Test error') }

      it 'captures the given exception' do
        expect(Sentry).to receive(:capture_exception).with(exception)

        described_class.capture_exception(exception)
      end
    end

    context 'when given a string' do
      let(:message) { 'Test error message' }

      it 'captures a new exception with the given message' do
        expect(Sentry).to receive(:capture_exception) do |exception|
          expect(exception).to be_a(StandardError)
          expect(exception.message).to eq(message)
          expect(exception.backtrace).not_to be_empty
        end

        described_class.capture_exception(message)
      end
    end
  end
end
# rubocop:enable RSpec/ExpectInHook

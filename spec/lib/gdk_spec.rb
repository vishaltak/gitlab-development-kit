# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK do
  let(:up_shortly_msg) { 'GitLab available at http://127.0.0.1:3000 shortly.' }

  before do
    allow(described_class).to receive(:install_root_ok?).and_return(true)

    fake_io = double('IO', read: '/usr/local/bin')
    allow(IO).to receive(:popen).and_call_original
    allow(IO).to receive(:popen).with(%w[support/pg_bindir], chdir: described_class.root).and_yield(fake_io)
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    ARGV.replace(input)
    subject.main
  end

  describe '.main' do
    describe 'psql' do
      it 'uses the development database by default' do
        expect_exec ['psql'],
                    ['psql', '-h', described_class.root.join('postgresql').to_s, '-p', '5432', '-d', 'gitlabhq_development', chdir: described_class.root]
      end

      it 'uses custom arguments if present' do
        expect_exec ['psql', '-w', '-d', 'gitlabhq_test'],
                    ['psql', '-h', described_class.root.join('postgresql').to_s, '-p', '5432', '-w', '-d', 'gitlabhq_test', chdir: described_class.root]
      end
    end
  end

  describe '.validate_yaml!' do
    let(:raw_yaml) { nil }

    before do
      described_class.instance_variable_set(:@config, nil)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('gdk.example.yml').and_return(raw_yaml)
    end

    context 'with valid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.validate_yaml!).to be_nil
      end
    end

    shared_examples 'invalid YAML' do |error_message|
      it 'prints an error' do
        expect(GDK::Output).to receive(:error).with("Your gdk.yml is invalid.\n\n")
        expect(GDK::Output).to receive(:puts).with(error_message, stderr: true)

        expect { described_class.validate_yaml! }.to raise_error(SystemExit)
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug" }

      it_behaves_like 'invalid YAML', %(undefined method `fetch' for "debug":String)
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug: fals" }

      it_behaves_like 'invalid YAML', "Value 'fals' for gdk.debug is not a valid bool"
    end
  end

  shared_examples 'GDK managing all services' do
    it 'prints up shortly message' do
      expect(GDK::Output).to receive(:puts)
      expect(GDK::Output).to receive(:notice).with(up_shortly_msg)

      action
    end
  end

  shared_examples 'GDK managing some services' do
    it 'does not print up shortly message' do
      expect(GDK::Output).not_to receive(:notice).with(up_shortly_msg)

      action
    end
  end

  describe '.start' do
    before do
      allow(Runit).to receive(:sv).with('start', services)
    end

    context 'when starting all services' do
      let(:services) { [] }

      it_behaves_like 'GDK managing all services' do
        let(:action) { described_class.start(services) }
      end
    end

    context 'when starting some services' do
      let(:services) { %w[rails-web] }

      it_behaves_like 'GDK managing some services', %w[rails-web] do
        let(:action) { described_class.start(services) }
      end
    end
  end

  describe '.restart' do
    before do
      allow(Runit).to receive(:sv).with('force-restart', services)
    end

    context 'when starting all services' do
      let(:services) { [] }

      it_behaves_like 'GDK managing all services' do
        let(:action) { described_class.restart(services) }
      end
    end

    context 'when starting some services' do
      let(:services) { %w[rails-web] }

      it_behaves_like 'GDK managing some services', %w[rails-web] do
        let(:action) { described_class.restart(services) }
      end
    end
  end
end

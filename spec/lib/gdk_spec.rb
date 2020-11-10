# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK do
  let(:hooks) { %w[date] }

  before do
    stub_pg_bindir
    allow(described_class).to receive(:install_root_ok?).and_return(true)
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
                    ["/usr/local/bin/psql --host=#{described_class.config.postgresql.host} --port=5432 --dbname=gitlabhq_development ", chdir: described_class.root]
      end

      it 'uses custom arguments if present' do
        expect_exec ['psql', '-w', '-d', 'gitlabhq_test'],
                    ["/usr/local/bin/psql --host=#{described_class.config.postgresql.host} --port=5432 -w -d gitlabhq_test", chdir: described_class.root]
      end
    end

    describe 'psql-geo' do
      it 'uses the development database by default' do
        expect_exec ['psql-geo'],
                    ["/usr/local/bin/psql --host=#{described_class.config.postgresql.geo.host} --port=5431 --dbname=gitlabhq_geo_development ", chdir: described_class.root]
      end

      it 'uses custom arguments if present' do
        expect_exec ['psql-geo', '-w', '-d', 'gitlabhq_geo_test'],
                    ["/usr/local/bin/psql --host=#{described_class.config.postgresql.geo.host} --port=5431 -w -d gitlabhq_geo_test", chdir: described_class.root]
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

        expect { described_class.validate_yaml! }.to raise_error(SystemExit).and output("\n").to_stderr
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

  describe '.start' do
    it 'executes hooks and starts services' do
      services = %w[rails-web]

      allow_any_instance_of(GDK::Config).to receive_message_chain('gdk.start_hooks').and_return(hooks)

      expect(described_class).to receive(:with_hooks).with(hooks, 'gdk start').and_yield
      expect(Runit).to receive(:sv).with('start', services).and_return(true)

      described_class.start(services)
    end
  end

  describe '.stop' do
    before do
      allow_any_instance_of(GDK::Config).to receive_message_chain('gdk.stop_hooks').and_return(hooks)
    end

    context 'all services' do
      it 'executes hooks and stops all services' do
        expect(Runit).to receive(:stop).and_return(true)
        expect(described_class).to receive(:with_hooks).with(hooks, 'gdk stop').and_yield

        described_class.stop([])
      end
    end

    context 'some services' do
      it 'executes hooks and stops some services' do
        services = %w[rails-web]

        expect(Runit).to receive(:sv).with('force-stop', services).and_return(true)
        expect(described_class).to receive(:with_hooks).with(hooks, 'gdk stop').and_yield

        described_class.stop(services)
      end
    end
  end

  describe '.restart' do
    it 'calls stop then start' do
      services = %w[rails-web]

      expect(described_class).to receive(:stop).with(services)
      expect(described_class).to receive(:start).with(services)

      described_class.restart(services)
    end
  end

  describe '.update' do
    it 'executes hooks and performs update' do
      allow_any_instance_of(GDK::Config).to receive_message_chain('gdk.update_hooks').and_return(hooks)

      expect(described_class).to receive(:with_hooks).with(hooks, 'gdk update').and_yield
      expect(described_class).to receive(:make).with('self-update').and_return(true)
      expect(described_class).to receive(:make).with('self-update', 'update').and_return(true)

      described_class.update
    end
  end

  describe '.execute_hooks' do
    it 'calls execute_hook_cmd for each cmd and returns true' do
      cmd = 'echo'
      description = 'example'

      allow(described_class).to receive(:execute_hook_cmd).with(cmd, description).and_return(true)

      expect(described_class.execute_hooks([cmd], description)).to be(true)
    end
  end

  describe '.execute_hook_cmd' do
    let(:cmd) { 'echo' }
    let(:description) { 'example' }

    before do
      stub_tty(false)
    end

    context 'when cmd is not a string' do
      it 'aborts with error message' do
        error_message = %(ERROR: Cannot execute 'example' hook '\\["echo"\\]')

        expect { described_class.execute_hook_cmd([cmd], description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
      end
    end

    context 'when cmd is a string' do
      context 'when cmd does not exist' do
        it 'aborts with error message', :hide_stdout do
          error_message = %(ERROR: No such file or directory - fail)

          expect { described_class.execute_hook_cmd('fail', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
        end
      end

      context 'when cmd fails' do
        it 'aborts with error message', :hide_stdout do
          error_message = %(ERROR: 'false' has exited with code 1.)

          expect { described_class.execute_hook_cmd('false', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
        end
      end

      context 'when cmd succeeds' do
        it 'returns true', :hide_stdout do
          expect(described_class.execute_hook_cmd(cmd, description)).to be(true)
        end
      end
    end
  end

  describe '.with_hooks' do
    it 'returns true' do
      before_hooks = %w[date]
      after_hooks = %w[uptime]
      hooks = { before: before_hooks, after: after_hooks }
      name = 'example'

      expect(described_class).to receive(:execute_hooks).with(before_hooks, "#{name}: before").and_return(true)
      expect(described_class).to receive(:execute_hooks).with(after_hooks, "#{name}: after").and_return(true)

      expect(described_class.with_hooks(hooks, name) { true }).to be(true)
    end
  end
end

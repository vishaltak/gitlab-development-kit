# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK do
  let(:hooks) { %w[date] }

  before do
    stub_pg_bindir
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    ARGV.replace(input)
    subject.main
  end

  def expect_output(level, message: nil)
    expect(GDK::Output).to receive(level).with(message || no_args)
  end

  describe '.main' do
    GDK::Command::COMMANDS.each do |command, command_class_proc|
      context "when invoking 'gdk #{command}' from command-line" do
        it "delegates execution to #{command_class_proc.call}" do
          stub_const('ARGV', [command])

          expect_any_instance_of(command_class_proc.call).to receive(:run).and_return(true)

          expect { described_class.main }.to raise_error(SystemExit)
        end
      end
    end

    context 'with an invalid command' do
      let(:command) { 'rstart' }

      it "shows a helpful error message" do
        stub_const('ARGV', [command])

        expect_output(:warn, message: 'rstart is not a GDK command.')
        expect_output(:warn, message: 'Did you mean?  restart')
        expect_output(:warn, message: '               start')
        expect_output(:puts)
        expect_output(:info, message: "See 'gdk help' for more detail.")

        expect(described_class.main).to be_falsey
      end
    end
  end

  describe '.validate_yaml!' do
    let(:raw_yaml) { nil }

    before do
      described_class.instance_variable_set(:@config, nil)
      stub_raw_gdk_yaml(raw_yaml)
    end

    after do
      described_class.instance_variable_set(:@config, nil)
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

      it_behaves_like 'invalid YAML', "Value 'fals' for setting 'gdk.debug' is not a valid bool."
    end
  end
end

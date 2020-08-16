# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK do
  before do
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
        expect(GDK::Output).to receive(:puts).with(error_message)

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
end

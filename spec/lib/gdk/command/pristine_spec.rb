# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Pristine do
  let(:config) { GDK.config }

  subject { described_class.new }

  describe '#run' do
    before do
      stub_tty(false)
    end

    context 'when a command fails' do
      it 'displays an error and returns false', :hide_stdout do
        error_message = 'something went wrong'
        expect_shellout_command('go clean -cache', config.gdk_root).and_raise(Errno::ENOENT, error_message)

        expect(GDK::Output).to receive(:puts).with("No such file or directory - #{error_message}", stderr: true)
        expect(GDK::Output).to receive(:error).with("Failed to complete running 'gdk pristine'.")

        expect(subject.run).to be(false)
      end
    end

    context 'when all commands succeed' do
      it 'displays an informational message and returns true', :hide_stdout do
        shellout_double = instance_double(Shellout, stream: nil, 'success?': true)

        expect_shellout_command('go clean -cache', config.gdk_root).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_INSTALL_CMD, config.gdk_root).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_PRISTINE_CMD, config.gdk_root).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_INSTALL_CMD, config.gitlab.dir).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_PRISTINE_CMD, config.gitlab.dir).and_return(shellout_double)
        expect_shellout_command('yarn clean', config.gitlab.dir).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_INSTALL_CMD, config.gitaly.ruby_dir).and_return(shellout_double)
        expect_shellout_command(described_class::BUNDLE_PRISTINE_CMD, config.gitaly.ruby_dir).and_return(shellout_double)

        expect(GDK::Output).to receive(:success).with("Successfully ran 'gdk pristine'!")

        expect(subject.run).to be(true)
      end
    end

    def expect_shellout_command(cmd, chdir)
      expect(Shellout).to receive(:new).with(cmd, chdir: chdir)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Bundler do
  let(:gitlab_dir) { Pathname.new('/home/git/gdk/gitlab') }
  let(:gitaly_ruby_dir) { Pathname.new('/home/git/gdk/gitaly/ruby') }

  describe '#success?' do
    context 'when gitaly has a BUNDLE_PATH configured' do
      it 'returns false' do
        expect_bundle_path_not_set(gitlab_dir)
        expect_bundle_path_set(gitaly_ruby_dir)

        expect(subject).not_to be_success
      end
    end

    context "when gitlab and gitaly don't have BUNDLE_PATH configured" do
      it 'returns true' do
        expect_bundle_path_not_set(gitlab_dir)
        expect_bundle_path_not_set(gitaly_ruby_dir)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when gitaly has a BUNDLE_PATH configured' do
      it 'returns a message' do
        expect_bundle_path_not_set(gitlab_dir)
        expect_bundle_path_set(gitaly_ruby_dir)

        expect(subject.detail).to match(/#{gitaly_ruby_dir} appears to have BUNDLE_PATH configured/)
      end
    end

    context "when gitlab and gitaly don't have BUNDLE_PATH configured" do
      it 'returns no message' do
        expect_bundle_path_not_set(gitlab_dir)
        expect_bundle_path_not_set(gitaly_ruby_dir)

        expect(subject.detail).to be_nil
      end
    end
  end

  def expect_bundle_path_not_set(chdir)
    expect_shellout(chdir, stdout: 'You have not configured a value for `PATH`')
  end

  def expect_bundle_path_set(chdir)
    expect_shellout(chdir, stdout: 'Set for your local app (<path>/.bundle/config): "vendor/bundle"')
  end

  def expect_shellout(chdir, success: true, stdout: '', stderr: '')
    # rubocop:todo RSpec/VerifiedDoubles
    shellout = double('Shellout', try_run: nil, read_stdout: stdout, read_stderr: stderr, success?: success)
    # rubocop:enable RSpec/VerifiedDoubles
    expect(Shellout).to receive(:new).with('bundle config get PATH', chdir: chdir).and_return(shellout)
    expect(shellout).to receive(:execute).with(display_output: false).and_return(shellout)
  end
end

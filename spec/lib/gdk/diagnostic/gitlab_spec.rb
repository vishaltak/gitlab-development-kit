# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Gitlab do
  let(:not_ok_log_dir_size) { described_class::GitlabLogDirDiagnostic::LOG_DIR_SIZE_NOT_OK_MB + 1 }
  let(:ok_log_dir_size) { described_class::GitlabLogDirDiagnostic::LOG_DIR_SIZE_NOT_OK_MB - 1 }

  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'for .gitlab_shell_secret' do
      before do
        allow(subject).to receive_message_chain(:gitlab_log_dir_diagnostic, :success?).and_return(true)
      end

      context 'for .gitlab_shell_secret existence' do
        before do
          stub_existence('gitlab', 'gitlab', false)
        end

        context "when both .gitlab_shell_secret files don't not exist" do
          it 'returns false' do
            stub_existence('gitlab_shell', 'gitlab-shell', false)

            expect(subject.success?).to be_falsey
          end
        end

        context 'when only the gitlab-shell .gitlab_shell_secret file exists' do
          it 'returns false' do
            stub_existence('gitlab_shell', 'gitlab-shell', true)

            expect(subject.success?).to be_falsey
          end
        end

        context 'when both .gitlab_shell_secret files exist' do
          it 'returns true' do
            stub_existence('gitlab', 'gitlab', true)
            stub_existence('gitlab_shell', 'gitlab-shell', true)

            expect(subject.success?).to be_truthy
          end
        end
      end

      context 'for .gitlab_shell_secret contents' do
        before do
          stub_content('gitlab', 'gitlab', 'abc')
        end

        context "when both .gitlab_shell_secret files don't match" do
          it 'returns false' do
            stub_content('gitlab_shell', 'gitlab-shell', 'def')

            expect(subject.success?).to be_falsey
          end
        end

        context 'when both .gitlab_shell_secret files match' do
          it 'returns true' do
            stub_content('gitlab_shell', 'gitlab-shell', 'abc')

            expect(subject.success?).to be_truthy
          end
        end
      end
    end

    context 'for gitlab/log/ dir size' do
      let(:gitlab_log_dir_exists) { nil }

      before do
        allow(subject).to receive_message_chain(:gitlab_shell_secret_diagnostic, :success?).and_return(true)
        stub_file(%i[gitlab log_dir], '/home/git/gdk/gitlab/log', exist: gitlab_log_dir_exists)
      end

      context "when /home/git/gdk/gitlab/log doesn't exist" do
        let(:gitlab_log_dir_exists) { false }

        it 'returns true' do
          expect(subject.success?).to be_truthy
        end
      end

      context 'when /home/git/gdk/gitlab/log does exist' do
        let(:gitlab_log_dir_exists) { true }
        let(:log_dir_size) { nil }

        before do
          stub_gitlab_log_dir_size(log_dir_size)
        end

        context 'when the size is not OK' do
          let(:log_dir_size) { not_ok_log_dir_size }

          it 'returns false' do
            expect(subject.success?).to be_falsey
          end
        end

        context 'when the size is OK' do
          let(:log_dir_size) { ok_log_dir_size }

          it 'returns true' do
            expect(subject.success?).to be_truthy
          end
        end
      end
    end
  end

  describe '#detail' do
    context 'for .gitlab_shell_secret' do
      before do
        allow(subject).to receive_message_chain(:gitlab_log_dir_diagnostic, :success?).and_return(true)
      end

      context 'for .gitlab_shell_secret existence' do
        before do
          stub_existence('gitlab', 'gitlab', false)
        end

        context "when both .gitlab_shell_secret files don't exist" do
          it 'returns detail content' do
            stub_existence('gitlab_shell', 'gitlab-shell', false)

            match = %r{  /home/git/gdk/gitlab/.gitlab_shell_secret\n  /home/git/gdk/gitlab-shell/.gitlab_shell_secret}

            expect(subject.detail).to match(match)
          end
        end

        context 'when only the gitlab-shell .gitlab_shell_secret file exists' do
          it 'returns detail content' do
            stub_existence('gitlab_shell', 'gitlab-shell', true)

            match = %r{  /home/git/gdk/gitlab/.gitlab_shell_secret}

            expect(subject.detail).to match(match)
          end
        end

        context 'when both .gitlab_shell_secret files exist' do
          it 'returns nil' do
            stub_existence('gitlab', 'gitlab', true)
            stub_existence('gitlab_shell', 'gitlab-shell', true)

            expect(subject.detail).to be_nil
          end
        end
      end

      context 'for .gitlab_shell_secret contents' do
        before do
          stub_content('gitlab', 'gitlab', 'abc')
        end

        context "when both .gitlab_shell_secret files don't match" do
          it 'returns detail content' do
            stub_content('gitlab_shell', 'gitlab-shell', 'def')

            expect(subject.detail).to match(/The gitlab-shell secret files need to match but they don't/)
          end
        end

        context 'when both .gitlab_shell_secret files match' do
          it 'returns nil' do
            stub_content('gitlab_shell', 'gitlab-shell', 'abc')

            expect(subject.detail).to be_nil
          end
        end
      end
    end

    context 'for gitlab/log/ dir size' do
      let(:log_dir_size) { nil }

      before do
        allow(subject).to receive_message_chain(:gitlab_shell_secret_diagnostic, :success?).and_return(true)
        stub_file(%i[gitlab log_dir], '/home/git/gdk/gitlab/log', exist: true)
        stub_gitlab_log_dir_size(log_dir_size)
      end

      context 'when the size is not OK' do
        let(:log_dir_size) { not_ok_log_dir_size }

        it 'returns detail content' do
          expect(subject.detail).to match(%r{^Your gitlab/log/ directory is #{log_dir_size}MB.*You can truncate the log files if you wish.*rake gitlab:truncate_logs$}m)
        end
      end

      context 'when the size is OK' do
        let(:log_dir_size) { ok_log_dir_size }

        it 'returns nil' do
          expect(subject.detail).to be_nil
        end
      end
    end
  end

  def stub_existence(key, project_dir, exist)
    stub_gitlab_shell_secret_file_with([key, :dir], project_dir, exist: exist)
  end

  def stub_content(key, project_dir, content)
    stub_gitlab_shell_secret_file_with([key, :dir], project_dir, content: content)
  end

  def stub_file(config_key, file, exist: true, content: '')
    double = instance_double(Pathname, exist?: exist, to_s: file, read: content)
    allow_any_instance_of(GDK::Config).to receive_message_chain(*config_key).and_return(double)
    double
  end

  def stub_gitlab_shell_secret_file_with(config_key, project_dir, content: 'abc', exist: true)
    file = '.gitlab_shell_secret'
    double = stub_file(config_key, "/home/git/gdk/#{project_dir}/#{file}", exist: exist, content: content)
    allow(double).to receive(:join).with(file).and_return(double)
  end

  def stub_gitlab_log_dir_size(size)
    double = instance_double(Pathname, exist?: true, size: size * described_class::GitlabLogDirDiagnostic::BYTES_TO_MEGABYTES)
    double_array = [double]
    allow(double).to receive(:glob).with('*').and_return(double_array)
    allow(double_array).to receive(:sum).and_yield(double)
    allow_any_instance_of(GDK::Config).to receive_message_chain(:gitlab, :log_dir).and_return(double)
  end
end

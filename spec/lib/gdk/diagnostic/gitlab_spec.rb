# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Gitlab do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
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

  describe '#detail' do
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
        it 'returns true' do
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

  def stub_existence(key, project_dir, exist)
    stub_file_with(key, project_dir, exist: exist)
  end

  def stub_content(key, project_dir, content)
    stub_file_with(key, project_dir, content: content)
  end

  def stub_file_with(key, project_dir, content: 'abc', exist: true)
    double = instance_double(Pathname, exist?: exist, to_s: "/home/git/gdk/#{project_dir}/.gitlab_shell_secret", read: content)
    allow_any_instance_of(GDK::Config).to receive_message_chain(key, :dir).and_return(double)
    allow(double).to receive(:join).with('.gitlab_shell_secret').and_return(double)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Gitlab do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    before do
      stub_content('gitlab', 'abc')
    end

    context "when both .gitlab_shell_secret files don't match" do
      it 'returns false' do
        stub_content('gitlab_shell', 'def')

        expect(subject.success?).to be_falsey
      end
    end

    context 'when both .gitlab_shell_secret files match' do
      it 'returns true' do
        stub_content('gitlab_shell', 'abc')

        expect(subject.success?).to be_truthy
      end
    end
  end

  describe '#detail' do
    before do
      stub_content('gitlab', 'abc')
    end

    context "when both .gitlab_shell_secret files don't match" do
      it 'returns detail content' do
        stub_content('gitlab_shell', 'def')

        expect(subject.detail).to match(/The gitlab-shell secret files need to match but they don't/)
      end
    end

    context 'when both .gitlab_shell_secret files match' do
      it 'returns nil' do
        stub_content('gitlab_shell', 'abc')

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_content(project_dir, content)
    dir = instance_double(Pathname, to_s: project_dir, read: content)
    allow_any_instance_of(GDK::Config).to receive_message_chain(project_dir, :dir).and_return(dir)
    allow(dir).to receive(:join).with('.gitlab_shell_secret').and_return(dir)
  end
end

# frozen_string_literal: true

RSpec.describe GDK::Dependencies::GitlabVersions do
  describe '#ruby_version' do
    it 'returns version from local file when present', :gdk_root do
      expect(subject.ruby_version).to match(/[2-3]\.[0-9]/)
    end

    it 'returns version from remote file when local is empty' do
      allow(subject).to receive(:local_ruby_version).and_return(false)

      expect(subject.ruby_version).to match(/[2-3]\.[0-9]/)
    end

    it 'raises exception when bugous version content is returned' do
      allow(subject).to receive(:local_ruby_version).and_return('bugous content')

      expect { subject.ruby_version }.to raise_error(GDK::Dependencies::GitlabVersions::VersionNotDetected)
    end
  end
end

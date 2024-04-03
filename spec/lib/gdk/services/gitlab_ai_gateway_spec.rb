# frozen_string_literal: true

describe GDK::Services::GitLabAiGateway do # rubocop:disable RSpec/FilePath
  describe '#name' do
    it 'returns gitlab-ai-gateway' do
      expect(subject.name).to eq('gitlab-ai-gateway')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run gitlab-ai-gateway' do
      expect(subject.command).to eq('support/exec-cd gitlab-ai-gateway poetry run ai_gateway')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end

require 'spec_helper'

describe Git::Repository do
  let(:repo) { described_class.new(config.gdk_root.to_s) }

  describe '#changed_files' do
    let(:target) { "8a6fa231335d31356a663e0a162102281ceb9d4e~" }
    let(:source) { "#{target}~" }

    subject { repo.changed_files(target) }

    it { is_expected.to be_an(Array) }
    it { is_expected.to include("Makefile\n") }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Message do
  let(:header) { 'the header' }
  let(:body) { 'the body' }

  subject { described_class.new(header, body) }

  describe '.from_yaml' do
    it 'creates a new intance of Message' do
      yaml = { 'header' => header, 'body' => body }.to_yaml

      expect(described_class.from_yaml(yaml)).to be_instance_of(described_class)
    end
  end

  describe '#render?' do
    context 'when not already rendered' do
      it 'returns true' do
        expect(subject.render?).to be_truthy
      end
    end

    context 'already rendered' do
      it 'returns false', :hide_stdout do
        allow(subject).to receive(:update_cached_file).and_return(true)
        subject.render

        expect(subject.render?).to be_falsey
      end
    end
  end

  describe '#render' do
    let(:expected_output_regex) { /#{header}\n--------------------------------------------------------------------------------\n#{body}\n/ }

    before do
      allow(subject).to receive(:update_cached_file).and_return(true)
    end

    context 'when not already rendered' do
      it 'displays the message to stdout' do
        expect { subject.render }.to output(expected_output_regex).to_stdout
      end
    end

    context 'when already rendered' do
      it 'displays nothing' do
        expect { subject.render }.to output(expected_output_regex).to_stdout

        expect { subject.render }.to output('').to_stdout
      end
    end
  end
end

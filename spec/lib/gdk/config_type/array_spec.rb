# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigType::Array do
  let(:key) { 'test_key' }
  let(:yaml) { { key => value } }
  let(:builder) { GDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

  subject { described_class.new(parent: GDK.config, builder: builder) }

  before do
    stub_pg_bindir
    stub_gdk_yaml(yaml)
  end

  describe '#parse' do
    context 'when value is initialized with an integer' do
      let(:value) { '123' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(['123'])
      end
    end

    context 'when value is initialized with a string' do
      let(:value) { 'test' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(['test'])
      end
    end

    context 'when value is initialized with a comma-separated list of integers' do
      let(:value) { '123,456,789' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(%w[123 456 789])
      end
    end

    context 'when value is initialized with a comma-separated list of strings' do
      let(:value) { 'foo,bar,baz' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(%w[foo bar baz])
      end
    end
  end
end

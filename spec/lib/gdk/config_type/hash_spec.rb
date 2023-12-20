# frozen_string_literal: true

RSpec.describe GDK::ConfigType::Hash do
  let(:value) { nil }
  let(:key) { 'test_key' }
  let(:yaml) { { key => value } }
  let(:builder) { GDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

  subject { described_class.new(parent: GDK.config, builder: builder) }

  before do
    stub_pg_bindir
    stub_gdk_yaml(yaml)
  end

  describe '#parse' do
    context 'when value is initialized with an string' do
      context 'when string is json parseable' do
        let(:value) { '{"test": "hash"}' }

        it 'returns parsed value' do
          expect(subject.parse(value)).to eq({ 'test' => 'hash' })
        end
      end

      context 'when string is not json parseable' do
        let(:value) { '.' }

        it 'raises parser error' do
          expect { subject.parse(value) }.to raise_error(GDK::StandardErrorWithMessage)
        end
      end
    end

    context 'when value is initialized with an array' do
      let(:value) { [] }

      it 'returns parsed value' do
        expect(subject.parse(value)).to eq({})
      end
    end
  end
end

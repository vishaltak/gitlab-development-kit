# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigType::Port do
  let(:config) { GDK.config }
  let(:parent) { config }
  let(:key) { 'fake-port' }
  let(:yaml) { { key => value } }
  let(:builder) { GDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

  subject { described_class.new(parent: parent, builder: builder, service_name: 'gdk') }

  before do
    stub_pg_bindir
    stub_gdk_yaml(yaml)
  end

  describe '#parse' do
    context 'when value is initialized with an integer' do
      let(:value) { '123' }

      it 'returns parsed value' do
        expect(subject.parse(value)).to eq(123)
      end
    end

    context 'when value is initialized with a string' do
      let(:value) { 'test' }

      it 'raises an exception' do
        expect { subject.parse(value) }.to raise_error(TypeError, "Value 'test' for setting '#{key}' is not a valid port.")
      end
    end

    context 'when value is initialized with a port that is already allocated' do
      let(:value) { 3808 }

      before do
        config.port_manager.claim(3808, 'webpack')
      end

      context "and the allocated port's service does not respond to enabled" do
        it 'raises an exception' do
          allow(parent).to receive(:respond_to?).with(:enabled?).and_return(false)

          expect { subject.parse(value) }.to raise_error(GDK::StandardErrorWithMessage, "Value '#{value}' for setting '#{key}' is not a valid port - Port 3808 is already allocated for service 'webpack'.")
        end
      end

      context "but the allocated port's service is not enabled" do
        it 'does not raise an exception' do
          allow(parent).to receive(:enabled?).and_return(false)

          expect(subject.parse(value)).to eq(value)
        end
      end

      context "and the allocated port's service is enabled" do
        it 'raises an exception' do
          allow(parent).to receive(:enabled?).and_return(true)

          expect { subject.parse(value) }.to raise_error(GDK::StandardErrorWithMessage, "Value '#{value}' for setting '#{key}' is not a valid port - Port 3808 is already allocated for service 'webpack'.")
        end
      end
    end
  end
end

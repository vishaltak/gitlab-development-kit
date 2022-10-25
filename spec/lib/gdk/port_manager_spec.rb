# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::PortManager do
  let(:config) { GDK.config }

  subject { described_class.new(config) }

  describe '#claim' do
    context 'when port and service not already allocated' do
      it 'claims port and returns true' do
        expect(subject.claim(3000, 'gdk')).to be_truthy
      end
    end

    context 'when port and service are already allocated' do
      context 'and the service is the same' do
        it 'claims port and returns true' do
          subject.claim(3000, 'gdk')

          expect(subject.claim(3000, 'gdk')).to be_truthy
        end
      end

      context 'but the services are not the same' do
        it 'raises an exception' do
          subject.claim(3000, 'gdk')

          expect { subject.claim(3000, 'not-gdk') }.to raise_error(described_class::PortAlreadyAllocated, "Port 3000 is already allocated for service 'gdk'")
        end
      end
    end
  end

  describe '#claimed_service_for_port' do
    context 'when the port has not been claimed' do
      it 'returns nil' do
        expect(subject.claimed_service_for_port(3000)).to be_nil
      end
    end

    context 'when the port has already been claimed' do
      it 'returns claimed service name' do
        subject.claim(3000, 'gdk')

        expect(subject.claimed_service_for_port(3000)).to eq('gdk')
      end
    end
  end

  describe '#default_port_for_service' do
    context 'when service is not configured' do
      it 'raise a ServiceUnknownError' do
        expect { subject.default_port_for_service('unknown_service') }.to raise_error(described_class::ServiceUnknownError, /Service 'unknown_service' is unknown, please add to GDK::PortManager::DEFAULT_PORTS_FOR_SERVICE/)
      end
    end

    context 'when service is configured' do
      it 'returns the allocated port' do
        expect(subject.default_port_for_service('gdk')).to eq(3000)
      end
    end
  end
end

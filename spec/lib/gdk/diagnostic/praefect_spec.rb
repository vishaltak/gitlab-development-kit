# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Praefect do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'when the praefect internal socket dir length is >= the max' do
      it 'returns false' do
        stub_max_praefect_internal_socket_dir_length(1)

        expect(subject.success?).to be_falsey
      end
    end

    context 'when the praefect internal socket dir length is < the max' do
      it 'returns true' do
        stub_max_praefect_internal_socket_dir_length(999)

        expect(subject.success?).to be_truthy
      end
    end
  end

  describe '#detail' do
    context 'when the praefect internal socket dir length is >= the max' do
      it 'returns detail content' do
        stub_max_praefect_internal_socket_dir_length(1)

        expect(subject.detail).to match(/please try and reduce the directory depth/)
      end
    end

    context 'when the praefect internal socket dir length is < the max' do
      it 'returns nil' do
        stub_max_praefect_internal_socket_dir_length(999)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_max_praefect_internal_socket_dir_length(value)
    stub_const('GDK::Diagnostic::Praefect::MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH', value)
  end
end

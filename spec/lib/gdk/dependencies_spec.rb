# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Dependencies do
  describe GDK::Dependencies::Checker do
    describe '.parse_version' do
      it 'returns the version in the string' do
        expect(described_class.parse_version('foo 1.2 bar')).to eq('1.2')
        expect(described_class.parse_version('foo 1.2.3.4.5.6 bar')).to eq('1.2.3.4.5.6')
      end

      it 'picks the first version looking number' do
        expect(described_class.parse_version("Yarn v0.1.1 2011 Author Name")).to eq('0.1.1')
        expect(described_class.parse_version('v0.1.1 2011')).to eq('0.1.1')
      end

      it 'uses the given prefix' do
        expect(described_class.parse_version('1.2.3 v4.5.6', prefix: 'v')).to eq('4.5.6')
      end

      it 'ignores suffixes' do
        expect(described_class.parse_version('1.2.3-foo+foo')).to eq('1.2.3')
      end

      it 'requires at least two numeric segments' do
        expect(described_class.parse_version('1')).to be_nil
      end
    end

    describe '#check_git_version' do
      context 'when git is not installed' do
        it 'returns nil' do
          stub_check_binary('git', false)

          expect(subject.check_git_version).to be_nil
        end
      end

      context 'when git is installed' do
        context 'but is not the required version' do
          it 'returns an error message' do
            installed_version = '2.28.0'
            expected_error_messages = ['ERROR: Git version 2.28.0 detected, please install Git version 2.29.0 or higher.']

            stub_check_binary('git', true)
            stub_git_version(installed_version)

            expect(subject.check_git_version).to eql(expected_error_messages)
            expect(subject.error_messages).to eql(expected_error_messages)
          end
        end

        context 'and is the required version' do
          it 'returns nil' do
            installed_version = described_class::EXPECTED_GIT_VERSION

            stub_check_binary('git', true)
            stub_git_version(installed_version)

            expect(subject.check_git_version).to be_nil
            expect(subject.error_messages).to be_empty
          end
        end
      end

      def stub_git_version(version)
        git_version = "git version #{version}"
        shellout_double = instance_double(Shellout, run: git_version)
        allow(Shellout).to receive(:new).with('git --version').and_return(shellout_double)
      end
    end
  end

  def stub_check_binary(binary, result)
    allow(subject).to receive(:check_binary).with(binary).and_return(result)
  end
end

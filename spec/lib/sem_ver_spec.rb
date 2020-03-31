# frozen_string_literal: true

require 'spec_helper'

describe SemVer do
  describe '#major' do
    it 'returns just the major version as an integer' do
      expect(described_class.new('1.2.3').major).to eq(1)
    end
  end

  describe '#minor' do
    context 'where a minor level is provided' do
      it 'returns just the minor version as an integer' do
        expect(described_class.new('1.2.3').minor).to eq(2)
      end
    end

    context 'where a minor (and patch) level is not provided' do
      it 'returns just the minor version as a 0 integer' do
        expect(described_class.new('1').minor).to eq(0)
      end
    end
  end

  describe '#patch' do
    context 'where a patch level is provided' do
      it 'returns just the patch version as an integer' do
        expect(described_class.new('1.2.3').patch).to eq(3)
      end
    end

    context 'where a patch level is not provided' do
      it 'returns just the patch version as a 0 integer' do
        expect(described_class.new('1.2').patch).to eq(0)
      end
    end
  end

  describe '#major_match?' do
    context 'where the version to check is a String' do
      context '1.0.0 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('1.0.0').major_match?('1.0.0')).to be_truthy
        end
      end

      context '1.0.0 vs 2.0.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0').major_match?('2.0.0')).to be_falsy
        end
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '1.0.0 vs 1.0.0' do
        it 'returns true' do
          version_to_check = described_class.new('1.0.0')

          expect(described_class.new('1.0.0').major_match?(version_to_check)).to be_truthy
        end
      end

      context '1.0.0 vs 2.0.0' do
        it 'returns false' do
          version_to_check = described_class.new('2.0.0')

          expect(described_class.new('1.0.0').major_match?(version_to_check)).to be_falsy
        end
      end
    end
  end

  describe '#major_minor_match?' do
    context 'where the version to check is a String' do
      context '1.0.0 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('1.0.0').major_minor_match?('1.0.0')).to be_truthy
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0').major_minor_match?('1.1.0')).to be_falsy
        end
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '1.0.0 vs 1.0.0' do
        it 'returns true' do
          version_to_check = described_class.new('1.0.0')

          expect(described_class.new('1.0.0').major_minor_match?(version_to_check)).to be_truthy
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns false' do
          version_to_check = described_class.new('1.1.0')

          expect(described_class.new('1.0.0').major_minor_match?(version_to_check)).to be_falsy
        end
      end
    end
  end

  describe '#<=>' do
    context 'where the version to check is a String' do
      it 'is supported' do
        expect(described_class.new('1.0.0') <=> '1.0.0').to eq(0)
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '1.0.0 vs 1.0.0' do
        it 'returns 0' do
          expect(described_class.new('1.0.0') <=> described_class.new('1.0.0')).to eq(0)
        end
      end

      context '2.0.0 vs 1.0.0' do
        it 'returns 1' do
          expect(described_class.new('2.0.0') <=> described_class.new('1.0.0')).to eq(1)
        end
      end

      context '1.1.0 vs 1.0.0' do
        it 'returns 1' do
          expect(described_class.new('1.1.0') <=> described_class.new('1.0.0')).to eq(1)
        end
      end

      context '1.0.1 vs 1.0.0' do
        it 'returns 1' do
          expect(described_class.new('1.0.1') <=> described_class.new('1.0.0')).to eq(1)
        end
      end

      context '1.0.0 vs 2.0.0' do
        it 'returns -1' do
          expect(described_class.new('1.0.0') <=> described_class.new('2.0.0')).to eq(-1)
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns -1' do
          expect(described_class.new('1.0.0') <=> described_class.new('1.1.0')).to eq(-1)
        end
      end

      context '1.0.0 vs 1.0.1' do
        it 'returns -1' do
          expect(described_class.new('1.0.0') <=> described_class.new('1.0.1')).to eq(-1)
        end
      end
    end
  end

  describe '#<' do
    context 'where the version to check is a String' do
      it 'is supported' do
        expect(described_class.new('1.0.0') < '2.0.0').to be_truthy
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '2.0.0 vs 1.0.0' do
        it 'returns false' do
          expect(described_class.new('2.0.0') < described_class.new('1.0.0')).to be_falsy
        end
      end

      context '1.1.0 vs 1.0.0' do
        it 'returns false' do
          expect(described_class.new('1.1.0') < described_class.new('1.0.0')).to be_falsy
        end
      end

      context '1.0.1 vs 1.0.0' do
        it 'returns false' do
          expect(described_class.new('1.0.1') < described_class.new('1.0.0')).to be_falsy
        end
      end

      context '1.0.0 vs 2.0.0' do
        it 'returns true' do
          expect(described_class.new('1.0.0') < described_class.new('2.0.0')).to be_truthy
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns true' do
          expect(described_class.new('1.0.0') < described_class.new('1.1.0')).to be_truthy
        end
      end

      context '1.0.0 vs 1.0.1' do
        it 'returns true' do
          expect(described_class.new('1.0.0') < described_class.new('1.0.1')).to be_truthy
        end
      end
    end
  end

  describe '#>' do
    context 'where the version to check is a String' do
      it 'is supported' do
        expect(described_class.new('2.0.0') > '1.0.0').to be_truthy
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '1.0.0 vs 2.0.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0') > described_class.new('2.0.0')).to be_falsy
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0') > described_class.new('1.1.0')).to be_falsy
        end
      end

      context '1.0.0 vs 1.0.1' do
        it 'returns false' do
          expect(described_class.new('1.0.0') > described_class.new('1.0.1')).to be_falsy
        end
      end

      context '2.0.0 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('2.0.0') > described_class.new('1.0.0')).to be_truthy
        end
      end

      context '1.1.0 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('1.1.0') > described_class.new('1.0.0')).to be_truthy
        end
      end

      context '1.0.1 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('1.0.1') > described_class.new('1.0.0')).to be_truthy
        end
      end
    end
  end

  describe '#==' do
    context 'where the version to check is a String' do
      it 'is supported' do
        expect(described_class.new('1.0.0') == '1.0.0').to be_truthy
      end
    end

    context 'where the version to check is an instance of SemVer' do
      context '1.0.0 vs 2.0.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0') == described_class.new('2.0.0')).to be_falsy
        end
      end

      context '1.0.0 vs 1.1.0' do
        it 'returns false' do
          expect(described_class.new('1.0.0') == described_class.new('1.1.0')).to be_falsy
        end
      end

      context '1.0.0 vs 1.0.1' do
        it 'returns false' do
          expect(described_class.new('1.0.0') == described_class.new('1.0.1')).to be_falsy
        end
      end

      context '1.0.0 vs 1.0.0' do
        it 'returns true' do
          expect(described_class.new('1.0.0') == described_class.new('1.0.0')).to be_truthy
        end
      end

      context '1.1.0 vs 1.1.0' do
        it 'returns true' do
          expect(described_class.new('1.1.0') == described_class.new('1.1.0')).to be_truthy
        end
      end

      context '1.0.1 vs 1.0.1' do
        it 'returns true' do
          expect(described_class.new('1.0.1') == described_class.new('1.0.1')).to be_truthy
        end
      end
    end
  end
end

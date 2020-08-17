# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Output do
  describe '.puts' do
    context 'by default' do
      it 'puts to stdout' do
        expect { described_class.puts('test') }.to output("test\n").to_stdout
      end
    end

    context 'with stderr: true' do
      it 'puts to stdout' do
        expect { described_class.puts('test', stderr: true) }.to output("test\n").to_stderr
      end
    end
  end

  describe '.warn' do
    it 'puts to stderr' do
      expect { described_class.warn('test') }.to output("(!) WARNING: test\n").to_stderr
    end
  end

  describe '.error' do
    it 'puts to stderr' do
      expect { described_class.error('test') }.to output("(❌) Error: test\n").to_stderr
    end
  end

  describe '.color' do
    it 'returns a color for index' do
      expect(described_class.color(0)).to eq("31")
    end
  end

  describe '.ansi' do
    it 'returns the ansi color code string' do
      expect(described_class.ansi('31')).to eq("\e[31m")
    end
  end

  describe '.reset_color' do
    it 'returns the ansi reset code string' do
      expect(described_class.reset_color).to eq("\e[0m")
    end
  end
end

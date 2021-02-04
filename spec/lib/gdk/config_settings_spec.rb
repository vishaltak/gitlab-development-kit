# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigSettings do
  subject(:config) { described_class.new }

  describe '.array' do
    it 'accepts an array' do
      described_class.array(:foo) { %w[a b] }

      expect { config.foo }.not_to raise_error
    end

    it 'fails on non-array value' do
      described_class.array(:foo) { %q(a b) }

      expect { config.foo }.to raise_error(TypeError)
    end

    context 'when there is YAML defined' do
      let(:test_klass) do
        new_test_klass do |s|
          s.array(:foo, merge: true) { %w[a] }
        end
      end

      subject(:config) { test_klass.new(yaml: { 'foo' => %w[b] }) }

      it 'is mergeable' do
        expect(config.foo).to eq(%w[a b])
      end
    end
  end

  describe '.hash_setting' do
    it 'accepts a hash' do
      described_class.hash_setting(:foo) { { a: 'A' } }

      expect { config.foo }.not_to raise_error
    end

    it 'fails on non-array value' do
      described_class.hash_setting(:foo) { %q(a b) }

      expect { config.foo }.to raise_error(TypeError)
    end

    context 'when there is YAML defined' do
      let(:test_klass) do
        new_test_klass do |s|
          s.hash_setting(:foo, merge: true) { { a: 'A' } }
        end
      end

      subject(:config) { test_klass.new(yaml: { 'foo' => { 'b' => 'B' } }) }

      it 'is mergeable' do
        expect(config.foo).to eq({ 'a' => 'A', 'b' => 'B' })
      end
    end
  end

  describe '.bool' do
    it 'accepts a bool' do
      described_class.bool(:foo) { 'false' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to eq(false)
    end

    it 'accepts a bool?' do
      described_class.bool(:foo) { 'false' }

      expect { config.foo? }.not_to raise_error
      expect(config.foo?).to eq(false)
    end

    it 'fails on non-bool value' do
      described_class.bool(:foo) { 'hello' }

      expect { config.foo }.to raise_error(TypeError)
    end
  end

  describe '.integer' do
    it 'accepts an integer' do
      described_class.integer(:foo) { '333' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to eq(333)
    end

    it 'fails on non-integer value' do
      described_class.integer(:foo) { '33d' }

      expect { config.foo }.to raise_error(TypeError)
    end
  end

  describe '.path' do
    it 'accepts a valid path' do
      described_class.path(:foo) { '/tmp' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to be_a(Pathname)
      expect(config.foo.to_s).to eq('/tmp')
    end

    it 'fails on non-path' do
      described_class.path(:foo) { nil }

      expect { config.foo }.to raise_error(TypeError)
    end
  end

  describe '.string' do
    it 'accepts a string' do
      described_class.string(:foo) { 'howdy' }

      expect { config.foo }.not_to raise_error
      expect(config.foo).to eq('howdy')
    end

    it 'fails on non-string' do
      described_class.string(:foo) { nil }

      expect { config.foo }.to raise_error(TypeError)
    end
  end

  describe 'dynamic setting' do
    let(:test_klass) do
      new_test_klass do |s|
        s.string(:bar) { 'hello' }
      end
    end

    subject(:config) { test_klass.new }

    it 'can read a setting' do
      expect(config.bar).to eq('hello')
    end

    context 'with foo.yml' do
      before do
        File.write(temp_path.join('foo.yml'), { 'bar' => 'baz' }.to_yaml)
      end

      after do
        File.unlink(temp_path.join('foo.yml'))
      end

      it 'reads settings from yaml' do
        expect(config.bar).to eq('baz')
      end
    end
  end

  describe '.settings_array' do
    it 'creates an array of the desired size' do
      described_class.settings_array(:foo, size: 3) { nil }

      expect(config.foo.count).to eq(3)
    end

    it 'creates an array of the desired size using block' do
      described_class.integer(:baz) { 'four'.length }
      described_class.settings_array(:foo, size: -> { baz }) { nil }

      expect(config.foo.count).to eq(4)
    end

    it 'creates array with self as parent' do
      described_class.settings_array(:foo, size: 1) { nil }

      expect(config.foo.parent).to eq(config)
    end

    it 'creates array of settings with self as grandparent' do
      described_class.settings_array(:foo, size: 1) { nil }

      expect(config.foo.first.parent.parent).to eq(config)
    end

    it 'attributes are available through root config' do
      config = Class.new(GDK::ConfigSettings) do
        settings_array(:arrrr, size: 3) do |i|
          string(:buz) { "sub #{i}" }
        end
      end.new

      expect(config.arrrr.map(&:buz)).to eq(['sub 0', 'sub 1', 'sub 2'])
    end
  end

  describe '#cmd!' do
    it 'executes command with the chdir being GDK.root' do
      expect(config.cmd!(%w[pwd])).to eql(GDK.root.to_s)
    end
  end

  def new_test_klass
    Class.new(described_class) do
      yield(self)
      const_set(:FILE, 'tmp/foo.yml')
    end
  end
end

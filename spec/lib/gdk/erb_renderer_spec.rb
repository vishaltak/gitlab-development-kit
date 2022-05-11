# frozen_string_literal: true

require 'spec_helper'

describe GDK::ErbRenderer do
  let(:protected_config_files) { [] }
  let(:erb_file) { fixture_path.join('example.erb') }
  let(:out_file) { Pathname.new('tmp/example.out') }
  let(:config) { config_klass.new(yaml: { 'gdk' => { 'protected_config_files' => protected_config_files } }) }

  let(:config_klass) do
    Class.new(GDK::ConfigSettings) do
      string(:foo) { 'foo' }
      string(:bar) { 'bar' }

      settings(:gdk) do
        array(:protected_config_files) { [] }
        bool(:overwrite_changes) { false }
      end
    end
  end

  subject(:renderer) { described_class.new(erb_file.to_s, out_file.to_s, config: config) }

  before do
    allow(renderer).to receive(:backup!)

    FileUtils.rm_f(out_file)
  end

  describe '#safe_render!' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(renderer).not_to receive(:warn_changes!)

        renderer.safe_render!

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end

      context 'with a ERB that generates random values' do
        let(:skip_if_exists) { false }
        let(:erb_file) { fixture_path.join('random_example.erb') }

        subject(:renderer) { described_class.new(erb_file.to_s, out_file.to_s, skip_if_exists: skip_if_exists, config: config) }

        it 'generates new content' do
          expect(renderer).to receive(:warn_changes!)
          expect(renderer).to receive(:warn_overwritten!)

          renderer.safe_render!
          text = File.read(out_file)
          renderer.safe_render!

          expect(File.read(out_file)).not_to match(text)
        end

        context 'with skip_if_exists is used' do
          let(:skip_if_exists) { true }

          it 'does not overwrite the file' do
            expect(renderer).not_to receive(:warn_changes!)

            renderer.safe_render!
            text = File.read(out_file)
            renderer.safe_render!

            expect(File.read(out_file)).to match(text)
          end
        end
      end
    end

    context 'output file exists with differences' do
      before do
        File.write(out_file, 'Foo is bar')
      end

      context 'with no protected config file match', :hide_stdout do
        let(:protected_config_files) { [] }

        it 'warns about changes and overwrites content' do
          expect(GDK::Output).to receive(:warn).with(%r{'tmp/example.out' has been overwritten})
          expect(renderer).to receive(:warn_changes!)

          renderer.safe_render!

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['tmp/*.out'] }

        it 'warns about changes and does not overwrite content' do
          expect(GDK::Output).to receive(:warn).with(%r{Changes to 'tmp/example.out' not applied because it's protected in gdk.yml.})

          renderer.safe_render!

          expect(File.read(out_file)).to match('Foo is bar')
        end
      end
    end
  end
end

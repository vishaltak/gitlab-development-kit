# frozen_string_literal: true

RSpec.describe GDK::Templates::ErbRenderer do
  let(:protected_config_files) { [] }
  let(:erb_file) { fixture_path.join('example.erb') }
  let(:out_file) { temp_path.join('some/example.out') }
  let(:config) { config_klass.new(yaml: { 'gdk' => { 'protected_config_files' => protected_config_files } }) }
  let(:locals) do
    { foo: 'foobar', bar: 'barfoo' }
  end

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

  subject(:renderer) { described_class.new(erb_file.to_s, **locals) }

  before do
    allow(GDK).to receive(:config) { config }

    FileUtils.rm_f(out_file)
  end

  describe '#safe_render!' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(renderer).not_to receive(:display_changes!)

        renderer.safe_render!(out_file)

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['some/example.out'] }

        it 'renders with a warning' do
          expect(GDK::Output).to receive(:warn).with(%r{Creating missing protected file 'some/example.out'.})

          renderer.safe_render!(out_file)

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
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
          expect(GDK::Output).to receive(:warn).with(%r{'some/example.out' has been overwritten})
          expect(renderer).to receive(:display_changes!)

          renderer.safe_render!(out_file)

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['some/*.out'] }

        it 'warns about changes and does not overwrite content' do
          expect(GDK::Output).to receive(:warn).with(%r{Changes to 'some/example.out' not applied because it's protected in gdk.yml.})

          renderer.safe_render!(out_file)

          expect(File.read(out_file)).to match('Foo is bar')
        end
      end
    end
  end

  describe 'render_to_string' do
    it 'renders the template with correct assigned config values' do
      expect(renderer.render_to_string).to match('Foo is foo, and Bar is bar')
    end

    it 'renders the template with correct assigned local values' do
      expect(renderer.render_to_string).to match('Local var foo is foobar and bar is barfoo')
    end
  end
end

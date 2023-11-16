# frozen_string_literal: true

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

  subject(:renderer) { described_class.new(erb_file.to_s, out_file.to_s) }

  before do
    allow(GDK).to receive(:config) { config }
    allow(renderer).to receive(:backup!)

    FileUtils.rm_f(out_file)
  end

  describe '#safe_render!' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(renderer).not_to receive(:display_changes!)

        renderer.safe_render!

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['tmp/example.out'] }

        it 'renders with a warning' do
          expect(GDK::Output).to receive(:warn).with(%r{Creating missing protected file 'tmp/example.out'.})

          renderer.safe_render!

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
          expect(GDK::Output).to receive(:warn).with(%r{'tmp/example.out' has been overwritten})
          expect(renderer).to receive(:display_changes!)

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

  describe 'render_to_string' do
    it 'renders the template with correct assigned locals' do
      expect(renderer.render_to_string).to match('Foo is foo, and Bar is bar')
    end
  end
end

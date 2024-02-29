# frozen_string_literal: true

RSpec.describe 'support/templates/gitlab/config/vite.gdk.json.erb' do
  let(:vite_settings) { {} }
  let(:nginx_settings) { {} }
  let(:yaml) do
    {
      'hostname' => 'gdk.test',
      'vite' => vite_settings,
      'nginx' => nginx_settings,
      'webpack' => {
        'enabled' => false
      }
    }
  end

  let(:source) { |example| example.example_group.top_level_description }

  before do
    config = GDK::Config.new(yaml: yaml)
    allow(GDK).to receive(:config).and_return(config)
  end

  subject(:output) do
    renderer = GDK::Templates::ErbRenderer.new(source)
    JSON.parse(renderer.render_to_string)
  end

  context 'with defaults' do
    let(:vite_settings) { {} }

    it do
      expect(output).to eq({
        'enabled' => false,
        'host' => '127.0.0.1',
        'port' => 3038,
        'hmr' => {
          'clientPort' => 3038,
          'host' => 'gdk.test',
          'protocol' => 'ws'
        }
      })
    end
  end

  context 'with hot module reloading disabled' do
    let(:vite_settings) {  { 'enabled' => true, 'port' => 3011, 'hot_module_reloading' => false } }

    it 'sets hmr to nil' do
      expect(output).to eq({
        'enabled' => true,
        'host' => '127.0.0.1',
        'port' => 3011,
        'hmr' => nil
      })
    end
  end

  context 'when vite is enabled' do
    let(:vite_settings) { { 'enabled' => true, 'port' => 3011 } }

    it do
      expect(output).to eq({
        'enabled' => true,
        'host' => '127.0.0.1',
        'port' => 3011,
        'hmr' => {
          'clientPort' => 3011,
          'host' => 'gdk.test',
          'protocol' => 'ws'
        }
      })
    end

    context 'when HTTPS is enabled' do
      before do
        yaml['https'] = { 'enabled' => true }
      end

      it 'sets the protocol to ws' do
        expect(output).to eq({
          'enabled' => true,
          'host' => '127.0.0.1',
          'port' => 3011,
          'hmr' => {
            'clientPort' => 3011,
            'host' => 'gdk.test',
            'protocol' => 'ws'
          }
        })
      end
    end

    context 'and nginx is enabled' do
      let(:nginx_settings) { { 'enabled' => true } }

      it 'sets the nginx port in hash' do
        expect(output).to eq({
          'enabled' => true,
          'host' => '127.0.0.1',
          'port' => 3011,
          'hmr' => {
            'clientPort' => 3000,
            'host' => 'gdk.test',
            'protocol' => 'ws'
          }
        })
      end

      context 'when HTTPS is enabled' do
        before do
          yaml['https'] = { 'enabled' => true }
        end

        it 'sets the protocol to wss' do
          expect(output).to eq({
            'enabled' => true,
            'host' => '127.0.0.1',
            'port' => 3011,
            'hmr' => {
              'clientPort' => 3000,
              'host' => 'gdk.test',
              'protocol' => 'wss'
            }
          })
        end
      end
    end
  end
end

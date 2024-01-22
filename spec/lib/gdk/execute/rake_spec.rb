# frozen_string_literal: true

RSpec.describe GDK::Execute::Rake do
  let(:shellout_mock) { instance_double(Shellout) }

  subject(:rake) { described_class.new('list:of:tasks', 'other:task') }

  describe '#execute_in_gdk' do
    context 'with mocked shellout' do
      before do
        allow(Shellout).to receive(:new).and_return(shellout_mock)
        allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      end

      context 'when asdf is available' do
        it "rake command starts with 'asdf exec'" do
          allow(GDK::Dependencies).to receive(:asdf_available?).and_return(true)

          expect(Shellout).to receive(:new).with(start_with('asdf', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_gdk
        end
      end

      context 'when asdf is not available' do
        it "rake command does not start with 'asdf exec'" do
          allow(GDK::Dependencies).to receive(:asdf_available?).and_return(false)

          expect(Shellout).to receive(:new).with(array_including('bundle', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_gdk
        end
      end

      it 'runs rake command with the defined tasks' do
        expect(Shellout).to receive(:new)
          .with(array_including('bundle', 'exec', 'rake', 'list:of:tasks', 'other:task'), any_args)
          .and_return(shellout_mock)

        rake.execute_in_gdk
      end
    end

    context 'with integration test' do
      subject(:rake) { described_class.new('--version') } # valid command that has no side-effect

      it 'allows passing extra parameters to shellout and runs with success' do
        rake.execute_in_gdk(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end
  end

  describe '#execute_in_gitlab' do
    context 'with mocked shellout' do
      before do
        allow(Shellout).to receive(:new).and_return(shellout_mock)
        allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      end

      context 'when Bundler is loaded' do
        it 'clears out bundler environment' do
          expect(rake).to receive(:bundler_available?).and_return(true)

          expect(Bundler).to receive(:with_unbundled_env).and_yield

          rake.execute_in_gitlab
        end
      end

      context 'when Bundler is not loaded' do
        it 'does not clear out bundler environment' do
          expect(rake).to receive(:bundler_available?).and_return(false)

          expect(Bundler).not_to receive(:with_unbundled_env)

          rake.execute_in_gitlab
        end
      end

      context 'when asdf is available' do
        it "rake command starts with 'asdf exec'" do
          allow(GDK::Dependencies).to receive(:asdf_available?).and_return(true)

          expect(Shellout).to receive(:new).with(start_with('asdf', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_gitlab
        end
      end

      context 'when asdf is not available' do
        it "rake command does not start with 'asdf exec'" do
          allow(GDK::Dependencies).to receive(:asdf_available?).and_return(false)

          expect(Shellout).to receive(:new).with(array_including('bundle', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_gitlab
        end
      end

      it 'runs rake command with the defined tasks' do
        expect(Shellout).to receive(:new)
          .with(array_including('bundle', 'exec', 'rake', 'list:of:tasks', 'other:task'), any_args)
          .and_return(shellout_mock)

        rake.execute_in_gitlab
      end
    end

    context 'with integration test' do
      subject(:rake) { described_class.new('some', 'tasks') } # valid command that has no side-effect

      it 'allows passing extra parameters to shellout and runs with success' do
        allow(rake).to receive(:rake_command).and_return(%w[echo rake some tasks])
        stub_gdk_yaml({
          'gitlab' => {
            'dir' => GDK.root
          }
        })

        rake.execute_in_gitlab(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end
  end

  describe '#success?' do
    subject(:rake) { described_class.new('--version') } # valid command that has no side-effect

    context 'with a successful rake execution' do
      it 'returns true' do
        allow(shellout_mock).to receive(:success?).and_return(true)

        rake.execute_in_gdk(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end

    context 'with a failed rake execution', :hide_output do
      subject(:rake) { described_class.new('--invalid') } # valid command that has no side-effect

      it 'returns false when a previous execution failed' do
        allow(shellout_mock).to receive(:success?).and_return(false)

        rake.execute_in_gdk(display_output: false)

        expect(rake.success?).to be_falsey
      end
    end

    it 'returns false when no execution was done before' do
      expect(rake.success?).to be_falsey
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Cleanup do
  subject { described_class.new }

  before do
    asdf_tool_versions_double = instance_double(Asdf::ToolVersions, unnecessary_software_to_uninstall?: true)
    allow(Asdf::ToolVersions).to receive(:new).and_return(asdf_tool_versions_double)
  end

  describe '#run' do
    context 'when not confirmed' do
      it 'returns true' do
        stub_prompt('n')

        expect_warn_and_puts
        expect(subject).not_to receive(:execute)

        expect(subject.run).to be_truthy
      end
    end

    context 'when confirmed' do
      context 'but an unhandled error occurs' do
        it 'calls execute but returns false' do
          exception = StandardError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts
          expect(GDK::Output).to receive(:error).with(exception)

          rake_uninstall_double = stub_rake_uninstall
          expect(rake_uninstall_double).not_to receive(:invoke).with('false')

          expect(subject.run).to be_falsey
        end
      end

      context 'but a RuntimeError error occurs' do
        it 'calls execute, handles the RuntimeError and returns true' do
          exception = RuntimeError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts
          expect(GDK::Output).to receive(:error).with(exception)

          expect_rake_uninstall

          expect(subject.run).to be_truthy
        end
      end

      context 'and without any errors' do
        context 'via direct response' do
          it 'calls execute' do
            stub_prompt('y')

            expect_warn_and_puts
            expect_rake_truncate_and_uninstall

            expect(subject.run).to be_truthy
          end
        end

        context 'by setting GDK_CLEANUP_CONFIRM to true' do
          it 'calls execute' do
            stub_env('GDK_CLEANUP_CONFIRM', 'true')

            expect_warn_and_puts
            expect_rake_truncate_and_uninstall

            expect(subject.run).to be_truthy
          end
        end
      end
    end

    def stub_prompt(response)
      allow(GDK::Output).to receive(:interactive?).and_return(true)
      allow(GDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(response)
    end

    def expect_warn_and_puts
      expect(GDK::Output).to receive(:warn).with("About to perform the following actions:").ordered
      expect(GDK::Output).to receive(:puts).with(stderr: true).ordered
      expect(GDK::Output).to receive(:puts).with('- Truncate gitlab/log/* files', stderr: true).ordered
      expect(GDK::Output).to receive(:puts).with('- Uninstall any asdf software that is not defined in .tool-versions', stderr: true).ordered
      expect(GDK::Output).to receive(:puts).with(stderr: true).at_least(:once).ordered
    end

    def expect_rake_truncate_and_uninstall
      expect_rake_truncate
      expect_rake_uninstall
    end

    def stub_rake_truncate
      stub_rake_task('gitlab:truncate_logs', 'gitlab.rake')
    end

    def expect_rake_truncate
      expect_rake_task('gitlab:truncate_logs', 'gitlab.rake', args: 'false')
    end

    def stub_rake_uninstall
      stub_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake')
    end

    def expect_rake_uninstall
      expect_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake', args: 'false')
    end

    def stub_rake_task(task_name, rake_file)
      allow(Kernel).to receive(:load).with(GDK.root.join('lib', 'tasks', rake_file)).and_return(true)
      rake_task_double = double("#{task_name} rake task") # rubocop:todo RSpec/VerifiedDoubles
      allow(Rake::Task).to receive(:[]).with(task_name).and_return(rake_task_double)
      rake_task_double
    end

    def expect_rake_task(task_name, rake_file, args: nil)
      rake_task_double = stub_rake_task(task_name, rake_file)
      expect(rake_task_double).to receive(:invoke).with(args).and_return(true)
    end
  end
end

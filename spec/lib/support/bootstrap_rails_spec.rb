# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/support/bootstrap_rails'

RSpec.describe Support::BootstrapRails do
  let(:instance) { described_class.new }

  describe '#execute' do
    let(:geo_secondary) { nil }

    subject { instance.execute }

    before do
      stub_no_color_env('true')
      allow_any_instance_of(GDK::Config).to receive_message_chain('geo.secondary?').and_return(geo_secondary)
    end

    context 'where we are a Geo secondary' do
      let(:geo_secondary) { true }

      it 'advises and exits' do
        expect(GDK::Output).to receive(:info).with("Exiting as we're a Geo secondary.")

        expect { subject }.to raise_error(SystemExit)
      end
    end

    context 'where we are not a Geo secondary' do
      let(:geo_secondary) { false }
      let(:postgres_mock) { instance_double(GDK::Postgresql, ready?: postgres_ready) }
      let(:postgres_ready) { nil }

      before do
        allow(GDK::Postgresql).to receive(:new).and_return(postgres_mock)
      end

      context 'but PostgreSQL is not ready' do
        let(:postgres_ready) { false }

        it 'advises and aborts' do
          expect { subject }
            .to output("ERROR: Cannot connect to PostgreSQL.\n").to_stderr
            .and raise_error(SystemExit)
        end
      end

      context 'and PostgreSQL is ready' do
        let(:postgres_ready) { true }
        let(:gitlabhq_development_db_exists) { nil }
        let(:gitlabhq_development_ci_db_exists) { nil }

        before do
          allow(instance).to receive(:try_connect!)

          allow(postgres_mock).to receive(:db_exists?).with('gitlabhq_development').and_return(gitlabhq_development_db_exists)
          allow(postgres_mock).to receive(:db_exists?).with('gitlabhq_development_ci').and_return(gitlabhq_development_ci_db_exists)
        end

        context 'when gitlabhq_development and gitlabhq_development_ci DBs already exist' do
          let(:gitlabhq_development_db_exists) { true }
          let(:gitlabhq_development_ci_db_exists) { true }

          it 'advises and skips further logic' do
            expect(GDK::Output).to receive(:info).with('gitlabhq_development exists, nothing to do here.')

            expect(GDK::Output).to receive(:info).with('gitlabhq_development_ci exists, nothing to do here.')

            subject
          end
        end

        context 'where neither gitlabhq_development gitlabhq_development_ci DBs exist' do
          let(:gitlabhq_development_db_exists) { false }
          let(:gitlabhq_development_ci_db_exists) { false }

          context 'attempts to setup the gitlabhq_development DB' do
            context 'but `rake `db:reset fails' do
              it 'exits with a status code of 1' do
                stub_shellout(described_class::RAKE_DEV_DB_RESET_CMD, success: false)

                expect { subject }
                  .to output(/The command '#{described_class::RAKE_DEV_DB_RESET_CMD.join(' ')}' failed/).to_stderr
                  .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
              end
            end

            context 'when `rake db:reset` succeeds' do
              context 'but `rake dev:copy_db:ci` fails' do
                it 'exits with a status code of 0' do
                  stub_shellout(described_class::RAKE_DEV_DB_RESET_CMD, success: true)
                  stub_shellout(described_class::RAILS_RUNNER_SKIP_RUGGED_AUTO_DETECT_CMD, success: true)
                  stub_shellout(described_class::RAKE_DEV_DB_SEED_CMD, success: true)
                  stub_shellout(described_class::RAKE_COPY_DB_CI_CMD, success: false)

                  expect { subject }
                    .to output(/The command '#{described_class::RAKE_COPY_DB_CI_CMD.join(' ')}' failed/).to_stderr
                    .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
                end
              end

              context 'and `rake dev:copy_db:ci` succeeds' do
                it 'exits with a status code of 0' do
                  stub_shellout(described_class::RAKE_DEV_DB_RESET_CMD, success: true)
                  stub_shellout(described_class::RAILS_RUNNER_SKIP_RUGGED_AUTO_DETECT_CMD, success: true)
                  stub_shellout(described_class::RAKE_DEV_DB_SEED_CMD, success: true)
                  stub_shellout(described_class::RAKE_COPY_DB_CI_CMD, success: true)

                  expect { subject }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end

  def stub_shellout(cmd, success:)
    shellout_double = instance_double(Shellout, success?: success)
    allow(Shellout).to receive(:new).with(cmd).and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(retry_attempts: 3).and_return(shellout_double)
  end
end

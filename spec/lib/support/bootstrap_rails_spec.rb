# frozen_string_literal: true

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

    context 'embedding db' do
      let(:embedding_enabled) { nil }

      before do
        allow_any_instance_of(GDK::Config).to receive_message_chain('gitlab.rails.databases.embedding.enabled').and_return(embedding_enabled)
        allow_any_instance_of(GDK::Postgresql).to receive(:ready?).and_return(true)
        allow(instance).to receive(:try_connect!)
        allow(instance).to receive_messages(bootstrap_main_db: true, bootstrap_ci_db: true)
      end

      context 'is not enabled' do
        it 'skips bootstrapping' do
          stub_rake_tasks('db:reset:embedding', success: false, retry_attempts: 3)

          expect_any_instance_of(GDK::Postgresql).not_to receive(:db_exists?).with('gitlabhq_development_embedding')
          expect { subject }.not_to raise_error
        end
      end

      context 'is enabled' do
        let(:embedding_enabled) { true }

        it 'tries to run bootstrapping' do
          stub_rake_tasks('db:reset:embedding', success: true, retry_attempts: 3)

          expect_any_instance_of(GDK::Postgresql).to receive(:db_exists?).with('gitlabhq_development_embedding')
          expect { subject }.not_to raise_error
        end
      end
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

        context 'when all DBs already exist' do
          let(:gitlabhq_development_db_exists) { true }
          let(:gitlabhq_development_ci_db_exists) { true }

          it 'advises and skips further logic' do
            expect(GDK::Output).to receive(:info).with('gitlabhq_development exists, nothing to do here.')

            expect(GDK::Output).to receive(:info).with('gitlabhq_development_ci exists, nothing to do here.')

            subject
          end
        end

        context 'where no DBs exist' do
          let(:gitlabhq_development_db_exists) { false }
          let(:gitlabhq_development_ci_db_exists) { false }

          context 'attempts to setup the gitlabhq_development DB' do
            context 'but `rake `db:reset fails' do
              it 'exits with a status code of 1' do
                stub_rake_tasks('db:reset', success: false, retry_attempts: 3)

                expect { subject }
                  .to output(/The rake task 'db:reset' failed/).to_stderr
                  .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
              end
            end

            context 'when `rake db:reset` succeeds' do
              context 'but `rake dev:copy_db:ci` fails' do
                it 'exits with a status code of 1' do
                  stub_rake_tasks('db:reset', success: true, retry_attempts: 3)
                  stub_rake_tasks('db:seed_fu', success: true, retry_attempts: 3)
                  stub_rake_tasks('dev:copy_db:ci', success: false, retry_attempts: 3)

                  expect { subject }
                    .to output(/The rake task 'dev:copy_db:ci' failed/).to_stderr
                    .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
                end
              end

              context 'and `rake dev:copy_db:ci` succeeds' do
                it 'exits with a status code of 0' do
                  stub_rake_tasks('db:reset', success: true, retry_attempts: 3)
                  stub_rake_tasks('db:seed_fu', success: true, retry_attempts: 3)
                  stub_rake_tasks('dev:copy_db:ci', success: true, retry_attempts: 3)

                  expect { subject }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end

  def stub_rake_tasks(*tasks, success:, **args)
    rake_double = instance_double(GDK::Execute::Rake, success?: success)
    allow(GDK::Execute::Rake).to receive(:new).with(*tasks).and_return(rake_double)
    allow(rake_double).to receive(:execute_in_gitlab).with(**args).and_return(rake_double)
  end
end

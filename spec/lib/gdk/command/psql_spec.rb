# frozen_string_literal: true

RSpec.describe GDK::Command::Psql do
  context 'with no extra arguments' do
    it 'uses the development database by default' do
      expect_exec %w[psql],
        ['/usr/local/bin/psql',
          "--host=#{GDK.config.postgresql.host}",
          "--port=#{GDK.config.postgresql.port}",
          '--dbname=gitlabhq_development',
          { chdir: GDK.root }]
    end
  end

  context 'with extra arguments' do
    it 'pass extra arguments to the psql cli application' do
      expect_exec ['psql', '-w', '-d', 'gitlabhq_test', '-c', 'select 1'],
        ['/usr/local/bin/psql',
          "--host=#{GDK.config.postgresql.host}",
          "--port=#{GDK.config.postgresql.port}",
          '--dbname=gitlabhq_development',
          '-w',
          '-d', 'gitlabhq_test',
          '-c', 'select 1',
          { chdir: GDK.root }]
    end
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    input.shift

    subject.run(input)
  end
end

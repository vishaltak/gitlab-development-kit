namespace :db do
  desc 'Rollback to database the master branch'
  task :rollback do
    repo = Git::Repository.new(File.join(config.gdk_root, 'gitlab'))

    migration_script = repo
      .untracked_files
      .append(*repo.changed_files('master'))
      .uniq
      .select { |f| f.start_with?('db/migrate') }
      .map do |migration|
      migration.chomp!

      migration_class = /\Adb.migrate.\d+_(?<klass>.+)\.rb\z/.match(migration)[:klass]
      <<~SCRIPT
        ran_migrations = ActiveRecord::Base.connection.migration_context.migrations_status. do |item|
          status, version, name = item.first == "up"

        end
        require '#{File.join(repo.path, migration)}'
        '#{migration_class}'.camelize.constantize.new.down
      SCRIPT
    end

    out, err, status = Open3.popen3(*%w[bundle exec rails runner -], chdir: repo.path) do |stdin, stdout, stderr, wait_thr|
      stdin.puts migration_script.join
      stdin.close

      [stdout.read, stderr.read, wait_thr.value]
    end

    raise out + err unless status.success?
  end

  desc 'Run the Rails database migrations'
  task :migrate do
    system('bundle', 'exec', 'rails', 'db:migrate', chdir: File.join(config.gdk_root, 'gitlab'))
  end
end

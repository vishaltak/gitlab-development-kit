namespace :db do
  desc 'Rollback to database the master branch'
  task :rollback do
    repo = Git::Repository.new(File.join(config.gdk_root, 'gitlab'))

    repo.untracked_files
        .append(*repo.changed_files('master'))
        .uniq
        .select { |f| f.start_with?('db/migrate') }
        .each do |migration|
      timestamp = /\A(?<timestamp>\d+)/.match(File.basename(migration))[:timestamp]
      system({ 'VERSION' => timestamp }, 'bundle', 'exec', 'rails', 'db:migrate:down', chdir: repo.path)
    end
  end

  desc 'Run the Rails database migrations'
  task :migrate do
    system('bundle', 'exec', 'rails', 'db:migrate', chdir: File.join(config.gdk_root, 'gitlab'))
  end
end

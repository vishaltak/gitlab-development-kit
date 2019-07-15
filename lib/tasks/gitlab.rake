namespace :gitlab do
  desc 'Install GitLab and its Ruby / Javascript dependencies'
  task setup: [:prerequisites, 'gitlab', :config, :install_dependencies, 'gitlab/.gettext']

  desc 'Build GitLab config files'
  task :config do
    system 'make gitlab-config'
  end

  desc 'Compile GitLab I18n'
  task :gettext_compile do
    system 'cd gitlab && bundle exec rake gettext:compile > gettext.log 2>&1'
    system 'git -C gitlab checkout locale/*/gitlab.po'
  end

  #
  # Private tasks (use as dependency only)
  #

  task :prerequisites do
    Helpers::DependenciesFinder.check_ruby_version!('2.6.3')
    Helpers::DependenciesFinder.ensure_bundler_available!('1.17.3')
    Helpers::DependenciesFinder.require_yarn_available!
  end

  multitask install_dependencies: [:bundle_install, 'gitlab/node_modules']

  task :bundle_install do
    next unless GDK::Dependencies.bundler_missing_dependencies?('gitlab')

    system 'bundle install --jobs 4 --without production', chdir: 'gitlab'
  end

  task :yarn_install do
    system 'yarn install --no-progress --pure-lockfile', chdir: 'gitlab'
  end
end

#
# Bootstrap tasks (only run when setting up for the first time)
#

directory 'gitlab' do |t|
  # Load GDK config
  gdk_config = Helpers::Config.instance.config_data

  Helpers::Git.clone_repo(gdk_config[:repositories][:gitlab], t.name)
end

directory 'gitlab/node_modules' do |t|
  Rake::Task['gitlab:yarn_install'].invoke
end

file 'gitlab/.gettext' do |t|
  Rake::Task['gitlab:gettext_compile'].invoke

  `touch #{t.name}`
end

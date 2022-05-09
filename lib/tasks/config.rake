# frozen_string_literal: true

CONFIGS = FileList[
  'Procfile',
  'gdk.example.yml',
  'support/makefiles/Makefile.config.mk',
  'nginx/conf/nginx.conf',
  'gitlab/config/gitlab.yml',
  'prometheus/prometheus.yml',
  'clickhouse/config.xml',
  'clickhouse/users.xml',
  'clickhouse/config.d/data-paths.xml',
  'clickhouse/config.d/gdk.xml',
  'clickhouse/config.d/logger.xml',
  'clickhouse/config.d/openssl.xml',
  'clickhouse/config.d/user-directories.xml',
  'clickhouse/users.d/gdk.xml'
]
CLOBBER.include(*CONFIGS)

desc 'Dump the configured settings'
task 'dump_config' do
  puts GDK.config.dump_as_yaml
end

desc 'Generate an example config file with all the defaults'
file 'gdk.example.yml' => 'clobber:gdk.example.yml' do |t|
  require 'gdk/config_example'

  begin
    yaml = GDK::ConfigExample.new.dump_as_yaml
    File.open(t.name, File::CREAT | File::TRUNC | File::WRONLY).write(yaml)
  rescue TypeError => e
    GDK::Output.abort(e)
  end
end

desc 'Regenerate all config files from scratch'
task reconfigure: [:all]

desc 'Generate all config files'
task all: CONFIGS

task 'clobber:gdk.example.yml' do |t|
  Rake::Cleaner.cleanup_files([t.name])
end

file GDK::Config::FILE do |t|
  FileUtils.touch(t.name)
end

task 'generate-file-at', [:file, :destination] do |_, args|
  file = args[:file]
  destination = args[:destination]
  source = Rake::Task[file].source

  GDK::ErbRenderer.new(source, destination, config: GDK.config).render!
end

# Define as a task instead of a file, so it's built unconditionally
task 'gdk-config.mk' => 'support/templates/makefiles/gdk-config.mk.erb' do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: GDK.config).render!
  puts t.name # Print the filename, so make can include it
end

desc 'Generate gitaly config toml'
file 'gitaly/gitaly.config.toml' => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(
    t.source,
    t.name,
    config: GDK.config,
    node: GDK.config.gitaly
  ).safe_render!

  GDK.config.gitaly.__storages.each do |storage|
    FileUtils.mkdir_p(storage.path)
  end

  FileUtils.mkdir_p(GDK.config.gitaly.log_dir)
  FileUtils.mkdir_p(GDK.config.gitaly.runtime_dir)
end

file 'gitaly/praefect.config.toml' => ['support/templates/gitaly/praefect.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: GDK.config).render!

  GDK.config.praefect.__nodes.each_with_index do |node, _|
    Rake::Task[node['config_file']].invoke
  end
end

GDK.config.praefect.__nodes.each do |node|
  desc "Generate gitaly config for #{node['storage']}"
  file node['config_file'] => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
    GDK::ErbRenderer.new(
      t.source,
      t.name,
      config: GDK.config,
      node: node
    ).safe_render!

    node.__storages.each do |storage|
      FileUtils.mkdir_p(storage.path)
    end

    FileUtils.mkdir_p(node['log_dir'])
    FileUtils.mkdir_p(node['runtime_dir'])
  end
end

Task = Struct.new(:name, :make_dependencies, :template, :erb_extra_args, :post_render, :no_op_condition, :timed, keyword_init: true) do
  def initialize(attributes)
    super
    self[:make_dependencies] = (attributes[:make_dependencies] || []).join(' ')
    self[:template] ||= "support/templates/#{self[:name]}.erb"
    self[:erb_extra_args] ||= {}
    self[:timed] = false if self[:timed].nil?
  end
end

CONFIG_FILE_TASKS = [
  Task.new(name: 'Procfile'),
  Task.new(name: 'gitlab/config/cable.yml'),
  Task.new(name: 'gitlab/config/database.yml'),
  Task.new(name: 'gitlab/config/gitlab.yml'),
  Task.new(name: 'gitlab/config/puma.rb'),
  Task.new(name: 'gitlab/config/redis.cache.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :rate_limiting }),
  Task.new(name: 'gitlab/config/redis.queues.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :queues }),
  Task.new(name: 'gitlab/config/redis.rate_limiting.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :rate_limiting }),
  Task.new(name: 'gitlab/config/redis.sessions.yml', erb_extra_args: { cluster: :sessions }),
  Task.new(name: 'gitlab/config/redis.shared_state.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :shared_state }),
  Task.new(name: 'gitlab/config/redis.trace_chunks.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :trace_chunks }),
  Task.new(name: 'gitlab/config/resque.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :shared_state }),
  Task.new(name: 'gitlab/workhorse/config.toml'),
  Task.new(name: 'gitlab-k8s-agent-config.yml'),
  Task.new(name: 'gitlab-pages/gitlab-pages.conf', make_dependencies: ['gitlab-pages/.git']),
  Task.new(name: 'gitlab-pages-secret'),
  Task.new(name: 'gitlab-runner-config.toml', no_op_condition: 'runner_enabled'),
  Task.new(name: 'gitlab-shell/config.yml', make_dependencies: ['gitlab-shell/.git']),
  Task.new(name: 'gitlab-spamcheck/config/config.toml'),
  Task.new(name: 'grafana/grafana.ini'),
  Task.new(name: 'nginx/conf/nginx.conf'),
  Task.new(name: 'openssh/sshd_config'),
  Task.new(name: 'prometheus/prometheus.yml', post_render: ->(task) { chmod('+r', task.name, verbose: false) }),
  Task.new(name: 'redis/redis.conf'),
  Task.new(name: 'registry/config.yml', make_dependencies: ['registry_host.crt']),
  Task.new(name: 'clickhouse/config.xml', template: 'support/templates/clickhouse/config.xml'),
  Task.new(name: 'clickhouse/users.xml', template: 'support/templates/clickhouse/users.xml'),
  Task.new(name: 'clickhouse/config.d/data-paths.xml'),
  Task.new(name: 'clickhouse/config.d/gdk.xml'),
  Task.new(name: 'clickhouse/config.d/logger.xml'),
  Task.new(name: 'clickhouse/config.d/openssl.xml'),
  Task.new(name: 'clickhouse/config.d/user-directories.xml'),
  Task.new(name: 'clickhouse/users.d/gdk.xml')
].freeze

MAKE_TASKS = [
  Task.new(name: 'gitlab-db-migrate', make_dependencies: ['ensure-databases-running']),
  Task.new(name: 'preflight-checks', timed: true),
  Task.new(name: 'preflight-update-checks', timed: true),
  Task.new(name: 'gitaly/gitaly.config.toml'),
  Task.new(name: 'gitaly/praefect.config.toml')
].freeze

CONFIG_FILE_TASKS.each do |task|
  desc "Generate #{task.name}"
  file task.name => [task.template, GDK::Config::FILE] do |t, args|
    GDK::ErbRenderer.new(t.source, t.name, config: GDK.config, **task.erb_extra_args).safe_render!
    task.post_render&.call(t)
  end
end

desc 'Dynamically generate Make targets for Rake tasks'
file 'support/makefiles/Makefile.config.mk' => Dir['lib/**/*'] do |t, _|
  tasks = CONFIG_FILE_TASKS + MAKE_TASKS

  GDK::ErbRenderer.new(
    'support/templates/makefiles/Makefile.config.mk.erb',
    t.name,
    config: GDK.config,
    tasks: tasks
  ).safe_render!
end

file 'snowplow/snowplow_micro.conf' => ['support/templates/snowplow_micro.conf.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: GDK.config).safe_render!
  chmod('+r', t.name)
end

file 'snowplow/iglu.json' => ['support/templates/iglu.json.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: GDK.config).safe_render!
  chmod('+r', t.name)
end

# frozen_string_literal: true

CONFIGS = FileList['Procfile', 'nginx/conf/nginx.conf', 'gitlab/config/gitlab.yml', 'prometheus/prometheus.yml']
CLOBBER.include(*CONFIGS, 'gdk.example.yml')

def config
  @config ||= GDK::Config.new
end

desc 'Dump the configured settings'
task 'dump_config' do
  puts GDK::Config.new.dump_as_yaml
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
task reconfigure: [:clobber, :all]

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

  GDK::ErbRenderer.new(source, destination, config: config).render!
end

# Define as a task instead of a file, so it's built unconditionally
task 'gdk-config.mk' => 'support/templates/gdk-config.mk.erb' do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).render!
  puts t.name # Print the filename, so make can include it
end

desc 'Generate gitaly config toml'
file 'gitaly/gitaly.config.toml' => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(
    t.source,
    t.name,
    config: config,
    node: config.gitaly
  ).safe_render!
  config.gitaly.__storages.each do |storage|
    FileUtils.mkdir_p(storage.path)
  end
  FileUtils.mkdir_p(config.gitaly.log_dir)
  FileUtils.mkdir_p(config.gitaly.runtime_dir)
end

file 'gitaly/praefect.config.toml' => ['support/templates/gitaly/praefect.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).render!

  config.praefect.__nodes.each_with_index do |node, _|
    Rake::Task[node['config_file']].invoke
  end
end

config.praefect.__nodes.each do |node|
  desc "Generate gitaly config for #{node['storage']}"
  file node['config_file'] => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
    GDK::ErbRenderer.new(
      t.source,
      t.name,
      config: config,
      node: node
    ).safe_render!
    node.__storages.each do |storage|
      FileUtils.mkdir_p(storage.path)
    end
    FileUtils.mkdir_p(node['log_dir'])
    FileUtils.mkdir_p(node['runtime_dir'])
  end
end

Task = Struct.new(:name, :make_dependencies, :template, :skip_if_exists, :erb_extra_args, :post_render, :no_op_condition, :timed, keyword_init: true) do
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
  Task.new(name: 'gitlab-pages-secret', skip_if_exists: true),
  Task.new(name: 'gitlab-runner-config.toml', no_op_condition: 'runner_enabled'),
  Task.new(name: 'gitlab-shell/config.yml', make_dependencies: ['gitlab-shell/.git']),
  Task.new(name: 'gitlab-spamcheck/config/config.toml'),
  Task.new(name: 'grafana/grafana.ini'),
  Task.new(name: 'nginx/conf/nginx.conf'),
  Task.new(name: 'openssh/sshd_config'),
  Task.new(name: 'prometheus/prometheus.yml', post_render: ->(task) { chmod('+r', task.name) }),
  Task.new(name: 'redis/redis.conf'),
  Task.new(name: 'registry/config.yml', make_dependencies: ['registry_host.crt'])
].freeze

MAKE_TASKS = [
  Task.new(name: 'gitlab-db-migrate', make_dependencies: ['ensure-databases-running']),
  Task.new(name: 'preflight-checks', timed: true),
  Task.new(name: 'preflight-update-checks', timed: true),
  Task.new(name: 'gitaly/gitaly.config.toml'),
  Task.new(name: 'gitaly/praefect.config.toml')
].freeze

MAKE_FILE_HEADER = <<~TASK_DEF
# ---------------------------------------------------------------------------------------------
# This file is used by the GDK to get interoperatability between Make and Rake with the end
# goal of getting rid of Make in the future: https://gitlab.com/groups/gitlab-org/-/epics/1556.
# This file can be generated with the `rake support/makefiles/Makefile.config.mk` task.
# ---------------------------------------------------------------------------------------------

TASK_DEF

MAKE_TASK_TEMPLATE = <<~TASK_DEF
.PHONY: %{name}
%{name}: %{make_dependencies}
\t$(Q)rake %{name}

TASK_DEF
MAKE_NO_OP_TASK_TEMPLATE = <<~TASK_DEF
.PHONY: %{name}
%{name}: %{make_dependencies}
ifeq ($(%{no_op_condition}),true)
\t$(Q)rake %{name}
else
\t@true
endif

TASK_DEF
MAKE_TIMED_TASK_TEMPLATE = <<~TASK_DEF
.PHONY: %{name}
%{name}: %{name}-timed

.PHONY: %{name}-run
%{name}-run: rake
\t$(Q)rake %{name}

TASK_DEF

CONFIG_FILE_TASKS.each do |task|
  desc "Generate #{task.name}"
  file task.name => [task.template, GDK::Config::FILE] do |t, args|
    GDK::ErbRenderer.new(t.source, t.name, skip_if_exists: task.skip_if_exists, config: config, **task.erb_extra_args).safe_render!
    task.post_render&.call(t)
  end
end

desc 'Dynamically generate Make targets for Rake tasks'
file 'support/makefiles/Makefile.config.mk' => Dir['lib/**/*'] do |t, args|
  File.open(t.name, mode: 'w+') do |file|
    file.write(MAKE_FILE_HEADER)
    (CONFIG_FILE_TASKS + MAKE_TASKS).each do |task|
      if task.no_op_condition
        file.write(MAKE_NO_OP_TASK_TEMPLATE % task.to_h)
      elsif task.timed
        file.write(MAKE_TIMED_TASK_TEMPLATE % task.to_h)
      else
        file.write(MAKE_TASK_TEMPLATE % task.to_h)
      end
    end
  end
end

file 'snowplow/snowplow_micro.conf' => ['support/templates/snowplow_micro.conf.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
  chmod('+r', t.name)
end

file 'snowplow/iglu.json' => ['support/templates/iglu.json.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name, config: config).safe_render!
  chmod('+r', t.name)
end

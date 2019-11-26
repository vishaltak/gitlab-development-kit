namespace :gitlab do
  namespace :mr do
    desc 'Create the required environment for a GitLab merge request'
    task :checkout, :mr_id do |_t, args|
      mr_id = args[:mr_id].to_i
      raise 'Invalid MR ID' if mr_id < 1

      gdk_root = config.gdk_root
      gitlab_dir = gdk_root.join('gitlab')
      mr_ref = "refs/merge-requests/#{mr_id}/head"

      commands = Runit.services.map do |service|
        GDK::Command::StartService.new(service)
      end

      commands.append(
        GDK::Command::Git.new(%w[add .], repo: gitlab_dir, desc: 'Adding changed file to the Git index'),
        GDK::Command::Git.new(%w[stash], repo: gitlab_dir, desc: 'Stashing the current changes'),
        Rake::Task['db:rollback'],
        GDK::Command::Git.new(%w[checkout HEAD -- db/schema.rb], repo: gitlab_dir, desc: 'Cleaning dirty db/schema.rb'),
        GDK::Command::Git.new(%W[fetch -f origin #{mr_ref}:#{mr_ref}], repo: gitlab_dir, desc: 'Fetching the merge request Git Data'),
        GDK::Command::Git.new(%W[checkout #{mr_ref}], repo: gitlab_dir, desc: 'Checking out the merge requests last commit'),
        GDK::Command::Make.new('unlock-dependency-installers', desc: 'Unlocking dependencies'),
        GDK::Command::Make.new('.gitlab-bundle', desc: 'Installing Ruby dependencies'),
        GDK::Command::RestartService.new('rails-web'),
        GDK::Command::RestartService.new('rails-background-jobs'),
        GDK::Command::Make.new('.gitlab-yarn', desc: 'Installing JavaScript dependencies'),
        GDK::Command::RestartService.new('webpack'),
        GDK::Command::Make.new('gitaly-update', recover_cmd: %w[make gitaly-setup], desc: 'Installing the required Gitaly version'),
        GDK::Command::RestartService.new('gitaly'),
        GDK::Command::Make.new('gitlab-pages-update', recover_cmd: %w[make gitlab-pages-setup], desc: 'Installing the require GitLab Pages version'),
        GDK::Command::RestartService.new('gitlab-pages'),
        GDK::Command::Make.new('gitlab-workhorse-update', recover_cmd: %w[make gitlab-workhorse-update], desc: 'Installing the required GitLab Workhorse server'),
        GDK::Command::RestartService.new('gitlab-workhorse'),
        Rake::Task['db:migrate']
      )

      commands.each(&:invoke)
    end
  end
end

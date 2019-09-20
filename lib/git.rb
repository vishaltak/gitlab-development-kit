module Git
  def self.run(args, repo_path = nil)
    # Passing an array to IO.popen guards against sh -c.
    # https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
    raise 'command must be an array' unless args.is_a?(Array)

    args = args.unshift('-C', repo_path) if repo_path
    args = args.unshift('git')

    IO.popen(args) do |cmd|
      cmd.readlines
    end
  end
end

require_relative 'git/repository'

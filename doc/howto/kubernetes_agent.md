# GitLab Kubernetes Agent

If you wish to clone and keep an updated [GitLab Kubernetes Agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) as part of your GDK, do the following:

1. Install [Bazel](https://www.bazel.build/)

    The recommended way to install Bazel is to use [Bazelisk](https://github.com/bazelbuild/bazelisk). Bazelisk is a version manager for Bazel, much like rbenv for Ruby.

    See the [installation instructions](https://docs.bazel.build/versions/master/install-bazelisk.html) for Bazelisk. If you are on Mac, Homebrew keg for Bazelisk currently [does not link it as `bazel`](https://github.com/Homebrew/homebrew-core/pull/55403) so you may need to create the symlink manually like so:

    ```shell
    ln -s ../Cellar/bazelisk/<version>/bin/bazelisk /usr/local/bin/bazel
    ```

   Run `brew info bazelisk` to get the installed version.

1. Add the following settings in your `gdk.yml`:

    ```yaml
    gitlab_k8s_agent:
      enabled: true
    ```

1. Create a new project. It will be used for agent's configuration. Note the project's ID. Use it as `project_id` below.

1. In the project's repository create a directory named `agents/my-agent`. In this directory create a file `config.yaml` with the following contents:

    ```yaml
    deployments:
      manifest_projects:
    #  - id: "some_project/name"
    ```

   You can find information about supported configuration options in [the agent's documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/configuration_repository.md).

1. There is no [user interface to import a Kubernetes cluster](https://gitlab.com/gitlab-org/gitlab/-/issues/220908) yet, so we need to seed the database manually:

    1. Start the Rails console

        ```shell
        bundle exec rails console
        ```

    1. The internal API that `kgb` (Kubernetes Agent's part that runs alongside GitLab) uses is disabled by default. To enable it run the following in the Rails console:

        ```ruby
        Feature.enable(:kubernetes_agent_internal_api)
        ```

    1. Create the agent record and an authentication token for the agent:

        ```ruby
        project_id = 123 # use ID of the project you created earlier
        agent_name = 'my-agent' # the name for the agent. This will be the directory name for the agent's configuration
        p = Project.find(project_id)
        agent = Clusters::Agent.create!(project: p, name: agent_name)
        token = Clusters::AgentToken.create!(agent: agent)
        puts token.token # this will print the token for the agent
        ```

1. The token from the previous step can be used by the `agentk` to authenticate itself with GitLab (`kgb`).

1. Run `gdk update` to get `kgb` installed as part of GDK.

1. You can start GDK with `gdk start`. It will print the URL for `agentk` to use:

    ```plaintext
    => http://127.0.0.1:3000 should be ready shortly.
    => kgb is available at tcp://127.0.0.1:5005.
    ```

1. You now have two pieces of information to connect `agentk` to GDK - the URL and the token.

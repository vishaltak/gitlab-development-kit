# GitLab Kubernetes Agent

If you wish to clone and keep an updated [GitLab Kubernetes Agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) as part of your GDK, do the following:

1. Install [Bazel](https://www.bazel.build/)

    The recommended way to install Bazel is to use [Bazelisk](https://github.com/bazelbuild/bazelisk). Bazelisk is a version manager for Bazel, much like rbenv for Ruby. See the [installation instructions](https://docs.bazel.build/versions/master/install-bazelisk.html) for Bazelisk.

1. Add the following settings in your `gdk.yml`:

    ```yaml
    gitlab_k8s_agent:
      enabled: true
    ```

1. Create a new project. It will be used for agent's configuration. Note the project's ID. Use it as `project_id` below.

1. In the project's repository create a directory named `.gitlab/agents/my-agent`. In this directory create a file `config.yaml` with the following contents:

    ```yaml
    gitops:
      manifest_projects:
    #  - id: "some_project/name"
    ```

   You can find information about supported configuration options in [the agent's documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/configuration_repository.md).

1. There is no [user interface to import a Kubernetes cluster](https://gitlab.com/gitlab-org/gitlab/-/issues/220908) yet, so we need to seed the database manually:

    1. Start the Rails console

        ```shell
        bundle exec rails console
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

1. The token from the previous step can be used by the `agentk` to authenticate itself with GitLab (`kas`).

1. Run `gdk update` to get `kas` installed as part of GDK.

1. Run `gdk reconfigure` to update various configuration files.

1. You can start GDK with `gdk start`. It will print the URL for `agentk` to use:

    ```plaintext
    => GitLab will be available at http://127.0.0.1:3000 shortly.
    => GitLab Kubernetes Agent Server available at grpc://127.0.0.1:5005.
    ```

1. You now have two pieces of information to connect `agentk` to GDK - the URL and the token.

1. To verify that `kas` is running you can:
    - Run `gdk tail gitlab-k8s-agent` to check the logs. You should see no errors in the logs. Empty logs are normal too.
    - Run `curl 127.0.0.1:5005`. It should print

        ```plaintext
        Warning: Binary output can mess up your terminal. Use "--output -" to tell
        Warning: curl to output it to your terminal anyway, or consider "--output
        Warning: <FILE>" to save to a file.
        ```

        This is normal because gRPC is a binary protocol.

    - If running with NGINX enabled, run `curl gdk.test:3000/-/kubernetes-agent`. It should print

        ```plaintext
        WebSocket protocol violation: Connection header "close" does not contain Upgrade
        ```

        This is a normal response from `kas` for such a request because it's expecting a WebSocket connection upgrade.

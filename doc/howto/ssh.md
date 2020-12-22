# SSH

If you want to work on the GitLab SSH integration then:

1. Add the following to your `<gdk-root>/gdk.yml` file:

   ```yaml
   ---
   sshd:
     enabled: true
   ```

1. Run `gdk reconfigure` or `make openssh-setup` to configure the `sshd` service.

1. Run `gdk start sshd` to start the `sshd` service.

You should now have an unprivileged SSH daemon process running on
`127.0.0.1:2222`, integrated with `gitlab-shell`. If you are not working on
GitLab SSH integration we recommend that you leave `sshd` service disabled.

## Change the listen port or other configuration

Copy lines into your `<gdk-root>/gdk.yml` file from `<gdk-root>/gdk.example.yml`,
and adjust as needed. For example, to change the listen port to `2223`:

1. Add the following to your `<gdk-root>/gdk.yml` file:

   ```yaml
   ---
   sshd:
     enabled: true
     listen_port: 2223
   ```

1. Run `gdk reconfigure` or `make openssh-setup` to configure the `sshd` service.

1. Run `gdk restart sshd` to restart the `sshd` service.

## Try it out

You can check that SSH works by cloning any project (e.g. `Project.first.ssh_url_to_repo`).
This also updates your `known_hosts` file.

## SSH key lookup from database

For more information, see the
[official documentation](https://docs.gitlab.com/ee/administration/operations/speed_up_ssh.html#the-solution).

We'll create a wrapper script to invoke
`<gdk-root>/gitlab-shell/bin/gitlab-shell-authorized-keys-check`. This wrapper is useful
because the file invoked by `AuthorizedKeysCommand`, and all of its parent directories,
*must* be owned by `root`. We'll place the wrapper script in `/opt/gitlab-shell` as an
example, but it can be placed in any directory which is owned by `root` and whose parent
directories are also owned by `root`.

1. Create a file at `/opt/gitlab-shell/wrap-authorized-keys-check` with the following
   contents, making sure to replace `<gdk-root>` with the actual path:

   ```shell
   #!/bin/bash

   <gdk-root>/gitlab-shell/bin/gitlab-shell-authorized-keys-check "$@"
   ```

1. Make the script owned by root:

   ```shell
   sudo chown root /opt/gitlab-shell/wrap-authorized-keys-check
   ```

1. Make the script executable:

   ```shell
   sudo chmod 755 /opt/gitlab-shell/wrap-authorized-keys-check
   ```

1. Make OpenSSH check for authorized keys using `wrap-authorized-keys-check`. Add the
   following configuration in your `<gdk-root>/gdk.yml` file:

   ```yaml
   ---
   sshd:
     enabled: true
     additional_config: |
       Match User <GDK user> # Apply the AuthorizedKeysCommands to the git user only
         AuthorizedKeysCommand /opt/gitlab-shell/wrap-authorized-keys-check <GDK user> %u %k
         AuthorizedKeysCommandUser <GDK user>
       Match all # End match, settings apply to all users again
   ```

   `GDK user` should be the user that is running your GDK. This is probably your local
   username. You can double check this by looking in
   `<gdk-root>/gitlab/config/gitlab.yml` for the value of `development.gitlab.user`
   (or `production.gitlab.user`), or check which username is returned by
   `Project.first.ssh_url_to_repo`.

# SSH

If you want to work on GitLab's SSH integration then uncomment the
'sshd:' line in your `<gdk-root>/Procfile`. Next time you run `gdk start` or `gdk start sshd`
you will get an unprivileged SSH daemon process running on
`localhost:2222`, integrated with `gitlab-shell`.

To change the host/port you need to edit `<gdk-root>/openssh/sshd_config` and
`<gdk-root>/gitlab/config/gitlab.yml`.

If you are aiming to SSH from a local VM, change the `ListenAddress` line to:
`ListenAddress 0.0.0.0:2222` (or write instead your host's private IP address).

If you are not working on GitLab SSH
integration we recommend that you leave the 'sshd:' line in the
Procfile commented out.

## Try it out

You can check that SSH works by cloning any project (e.g. `Project.first.ssh_url_to_repo`).
This will also update your `known_hosts` file.

## SSH key lookup from database

To enable SSH key lookup from the database, check the
[official documentation](https://docs.gitlab.com/ee/administration/operations/speed_up_ssh.html#the-solution).

The executable configured at `AuthorizedKeysCommand`, and all of its
parent directories, should be owned by `root`. For example, you can
place it in the directory as documented: `/opt/gitlab-shell/authorized_keys`

The configuration file of sshd can be found at: `<gdk-root>/openssh/sshd_config`

The `AuthorizedKeysCommandUser` should be set to the user that is running your GDK.
This is probably your local username. You can double check this by looking in `<gdk-root>/gitlab/config/gitlab.yml`
for the value of `development.gitlab.user` (or `production.gitlab.user`),
or check which username is returned by `Project.first.ssh_url_to_repo`.

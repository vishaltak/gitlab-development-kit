# Install, set up, and update GDK

> 🚨**Note:** Before undertaking these steps, be sure you have [prepared your system](prepare.md). 🚨

To get GDK up and running:

1. Install the `gitlab-development-kit` gem:

   ```shell
   gem install gitlab-development-kit
   ```

   This is required the first time you install GDK, and any time you upgrade Ruby.

1. Initialize a new GDK directory. You can initialize either:

   - The default directory (`gitlab-development-kit`), with:

     ```shell
     gdk init
     ```

   - A custom directory. For example, to initialize `gdk`, run:

     ```shell
     gdk init gdk
     ```

1. Install GDK components within the GDK directory:

   1. Change into the newly-created GDK directory.
   1. Install the necessary components (repositories, Ruby gem bundles, and configuration) using
      `gdk install`. Use one of the following methods:

      - For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org) we
        recommend developing against the GitLab project (the default). For:

        - SSH (recommended), run:

          ```shell
          gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
          ```

        - HTTP, run:

          ```shell
          gdk install
          ```

        Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
        The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

      - Other options, in order of recommendation:

        - [Develop in your own GitLab fork](#develop-in-your-own-gitlab-fork)
        - [Develop against the GitLab FOSS project](#develop-against-the-gitlab-foss-project)

## Develop against the GitLab FOSS project

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab FOSS](https://gitlab.com/gitlab-org/gitlab-foss).

After installing the `gitlab-development-kit` gem and initializing a GDK directory, for:

- SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

- HTTP, run:

  ```shell
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone will be done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

## Develop in your own GitLab fork

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab](https://gitlab.com/gitlab-org/gitlab).

After installing the `gitlab-development-kit` gem and initializing a GDK directory, for:

- SSH, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- HTTP, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=https://gitlab.com/<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

The `set-gitlab-upstream` script creates a remote named `upstream` for
[the canonical GitLab repository](https://gitlab.com/gitlab-org/gitlab). It also
modifies `gdk update` (See [Update GitLab](gdk_commands.md#update-gitlab))
to pull down from the upstream repository instead of your fork, making it easier
to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `gdk update` and then
`git push origin` from the `gitlab` directory.

## Set up `gdk.test` hostname

`gdk.test` is the standard for referring to the local GDK instance in documentation steps and GDK
tools. To set up `gdk.test` as a hostname:

1. Make `gdk.test` resolveable. For example, add the following to `/etc/hosts`:

   ```plaintext
   127.0.0.1 gdk.test
   ```

1. Add the following to `gdk.yml`:

   ```yaml
   hostname: gdk.test
   ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

## Common errors during installation and troubleshooting

During `gdk install` process, you may encounter some dependencies related errors. Please refer to
the [Troubleshooting page](troubleshooting.md) or [open an issue on GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues)
if you get stuck.

## GitLab Enterprise Features

Instructions to generate a developer license can be found in the
[onboarding documentation](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).

The license key generator is only available for GitLab team members, who should use the "Sign in with GitLab"
link using their `dev.gitlab.org` account.

## Post-installation

Start GitLab and all required services:

```shell
gdk start
```

To stop the Rails app, which saves memory (useful when running tests):

```shell
gdk stop rails
```

To access GitLab, you may now go to <http://localhost:3000> in your browser.
It may take a few minutes for the Rails app to be ready. During this period you would see `dial unix /Users/.../gitlab.socket: connect: connection refused` in the browser.

The development login credentials are `root` and
`5iveL!fe`.

GDK comes with a number of settings, and most users will use the
default values, but you are able to override these in `gdk.yml` in the
GDK root.

For example, to change the port you can set this in your `gdk.yml`:

```yaml
port: 3001
```

And run the following command to apply:

```shell
gdk reconfigure
```

You can find a bunch of other settings that are configurable in `gdk.example.yml`.

Read the [configuration document](configuration.md) for more details.

After installation [learn how to use GDK](howto/index.md) enable other features.

### Running GitLab and GitLab FOSS concurrently

To have multiple GDK instances running concurrently, for example to
test GitLab and GitLab FOSS, initialize each into a separate GDK
folder. To run them simultaneously, make sure they don't use
conflicting port numbers.

You can for example use the following `gdk.yml` in one of both GDKs.

```yaml
port: 3001
webpack:
  port: 3809
gitlab_pages:
  port: 3011
```

## Update GDK

To update an existing GDK installation, run the following:

```shell
cd <gdk-dir>
gdk update && gdk reconfigure
```

You can run `gdk doctor` to ensure the update left GDK in a good state. If it reports any issues,
you should address them as soon as possible.

### Update external dependencies

As well as keeping GDK up to date, many of the underlying dependencies should also be regularly
updated. For example, to list dependencies that are outdated for macOS with `brew`, run:

```shell
brew update && brew outdated
```

Review the list of outdated dependencies. There may be dependencies you don't wish to upgrade. To
upgrade:

- All outdated dependencies for macOS with `brew`, run:

  ```shell
  brew update && brew upgrade
  ```

- Specific dependencies for macOS with `brew`, run:

  ```shell
  brew update && brew upgrade <package name>

We recommend you update GDK immediately after you update external dependencies.

## Create new GDK

After you have set up GDK initially, it's very easy to create new "fresh installations".
You might do this if you have problems with existing installation that are complicated to fix, and
you just need to get up and running quickly. To create a fresh installation:

1. In the parent folder for GDK, run
   [`gdk init <new directory>`](#initialize-a-new-gdk-directory).
1. In the new directory, run [`gdk install`](#install-gdk-components).

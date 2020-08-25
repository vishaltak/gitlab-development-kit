# Install and set up GDK

Before undertaking these steps, be sure you have [prepared your system](prepare.md).

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

        - Cloning `gitlab` using SSH (recommended), run:

          ```shell
          gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
          ```

        - Cloning `gitlab` using HTTPS, run:

          ```shell
          gdk install
          ```

        Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
        The clone is done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

      - Other options, in order of recommendation:
        - Install using [a GitLab fork](#install-using-your-own-gitlab-fork).
        - Install using [the GitLab FOSS project](#install-using-gitlab-foss-project).

## Install using GitLab FOSS project

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab FOSS](https://gitlab.com/gitlab-org/gitlab-foss).

After installing the `gitlab-development-kit` gem and initializing a GDK directory, for:

- Cloning `gitlab-foss` using SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

- Cloning `gitlab-foss` using HTTPS, run:

  ```shell
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
The clone is done using [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

## Install using your own GitLab fork

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab](https://gitlab.com/gitlab-org/gitlab).

After installing the `gitlab-development-kit` gem and initializing a GDK directory, for:

- Cloning your `gitlab` fork using SSH, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- Cloning your `gitlab` fork using HTTPS, run:

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

## Resolve installation errors

During the `gdk install` process, you may encounter some dependency-related errors. If these errors
occur:

- Run `gdk doctor`, which can detect problems and offer possible solutions.
- Refer to the [troubleshooting page](troubleshooting.md).
- [Open an issue in the GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).

## Use GitLab Enterprise features

Instructions to generate a developer license can be found in the
[onboarding documentation](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).

The license key generator is only available for GitLab team members, who should use the "Sign in
with GitLab" link using their `dev.gitlab.org` account.

For information on adding your license to GitLab, see
[Activate GitLab EE with a license](https://docs.gitlab.com/ee/user/admin_area/license.html)

## Post-installation

After successful installation, see:

- [GDK commands](gdk_commands.md).
- [GDK configuration](configuration.md).

After installation [learn how to use GDK](howto/index.md) enable other features.

## Update GDK

For information on updating GDK, see [Update GDK](gdk_commands.md#update-gdk).

## Create new GDK

After you have set up GDK initially, it's very easy to create new "fresh installations".
You might do this if you have problems with existing installation that are complicated to fix, and
you just need to get up and running quickly. To create a fresh installation:

1. In the parent folder for GDK, run
   [`gdk init <new directory>`](#initialize-a-new-gdk-directory).
1. In the new directory, run [`gdk install`](#install-gdk-components).

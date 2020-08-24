# GDK commands

The `gdk` command has many sub-commands to perform common tasks.

## Start GDK and basic commands

To start up the GDK with all default enabled services, run:

```shell
gdk start
```

To access GitLab, go to <http://localhost:3000> in your browser. It may take a few minutes for the
Rails app to be ready. During this period you can see `If you just started GDK it can take 30-60 seconds before GitLab has finished booting. This page will automatically reload every 5 seconds.`
in the browser.

The development login credentials are `root` and `5iveL!fe`.

To see logs, run:

```shell
gdk tail
```

When you are not using GDK you may want to shut it down to free up memory on your computer:

```shell
gdk stop
```

If you'd like to run a specific group of services, you can do so by providing
the service names as arguments. Multiple arguments are supported.

## Run specific services

GDK can start specific services only. For example, to start just PostgreSQL and Redis, run:

```shell
gdk start postgresql redis
```

## Measure performance

You can easily create a Sitespeed report for local `gdk` URLs or online URLs with our standardized
Sitespeed settings. We support local relative and absolute URLs as arguments. As soon as the report
is generated, it is automatically opened in your browser.

```shell
gdk measure /explore http://127.0.0.1/explore https://gitlab.com/explore
```

The reports are stored in `<gdk-root>/sitespeed-result` as `<branch>_YYYY-MM-DD-HH-MM-SS`. This
requires Docker installed and running.

## Stop specific services

GDK can stop specific services. For example, to stop the Rails app to save memory (useful when
running tests), run:

```shell
gdk stop rails
```

## Update GDK

To update `gitlab` and all of its dependencies, run the following commands:

```shell
cd <gdk-dir>
gdk update
gdk reconfigure
```

This also performs any possible migrations.

You can run `gdk doctor` to ensure the update left GDK in a good state. If it reports any issues,
you should address them as soon as possible.

If there are changes in the local repositories, or a different branch than `master` is checked out,
the `gdk update` command:

- Stashes any uncommitted changes.
- Changes to `master` branch.

It then updates the remote repositories.

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
  ```

We recommend you update GDK immediately after you update external dependencies.

### Update GDK configuration files

Sometimes there are changes in `gitlab-development-kit` that require you to regenerate configuration
files. You can always remove an individual file (for example, `rm Procfile`) and rebuild
the necessary configuration files created by GDK, by running:

```shell
gdk reconfigure
```

## View configuration settings

With `gdk config` you can view GDK configuration settings:

```shell
gdk config get <configuration value>
```

More information can be found in the [configuration documentation](configuration.md).

## Enable shell completion

To enable tab completion for the `gdk` command in Bash, add the following to your `~/.bash_profile`:

```shell
source ~/path/to/your/gdk/support/completions/gdk.bash
```

For Zsh, you can enable Bash completion support in your `~/.zshrc`:

```shell
autoload bashcompinit
bashcompinit

source ~/path/to/your/gdk/support/completions/gdk.bash
```

## Preview GitLab changes

GDK is a common way to do GitLab development. It provides all the necessary structure to run GitLab
locally with code changes to preview the result. This provides:

- A fast feedback loop, because you don't need to wait for a GitLab Review App to be deployed to
  preview changes.
- Lower costs, because you can run GitLab and tests locally, without incurring the
  costs associated with running pipelines in the cloud.

These instructions explain how to preview user-facing changes, not how to do GitLab
development.

### Prepare GDK for previewing

To prepare GDK for previewing GDK changes:

1. Go to your GDK directory:

   ```shell
   cd <gdk-dir>
   ```

1. [Update](#update-gdk) and [start](#start-gdk-and-basic-commands) GDK. This ensures your
   GDK environment is close to the environment the changes:
   - Were made in, if you are previewing someone else's changes.
   - Are to be made in, if you are making your own changes.
1. Go to your local GitLab in your web browser and sign in (by default, [`http://localhost:3000`](http://localhost:3000)).
   Verify that GitLab runs properly.
1. Verify the current behavior of the feature affected by the changes. For Enterprise Edition
   features, you may need to [perform additional tasks](index.md#use-gitlab-enterprise-features).

### Make changes to GitLab

The process for applying changes to GitLab depends on whether you are:

- Making the changes yourself.
- Previewing someone else's changes.

To make your own changes:

1. Go to your `gitlab` directory, throw away any changes GDK made when updating that left your
   checkout unclean, and switch to a new `gitlab` project branch:

   ```shell
   cd <gdk-dir>/gitlab
   git checkout -- .
   git checkout -b <your branch name>
   ```

1. Make the necessary changes within the `gitlab` directory.

To apply changes someone else made:

1. Switch to the branch containing the changes. The easiest way to do this is to:
   1. Go to the MR with the submitted changes.
   1. From the **Overview** tab, click the [**Check out branch** button](https://docs.gitlab.com/ee/user/project/merge_requests/index.html#merge-request-navigation-tabs-at-the-top).
      This displays a procedure.
   1. Copy the commands from **Step 1.** of the procedure. This adds to the clipboard all the
      commands required to switch to the branch locally.
   1. Go to your local `gitlab` directory and check you're on a clean checkout of `master`:

      ```shell
      cd <gdk-dir>/gitlab
      git status
      ```

      You can discard any modifications caused by `gdk update` by running `git checkout -- .`.

   1. Paste the contents of the clipboard into your command line window and run them (for example, press enter). Your `gitlab` project
      branch should now be the branch containing the changes you want to preview. Confirm by
      running:

      ```shell
      git status
      git log
      ```

### Preview changes

After the changes are applied to GitLab:

1. Go to GitLab in your web browser to preview your changes (by default, [`http://localhost:3000`](http://localhost:3000)).
   It might be necessary to refresh the page, or even restart GDK:

   ```shell
   gdk restart
   ```

1. If previewing your changes, when you are satisfied with your changes and want to submit them for
   review, follow the process for submitting a merge request for a `gitlab` branch from the command
   line.
1. Once the work is completed, we recommend [updating GDK](#update-gdk) again. This means that the
   next time you want to run it, GDK is based on `master` and not on the changed branch.

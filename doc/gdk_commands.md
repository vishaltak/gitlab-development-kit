# GDK commands

The `gdk` command has many sub-commands to perform common tasks.

## Start GDK and basic commands

To start up the GDK with all default enabled services, run:

```shell
gdk start
```

To access GitLab, go to <http://localhost:3000> in your browser. It may take a few minutes for the
Rails app to be ready. During this period you can see `If you just started GDK it can take 60-300 seconds before GitLab has finished booting. This page will automatically reload every 5 seconds.`
in the browser.

### Get the login credentials

The development login credentials are `root` and `5iveL!fe`.

You can also get the credentials by running:

```shell
gdk help
```

## View logs

To see logs, run:

```shell
gdk tail
```

## Stop GDK

When you are not using GDK you may want to shut it down to free up memory on your computer:

```shell
gdk stop
```

## Run specific services

You can start specific services only by providing the service names as arguments.
Multiple arguments are supported. For example, to start just PostgreSQL and Redis, run:

```shell
gdk start postgresql redis
```

## Stop specific services

GDK can stop specific services. For example, to stop the Rails app to save memory (useful when
running tests), run:

```shell
gdk stop rails
```

## Kill all services

Services can fail to properly stop when running `gdk stop` and must be forcibly
terminated. To terminate unstoppable services, run:

```shell
gdk kill
```

This command is a manual command because it kills all `runsv` processes,
which can include processes outside the current GDK. Don't use this command if you're running
other processes with `runit`, or if you're running multiple instances of GDK (and you don't want to stop them all).

## Update GDK

To update `gitlab` and all of its dependencies, run the following commands:

```shell
gdk update
```

This also performs any possible database migrations.

If there are changes in the local repositories, or a different branch than `main` is checked out,
the `gdk update` command:

- Stashes any uncommitted changes.
- Changes to `main` branch.

It then updates the remote repositories.

## Update your `gdk.yml`

When updating your `gdk.yml`, you must regenerate the necessary configuration files by
running:

```shell
gdk reconfigure
```

## View configuration settings

With `gdk config get` you can view GDK configuration settings:

```shell
gdk config get <configuration value>
```

## Set configuration settings

With `gdk config set` you can set GDK configuration settings:

```shell
gdk config set <name> <value>
```

More information can be found in the [configuration documentation](configuration.md).

## Check GDK health

You can run `gdk doctor` to ensure the update left GDK in a good state. If it reports any issues,
you should address them as soon as possible.

```shell
gdk doctor
```

## Reset data

There may come a time where you wish to reset the data within your GDK. Backups
of any reset data are taken prior and you are prompted to confirm you
wish to proceed:

```shell
gdk reset-data
```

## GDK pristine

If you want to return your GDK instance to a pristine state, which installs
Ruby gems and Node modules from scratch for GitLab, Gitaly, cleaning temporary
directories, and cleaning the global Golang cache:

```shell
gdk pristine
```

## Cleanup

Over time, your GDK may contain large log files in addition to asdf-installed
software that's no longer required. To cleanup your GDK, run:

```shell
gdk cleanup
```

The `gdk cleanup` command is destructive and requires you to confirm
if you want to proceed. If you prefer to run without confirming
(for example, if you want to run as a [GDK hook](configuration.md#hooks)),
run:

```shell
GDK_CLEANUP_CONFIRM=true gdk cleanup
```

## Measure performance

You can easily create a Sitespeed report for local `gdk` URLs or online URLs with our standardized
Sitespeed settings. We support local relative and absolute URLs as arguments. As soon as the report
is generated, it is automatically opened in your browser.

```shell
gdk measure /explore http://127.0.0.1/explore https://gitlab.com/explore
```

## Measure Workflows performance

```shell
gdk measure-workflow repo_browser
```

All workflow scripts are located in `support/measure_scripts/`, for example `repo_browser` to measure the
basic workflow in the repository.

The reports are stored in `<gdk-root>/sitespeed-result` as `<branch>_YYYY-MM-DD-HH-MM-SS`. This
requires Docker installed and running.

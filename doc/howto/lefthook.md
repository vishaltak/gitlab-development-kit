# Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) is a Git hooks manager that allows
custom logic to be executed prior to Git committing or pushing. GDK comes with
Lefthook configuration (`lefthook.yml`), but it must be installed.

## Lefthook for the GDK

We have a `lefthook.yml` checked in but is ignored until Lefthook is installed.

### Install Lefthook

1. Install the `lefthook` Ruby gem:

   ```shell
   bundle install
   ```

1. Install Lefthook managed Git hooks:

   ```shell
   bundle exec lefthook install
   ```

1. Test Lefthook is working by running the Lefthook `prepare-commit-msg` Git hook:

   ```shell
   bundle exec lefthook run prepare-commit-msg
   ```

This should return a fully qualified path command with no other output.

### Run Lefthook hooks manually

To run the `pre-push` Git hook, run:

   ```shell
   bundle exec lefthook run pre-push
   ```

### Troubleshooting: Vale not found error

If you get the error `ERROR: Vale not found` when running Lefthook, you can
[install it manually](https://docs.gitlab.com/ee/development/documentation/testing.html#install-linters).

## Lefthook for GitLab

The [GitLab project](https://gitlab.com/gitlab-org/gitlab) also [supports Lefthook](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml). Both the GitLab project and Lefthook are automatically set up when you install or update the GDK.

### Disabling Lefthook for GitLab

To disable Lefthook for GitLab, run:

```shell
gdk config set gitlab.lefthook_enabled false
```

This:

- Stops Lefthook from installing its hooks and running.
- Updates your `gdk.yml` file, so when you run `gdk update` in future, that operation will not install Lefthook's hooks.

## Local Lefthook configuration

Lefthook uses the `lefthook.yml` and `lefthook-local.yml` files. To run custom commands and logic in Lefthook, you can create a custom `lefthook-local.yml` configuration.

For more information, see [Lefthook's configuration guide](https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md).

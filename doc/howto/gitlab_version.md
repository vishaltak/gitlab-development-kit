# GitLab version

Use the GDK to run a previous version of GitLab.

## Change the version

1. Find the [tag](https://gitlab.com/gitlab-org/gitlab/-/tags) or commit hash for the version of GitLab you want to use.
1. Navigate to the `/gitlab-development-kit/gitlab/` folder using the command line.
1. Switch to the target tag or commit hash and detatch from `HEAD`:

    ```shell
    git switch <tag> --detach
    ```

    For example, `git switch v14.9.3-ee --detach` or `git switch 5087c814 --detach`.

1. Install and update dependencies:

    ```shell
    bundle install
    yarn install
    ```

1. Run database migrations:

    ```shell
    bundle exec rails db:migrate
    ```

1. Restart (or start) the GDK:

    ```shell
    gdk restart
    ```

   Always restart the GDK after performing database migrations to prevent deadlocks in components such as Sidekiq. The existing Rails process caches the
   database schema at boot, and may run on false assumptions until it reloads the database.

## Creating an alias

If this is an action you'll perform regularly consider creating the following alias:

```shell
gdkdowngradeto = !f() { git switch \"$1\" --detach && bundle exec rails db:migrate && bundle install && yarn install && gdk restart; }; f
```

Run the alias using `gdkdowngradeto v14.9.3-ee` or any other tag or commit hash.

# Cells

Support for Cells in GDK is still experimental,
as development to make Cells work is still ongoing in this
[epic](https://gitlab.com/groups/gitlab-org/-/epics/7582).

## How to install a second GDK to act as a Cell

Here are some minimal steps to make another GDK act as a Cell.

1. Until this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412280) is
   fixed, set the following environment variable. For example you can set in
   your `.bash_profile`, or `.zshrc`:

   ```shell
   export GITLAB_VALIDATE_DATABASE_CONFIG=0
   ```

1. Clone GDK into a second directory adjacent to your existing GDK:

   ```shell
   cd ../
   git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git gdk2
   ```

1. Change directory to your existing GDK:

   ```shell
   cd gdk
   ```

1. Run the script:

   ```shell
    ./support/cells-add-secondary --secondary_port 3001 --primary . ../gdk2
   ```

The new GDK will be available at the URL `http://127.0.0.1:3001`

### Cleanup

To cleanup, and remove the 2nd cell:

1. Go to the directory for the 2nd GDK. If we assume it's `gdk2` from the above
   section:

   ```shell
   cd ../gdk2
   ```

1. Stop GDK for the 2nd cell:

   ```shell
   gdk stop
   ```

1. Optionally, remove the 2nd GDK directory:

   ```shell
   cd ..
   rm -rf gdk2
   ```

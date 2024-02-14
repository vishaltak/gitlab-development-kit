# Cells (Experiment)

**NOTE:** This document doesn't reflect the newest Cells 1.X and 2.X architecture that
are depicted [here](https://docs.gitlab.com/ee/architecture/blueprints/cells/index.html#cells-iterations).

Support for cells in the GDK is still an Experiment.
For more information, see [epic 7582](https://gitlab.com/groups/gitlab-org/-/epics/7582).

## Install another GDK to act as a cell

To install another GDK to act as a cell:

1. Until [issue 412280](https://gitlab.com/gitlab-org/gitlab/-/issues/412280)
   is resolved, in `.bash_profile` or `.zshrc`, set the
   `GITLAB_VALIDATE_DATABASE_CONFIG` environment variable:

   ```shell
   export GITLAB_VALIDATE_DATABASE_CONFIG=0
   ```

1. Clone the GDK into a second directory adjacent to your existing GDK:

   ```shell
   cd ../
   git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git gdk2
   ```

1. Change the directory to your existing GDK:

   ```shell
   cd gdk
   ```

1. Run this script:

   ```shell
   ./support/cells-add-secondary --secondary_port 3001 --primary . ../gdk2
   ```

1. To bump the IDs of cell-local tables, in the `gdk2/gitlab` directory, run the following `rake` task:

   ```shell
   cd ../gdk2/gitlab
   bundle exec rake gitlab:db:cells:bump_cell_sequences\[10000\]
   ```

The new GDK is available at `http://127.0.0.1:3001`.

The new GDK might serve errors due to
[issue 1893](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1893).
If this happens, you need to stop `webpack`:

```shell
gdk stop webpack
```

### `gdk.test` configuration

If you use [`gdk.test:3000`](gdk.test:3000) to log into your GDK instance, you need to [configure the second cell to use `gdk.test`](local_network.md#local-interface) as well.

### Clean up the installation

To clean up the installation and remove the second cell:

1. Go to the directory of the second GDK. In this example, the directory is named `gdk2`.

   ```shell
   cd ../gdk2
   ```

1. Stop the GDK for the second cell:

   ```shell
   gdk stop
   ```

1. Optional. Remove the second GDK directory:

   ```shell
   cd ..
   rm -rf gdk2
   ```

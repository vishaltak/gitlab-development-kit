# GitLab Docs in GDK

You can use the GDK to develop GitLab documentation. The GDK can:

- Maintain a clone of the [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) repository
  for work on changes to that project.
- Preview changes made in the GDK-managed `gitlab/doc` directory.
- Run linting tasks that require `gitlab-docs`, including internal link and anchor checks.

## Enable GitLab Docs

To enable GDK to manage `gitlab-docs`:

1. Add the following to your [`gdk.yml` file](../configuration.md#gitlab-docs-settings):

   ```yaml
   gitlab_docs:
     enabled: true
   ```

   The default port is `3005` but this can be customized. For example:

   ```yaml
   gitlab_docs:
     enabled: true
     port: 4005
   ```

   By default, `gitlab-docs` is updated from the default project branch every time `gdk update` is
   run. This can be disabled:

   ```yaml
   gitlab_docs:
     enabled: true
     auto_update: false
   ```

1. Run `gdk update` to:
   - Clone `gitlab-docs` for the first time, or update an existing local copy.
   - Compile a published version of the contents of the `gitlab/doc` directory.
1. Start GDK, which also starts the `gitlab-docs` service when enabled:

   ```shell
   gdk start
   ```

1. Go to the URL shown in the terminal to ensure the site loads correctly. If the site doesn't
   load correctly, `tail` the `gitlab-docs` logs:

   ```shell
   gdk tail gitlab-docs
   ```

## Make documentation changes

You can preview documentation changes as they would appear when published on
[GitLab Docs](https://docs.gitlab.com).

To make changes to GitLab documentation and preview them:

1. Start GDK and ensure you can preview the documentation site:

   ```shell
   gdk start
   ```

1. Make the necessary changes to the files in `<path_to_gdk>/gitlab/doc`.
1. Restart the `gitlab-docs` service to recompile the published version of the documentation with
   the new changes:

   ```shell
   gdk restart gitlab-docs
   ```

After recompilation, the preview is automatically refreshed with the changes.

NOTE:
These instructions work for all users, but the restart step might not be needed for non-macOS users.
The copy of `gitlab-docs` managed by GDK symlinks to the `gitlab/doc` directory,
which affects the ability to "hot reload" the documentation preview on macOS.

### Include more documentation

The full published documentation suite [includes additional documentation](https://docs.gitlab.com/ee/development/documentation/site_architecture/index.html)
from outside the [`gitlab` project](https://gitlab.com/gitlab-org/gitlab).

To be able to make and preview changes to the additional documentation:

1. Add the following to your [`gdk.yml`](../configuration.md#additional-projects) as required:

   ```yaml
   gitlab_docs:
     enabled: true
   gitlab_runner:
     enabled: true
     docs_enabled: true
   omnibus_gitlab:
     enabled: true
     docs_enabled: true
   charts_gitlab:
     enabled: true
     docs_enabled: true
   ```

1. Run `gdk update` to:
   - Clone the additional projects for the first time, or update existing local copies.
   - Compile a published version of the additional documentation.

NOTE:
`gitlab_runner` should not be confused with [`runner`](runner.md).

By default, the checked out versions of `gitlab_runner`, `omnibus_gitlab`, and `charts_gitlab` are
updated automatically when `gdk update` is run. To disable this, set `auto_update: false` against
whichever project to disable.

### Check links

If you move or rename any sections within the documentation, you can verify your changes
don't break any links by running:

```shell
make gitlab-docs-check
```

This check requires:

- `gitlab_docs.enabled` is true.
- `docs_enabled` is true for [all other projects](#include-additional-documentation) that provide
  documentation.

### Troubleshooting

Sometimes the local published version of the documentation can fall out-of-date with the source
content. In these cases, you can remove the data structure `nanoc` uses to keep track of changes
with the following command:

```shell
make gitlab-docs-clean
```

This causes `nanoc` to rebuild all documentation on the next run.

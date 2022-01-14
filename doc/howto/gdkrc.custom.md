# .gdkrc.custom

The `<GDK_ROOT>/.gdkrc.custom` file allows customization of the GDK executing
environment by enhancing variables and logic defined in `<GDK_ROOT>/.gdkrc`.

Some examples of what you might need to add to `.gdkrc.custom` include:

- Customizing `LDFLAGS`, `CPPFLAGS` or `PKG_CONFIG_PATH` environment variables
- Setting an environment variable for an upcoming MR, e.g `export GITLAB_NEW_FEATURE_X=1`

Changes to `.gdkrc.custom` are ignored by Git.

# Rails Web

Rails Web is enabled by default.
If you don't want GDK to automatically start the Rails Web service:

1. Set `rails_web.enabled` to `false`:

   ```shell
   gdk config set rails_web.enabled false
   ```

1. Run `gdk reconfigure`

# Announcements

If you make notable changes to GDK, you can add an announcement that is 
displayed in a user's console after a `gdk install` or `gdk update` is 
executed. For example:

```plaintext
ℹ️  Announcements support added
--------------------------------------------------------------------------------
Announcements can now be added under data/messages as YAML files that will be
rendered to the user after a GDK install or update.

See https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/2879 for more details.
```

After being displayed, announcements are cached in `<GDK_ROOT>/.cache/.gdk-announcements.yml` 
and not displayed again. If the cache is cleared, all announcements are 
displayed again.

## Add a new announcement

Announcements are YAML files stored in `data/announcements`. To add a new announcement:

1. In the `data/announcements` directory, create a new file with a filename that follows the pattern
   `<next-unique-number>_<description_using_underscores>.yml`. If the most recent announcement file is called 
   `0001_announcement_support.yml`, your announcement's filename
   would be something like `0002_your_new_announcement.yml`. Make the filename meaningful, but it doesn't affect the display
   of the announcement itself.
1. In the new file, add the required `header` and `body` fields. The format is:

   ```yaml
   ---
   header: <Header here>
   body: |
      <Multiline body here>
   ```

For an example of an existing announcement, see
[`data/announcements/0001_announcement_support.yml`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/data/announcements/0001_announcement_support.yml)

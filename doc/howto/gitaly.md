# Gitaly

GitLab uses [Gitaly](https://docs.gitlab.com/ee/administration/gitaly/index.html) to abstract all
Git calls. To work on local changes to `gitaly`, please refer to the
[Beginner's guide to Gitaly contributions](https://gitlab.com/gitlab-org/gitaly/blob/main/doc/beginners_guide.md).

For more information on Praefect, refer to
[Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html).

## Praefect options

By default, GDK is set up use Praefect as a proxy to Gitaly. To disable Praefect, set the following
in `gdk.yml`:

```yaml
praefect:
  enabled: false
```

### Praefect on a Geo secondary

Praefect needs a read-write capable database to track it's state. On a Geo
secondary the main database is read-only. So when GDK is [configured to be
a Geo secondary](geo.md#secondary), Praefect uses the Geo tracking database
instead.

If you have modified this setting, you need to recreate the Praefect database
using:

```shell
make gitaly-setup
```

### Praefect virtual storages

If you need to work with multiple storages in GitLab, you can create a second virtual storage in
Praefect. You need at least one more Gitaly service or storage to create another virtual storage.

#### Add more Gitaly nodes

**TODO**: [Automate this process](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/827)

By default, GDK generates Praefect configuration containing only one Gitaly node. To add additional
backend Gitaly nodes to use in more virtual storages:

1. Increase the number of nodes by adding the following to `gdk.yml`:

   ```yaml
   praefect:
     node_count: 2
   ```

1. Run `gdk reconfigure`.
1. Edit the Praefect configuration file `gitaly/praefect.config.toml` to add the
   new virtual storage.

   - Before:

     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"

     [[virtual_storage.node]]
     storage = "praefect-internal-1"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-1.socket"
     ```

   - After:

     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"

     [[virtual_storage]]
     name = 'default2'

     [[virtual_storage.node]]
     storage = "praefect-internal-1"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-1.socket"
     ```

1. Edit `gitlab/config/gitlab.yml` to add the new virtual storage:

   - Before:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```

   - After:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
         default2:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```

1. Run `gdk restart`.

#### Add more shards to Gitaly storage

There are situations where we might need to configure several shards to store repositories. For
example, to create several shards with a single Praefect node:

1. Create the directories on disk for the new shards.
1. Edit the Praefect configuration file `gitaly/praefect.config.toml` to add the new virtual
   storage.

   - Before:

     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"
     ```

   - After:

     ```toml
     [[virtual_storage]]
     name = 'default'

     [[virtual_storage.node]]
     storage = "praefect-internal-0"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"

     [[virtual_storage]]
     name = 'storage_2'

     [[virtual_storage.node]]
     storage = "praefect-internal-extra-2"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"

     [[virtual_storage]]
     name = 'storage_3'

     [[virtual_storage.node]]
     storage = "praefect-internal-extra-3"
     address = "unix:/Users/paulokstad/gitlab-development-kit/gitaly-praefect-0.socket"
     ```

1. Edit `gitaly/gitaly.config.toml` to add the new virtual storage:

   - Before:

     ```toml
     [[storage]]
     name = "default"
     path = "/Users/paulokstad/gitlab-development-kit/repositories"
     ```

   - After:

     ```toml
     [[storage]]
     name = "default"
     path = "/Users/paulokstad/gitlab-development-kit/repositories"

     [[storage]]
     name = "storage_2"
     path = "/mnt/storage_2"

     [[storage]]
     name = "storage_3"
     path = "/mnt/storage_3"
      ```

1. Edit `gitaly/gitaly-0.praefect.toml` to add the new virtual storage:

   - Before:

     ```toml
     [[storage]]
     name = "praefect-internal-0"
     path = "/Users/paulokstad/gitlab-development-kit/repositories"
     ```

   - After:

     ```toml
     [[storage]]
     name = "praefect-internal-0"
     path = "/Users/paulokstad/gitlab-development-kit/repositories"

     [[storage]]
     name = "praefect-internal-extra-2"
     path = "/mnt/storage_2"

     [[storage]]
     name = "praefect-internal-extra-3"
     path = "/mnt/storage_3"
     ```

1. Edit `gitlab/config/gitlab.yml` to add the new virtual storage:

   - Before:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```

   - After:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
         storage_2:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
         storage_3:
           path: /
           gitaly_address: unix:/Users/paulokstad/gitlab-development-kit/praefect.socket
     ```

1. Run `gdk restart`.
1. Enable the new shards in the
   [Admin Area](https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored).

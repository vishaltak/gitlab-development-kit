# Snowplow Micro

You can use GDK to run Snowplow Micro collector.

## Enable Snowplow Micro

To enable GDK to manage `snowplow-micro`:

1. Ensure [Docker is installed and working](https://www.docker.com/get-started).

1. Enable Snowplow Micro:

   ```shell
   gdk config set snowplow_micro.enabled true
   ```

1. Optional. Snowplow Micro runs on port `9091` by default, you can change to `9092` by running:

   ```shell
   gdk config set snowplow_micro.port 9092
   ```

1. Regenerate your Procfile by reconfiguring GDK:

   ```shell
   gdk reconfigure
   ```

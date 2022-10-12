# Local network binding

For ease of documentation:

- `gdk.test` is the standard hostname for referring to the local GDK instance.
- `registry.test` is the standard hostname for referring to a local [container registry](registry.md).

We recommend [mapping this to a loopback interface](#create-loopback-interface), but it can be mapped to `127.0.0.1`.

To set up `gdk.test` and `registry.test` as hostnames:

1. Map `gdk.test` to a local address. If using [loopback interface](#create-loopback-interface), add the following to
   `/etc/hosts`:

   ```plaintext
   172.16.123.1 gdk.test registry.test
   ```

   Or, if using `127.0.0.1`:

   ```plaintext
   127.0.0.1 gdk.test registry.test
   ```

1. Set `hostname` to `gdk.test`.

   ```shell
   gdk config set hostname gdk.test
   ```

1. If using [loopback interface](#create-loopback-interface), change `listen_address` to be the loopback alias:

    ```shell
    gdk config set listen_address 172.16.123.1
    ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

1. Restart GDK to use the new configuration:

   ```shell
   gdk restart
   ```

## Create loopback interface

Some functionality may not work if GDK processes listen on `localhost` or `127.0.0.1` (for example,
services [running under Docker](runner.md#docker-configuration)). Therefore, an IP address on a different private network should be
used.

`172.16.123.1` is a useful [private network address](https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses)
that can avoid clashes with `localhost` and `127.0.0.1`. To configure a loopback interface for this
address:

1. Create an internal interface. On macOS, this adds an alias IP `172.16.123.1` to the loopback
   adapter:

   ```shell
   sudo ifconfig lo0 alias 172.16.123.1
   ```

   On Linux, you can create a dummy interface:

   ```shell
   sudo ip link add dummy0 type dummy
   sudo ip address add 172.16.123.1 dev dummy0
   sudo ip link set dummy0 up
   ```

1. Set `listen_address` to `172.16.123.1`:

    ```shell
    gdk config set listen_address 172.16.123.1
    ```

    Or, if you added `gdk.test` to your `/etc/hosts` file:

    ```shell
   gdk config set hostname gdk.test
    ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ``` 

   Your `gdk.yml` should contain these lines afterwards:
  
   ```yaml
   hostname: gdk.test
   listen_address: 172.16.123.1
   ```

1. Restart GDK to use the new configuration:

   ```shell
   gdk restart
   ```

### Create loopback device on startup

For this to work across reboots, the aliased IP address command must be run at startup. To
automate this on macOS, create a file called `org.gitlab1.ifconfig.plist` at `/Library/LaunchDaemons/`
containing:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.gitlab1.ifconfig</string>
    <key>RunAtLoad</key>
    <true/>
    <key>Nice</key>
    <integer>10</integer>
    <key>ProgramArguments</key>
    <array>
      <string>/sbin/ifconfig</string>
      <string>lo0</string>
      <string>alias</string>
      <string>172.16.123.1</string>
    </array>
</dict>
</plist>
```

The method to persist this dummy interface on Linux varies between distributions. On Ubuntu 20.04,
you can run:

```shell
sudo nmcli connection add type dummy ifname dummy0 ip4 172.16.123.1
```

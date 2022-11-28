# NGINX

Installing and configuring NGINX allows you to enable HTTPS (with SSL/TLS), HTTP/2 as
well as greater flexibility around HTTP routing.

## Install dependencies

You need to install NGINX:

```shell
# on macOS
brew install nginx

# on Debian/Ubuntu
apt install nginx

# on Fedora
yum install nginx
```

## Add entry to /etc/hosts

To be able to use a hostname instead of IP address, add a line to
`/etc/hosts`.

```shell
echo '127.0.0.1 gdk.test' | sudo tee -a /etc/hosts
```

`gdk.test` (or anything ending in `.test`) is recommended as `.test` is a
[reserved TLD for testing software](https://en.wikipedia.org/wiki/.test).

### Configuring a loopback device (optional)

NOTE:
You can skip this step unless you need a [runner under Docker](runner.md#docker-configuration).

If you want an isolated network space for all the services of your
GDK, you can [add a loopback network interface](local_network.md).

## Update `gdk.yml`

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
nginx:
  enabled: true
  http:
    enabled: true
```

## Update `gdk.yml` for HTTPS (optional)

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  ssl:
    certificate: <path/to/file/gdk.test.pem>
    key: <path/to/file/gdk.test-key.pem>
```

To also run the [Docs site](gitlab_docs.md) under HTTPS, run:

```shell
gdk config set gitlab_docs.enabled true
gdk config set gitlab_docs.https true
```

### Generate certificate

[`mkcert`](https://github.com/FiloSottile/mkcert) is needed to generate certificates.
Check out their [installation instructions](https://github.com/FiloSottile/mkcert#installation)
for all the different platforms.

On macOS, install with `brew`:

```shell
brew install mkcert nss
mkcert -install
```

Using `mkcert` you can generate a self-signed certificate. It also
ensures your browser and OS trust the certificate.

```shell
mkcert gdk.test
```

## Update `gdk.yml` for HTTP/2 (optional)

Place the following settings in your `gdk.yml`:

```yaml
---
hostname: gdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  http2:
    enabled: true
  ssl:
    certificate: <path/to/file/gdk.test.pem>
    key: <path/to/file/gdk.test-key.pem>
```

## Configure GDK

Run the following to apply these changes:

```shell
gdk reconfigure
gdk restart
```

## Run

GitLab should now be available for:

- HTTP: <http://gdk.test:8080>
- HTTPS: <https://gdk.test:3443> (if you set up HTTPS).

GitLab Docs should now be available for:

- HTTP: <http://gdk.test:3005>
- HTTPS: <https://gdk.test:3030> (if you set up HTTPS).

## Troubleshooting

### `nginx: invalid option: "e"`

NGINX v1.19 supports the `-e` flag, but v1.18 does not. If you encounter this
error, use [NGINX's repositories](https://nginx.org/en/linux_packages.html)
to install the latest package instead of the one shipped with your distribution.

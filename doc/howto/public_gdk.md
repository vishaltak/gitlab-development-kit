# Use Caddy to make GDK publicly accessibly

You might sometimes need to allow GDK to be publicly accessible. For example:

- When working with webhooks and integrations, the external services may require a publicly-accessible URL.
- Some authentication flows, such as OIDC, might also require callbacks to a publicly-accessible URL.

You shouldn't expose local ports to the internet, either by opening up the port or using tunnels that forward traffic back to your development machine (for example, by using
`ngrok`) because of [security risks](https://handbook.gitlab.com/handbook/business-technology/it/security/system-configuration/#other-servicesdevices). Because GitLab offers
remote code execution as a feature, GitLab Runner could execute CI/CD jobs directly on the host machine, for example.

For development machines that contain sensitive data, such as company-issued laptops, you should instead run GDK on a sandboxed virtual machine and make it publicly accessible.

## Prerequisites

- A virtual machine with sufficient resources to run GDK. A cloud-based virtual machine is easier to configure for DNS.
- GDK and its dependencies installed on the virtual machine following the GDK installation instructions.
- HTTP and HTTPS ports on the virtual machine are open, following the cloud provider's instructions.
- A DNS `A` record pointing to the virtual machine's public IP address. For example, `gdk.mydomain.io`.
- [`caddy`](https://caddyserver.com/) installed for reverse proxy.

## Configure GDK

In the virtual machine:

1. Add the following to `gdk.yml` file:

   ```yaml
   gitlab:
     rails:
       hostname: 'gdk.mydomain.io'
       allowed_hosts:
        - 'gdk.mydomain.io'
   ```

1. Run `gdk reconfigure`.

## Configure a reverse proxy using Caddy

`caddy` is recommended as a reverse proxy because it automatically provisions TLS certificate using Let's Encrypt.

1. Create a `Caddyfile` file with the following content:

   ```plaintext
   gdk.mydomain.io {
     reverse_proxy :3000
   }
   ```

1. Start caddy with `caddy run`.

This will forward requests to GitLab Workhorse, assuming it is running on the default port 3000.

Now GDK will be available on its URL. For example, `https://gdk.mydomain.io`.

## Security reminders

- [Change](https://docs.gitlab.com/ee/security/reset_user_password.html) the root account password.
- Remember to [disable sign-ups](https://docs.gitlab.com/ee/administration/settings/sign_up_restrictions.html#disable-new-sign-ups).
- Stop the reverse proxy when it is no longer needed.

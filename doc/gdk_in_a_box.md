# GDK-in-a-box

GDK-in-a-box provides a preconfigured virtual machine you can download and boot
to instantly start developing.

## Run on macOS

1. Download and [install UTM](https://docs.getutm.app/installation/macos/).
1. Download and unzip [GDK-in-a-box](https://go.gitlab.com/cCHpCP).
1. Double-click `gdk.utm`.
1. Follow the [standard setup steps](#standard-setup).

## Run on Linux / Windows

1. Download and [install VirtualBox](https://www.virtualbox.org/wiki/Downloads).
1. Download and unzip [GDK-in-a-box](https://go.gitlab.com/5iydBP).
1. Double-click `gdk.vbox`.
1. Follow the [standard setup steps](#standard-setup).

## Standard setup

NOTE:

- You might need to modify the system configuration (CPU cores and RAM).
- You must have the VSCode **Remote - SSH** extension installed.

1. Start the VM (minimise the console because you won't need it).
1. Import the SSH key: `curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/setup-ssh-key" | bash`.
1. Connect VSCode (Remote-SSH: Connect to host): `debian@gdk.local`.
1. Open `/home/gitlab-development-kit/gitlab`.
1. Open GitLab in your browser: [http://gdk.local:3000](http://gdk.local:3000).
1. Login to GitLab with `root/5iveL!fe`.
1. Configure Git with your name, e-mail and OAuth token/SSH key.

## Building GDK-in-a-box

This isn't neccessary to use GDK-in-box.
Follow the [instructions to build a new version of GDK-in-a-box](build_gdk_in_a_box.md).

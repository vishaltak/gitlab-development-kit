# GDK-in-a-box

GDK-in-a-box provides a preconfigured virtual machine you can download and boot
to instantly start developing.

## Run on macOS

1. Download and [install UTM](https://mac.getutm.app/).
1. Download and unzip [GDK-in-a-box](https://go.gitlab.com/cCHpCP).
1. Double-click `gdk.utm`.
1. Follow the [standard setup steps](#standard-setup).

## Run on Linux / Windows

1. Download and [install VirtualBox](https://www.virtualbox.org/wiki/Downloads).
1. Download and unzip [GDK-in-a-box](https://go.gitlab.com/5iydBP).
1. Double-click `gdk.vbox`.
1. Follow the [standard setup steps](#standard-setup).

## Standard setup

Take a look at the [YouTube demo of launching GDK-in-a-box](https://go.gitlab.com/b54mHb).

NOTE:

- You might need to modify the system configuration (CPU cores and RAM).
- You must have the VSCode **Remote - SSH** extension installed.
- GitLab team members: GDK-in-a-box is configured to use the [community forks](https://gitlab.com/gitlab-community/meta).
  Please consider reading about them and using them moving forward.
  The docs detail [how to checkout branches from different remotes](https://gitlab.com/gitlab-community/meta#checkout-a-branch-from-a-different-remote),
  but as a last resort you may reconfigure your remote to the canonical project.

1. In a local terminal, import the SSH key by running: `curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/setup-ssh-key" | bash`.
1. Start the VM (minimise the console because you won't need it).
1. Connect VSCode to the VM:
   - Select **Remote-SSH: Connect to host** from the command palette
   - Enter the SSH host: `debian@gdk.local`.
1. A new VSCode window will open.
   Close the old window to avoid confusion.
1. In VSCode, select **Terminal > New terminal** and configure Git by running: `curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/first_time_setup" | bash`.
   - Enter your name and e-mail address when prompted.
   - Add the displayed [SSH key to your profile](https://gitlab.com/-/profile/keys).
1. In VSCode, select **File > Open folder**, and navigate to: `/home/debian/gitlab-development-kit/gitlab`.
1. Open GitLab in your browser: [http://gdk.local:3000](http://gdk.local:3000).
1. Login to GitLab with `root/5iveL!fe`.

## Update

You can update GDK-in-a-box at any time.
While connected via Remote-SSH:

- In VSCode, select **Terminal > New terminal**.
- Run: `gdk update`.

## Troubleshoot

If you have any issues, the simplest and fastest solution is to:

- Delete the virtual machine.
- Download the latest build.
- Follow the [standard setup instructions](#standard-setup).

NOTE:

Your GitLab instance will be restored to defaults.
Be sure to commit and push all changes beforehand, or they will be lost.

## Building GDK-in-a-box

This isn't neccessary to use GDK-in-box.
Follow the [instructions to build a new version of GDK-in-a-box](build_gdk_in_a_box.md).

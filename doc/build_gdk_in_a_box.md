# Build GDK-in-a-box

This is the manual process to create the GDK-in-a-box virtual machines:

## Build on macOS

1. Download the preconfigured [Debian 12 VM](https://mac.getutm.app/gallery/debian-12).
1. In UTM, edit the VM config:
   - **Information > Name**: `GDK`.
   - **System > CPU Cores**: `8`.
   - **System > RAM**: `16384` MB.
1. Follow the [standard VM build steps](#standard-build).
1. Zip `gdk.utm`.
1. [Publish](#publish) the new image.

## Build on Linux and Windows

1. Download the latest [Debian 12 installation media](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/).
1. Create a new Virtual Machine with the settings:
   - **General > Basic**:
     - **Name**: `GDK`.
     - **Type**: `Linux`.
     - **Version**: `Debian (64-bit)`.
   - **General > Advanced > Shared Clipboard**: `Bidirectional`.
   - **System > Motherboard > Base Memory**: `16384 MB`.
   - **System > Processor > Processors**: `18`.
   - **Network > Adapter 1 > Attached to:**: `Bridged Adapter`.
1. Mount the installation ISO and start the virtual machine.
1. Follow the [standard VM build steps](#standard-build).
1. Zip `gdk.vbox` and `gdk.vdi`.
1. [Publish](#publish) the new image.

## Standard build

1. Boot the VM.
1. Login to the console with user: `debian` and password: `debian`.
1. Run the following commands:

   ```shell
   sudo systemctl set-default multi-user.target
   hostnamectl hostname gdk
   sudo reboot
   ```

1. Sign in with SSH to `debian@gdk.local` with password: `debian`.
   1. Configure the grub bootloader so that it does not wait:
      - ```sudo nano /etc/default/grub```.
      - Set **GRUB_TIMEOUT** to `0`.
      - Save and exit.
      - Update grub: ```sudo update-grub```.
   1. Remove Gnome/desktop/UI: ```sudo tasksel```.
   1. Install pre-requisites:

   ```shell
   sudo apt update
   sudo apt install git make curl
   ```

   1. Download the SSH key and allow it to connect:
    
      ```shell
      curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/gdk.local_rsa.pub" -o ~/.ssh/id_rsa.pub
      cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
      ```

1. Add the SSH key to your local machine:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/setup-ssh-key" | bash
   ```

1. Login with SSH to `debian@gdk.local`. You do not need a password to log in.
   1. Install GDK using the one-line installation method: ```curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash```.
   1. When prompted, configure GDK to use the GitLab community fork, and telemetry with anonymous user: `gdk-in-a-box`.
   1. Load asdf into your shell: ```source "/home/debian/.asdf/asdf.sh"```.
   1. Enable Vite: 
  
   ```shell
   echo "Feature.enable(:vite)" | gdk rails c
   gdk config set webpack.enabled false
   gdk config set vite.enabled true
   ```

   1. Configure GDK to listen outside on the local network:

   ```shell
   gdk config set hostname gdk.local
   gdk config set listen_address 0.0.0.0
   ```

   1. Enable telemetry:

   ```shell
   gdk config set telemetry.enabled true
   gdk config set telemetry.platform 'gdk-in-a-box'
   ```

   1. Apply configuration changes: ```gdk reconfigure```.
   1. Start GDK: ```gdk start```.
1. Sign in to GDK in your web browser: [http://gdk.local:3000](http://gdk.local:3000).
   When prompted to set a new password, enter `5iveL!fe` to keep the existing credentials.
1. Shutdown the VM.

## Publish

1. Upload the zip file to [GCP](https://console.cloud.google.com/storage/browser/contributor-success-public).
1. Update the short links in [campaign manager](https://campaign-manager.gitlab.com/campaigns/view/94).

## Potential future housekeeping

The zipped virtual machines are roughly 7 GB.
We should try and reduce this.

- Use a smaller Linux distribution or remove unneccessary packages.
- Clear apt cache.

## Terminal customization

To jazz up the terminal prompt with colors and the branch name: 

1. `code ~/.bashrc`
1. At the end of the file paste: 

   ```shell
   # Function to return the current git branch name
   git_branch() {
     git branch 2>/dev/null | grep '^*' | colrm 1 2
   }

   # Prompt customization 
   export PS1="\[\033[01;36m\]➜  \[\033[01;32m\]\u@\h \[\033[01;36m\]\W \[\033[01;34m\]git:\[\033[01;34m\](\[\033[01;31m\]\$(git_branch)\[\033[01;34m\]) \[\033[00m\]"
   ```

1. Save and run `source ~/.bashrc`.

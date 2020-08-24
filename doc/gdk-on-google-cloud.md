# Deploying the GDK in the Google Cloud

## Preparations

1. Make sure you have a [Google Cloud](console.cloud.google.com/) account.
1. Create and new project in gcloud and take note of the project id for later steps.
1. [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos) on your machine, initialize it, and configure it to use the project you just created (only if you have more than one):

```shell
   gcloud config set project YOUR_PROJECT_ID
```

## Creating the Virtual Machine

1. Create a virtual machine with the GDK image: 

```shell
   gcloud compute instances create gdk --image-project gdk-cloud --image gitlab-gdk-master-1597726225
```

1. Confirm that a VM got created by checking the overview of your [Virtual Machine Instances](https://console.cloud.google.com/compute/instances).
1. Stop the instance.
1. Go to the detail page of your new Virtual Machine and click on Edit.
1. Upgrade the machine type to **n1-standard-4 (4 vCPU, 15GB Memory)**, enable both **Allow HTTP traffic** and **Allow HTTPS traffic** in the Firewalls section and save your changes.

## Running the GDK

1. Start the instance.
1. Connect to your Virtual Machine via SSH. You can do so by clicking the SSH dropdown for your Virtual Machine on the overview page in the Google Cloud UI and selecting **Open in browser window**.
1. Wait for the terminal to load, then enter the following commands (all following terminal commands are supposed to be executed in this window, unless stated otherwise):

```shell
   sudo su - gdk
   cd gdk
   gdk start
```

1. We now have to fix some settings, this is a temporary step that will hopefully not be necessary anymore soon.

```shell
   sudo vim /etc/nginx/sites-enabled/default
```

1. Now press **i**, change `http://localhost:8080` to `http://localhost:3000`, press **ESC** and then type **:wq** and press **Enter**
1. Restart NGINX:

```shell
   sudo nginx -s reload
```

1. On the Virtual Machine details, you can see the external IP. Visit that address in a new tab (don't use https://, only http://).
1. You should now see the familiar 502 page. Wait 1-2 minutes and you will (hopefully) see the login screen to your GDK 🎉. In case you see a 504 Gateway Timeout message, reloading the page 1-2 times should fix it.

## Making changes to the code with Code Server (cloud version of VS Code)

1. In the browser terminal of your Virtual Machine, create a self-signed certificate for Code Server:

```shell
   export XDG_RUNTIME_DIR=/run/user/`id -u`
   loginctl enable-linger $(whoami)
   systemctl --user enable --now code-server
   sed -i.bak 's/cert: false/cert: true/' ~/.config/code-server/config.yaml
   sed -i.bak 's/bind-addr: 127.0.0.1:8080/bind-addr: 0.0.0.0:443/' ~/.config/code-server/config.yaml
   sed -i.bak 's/auth: password/auth: none/' ~/.config/code-server/config.yaml
   sudo setcap cap_net_bind_service=+ep /usr/lib/code-server/lib/node
   systemctl --user restart code-server
```
<!-- markdownlint-disable MD034 -->
1. Open https://IP_OF_YOUR_VM to see VS Code running in your browser.
<!-- markdownlint-enable MD034 -->
<!-- markdownlint-disable MD044 -->
1. Click the first icon in the left sidebar, and select **File** -> **Open..**. That brings up a new menu where you can select **gdk** -> **gitlab**. Here you can now switch branches, make changes that will directly be displayed in the cloud GDK and commit any changes you made.
<!-- markdownlint-enable MD044 -->

🎉 This is everything you needed to review and develop in the cloud GDK from now on! 🦊

## Working on the GDK in VS Code

If you rather want to use your local VS Code version, you can also connect via SSH from your local machine:

1. In your local terminal, copy your SSH public key:

```shell
   pbcopy < ~/.ssh/id_ed25519.pub
```

1. Open the browser window terminal for your Virtual Machine again.
1. Install your SSH keys under the `gdk` user:

```shell
   sudo su - gdk
   mkdir ~/.ssh
   chmod 700 ~/.ssh
   touch ~/.ssh/authorized_keys
   echo YOUR_SSH_PUB_KEY_WE_JUST_COPIED >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
```

1. Open VS Code and install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension. 
1. Your VS Code should now have a green button with a `lower than` and `greater than` sign at the bottom left, click on it.
1. In the menu that pops up, select **Remote-SSH: Connect to Host...** and then **+ Add New SSH Host...**.
1. Enter the following SSH Connection Command:

```shell
   ssh -i PATH_OF_YOUR_PRIVATE_SSH_KEY_FILE gdk@IP_OF_YOUR_VM
```

1. Choose where you want to save the configuration.
1. You should now see a toast message that a new host was added, click on **Connect**.
<!-- markdownlint-disable MD044 -->
1. A new VS Code window should start, confirm that you want to continue and enter the passphrase for your SSH key. You are now connected, jump to the explorer tab (first option in the left sidebar), click on **Open folder** and then select first **gdk**, followed by **gitlab**.
<!-- markdownlint-enable MD044 -->

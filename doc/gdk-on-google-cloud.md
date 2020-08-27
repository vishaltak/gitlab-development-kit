# Deploying the GDK in the Google Cloud

## Preparations

1. Make sure you have a [Google Cloud](console.cloud.google.com/) account.
1. Create and new project in gcloud and take note of the project id for later steps.
1. [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos) on your machine, initialize it, and configure it to use the project you just created (only if you have more than one):

```shell
   gcloud config set project YOUR_PROJECT_ID
```

## Creating the Virtual Machine

Create a virtual machine with the GDK image: 

```shell
   gcloud compute instances create gdk --machine-type n1-standard-4 --image-project gdk-cloud --image gitlab-gdk-master-1598444035
```

Confirm that a VM got created and is running by checking the overview of your [Virtual Machine Instances](https://console.cloud.google.com/compute/instances).

## Running the GDK

Now log into your Virtual Machine and forward the port the GDK is running on in the cloud to your local machine. To do so, enter the following command in the terminal on your own machine and follow the instructions to create your SSH key file:

```shell
   gcloud compute ssh gdk@gdk -- -L 3000:localhost:3000
```

As soon as you see a green arrow on a new line, you are logged in. You can now start the gdk as usual:

```shell
   cd gdk
   gdk start
```

1. If you visit the familiar `localhost:3000` you should now see the familiar 502 page. Wait 1-2 minutes and you will (hopefully) see the login screen to your GDK 🎉. In case you see a 504 Gateway Timeout message, reloading the page 1-2 times should fix it.

## Making changes to the code 

## Option A: VS Code on your own machine

1. Open VS Code and install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension. 
1. Your VS Code should now have a green button with a `lower than` and `greater than` sign at the bottom left, click on it.
1. In the menu that pops up, select **Remote-SSH: Connect to Host...** and then **+ Add New SSH Host...**.
1. Enter the following SSH Connection Command:

```shell
   ssh -i ~/.ssh/google_compute_engine gdk@IP_OF_YOUR_VM
```

1. Choose the file you want to save the configuration in.
1. You should now see a toast message that a new host was added, click on **Connect**.
<!-- markdownlint-disable MD044 -->
1. A new VS Code window should start, confirm that you want to continue and enter the passphrase for your SSH key. You are now connected, jump to the explorer tab (first option in the left sidebar), click on **Open folder** and then select first **gdk**, followed by **gitlab**.
<!-- markdownlint-enable MD044 -->

### Option B: Code Server (VS Code in your browser)

1. In the browser terminal of your Virtual Machine, create a self-signed certificate for Code Server:

```shell
   export XDG_RUNTIME_DIR=/run/user/`id -u`
   loginctl enable-linger $(whoami)
   systemctl --user enable --now code-server
   sed -i.bak 's/cert: false/cert: true/' ~/.config/code-server/config.yaml
   sed -i.bak 's/auth: password/auth: none/' ~/.config/code-server/config.yaml
   sudo setcap cap_net_bind_service=+ep /usr/lib/code-server/lib/node
   systemctl --user restart code-server
```

1. Forward now the Code Server port from the Virtual Machine to your machine by entering the following command in the terminal of your own machine, and keeping it running:

```shell
   ssh -N -L 8080:localhost:8080 gdk@IP_OF_YOUR_VM
```

1. Open `localhost:8080` to see VS Code running in your browser.
<!-- markdownlint-disable MD044 -->
1. Click the first icon in the left sidebar, and select **File** -> **Open..**. That brings up a new menu where you can select **gdk** -> **gitlab**. Here you can now switch branches, make changes that will directly be displayed in the cloud GDK and commit any changes you made.
<!-- markdownlint-enable MD044 -->

🎉 This is everything you needed to review and develop in the cloud GDK from now on! 🦊

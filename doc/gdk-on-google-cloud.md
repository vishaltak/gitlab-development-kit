# Deploying the GDK in the Google Cloud

Before you create a Compute Engine virtual machine:

1. Make sure you have a [Google Cloud](console.cloud.google.com/) account.
1. [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos) on your machine
1. Create a new project in Google Cloud. A new project ensures you are not inheriting
   any vulnerable configurations, such as wide-open firewall rules. The project name
   must be unique across all Google Cloud projects for all users, so you might have to
   try multiple times:

   ```shell
   gcloud projects create <YOUR_NEW_PROJECT_NAME>
   ```

1. Set the new project as default target for any commands you run:

   ```shell
   gcloud config set project <YOUR_NEW_PROJECT_NAME>
   ```

## Create the virtual machine

To create a virtual machine for GDK:

1. Create a virtual machine with the GDK image.

   ```shell
   gcloud compute instances create gdk --machine-type n1-standard-4 --no-service-account --no-scopes --image-project gdk-cloud --image gitlab-gdk-master-1598444035
   ```

   The command might fail with an error message that billing is not enabled for that
   project. If so:

   1. Visit `https://console.cloud.google.com/billing/linkedaccount?project=<YOUR_NEW_PROJECT_NAME>`.
   1. Link a billing account to this project and run the command again.

1. Confirm that a virtual machine was created by checking the overview of your
   [Virtual Machine Instances](https://console.cloud.google.com/compute/instances).

## Run GDK

To run GDK on the image created above:

1. Start the virtual machine:

   ```shell
   gcloud compute instances start gdk
   ```

1. Log in to the virtual machine and forward the GDK port on the virtual machine to your
   local machine by running the following commands:

   ```shell
   gcloud compute config-ssh
   sed -i '' $'/CheckHostIP=no/s/^/ User gdk\\\n/' ~/.ssh/config
   gcloud compute ssh gdk@gdk -- -L 3000:localhost:3000
   ```

   This will create an SSH key file.

1. When you see a green arrow on a new line, you are logged in. You can now start GDK:

   ```shell
   cd gdk
   gdk start
   ```

Go to [`localhost:3000`](http://localhost:3000) and after about 1-2 minutes, you will
see the login screen for GDK 🎉.

## Stop GDK

**IMPORTANT:** While your virtual machine is running, it costs money. When you are
finished using GDK:

1. Leave the SSH environment by typing `exit` into the terminal.
1. Type **Control + C** and then execute the following command:
   
   ```shell
   gcloud compute instances stop gdk
   ```

To run GDK again, follow the instructions in [Run GDK](#run-gdk).

## Change code in GDK

There are two ways to change code using GDK on Google cloud:

- Using an editor on your own machine.
- Using a code server.

## Option A (recommended): VS Code on your own machine

1. Open VS Code and install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension. 
1. Your VS Code should now have a green button with a `lower than` and `greater than` sign at the bottom left, click on it.
<!-- markdownlint-disable MD044 -->
<!-- vale off -->
1. In the menu that pops up, select **Remote-SSH: Open configuration file** and select the first option.
1. In the file that now opens, add `User gdk` below the line with the `HostName` variable.
1. Open the Remote menu from the lower left corner again and this time select **Remote-SSH: Connect to Host...** and then choose **gdk.YOUR_ZONE.YOUR_PROJECT_ID**.
<!-- vale on -->
1. A new VS Code window should start, confirm that you want to continue and enter the passphrase for your SSH key that you configured previously in the terminal. You are now connected, jump to the explorer tab (first option in the left sidebar), click on **Open folder** and then enter the folder **/home/gdk/gdk/gitlab** to be opened.
<!-- markdownlint-enable MD044 -->

### Option B: Code Server (VS Code in your browser)

Open a new terminal window if you want to keep the GDK running at the same time as Code Server. Then you need to also forward the Code Server port from the Virtual Machine to your machine by entering the following command in the terminal of your own machine, and keeping it running:

```shell
   gcloud compute ssh gdk@gdk -- -L 8080:localhost:8080
```

Enter the passphrase for your SSH key file again and wait for same green arrow to appear, then execute the following commands to set up Code Server for the first time and disable the unnecessary authentication:

```shell
   systemctl --user enable --now code-server
   sed -i.bak 's/auth: password/auth: none/' ~/.config/code-server/config.yaml
```

You can now start Code Server. Logging in with the first command in this section and running the following line is the only thing you have to do from now on to get Code Server running, the previous setup instructions are only necessary for the first time.

```shell
   systemctl --user restart code-server
```

1. You can now open `localhost:8080` to see VS Code running in your browser.
<!-- markdownlint-disable MD044 -->
1. Click the first icon in the left sidebar, and select **File** -> **Open..**. That brings up a new menu where you can select **gdk** -> **gitlab**. Here you can now switch branches, make changes that will directly be displayed in the cloud GDK and commit any changes you made.
<!-- markdownlint-enable MD044 -->

🎉 This is everything you needed to review and develop in the cloud GDK from now on! 🦊

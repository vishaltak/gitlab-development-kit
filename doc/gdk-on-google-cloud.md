# Deploying the GDK in the Google Cloud

## Preparations

1. Make sure you have a [Google Cloud](console.cloud.google.com/) account.
1. [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos) on your machine
1. Create and new project in gcloud. A new project ensures you are not inheriting any vulnerable configurations, such as wide-open firewall rules. The project name has to be unique across all Google Cloud projects for all users, so you might have to try multiple times.

```shell
   gcloud projects create YOUR_NEW_PROJECT_NAME
```

1. Now you have to make sure to use that new project as default target for any commands you are going to run.

```shell
   gcloud config set project YOUR_NEW_PROJECT_NAME
```

## Creating the Virtual Machine

Create a virtual machine with the GDK image. It is possible that this fails with an error message that billing is not enabled for that project, in that case visit https://console.cloud.google.com/billing/linkedaccount?project=YOUR_NEW_PROJECT_NAME, link a billing acount to this project and run the command again.

```shell
   gcloud compute instances create gdk --machine-type n1-standard-4 --no-service-account --no-scopes --image-project gdk-cloud --image gitlab-gdk-master-1598444035
```

Confirm that a VM got created by checking the overview of your [Virtual Machine Instances](https://console.cloud.google.com/compute/instances).

## Running the GDK

You can now start your Virtual Machine:

```shell
   gcloud compute instances start gdk
```

Now log into your Virtual Machine and forward the port the GDK is running on in the cloud to your local machine. To do so, enter the following command in the terminal on your own machine and follow the instructions to create your SSH key file:

<!-- markdownlint-disable MD044 -->
```shell
   gcloud compute config-ssh
   gcloud compute ssh gdk@gdk -- -L 3000:localhost:3000
```
<!-- markdownlint-enable MD044 -->

As soon as you see a green arrow on a new line, you are logged in. You can now start the GDK as usual:

```shell
   cd gdk
   gdk start
```

If you visit the familiar `localhost:3000` you should now see the familiar 502 page, if not just wait a couple of seconds and reload the page. Wait 1-2 minutes while the 502 page reloads itself multiple times, and you will (hopefully) see the login screen to your GDK 🎉. In case you see a 504 Gateway Timeout message or an error message that the "Request ran for longer than 60000ms", reloading the page 1-2 more times should fix it.

**IMPORTANT:** While your Virtual Machine is running, it costs money. When you are done working on the GDK, first leave the SSH environment by typing `exit` into the terminal, followed by **Control + c** and then execute the following command:

```shell
   gcloud compute instances stop gdk
```

Any time you need it to work with the GDK again, you can follow only the instructions in this section (Running the GDK).

## Making changes to the code 

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

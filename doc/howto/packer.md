# Using Google Cloud images to developer with GDK

## Building the image

1. Make sure you have a Google Cloud account
1. Create and new project in gcloud and take note of the project id for later steps
1. Download your `account.json` credentials from your gcloud account and put it inside the GDK `packer` folder.
1. [Install Packer](https://learn.hashicorp.com/tutorials/packer/getting-started-install)
1. Find out which gcloud region is best for you with [gcping](http://www.gcping.com/), then select a zone within that region (from [Google Cloud Docs](https://cloud.google.com/compute/docs/regions-zones)). For example, if the region is `australia-southeast1`, a suitable zone would be `australia-southeast1-b`.
1. `cd` into your GDK `packer` directory and run:

   ```shell
      cd gdk/packer
      packer build -var zone=<zone_id> project_id=<gcloud_project_id> base-stack.json
   ```

This should take a while to build (10-30 min). If successfull, you should see an output indicating the created image name.

### Using the image

To use the image, you need the following steps:

1. Go to your Google Cloud project settings and select the option to run a new VM instance.
1. Select the machine type. Recommended for running everything including specs is n1-standard-4 with 15GB memory.
1. Select the newly created image as you base image.
1. Tick "allow http and https" option if you want HTTP access.
1. Again, select the zone closest to you for speedy access.

Boot the image and you should be able to log in via SSH with your user.

### Caveats

GDK is hosted under the `gdk` user. You're tipically loging in into the machine with your personal user so it's recommended that you install
your SSH keys under the `gdk` user and login into the box directly as the `gdk` user.

```shell
sudo su - gdk
echo YOUR_SSH_PUB_KEY >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
```

### Making the image public and sharing

You can turn your image public for sharing like so:

```shell
gcloud compute images add-iam-policy-binding IMAGE_NAME_HERE --project PROJECT_NAME_HERE --member='allAuthenticatedUsers' --role='roles/compute.imageUser'
```

This will allow anyone to create an instance with the newly created image like so:

```shell
gcloud compute instances create INSTANCE_NAME_HERE --image-project gdk-cloud --image CREATED_IMAGE_ID
```

# AWS EKS Configuration

This page describes obtaining resources for local testing of GitLab's EKS support
with the GDK:

* Configured with less privileged credentials in the GDK
* Fewer steps than the complete EKS configuration

## Prerequisites (For GitLab team members only)

IMPORTANT: These steps are currently only applicable to GitLab team members as it
depends on our corporate resources. For non-GitLab employees, follow the
standard instructions in the documentation.

### "AWS (support/staging)" User Account

The rest of these instructions refer to the AWS environment identified as
"AWS (support/staging)" in the Tech Stack spreadsheet.

1. Request an account in the "AWS (support/staging)" account by
  [creating an access request](https://gitlab.com/gitlab-com/access-requests/issues/new?issuable_template=Single%20Person%20Access%20Request).

   You need to request:

   - [ ] AWS (support/staging): `development and testing of EKS related features with the GDK`

2. Once provisioned, visit the IAM configuration under `IAM -> Users`, find your your account,
   and enable a multi-factor authentication (MFA) method.

### `gitlab-eks-provisioner` Credentials

Within the AWS (support/staging) account, there is a `gitlab-eks-provisioner` IAM user
that has already been created as follows:

 * Programmatic access
 * has been granted access to assume any role whose name starts with `gitlab-eks-`, using
   a policy similar to the one listed [for self-managed instances](https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html#additional-requirements-for-self-managed-instances).

You will need the account ID, access key ID, and secret access key which can be
found in the GitLab Team 1password vault.

## Enabling EKS and Creating Clusters

### Enable EKS Integration

To enable the EKS integration within your GDK instance, follow the [steps
outlined for self-managed instances](https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html#additional-requirements-for-self-managed-instances) and use the
`AWS gitlab-eks-provisioner` credentials found within 1Password.

### Creating a new AWS EKS Cluster

When creating a new EKS cluster in a group or project, use the following values when completing
step 4 of [Creating the cluster on EKS](https://docs.gitlab.com/ee/user/project/clusters/add_eks_clusters.html#new-eks-cluster)

1. Skip to step 12. The `gitlab-eks-policy` should already exist in the project.
1. For policy name (step 12), choose `gitlab-eks-policy`.
1. Format your role name as follows: `gitlab-eks-[name]` with `[name]` being
   your `gitlab.com` handle.

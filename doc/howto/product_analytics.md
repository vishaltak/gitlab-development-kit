# Product Analytics

[Product Analytics](https://docs.gitlab.com/ee/user/product_analytics/) must be run locally in conjunction with the [Product Analytics DevKit](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit).

## Setup

### Prerequisites

- Your GDK instance must have an active license for GitLab Premium or Ultimate.
- You must have Docker (or equivalent) on your machine.
- You will need access to the `Engineering` password vault
- Your GDK [simulates a SaaS instance](https://docs.gitlab.com/ee/development/ee_features.html#simulate-a-saas-instance).

### One-line setup

To automatically set up Product Analytics, in your `gitlab` directory run the following command:

```shell
# You can replace gitlab-org with the group name you want to enable Product Analytics on.
RAILS_ENV=development bundle exec rake gitlab:product_analytics:setup\['gitlab-org'\]
```

After running the command [set up the DevKit](#set-up-the-product-analytics-devkit) if you haven't already done so.

### Manual setup

1. Enable the required [feature flags](#feature-flags).
1. Run GDK in [SaaS mode](https://docs.gitlab.com/ee/development/ee_features.html#simulate-a-saas-instance) with an Ultimate license.
1. Set the **Ultimate** plan on your test group.
1. Enable Experiment & Beta features on your test group.

    1. Go to **Settings > General**.
    1. Expand **Permissions and group features**.
    1. Enable **Experiment & Beta features** and **Product analytics**.
    1. Select **Save changes**.

1. [Set up the DevKit](#set-up-the-product-analytics-devkit) and connect it to your GDK.

Once set up you can follow the [instructions](#view-product-analytics-dashboards) below on how to view the product analytics dashboards.

### Feature flags

Product analytics features are behind feature flags and must be enabled to use them in GDK.

- To make the product analytics checkbox visible in the root group settings, run:

  ```shell
  echo "Feature.enable(:product_analytics_beta_optin)" | gdk rails c
  ```

- To enable product analytics and make the dashboards available, run:

  ```shell
  echo "Feature.enable(:product_analytics_dashboards)" | gdk rails c
  ```

- To enable product analytics settings and make them visible, run:

  ```shell
  echo "Feature.enable(:product_analytics_admin_settings)" | gdk rails c
  ```

- To enable the project menu item and make it visible, run:

  ```shell
  echo "Feature.enable(:combined_analytics_dashboards)" | gdk rails c
  ```

### Set up the Product Analytics DevKit

1. Follow the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit) to set up the Product Analytics DevKit on your machine.
1. Continue following the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#connecting-gdk-to-your-devkit) to connect the GDK to the Product Analytics DevKit.

### View Product Analytics dashboards

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find the project set up in the previous
   section.
1. On the left sidebar, select **Analyze > Analytics dashboards**.

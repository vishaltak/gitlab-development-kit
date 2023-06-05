# Product Analytics

[Product Analytics](https://docs.gitlab.com/ee/user/product_analytics/) must be run locally in conjunction with the [Product Analytics DevKit](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit).

## Setup

### Prerequisites

- Your GDK instance must have an active license for GitLab Premium or Ultimate.
- You must have Docker (or equivalent) on your machine.

### Feature flags

Product analytics features are behind feature flags and must be enabled to use them in GDK.

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

- To enable Snowplow support, first [set up Snowplow instead of Jitsu](#set-up-snowplow-instead-of-jitsu) and then run:

  ```shell
  echo "Feature.enable(:product_analytics_snowplow_support)" | gdk rails c
  ```

- To enable the dashboard and visualization editors and make the editors visible, run:

  ```shell
  echo "Feature.enable(:combined_analytics_dashboards_editor)" | gdk rails c
  ```

  The editors are not compatible with Snowplow and should only be enabled with Snowplow for testing purposes.

### Set up the Product Analytics DevKit

1. Follow the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit) to set up the Product Analytics DevKit on your machine.
1. Continue following the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#connecting-gdk-to-your-devkit) to connect the GDK to the Product Analytics DevKit.

#### Set up Snowplow instead of Jitsu

If you have the `product_analytics_snowplow_support` feature flag enabled, you must set up your Product Analytics DevKit to use
[Snowplow instead of Jitsu](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#snowplow-instead-of-jitsu-work-in-progress).

### View Product Analytics dashboards

1. On the top bar, select **Main menu > Projects** and find the project set up in the previous section.
1. On the left sidebar, select **Analytics > Dashboards**.

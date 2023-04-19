# Product Analytics

[Product Analytics](https://docs.gitlab.com/ee/user/product_analytics/) must be run locally in conjunction with the [Product Analytics DevKit](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit).

## Setup

### Prerequisites

- Your GDK instance must have an active license for GitLab Premium or Ultimate.
- You must have Docker (or equivalent) on your machine.

### Feature flags

Product Analytics is currently behind the `product_analytics_dashboards` feature flag.

To enable the feature flag and make the dashboards available, run: `echo "Feature.enable(:product_analytics_dashboards)" | gdk rails c`.

The product analytics settings under admin settings is currently behind the `product_analytics_admin_settings` feature flag.

To enable the feature flag and make the settings visible, run: `echo "Feature.enable(:product_analytics_admin_settings)" | gdk rails c`.

The project menu item is currently behind the `combined_analytics_dashboards` feature flag.

To enable the feature flag and make the menu item visible, run: `echo "Feature.enable(:combined_analytics_dashboards)" | gdk rails c`.

The snowplow support is currently behind the `product_analytics_snowplow_support` feature flag.

To enable the feature flag and make the menu item visible, run: `echo "Feature.enable(:product_analytics_snowplow_support)" | gdk rails c`.

### Set up the Product Analytics DevKit

- Follow the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit) to set up the Product Analytics DevKit on your machine.
- Continue following the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#connecting-gdk-to-your-devkit) to connect the GDK to the Product Analytics DevKit.

### View Product Analytics dashboards

1. On the top bar, select **Main menu > Projects** and find the project set up in the previous section.
1. On the left sidebar, select **Analytics > Dashboards**.

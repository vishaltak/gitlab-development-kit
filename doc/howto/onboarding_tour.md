# How to work on OnBoarding Tour...

Since this feature is behind a feature flag and uses `Gitlab CE` as the demo project in production, there are a few steps required in order to get this working locally.

1. Enable feature flag via `rails console`:

```ruby
Feature.enable(:user_onboarding)
```

2. Make sure to change `get_onboarding_demo_project` in `onboarding_controller.rb` to the following:

```ruby
def get_onboarding_demo_project
  Project.find_by_full_path("gitlab-org/gitlab-test")
end
````

Also, change `user_onboarding_enabled?` in `ee/app/helpers/ee/application_helper.rb` to the following:

```ruby
def user_onboarding_enabled?
  ::Feature.enabled?(:user_onboarding)
end
```

For local testing, if you want the onboarding to automatically appear for new users (that have no projects and have not previously dismissed the onboarding), the following patch needs to be made:

`ee/app/controllers/ee/dashboard/projects_controller.rb`

```
def show_onboarding_welcome_page?
- return false unless ::Gitlab.com?
  return false if cookies['onboarding_dismissed'] == 'true'

  ::Feature.enabled?(:user_onboarding) && !show_projects?(projects, params)
end
```

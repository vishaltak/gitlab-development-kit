# How to set up MailRoom and Service Desk

Service Desk requires [EE Licence](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses).

## Using webhooks

1. Stop any running GDK services.
1. Upgrade MailRoom gem to the [latest version](https://rubygems.org/gems/gitlab-mail_room/) in `/gitlab/Gemfile`.
1. For [historical reasons](https://docs.gitlab.com/ee/development/emails.html#mailroom-gem-updates), `gitlab-mail_room`
   is kept at version `0.0.9` in the `Gemfile`. Upgrade MailRoom gem to the
   [latest version](https://rubygems.org/gems/gitlab-mail_room/) in `<gdk_root>/gitlab/Gemfile`. For example:

   ```diff
   -gem 'gitlab-mail_room', '~> 0.0.9', require: 'mail_room'
   +gem 'gitlab-mail_room', '~> 0.0.21', require: 'mail_room'
   ```

   In the `<gdk_root>/gitlab/` directory:
   
   ```shell
   bundle install
   ```

1. Generate a secret file for MailRoom. For example:

   ```shell
   echo $( ruby -rsecurerandom -e "puts SecureRandom.base64(32)" ) > ~/.gitlab-mailroom-secret
   ```

1. (Optional) Using a new Gmail account for testing purposes is recommended. If using Gmail, create an
   [App Password](https://support.google.com/accounts/answer/185833). Store this password securely and use it as an
   environment variable.
1. Set [incoming_email](https://docs.gitlab.com/ee/administration/incoming_email.html) and
   [service_desk_email](https://docs.gitlab.com/ee/user/project/service_desk.html#using-a-custom-email-address)
   configuration to point to an email inbox.

   ```yaml
   incoming_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "personal-email@gmail.com"
     password: "<app password>"
     delivery_method: webhook
     gitlab_url: <gdk url>
     secret_file: ~/.gitlab-mailroom-secret

   service_desk_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "personal-email@gmail.com"
     password: "<app password>"
     delivery_method: webhook
     gitlab_url: <gdk url>
     secret_file: ~/.gitlab-mailroom-secret
   ```

1. Restart all services.
1. Start MailRoom in a console with the following command:

   ```shell
   bundle exec mail_room -c ./config/mail_room.yml
   ```

After configuring services test:

1. On the top bar, select **Main menu > Projects** and find a project configured with Service Desk.
1. Compose an email to send to the email address set in the Service Desk settings page.
1. Check that an issue is created on the Service Desk issue board.

NOTE:
GDK is by default not prepared to send emails using SMTP, which only applies to production mode. In development mode,
GDK uses `letter_opener_web` to show sent messages in a web interface under
`http://<gdk_host>:<gdk_port>/rails/letter_opener`. [How can I send notification emails via SMTP?](email.md)

## Using Sidekiq

1. Stop any running GDK services.
1. Upgrade MailRoom gem to the [latest version](https://rubygems.org/gems/gitlab-mail_room/) in `/gitlab/Gemfile`.
1. For [historical reasons](https://docs.gitlab.com/ee/development/emails.html#mailroom-gem-updates), `gitlab-mail_room`
   is kept at version `0.0.9` in the `Gemfile`. Upgrade MailRoom gem to the
   [latest version](https://rubygems.org/gems/gitlab-mail_room/) in `<gdk_root>/gitlab/Gemfile`. For example:

   ```diff
   -gem 'gitlab-mail_room', '~> 0.0.9', require: 'mail_room'
   +gem 'gitlab-mail_room', '~> 0.0.21', require: 'mail_room'
   ```
   
   In the `<gdk_root>/gitlab/` directory:

   ```shell
   bundle install
   ```

1. (Optional) Using a new Gmail account for testing purposes is recommended. If using Gmail, create an
   [App Password](https://support.google.com/accounts/answer/185833). Store this password securely and use it as an
   environment variable.
1. Set [incoming_email](https://docs.gitlab.com/ee/administration/incoming_email.html) and
   [service_desk_email](https://docs.gitlab.com/ee/user/project/service_desk.html#using-a-custom-email-address)
   configuration to point to an email inbox. 
   In the `development:` section of `gitlab/config/gitlab.yml` add:

   ```yaml
   incoming_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "personal-email@gmail.com"
     password: "<app password>"
     gitlab_url: <gdk url>

   service_desk_email:
     enabled: true
     address: "personal-email+%{key}@gmail.com"
     user: "personal-email@gmail.com"
     password: "<app password>"
     gitlab_url: <gdk url>
   ```

1. Restart all services.
1. Start MailRoom in a console with the following command:

   ```shell
   bundle exec mail_room -c ./config/mail_room.yml
   ```

After configuring services test:

1. On the top bar, select **Main menu > Projects** and find a project configured with Service Desk.
1. Compose an email to send to the email address set in the Service Desk settings page.
1. Check that an issue is created on the Service Desk issue board.

NOTE:
GDK is by default not prepared to send emails using SMTP, which only applies to production mode. In development mode,
GDK uses `letter_opener_web` to show sent messages in a web interface under
`http://<gdk_host>:<gdk_port>/rails/letter_opener`. [How can I send notification emails via SMTP?](email.md)

## Troubleshooting

If you have problems with issues not being created from email:

1. Tail the MailRoom logs with the following command:

   ```shell
   tail -f <gdk_root>/log/mail_room_json.log
   ```

1. Watch the MailRoom logs and ensure that the email is handled. There should be a log file stating that the email
   content is delivered using a webhook (_postback_ in MailRoom terminology).
1. Verify that the Rails web server receives a `POST` request sent to `/api/v4/internal/mail_room/incoming_email`.
1. Verify that a job of `EmailReceiverWorker` is received and handled by Sidekiq.

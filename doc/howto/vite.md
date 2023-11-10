# Enable Vite instead of Webpack

Vite has been merged into GitLab as part of the [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129392)

To enable `vite` locally

1. Run `echo "Feature.enable(:vite)" | gdk rails c`
1. Launch `bundle exec vite dev`
1. Restart GDK: `gdk restart`

## What's next?

Please share your experience in these issues, this is very important for further Vite evaluation in GitLab:

- [Vite developer experience feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/423851)
- [Vite integration issues](https://gitlab.com/gitlab-org/gitlab/-/issues/423850)

Do report any bugs and developer experience struggles you’re having.

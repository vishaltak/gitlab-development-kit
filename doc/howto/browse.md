# Browse your development GitLab server

If you just want to browse your local GitLab installation this is the
quickest way to do it.

```shell
cd gitlab-development-kit
gdk start
```

Open [localhost:3000](http://localhost:3000) in your web browser. It
may take a few seconds for GitLab to boot in development mode. Once
the sign-in page is there, log in with user `root` and password
you can get it by running from your GitLab root folder: `cat .root_password`.

You can shut down GDK in your terminal with `gdk stop`.

# Debugging with Pry

[Pry](https://pryrepl.org/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop in the magic word `binding.pry` into your
code.

When running tests, Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec` etc.).

If you want to get a debugging prompt while browsing on your local
development server (localhost:3000), you should use `binding.pry_shell` instead.

You can then connect to this session by running `pry-shell` in your terminal. See
[Pry debugging docs](https://docs.gitlab.com/ee/development/pry_debugging.html)
for more usage.

## Run a web server in the foreground

An alternative to `binding.pry_shell` is to run your Rails web server Puma in
the foreground.
Start by kicking off the normal GDK processes via `gdk start`. Then open a new
terminal session and run:

```shell
gdk stop rails-web && GITLAB_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true gdk rails s
```

This starts a single mode Puma server in the foreground with only one thread. Once the
`binding.pry` breakpoint has been reached, Pry prompts appear in the window
that runs `gdk rails s`.

When you have finished debugging, remove the `binding.pry` breakpoint and go
back to using Puma in the background. Terminate `gdk rails s` by pressing Ctrl-C
and run `gdk start rails-web`.

NOTE:
It's not possible to submit commits from the web without at least two Puma server
threads running. This means when running Puma in the foreground for debugging,
actions such as creating a file from the web time out.

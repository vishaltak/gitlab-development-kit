#!/bin/sh
# begin gdk managed content
# This script is injected into the lefthook pre-push script by GDK.

# https://git-scm.com/docs/githooks#_pre_push
# Information about what is to be pushed is provided on the hook’s standard input with lines of the form:
# <local ref> SP <local object name> SP <remote ref> SP <remote object name> LF
remote_ref="$(cat - | cut -d ' ' -f 3)"

if [ "$remote_ref" = "refs/heads/master" ]; then
  # We are currently doing a push to master.
  # Either we are syncing a fork, or mistakenly doing a push to canonical
  # (which will result in remote rejecting the push).
  # Either way, we don't need to run lefthook checks here.
  exit 0
fi

# end gdk managed content

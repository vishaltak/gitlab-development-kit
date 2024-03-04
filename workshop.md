## Challenge #1: Fix broken GDK

## Challenge #2: Make `gdk doctor` detect missing Redis version

:warning: This is a draft.

### Before you start

1. `asdf uninstall redis 7.0.14`
1. `gdk restart`
1. `gdk doctor`

Expected Result: `gdk doctor` detects missing Redis version, then suggests that the user installs the updated version. 

Actual Result: <TODO>.

### Hints 

1. `gdk tail redis`
   1. `fatal: unable to run: redis-server: file does not exist`
1. `gdk redis-cli` 
   1.  `No such file or directory - redis-cli`
1. `GDK::Command::Doctor > GDK::Diagnostic  > StaleServices`

## Challenge #3: Add AI Gateway as a new service

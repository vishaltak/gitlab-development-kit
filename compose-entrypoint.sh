#!/bin/sh

# chown the bind mounts
sudo chown gdk:gdk gitlab gitlab-workhorse go-gitlab-shell gitaly

if [ -f gitlab/.gdk-installed ]; then
	make symlink-gitlab-shell
	make Procfile && gdk run
else
	gdk install && touch gitlab/.gdk-installed
	pkill -9 -f node
	gdk run
fi

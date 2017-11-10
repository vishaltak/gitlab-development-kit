#!/bin/sh

if [ -f gitlab/.gdk-installed ]; then
	make symlink-gitlab-shell
	make Procfile && gdk run
else
	gdk install && touch gitlab/.gdk-installed
	pkill -9 -f node
	gdk run
fi

#!/bin/sh

if [ -f gitlab/.gdk-installed ]; then
	gdk run
else
	gdk install && pkill -9 -f node && touch gitlab/.gdk-installed
	gdk run
fi

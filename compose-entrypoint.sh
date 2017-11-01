#!/bin/sh

if [ -f gitlab/.gdk-installed ]; then
	gdk run
else
	gdk install && touch gitlab/.gdk-installed && pkill node && gdk run
fi

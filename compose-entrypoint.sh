#!/bin/sh

if [ -f .gdk-installed ]; then
	gdk run
else
	gdk install
	touch .gdk-installed
fi

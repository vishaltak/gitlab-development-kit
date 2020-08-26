#!/bin/bash -e

rbenv local 2.6.6
gem install bundler -v '= 1.17.3'
gem install gitlab-development-kit
gdk init gdk
cd gdk
cp /tmp/gdk.yml .
gdk install
gdk stop
sleep 10
gdk start postgresql
sleep 10
cp /tmp/Gitlab.gitlab-license ./gitlab/config/Gitlab.gitlab-license
cd gitlab && bundle exec rake gitlab:license:load --trace
gdk stop

# enable-guest-attributes = TRUE
# gdk-hostname = gdk.test
# curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/foobar"  -H "Metadata-Flavor: Google"

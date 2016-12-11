FROM ruby:2.3.3-alpine
MAINTAINER hrvoje.marjanovic@gmail.com


# rest of gitlab requirements

# sudo nodejs npm
# libpq-dev ed pkg-config

RUN apk add --no-cache bash git make build-base krb5-dev
RUN adduser -S gdk

RUN apk add --no-cache icu-dev

RUN apk add --no-cache postgresql-dev

RUN apk add --no-cache cmake

RUN apk add --no-cache linux-headers

RUN apk add --no-cache sudo nodejs

USER gdk

ENV BUNDLE_PATH="/gitlab-development-kit/.bundle"
WORKDIR /gitlab-development-kit


FROM elixir:1.5.1
MAINTAINER Noel del Castillo <noel@pragtechnologies.com>

ENV REPLACE_OS_VARS=true SHELL=/bin/bash
ENV DEBIAN_FRONTEND noninteractive
ENV NODE_VERSION 7

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
RUN apt-get install -y apt-utils nodejs imagemagick inotify-tools wkhtmltopdf erlang-xmerl

RUN mkdir -p /app
WORKDIR /app

COPY . /app

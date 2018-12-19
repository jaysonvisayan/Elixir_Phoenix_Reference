FROM elixir:1.4.4
MAINTAINER Noel del Castillo <noel@pragtechnologies.com>

ENV DEBIAN_FRONTEND noninteractive
ENV MIX_ENV test

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mkdir -p /app

COPY . /app

WORKDIR /app

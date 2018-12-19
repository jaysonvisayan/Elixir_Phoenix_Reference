#!/bin/bash

# printenv
mix deps.get
mix compile

MIX_ENV=build mix ecto.create
MIX_ENV=build mix ecto.migrate

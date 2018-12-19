#!/bin/bash

mix deps.get
mix compile

MIX_ENV=build mix ecto.reset

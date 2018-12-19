#!/bin/bash

mix deps.get
mix compile

MIX_ENV=test mix ecto.setup-no-seed
mix test

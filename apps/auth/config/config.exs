# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :auth,
  namespace: Auth

# Configures the endpoint
config :auth, AuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bXlSaS/rZ9DVbGFLVeUMInxjNcR6b532nFZyMKXy6OLmSuyxUyP7oHF97KqdRFVk",
  render_errors: [view: AuthWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Auth.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :auth, Auth.Guardian,
  issuer: "Medilink", # Name of your app/company/product
  secret_key: "cEvGfuWpCI+Uwnol9F82KcIevi35bKGCtKXRVOA52e6Hx3dfTbWifAFpgJh4igJh"

import_config "#{Mix.env}.exs"

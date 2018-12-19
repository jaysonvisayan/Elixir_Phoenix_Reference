# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :worker,
  namespace: Worker

# Configures the endpoint
config :worker, WorkerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "li3TQ2I80bAqHiCnYKH1dK+/S+I5511mXOCAmtEwd4yT5B567v8XOb8zPK3j2uQI",
  render_errors: [view: WorkerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Worker.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

#Bamboo
# config :worker, Innerpeace.Worker.Mailer,
#   adapter: Bamboo.SendgridAdapter,
#   api_key: "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"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

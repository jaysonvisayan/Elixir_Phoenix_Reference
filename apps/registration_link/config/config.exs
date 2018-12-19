# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :registration_link,
  namespace: RegistrationLink,
  ecto_repos: [Innerpeace.Db.Repo]

# Configures the endpoint
config :registration_link, RegistrationLinkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HsnsYhsOSr3+tJZ8/e75lNXbsNpGw/2eSkeZADXGOwo5uvcw3mx7FsIIfs1dRZJK",
  render_errors: [view: RegistrationLinkWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RegistrationLink.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Guardian
config :registration_link, RegistrationLink.Guardian,
  hooks: GuardianDb,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "RegistrationLink",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true, # optional
  secret_key: "TC0uFk5Py16FzTjzSp1NyNva/9kYL5iTbdGn2ivvSTM60YvNw2zw3LAmElJjrYuW"

# GuardianDB
config :guardian_db, GuardianDb,
  repo: Innerpeace.Db.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

config :registration_link, env: Mix.env

config :registration_link, :permission, RegistrationLinkWeb.Permission.Session
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :account_link,
  namespace: AccountLink,
  ecto_repos: [Innerpeace.Db.Repo]

# Configures the endpoint
config :account_link, AccountLinkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bklegDfac9NmGpzpJVj8ybztJ5U/wEhHeO42x9xcQW6IbYBhEZ+PkGIdSWI4Xpzm",
  render_errors: [view: AccountLinkWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AccountLink.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Guardian
config :account_link, AccountLink.Guardian,
  hooks: GuardianDb,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "AccountLink",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true, # optional
  secret_key: "a2nSAkH7s48aYs4DXEcDfonjPcOqIO1drmQfZkqUTb7AW1teaXDsPK3u0OBqvmn2"

# GuardianDB
config :guardian_db, GuardianDb,
  repo: Innerpeace.Db.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

#Bamboo
config :account_link, Innerpeace.AccountLink.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: "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"

config :account_link, env: Mix.env

config :account_link, AccountLinkWeb.Gettext,
  locales: ~w(en zh)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

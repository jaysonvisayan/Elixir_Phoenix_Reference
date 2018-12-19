# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :member_link,
  namespace: MemberLink
  # ecto_repos: [Innerpeace.Db.Repo]

# Configures the endpoint
config :member_link, MemberLinkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xt+WhZM4+CHam+i6lWtHobY+CANL3GKXZtSYCaI4Grzaw5c7ZT/7Vh8CyGPOrKZY",
  render_errors: [view: MemberLinkWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MemberLink.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Guardian
config :member_link, MemberLink.Guardian,
  hooks: GuardianDb,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "MemberLink",
  ttl: {30, :days},
  allowed_drift: 2000,
  verify_issuer: true, # optional
  secret_key: "ZmfRPGD1eDjRUnWh0VeoyHcWAjGcCB6/idEWdBPVFj4nQKjxD0EHN6L3eAuCXwjR"

# GuardianDB
config :guardian_db, GuardianDb,
  repo: Innerpeace.Db.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

# Bamboo
config :member_link, Innerpeace.MemberLink.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: "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"

config :member_link, env: Mix.env

config :member_link, MemberLinkWeb.Gettext,
  locales: ~w(en zh)
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

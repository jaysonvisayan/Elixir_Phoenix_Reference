use Mix.Config

config :db, env: Mix.env

config :db,
  ecto_repos: [Innerpeace.Db.Repo]

config :db, arc_storage: :local

config :db, Innerpeace.Db.Hydra,
  private_link: "http://localhost:9000",
  public_link: "http://localhost:9000"

config :oauth2,
  serializers: %{
    "application/vnd.api+json" => Poison
  }

import_config "#{Mix.env}.exs"

config :db, Innerpeace.Db.Repo,
  ownership_timeout: 60_000

# config :db, Innerpeace.Db.Utilities.SMS,
#   cached: false,
#   infobip_username: "Equicom",
#   infobip_password: "TA031417ecsPH",
#   sms_cached: false

use Mix.Config

config :db, Innerpeace.Db.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USER") || "${DB_USER}",
  password: System.get_env("DB_PASSWORD") || "${DB_PASSWORD}",
  database: System.get_env("DB_NAME") || "${DB_NAME}",
  hostname: System.get_env("DB_HOST") || "${DB_HOST}",
  pool_size: System.get_env("DB_POOL") || "${DB_POOL}",
  pool_timeout: 15_000,
  timeout: 15_000

# Set to AWS
config :db, arc_storage: :s3
config :arc,
  storage: Arc.Storage.S3,
  bucket: "${S3_BUCKET}",
  asset_host: "${S3_HOST}"

config :ex_aws,
  access_key_id: "${ACCESS_KEY}",
  secret_access_key: "${ACCESS_SECRET}",
  region: "ap-southeast-1",
  s3: [
    scheme: "https://",
    host: "s3.ap-southeast-1.amazonaws.com",
    region: "ap-southeast-1"
  ],
  recv_timeout: 60_000

config :db, Innerpeace.Db.Hydra,
  private_link: "${HYDRA_PRIVATE}",
  public_link: "${HYDRA_PUBLIC}"

config :db, Innerpeace.Db.Utilities.SMS,
  infobip_username: "${SMS_USERNAME}",
  infobip_password: "${SMS_PASSWORD}",
  sms_cached: "${SMS_CACHED}"

config :db, Innerpeace.Db.Base.Api.UtilityContext,
credentials: %{
  username: "${SAP_USERNAME}",
  password: "${SAP_PASSWORD}",
  url: "${SAP_URL}"
}

# K8 Configs
# config :db, Innerpeace.Db.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "${DB_USER}",
#   password: "${DB_PASSWORD}",
#   database: "${DB_NAME}",
#   hostname: "${DB_HOST}",
#   pool_size: 10

# config :db, arc_storage: :s3

# config :arc,
#   storage: Arc.Storage.S3,
#   bucket: "innerpeace-payorlink-staging",
#   asset_host: "https://s3-ap-southeast-1.amazonaws.com/innerpeace-payorlink-staging"

# config :ex_aws,
#   access_key_id: "AKIAIUTN55IQTZC7DL6A",
#   secret_access_key: "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",
#   region: "ap-southeast-1"

# elixir-pdf-generator config
# config :pdf_generator,
#     command_prefix: "/usr/bin/xvfb-run"

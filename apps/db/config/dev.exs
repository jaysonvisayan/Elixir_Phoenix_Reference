
use Mix.Config

# Configure MariaDB
# config :db, Innerpeace.Db.Repo,
#   adapter: Ecto.Adapters.MySQL,
#   username: System.get_env("DB_USER") || "root",
#   password: System.get_env("DB_PASSWORD") || "p@ssw0rd",
#   database: System.get_env("DB_NAME") || "innerpeace_umbrella_dev",
#   hostname: System.get_env("DB_HOST") || "localhost",
#   pool_size: 10

# Configure PostgreDb
config :db, Innerpeace.Db.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USER") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  database: System.get_env("DB_NAME") || "payorlink_dev",
  hostname: System.get_env("DB_HOST") || "localhost",
  pool_size: 10

# IST Db
# config :db, Innerpeace.Db.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "payorlink_ist",
#   hostname: "172.16.45.21",
#   pool_size: 10

# UAT Db
# config :db, Innerpeace.Db.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "payorlink_uat",
#   hostname: "172.16.45.11",
#   pool_size: 10

# Migration Db
 # config :db, Innerpeace.Db.Repo,
 #   adapter: Ecto.Adapters.Postgres,
 #   username: "postgres",
 #   password: "postgres",
 #   database: "payorlink_migration",
 #   hostname: "172.16.20.181",
 #   pool_size: 10

# config :payor_link, Innerpeace.Db.Utilities.SMS,
#   proxy: {"172.16.252.23", 3128}


# Set to local
config :db, arc_storage: :local

config :db, hydra: "http://localhost:9000"

config :db, Innerpeace.Db.Utilities.SMS,
  infobip_username: "Equicom",
  infobip_password: "TA031417ecsPH",
  sms_cached: "false",
  proxy: {"172.16.252.23", 3128}

config :db, Innerpeace.Db.Base.Api.UtilityContext,
credentials: %{
  username: "jake.garrido",
  password: "P@ssw0rd",
  url: "https://my331886.crm.ondemand.com/sap/c4c/odata/v1/c4codata/ServiceRequestCollection/"
}



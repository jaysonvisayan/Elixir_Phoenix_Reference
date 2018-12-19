use Mix.Config

# Configure PostgreDB
config :db, Innerpeace.Db.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: System.get_env("POSTGRES_NAME") || "payorlink_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :db, Innerpeace.Db.Utilities.SMS,
  cached: true,
  infobip_username: "Equicom",
  infobip_password: "TA031417ecsPH",
  sms_cached: "true",
  proxy: {"172.16.252.23", 3128}

## worker
config :exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  queues: [
    {"member_activation_job", 3},
    {"benefit_migration_job", 3},
    {"product_migration_job", 3},
    {"account_migration_job", 3},
    {"member_migration_job", 3},
    {"member_existing_migration_job", 3},
    {"benefit_batch_migration_job", 3},
    {"product_batch_migration_job", 3},
    {"member_batch_migration_job", 3},
    {"member_batch_existing_migration_job", 3},
    {"create_member_job", 20},
    {"create_member_existing_job", 20},
    {"create_benefit_job", 10},
    {"create_product_job", 10},
    {"create_account_job", 10},
    {"notification_job", 3},
    {"acu_schedule_member_job", 15},
    {"availed_loa_job", 10},
    {"forfeited_loa_status_job", 4},
    {"member_batch_migration_job", 5},
    {"balancing_file_job", 1},
    {"trigger_generate_claims_file_job", 1},
    {"generate_claims_file_job", 1},
    {"update_migrated_claim_job", 10},
    {"account_single_migration_job", 3},
    {"member_batch_upload_job", 10},
    {"member_parser_job", 20},
    {"job_checker", 10},
    {"generate_member_card_no_job", 50}
  ],
  scheduler_enable: true,
  max_retries: 0,
  mode: :default

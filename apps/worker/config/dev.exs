use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :worker, WorkerWeb.Endpoint,
  http: [port: 4010],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :worker, WorkerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/worker_web/views/.*(ex)$},
      ~r{lib/worker_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace jamesduring development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

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
    {"check_job_acu_schedules_job", 10},
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
    {"generate_member_card_no_job", 50},
    {"member_with_user_job", 3},
    {"create_member_with_user_job", 15}
  ],
  scheduler_enable: true,
  max_retries: 0,
  mode: :default

# config :worker, Innerpeace.Worker.Mailer,
#     adapter: Bamboo.LocalAdapter

config :exq_ui,
  web_port: 4040,
  web_namespace: "",
  server: true

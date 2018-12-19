use Mix.Config

config :payor_link, Innerpeace.PayorLink.Web.Endpoint,
  load_from_system_env: true,
  cache_static_manifest: "priv/static/cache_manifest.json",
  http: [port: "4001"],
  secret_key_base: "${SECRET_KEY_BASE}",
  url: [host: "${HOST}", port: "4001"], # This is critical for ensuring web-sockets properly authorize.
  server: true,
  root: ".",
  version: Application.spec(:payor_link, :vsn)

config :logger, level: :info

config :pdf_generator,
    command_prefix: "/usr/bin/xvfb-run"

config :sentry,
  dsn: "${SENTRY_DNS}",
  environment_name: String.to_atom("${SENTRY_ENV}"),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{
    env: "${SENTRY_ENV}",
    app_version: "#{Application.spec(:payor_link, :vsn)}"
  },
  included_environments: [:prod, :staging, :uat, :migration, :autotest, :ist, :prod_staging]

# Guardian
config :payor_link, PayorLink.Guardian,
  hooks: Guardian.DB,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "Payorlink 2.0",
  ttl: {10, :days},
  allowed_drift: 2000,
  verify_issuer: true,
  # generated using: JOSE.JWK.generate_key({:oct, 16}) |> JOSE.JWK.to_map |> elem(1)
  secret_key: %{"k" => "${GUARDIAN_KEY}", "kty" => "oct"}

config :exq,
  host: "${REDIS_HOST}",
  port: "${REDIS_PORT}",
  namespace: "exq",
  mode: :enqueuer,
  scheduler_enable: true,
  start_on_application: false

# config :payor_link, Innerpeace.PayorLink.Scheduler,
#   timezone: "Asia/Singapore",
#   global: true,
#   run_strategry: {Quantum.RunStrategy.Random, :cluster},
#   jobs: [
#     {"1 0 * * *", {Innerpeace.Db.Base.MemberContext, :generate_balancing_file, []}},
#     {"10 17 * * *", {Innerpeace.Db.Base.MemberContext, :generate_balancing_file, []}}
#   ]

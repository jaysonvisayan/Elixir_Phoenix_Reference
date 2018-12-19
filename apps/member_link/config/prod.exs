use Mix.Config

config :member_link, MemberLinkWeb.Endpoint,
  load_from_system_env: true,
  http: [port: "4002"],
  secret_key_base: "${SECRET_KEY_BASE}",
  url: [host: "${HOST}", port: "4002"], # This is critical for ensuring web-sockets properly authorize.
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:member_link, :vsn),
  env: "${APP_SIGNAL_ENV}"

# Do not print debug messages in production
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
    app_version: "#{Application.spec(:member_link, :vsn)}"
  },
  included_environments: [:prod, :staging, :uat, :migration, :autotest, :prod_staging]

# Key
config :member_link, MemberLink.Guardian,
  mg_key: "${MG_KEY}"


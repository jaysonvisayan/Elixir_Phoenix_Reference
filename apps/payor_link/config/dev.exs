use Mix.Config

config :payor_link, Innerpeace.PayorLink.Web.Endpoint,
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]

config :payor_link, Innerpeace.PayorLink.Mailer,
    adapter: Bamboo.LocalAdapter

config :payor_link, Innerpeace.PayorLink.Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/payor_link/web/views/.*(ex)$},
      ~r{lib/payor_link/web/templates/.*(eex)$}
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :exq,
  host: "127.0.0.1",
  port: 6379,
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
#     {"50 11 * * *", {Innerpeace.Db.Base.MemberContext, :generate_balancing_file, []}},
#     {"0 14 * * *", {Innerpeace.Db.Base.MemberContext, :generate_balancing_file, []}}
#   ]

# config :sentry,
#   dsn: "https://783a2f39081e4ebba20e8aa3f32dbc03:83e3229b76e743df86469933c4044cc8@sentry.medilink.com.ph/2",
#   environment_name: String.to_atom("local"),
#   enable_source_code_context: true,
#   root_source_code_path: File.cwd!,
#   tags: %{
#     env: "local",
#     app_version: "#{Application.spec(:payor_link, :vsn)}"
#   },
#   included_environments: [:local]



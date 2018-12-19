use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :payor_link, Innerpeace.PayorLink.Web.Endpoint,
  http: [port: 9000],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

config :payor_link, Innerpeace.PayorLink.Mailer,
  adapter: Bamboo.TestAdapter

config :payor_link, Innerpeace.PayorLink.SMS,
  sms_cached: true,
  proxy: {"172.16.252.23", 3128}

config :payor_link, :permission, Innerpeace.Permission.Mock

config :exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  mode: :enqueuer,
  scheduler_enable: true,
  start_on_application: false

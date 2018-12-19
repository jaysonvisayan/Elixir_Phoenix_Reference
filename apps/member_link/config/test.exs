use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :member_link, MemberLinkWeb.Endpoint,
  http: [port: 9001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

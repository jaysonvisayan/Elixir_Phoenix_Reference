# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :payor_link,
  namespace: Innerpeace.PayorLink,
  ecto_repos: [Innerpeace.Db.Repo]

# Configures the endpoint
config :payor_link, Innerpeace.PayorLink.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "z9T5L25oJplM/QcqJPdWpC9OccelE8o7Jfziu5aGosvC2vqXaNpY7mTo1r5ge+sE",
  render_errors: [view: Innerpeace.PayorLink.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Innerpeace.PayorLink.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  backends: [:console, {Logger.Backends.Gelf, :gelf_logger}]

config :logger, :gelf_logger,
  host: "graylog.medilink.com.ph",
  port: 12201,
  application: "payor_link",
  compression: :gzip, # Defaults to :gzip, also accepts :zlib or :raw
  metadata: [:request_id, :function, :module, :file, :line],
  tags: [
    list: "of",
    extra: "tags"
  ]

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
  secret_key: %{"k" => "DyyZHCR-SOchpGMvssJLhA", "kty" => "oct"}

# GuardianDB
config :guardian, Guardian.DB,
  repo: Innerpeace.Db.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

#Bamboo
config :payor_link, Innerpeace.PayorLink.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: "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"

config :payor_link, :permission, Innerpeace.Permission.Session

config :hound, driver: "chrome_driver"

config :mime, :types, %{
  "acunetix/wvs" => ["xml"]
}

#Cipher
config :cipher, keyphrase: "testiekeyphraseforcipher",
    ivphrase: "testieivphraseforcipher",
    magic_token: "magictoken"

# FTP Server Setup
config :payor_link, Innerpeace.PayorLink.FileTransferProtocol,
  # Test FTP Server Ubuntu
   host: '210.8.0.95',
   port: nil,
   username: 'OdHyxzvcC%2BQ%2BKNx%2FpMqIyg%3D%3D',
   # password: 'B9qcyAo5DD8W7fz%2F3YBeQw%3D%3D',
   host_dir: '/Desktop/TEST/',
   claims_dir: '/uploads/claims_file/'

  #Prod FTP Server
  # host: '172.16.24.204',
  # port: 21,
  # username: 'kB%2Fl44HCS%2FL6IXYj4tlN6g%3D%3D',
  # password: 'W5lkmBrXWrj1%2Fgh6tTLPIA%3D%3D',
  # host_dir: '/Files/',
  # claims_dir: '/uploads/claims_file/'

  # Test FTP Server
  #host: '172.16.45.37',
  #port: nil,
  #username: 'p28ju0grgIO%2F6C7JJXBVcw%3D%3D',
  #password: 'VF4za%2F8tJQh4uOeGNbKLLw%3D%3D',
  #host_dir: '/files/',
  #claims_dir: '/uploads/claims_file/'

#reCAPTCHA
config :recaptcha,
  public_key: {:system, "6LcbNmYUAAAAANoVYBN-fvwDyBa3RAPDk-FAOFb9"},
  secret: {:system, "6LcbNmYUAAAAAKhxjrkxXCH_C9oO_ZMOW6qcvIY9"}

config :payor_link, env: Mix.env

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"


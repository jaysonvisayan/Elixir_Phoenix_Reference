# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"9liua9ixyHc%NvV=w)S:x;*qdEC]T_j^WF4&M9q|D9Z5|]Ut.!1=C*?hr1P||!eG"
end

environment :staging do
  set include_erts: false
  set include_src: false
  set cookie: :"wbnpK2wIoEvi1C7gM6y5I/kPFDe1HIgdMcR/yEVKL0lHmrOSxEhPCgjpeHm7r8Rd"
end

environment :uat do
  set include_erts: false
  set include_src: false
  set cookie: :"BCvPkUupzC67w93Gq7vrfJXwHnndSyXFFQWwXqljUu2GDiy1p+l1LLVYwI8lRBHJ"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"81<sn8Sm<i0w^Q:u46~6`|2gowxf9E={DuUKzlutPd>,K^Esz5<Lr,6%DVL5LLIw"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :payor_link do
  set version: current_version(:payor_link)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    payor_link: :permanent
  ]
end

release :member_link do
  set version: current_version(:member_link)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    member_link: :permanent
  ]
end

release :account_link do
  set version: current_version(:account_link)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    account_link: :permanent
  ]
end

release :registration_link do
  set version: current_version(:registration_link)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    registration_link: :permanent
  ]
end

release :auth do
  set version: current_version(:auth)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    auth: :permanent
  ]
end

release :worker do
  set version: current_version(:worker)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    worker: :permanent
  ]
end

release :scheduler do
  set version: current_version(:scheduler)
  set applications: [
    :runtime_tools,
    :misc_random,
    db: :permanent,
    scheduler: :permanent
  ]
end

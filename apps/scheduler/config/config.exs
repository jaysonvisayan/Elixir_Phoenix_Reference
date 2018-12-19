# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :scheduler, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:scheduler, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

# import_config "#{Mix.env}.exs"

config :scheduler, Scheduler.Schedule,
  timezone: "Asia/Singapore",
  global: true,
  jobs: [
    # {"1 0 * * *", {Innerpeace.Db.Base.MemberContext, :generate_balancing_file, []}},
    # {"0 */2 * * *", {Innerpeace.Db.Base.MemberContext, :generate_claims_file, []}},
    {"1 0 * * *", {Innerpeace.Db.Base.WorkerErrorLogContext, :email_error_logs, []}},
    {"1 0 * * *", {Innerpeace.Db.Base.UserContext, :disable_users_after_cutoff, []}},
    {"0 */12 * * *", {Innerpeace.Db.Base.AuthorizationContext, :update_acu_status_to_stale, []}},
    # {"0 */12 * * *", {Innerpeace.Db.Base.AuthorizationContext, :check_facility_prescription_date, []}},
    {"1 0 * * *", {Innerpeace.Db.Base.AccountContext, :update_account_status, []}},
    {"* * * * *", {Innerpeace.Db.Base.AcuScheduleContext, :update_job_acu_schedule, []}}
    # {"1 0 * * *", {Innerpeace.Db.Base.MemberContext, :update_peme_status_to_stale_or_cancel, []}}
  ]

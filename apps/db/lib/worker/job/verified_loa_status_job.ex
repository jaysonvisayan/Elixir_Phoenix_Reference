defmodule Innerpeace.Db.Worker.Job.VerifiedLoaStatusJob do
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.AuthorizationContext,
    Db.Base.AcuScheduleContext,
  }

  alias Ecto.Changeset

  def perform(authorization_id) do
    AuthorizationContext.update_otp_status(authorization_id)
    update_provider_loa(authorization_id)
  end

  def update_provider_loa(authorization_id) do
    AcuScheduleContext.update_provider_api(authorization_id)
  end

end

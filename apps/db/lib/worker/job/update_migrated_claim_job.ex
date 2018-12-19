defmodule Innerpeace.Db.Worker.Job.UpdateMigratedClaim do
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.AuthorizationContext
  }

  alias Ecto.Changeset

  def perform(params) do
    AuthorizationContext.update_migrated_claim(params)
  end

end

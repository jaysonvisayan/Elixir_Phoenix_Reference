defmodule Innerpeace.Worker.Job.AvailedLoaJob do
  @moduledoc "This module generates balancing file at the end of the day"

  alias Innerpeace.Db.Base.Api.AuthorizationContext

  def perform(authorization_id) do
    AuthorizationContext.update_verified(authorization_id)
  end
end

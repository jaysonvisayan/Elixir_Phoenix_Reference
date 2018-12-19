defmodule Innerpeace.Db.Worker.Job.ActivateMemberJob do
  @moduledoc "This module activates member on it's effectivity date"

  alias Innerpeace.Db.Base.MemberContext

  def perform (member_id) do
    member_id
    |> MemberContext.get_member!
    |> MemberContext.activate_member(
      %{"status" => "Active"}
    )
  end
end

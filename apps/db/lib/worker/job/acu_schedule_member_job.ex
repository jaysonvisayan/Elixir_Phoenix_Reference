defmodule Innerpeace.Db.Worker.Job.AcuScheduleMemberJob do
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.AcuScheduleMember,
    Db.Base.Api.MemberContext,
    Db.Base.AcuScheduleContext,
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset

  def perform(member_id, acu_schedule_id, user_id) do
    params = %{
      "acu_schedule_id" => acu_schedule_id,
      "member_id" => member_id
    }
    {:ok, asm} =
      %AcuScheduleMember{}
      |> AcuScheduleMember.changeset(params)
      |> Repo.insert()
    AcuScheduleContext.create_acu_loa(user_id, member_id, acu_schedule_id)
  end

end

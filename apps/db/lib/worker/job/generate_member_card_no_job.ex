defmodule Innerpeace.Db.Worker.Job.GenerateMemberCardNoJob do
  alias Innerpeace.{
    Db.Parsers.MemberParser,
    Db.Schemas.Member,
    Db.Schemas.MemberUploadLog,
    Db.Repo,
    Db.Base.MemberContext,
    Db.Base.UserContext,
  }
  alias Ecto.Changeset

  def perform(member) do
    Member
    |> Repo.get(member["member_id"])
    |> Member.changeset_batch_card_no(%{card_no: member["card_no"]} )
    |> Repo.update()

    MemberUploadLog
    |> Repo.get(member["member_upload_log_id"])
    |> MemberUploadLog.changeset(%{card_no: member["card_no"]})
    |> Repo.update()
  end

end

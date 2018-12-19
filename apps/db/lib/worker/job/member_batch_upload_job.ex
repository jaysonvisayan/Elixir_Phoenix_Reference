defmodule Innerpeace.Db.Worker.Job.MemberBatchUploadJob do
  alias Innerpeace.{
    Db.Parsers.MemberParser,
    Db.Schemas.Member,
    Db.Repo,
    Db.Base.MemberContext,
    Db.Base.UserContext,
  }
  alias Ecto.Changeset

  def perform(data, filename, user_id, upload_type, member_file_upload_id, account_code) do
    parse_data(data, filename, user_id, upload_type, member_file_upload_id, account_code)
  end

  def parse_data(data, filename, user_id, upload_type, member_file_upload_id, account_code) do
    ##### start of each
    #### card_no generator disabled due to its conflict in member parser part
    data |> Enum.each(fn(data) ->
      Exq
      |> Exq.enqueue(
        "member_parser_job",
        "Innerpeace.Db.Worker.Job.MemberParserJob",
        [data, filename, user_id, upload_type, account_code, member_file_upload_id]
      )
    end)

    Exq
    |> Exq.enqueue_in(
      "job_checker", 1,
      "Innerpeace.Db.Worker.Job.JobChecker",
      [data |> Enum.count, member_file_upload_id]
    )

  end

end

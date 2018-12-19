defmodule Innerpeace.Db.Worker.Job.JobChecker do
  alias Innerpeace.{
    Db.Utilities.CardNoGenerator,
    Db.Parsers.MemberParser,
    Db.Schemas.Member,
    Db.Repo,
    Db.Base.MemberContext,
    Db.Base.UserContext,
  }
  alias Ecto.Changeset

  def perform(data_count, member_upload_file_id) do
    member_success =
      member_upload_file_id
      |> MemberContext.get_member_upload_logs_by_type("success")
      |> Enum.map(&(%{member_upload_log_id: &1.id, member_id: &1.member_id}))

    member_error =
      member_upload_file_id
      |> MemberContext.get_member_upload_logs_by_type("failed")
      |> Enum.map(&(%{member_upload_log_id: &1.id, member_id: &1.member_id}))

    (member_success ++ member_error)
    |> is_job_finished?(data_count, member_upload_file_id, member_success)
  end

  defp is_job_finished?(member_upload_logs, data_count, member_upload_file_id, member_success) do
    with true <- is_equal?(member_upload_logs, data_count) do
      member_success
      |> distribute_card_no_to_member(list_card_no_generated(member_success |> Enum.count(), []), [] )
      |> Enum.map(&(
        Exq
        |> Exq.enqueue("generate_member_card_no_job",
          "Innerpeace.Db.Worker.Job.GenerateMemberCardNoJob", [&1])
      ))

    else
      false ->
        Exq
        |> Exq.enqueue_in("job_checker", 5,
          "Innerpeace.Db.Worker.Job.JobChecker",
          [data_count, member_upload_file_id]
        )
    end
  end

  defp is_equal?(member_upload_logs, data_count), do:
    if data_count == member_upload_logs |> Enum.count(), do: true, else: false
  defp list_card_no_generated(0, result), do: result
  defp list_card_no_generated(member_success_count, result) do
    (member_success_count - 1)
    |> list_card_no_generated(result ++ [CardNoGenerator.generate_card_number(nil)])
  end

  defp distribute_card_no_to_member([], [], result), do: result
  defp distribute_card_no_to_member([member_head | member_tails], [card_head | card_tails], result) do
    result = result ++ [ member_head |> Map.put_new(:card_no, card_head) ]
    distribute_card_no_to_member(member_tails, card_tails, result)
  end

end

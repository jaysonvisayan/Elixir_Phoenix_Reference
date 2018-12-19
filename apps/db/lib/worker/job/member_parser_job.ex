defmodule Innerpeace.Db.Worker.Job.MemberParserJob do
  alias Innerpeace.{
    Db.Parsers.MemberParser,
    Db.Schemas.Member,
    Db.Repo,
    Db.Base.MemberContext,
    Db.Base.UserContext,
  }
  alias Ecto.Changeset

  def perform(data, filename, user_id, upload_type, account_code, member_file_upload_id) do
    data = Map.put_new(data, "Account Code", account_code)

    if upload_type == "Individual, Family, Group (IFG)" do
      principal_number = data["Principal Number"]
      data =
        data
        |> Map.put("Employee No", principal_number)
        |> Map.delete("Principal Number")
    end

    data =
      data
      |> Map.put("member_file_upload_id", member_file_upload_id)
      |> Map.put("upload_type", upload_type)

    with {:passed} <- MemberParser.validations(1, data, []) do
      member =
        data
        |> Map.put("created_by_id", user_id)
        |> Map.put("updated_by_id", user_id)
        |> MemberParser.member_paramsv2()

      case member do
        {:error, message} ->
          MemberParser.insert_log_failed(data, filename, member_file_upload_id, user_id, message)

        _ ->

          with {:ok, member} <- MemberParser.insert_member(member) do
            MemberParser.insert_products(member.id, member.account_code, data["Plan Code"])
            MemberParser.insert_log_successv2(data, filename, member_file_upload_id, user_id, member.id)

            remarks = %{
              "comment" => "Member successfully enrolled"
            }
            MemberParser.insert_member_comment(member.id, remarks, user_id)
            MemberContext.update_member_status(member.account_code)
            MemberParser.activate_member_on_effectivity_date(member)
          else
            _ ->
              message = MemberParser.join_message("Error inserting member")
              MemberParser.insert_log_failed(data, filename, member_file_upload_id, user_id, message)
          end

      end

    else
      {:failed, message} ->
        message = MemberParser.join_message(message)
        MemberParser.insert_log_failed(data, filename, member_file_upload_id, user_id, message)
      {:ignored} ->
        "If all columns are empty"
    end
  end

end

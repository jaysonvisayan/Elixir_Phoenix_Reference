defmodule Innerpeace.Db.Parsers.MemberMaintenanceParser do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.Member,
    Schemas.Product
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    AccountContext,
    Api.UtilityContext
  }

  def cancel_parse_data(data, filename, user_id, upload_type) do
    batch_no =
      MemberContext.get_member_upload_logs()
      |> Enum.count()
      |> MemberContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      upload_type: upload_type,
      remarks: "ok"
    }

    {:ok, member_file_upload} =
      MemberContext.create_member_upload_file(file_params)

    # Batch Upload
    Enum.each(data, fn({_, data}) ->
      # raise validations(1, data, [])
      # try do
       with {:passed} <- cancel_validations(1, data, []) do
        member = MemberContext.get_member(data["Member ID"])
        {:true, date} = validate_date(data["Cancellation Date"])
        cancel_params = %{cancel_date: date, cancel_reason: data["Reason"]}
        MemberContext.cancel_member(member, cancel_params)
        data
        |> cancel_logs_params()
        |> Map.put(:member_upload_file_id, member_file_upload.id)
        |> Map.put(:created_by_id, user_id)
        |> insert_log("success", "Member successfully cancelled")
       else
         {:failed, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> cancel_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)

         {:ignored, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> cancel_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)
       end
    end)
  end

  def cancel_validations(step, data, message) do
    case step do
      # validate columns
      1 ->
        if {:complete} == validate_columns(data) do
          cancel_validations(2, data, message)
        else
          {:missing, empty} = validate_columns(data)
          count_empty = empty |> String.split(",") |> Enum.count

          if count_empty > 0 do
            message = message ++ [empty]
            {:ignored, message}
          else
            message = message ++ [empty]
            cancel_validations(2, data, message)
          end
        end

      # validate member
      2 ->
        member_id = data["Member ID"]
        with false <- member_id == "",
             {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data)
        do
          # On success returns no error
          cancel_validations(3, data, message)
        else
          true ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(3, data, message)

          {:invalid_id} ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(3, data, message)

          {:invalid_member} ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(3, data, message)
          end

      # validate member status
      3 ->
        if UtilityContext.valid_uuid?(data["Member ID"]) != {:invalid_id} do
          member = MemberContext.get_member(data["Member ID"])
          with {:valid_member} <- validate_member(data),
               true <- member.status == "Active" or member.status == "Suspended"
          do
            # On success returns no error
            cancel_validations(4, data, message)
          else
            false ->
              # status is already cancelled
              message = message ++ ["You are only allowed to cancel suspended and active members"]
              cancel_validations(4, data, message)

            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              cancel_validations(4, data, message)
          end
        else
          message = message ++ ["You have entered an invalid Member ID"]
          cancel_validations(4, data, message)
        end

      # validate reason
      4 ->
        if Enum.member?(["Reason 1", "Reason 2"], data["Reason"]) do
          cancel_validations(5, data, message)
        else
          message = message ++ ["Invalid Reason"]
          cancel_validations(5, data, message)
        end

      # validate cancel date with account
      5 ->
        cancel_date  = data["Cancellation Date"]
        member_id = data["Member ID"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
             {:valid_date} <- validate_date_with_account(cancel_date, member_id)
        do
          cancel_validations(6, data, message)
        else
          {:invalid_id} ->
          message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(6, data, message)

          {:invalid_member} ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(6, data, message)

          {:invalid_date_format} ->
            message = message ++ ["Invalid Cancellation Date, date must be in mm/dd/yyyy format"]
            cancel_validations(6, data, message)

          {:invalid_suspend_and_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            cancel_validations(6, data, message)
          {:invalid_suspend_date} ->
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            cancel_validations(6, data, message)
          {:invalid_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            cancel_validations(6, data, message)
        end

      # validate cancel date
      6 ->
        cancel_date  = data["Cancellation Date"]
        member_id = data["Member ID"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
             {:valid_cancel_date} <- validate_cancellation_date(cancel_date,
                                                                member_id)
        do
          # On success returns no error
          cancel_validations(7, data, message)
        else
          {:invalid_id} ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(7, data, message)
          {:invalid_member} ->
            message = message ++ ["You have entered an invalid Member ID"]
            cancel_validations(7, data, message)
          {:invalid_date_format} ->
            message = message ++ ["Invalid Cancellation Date, date must be in mm/dd/yyyy format"]
            cancel_validations(7, data, message)
          {:invalid_date_for_future_member_movement} ->
            message = message ++ ["Cancellation Date must not be less than or equal to the future suspension or reactivation date."]
            cancel_validations(7, data, message)
          {:invalid_date_for_expiry} ->
            message = message ++ ["Invalid cancellation date, cancellation date should not be greater than or equal to the expiry date."]
            cancel_validations(7, data, message)
          {:invalid_date} ->
            message = message ++ ["Invalid cancellation date, cancellation date must be future dated."]
            cancel_validations(7, data, message)
        end
      _ ->
          if Enum.empty?(message) do
            {:passed}
          else
            {:failed, message}
          end
    end
  end

  def suspend_parse_data(data, filename, user_id, upload_type) do
    batch_no =
      MemberContext.get_member_upload_logs()
      |> Enum.count()
      |> MemberContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      upload_type: upload_type,
      remarks: "ok"
    }

    {:ok, member_file_upload} =
      MemberContext.create_member_upload_file(file_params)

    # Batch Upload
    Enum.each(data, fn({_, data}) ->
      # raise validations(1, data, [])
      # try do
       with {:passed} <- suspend_validations(1, data, []) do
         member = MemberContext.get_member(data["Member ID"])
        {:true, date} = validate_date(data["Suspension Date"])
        suspend_params = %{suspend_date: date, suspend_reason: data["Reason"]}
        MemberContext.suspend_member(member, suspend_params)
              data
              |> suspend_logs_params()
              |> Map.put(:member_upload_file_id, member_file_upload.id)
              |> Map.put(:created_by_id, user_id)
              |> insert_log("success", "Member successfully suspend")
       else
         {:failed, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> suspend_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)

         {:ignored, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> suspend_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)
       end
    end)
  end

  def suspend_validations(step, data, message) do
    case step do
      # validate columns
      1 ->
          if {:complete} == validate_columns(data) do
            suspend_validations(2, data, message)
          else
            {:missing, empty} = validate_columns(data)
            count_empty = empty |> String.split(",") |> Enum.count

            if count_empty > 0 do
              message = message ++ [empty]
              {:ignored, message}
            else
              message = message ++ [empty]
              suspend_validations(2, data, message)
            end
        end

      # validate member
      2 ->
        member_id = data["Member ID"]
        with false <- member_id == "",
             {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data)
          do
            # On success returns no error
            suspend_validations(3, data, message)
          else
            true ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(3, data, message)

            {:invalid_id} ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(3, data, message)

            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(3, data, message)
          end

      # validate member status
      3 ->
        if UtilityContext.valid_uuid?(data["Member ID"]) != {:invalid_id} do
        member = MemberContext.get_member(data["Member ID"])
        with {:valid_member} <- validate_member(data),
             true <- member.status == "Active"
          do
            # On success returns no error
            suspend_validations(4, data, message)
          else
            false ->
              message = message ++ ["You are only allowed to suspend active members"]
              suspend_validations(4, data, message)

            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(4, data, message)
          end
        else
          message = message ++ ["You have entered an invalid Member ID"]
          suspend_validations(4, data, message)
        end

      # validate reason
      4 ->
        if Enum.member?(["Reason 1", "Reason 2"], data["Reason"]) do
          suspend_validations(5, data, message)
        else
          message = message ++ ["Invalid Reason"]
          suspend_validations(5, data, message)
        end

      # validate suspend date with account
      5 ->
        member_id = data["Member ID"]
        suspend_date  = data["Suspension Date"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
        {:valid_date} <- validate_date_with_account(suspend_date,
        member_id) do
          suspend_validations(6, data, message)
        else
          {:invalid_id} ->
            message = message ++ ["You have entered an invalid Member ID"]
            suspend_validations(6, data, message)

          {:invalid_member} ->
            message = message ++ ["You have entered an invalid Member ID"]
            suspend_validations(6, data, message)

          {:invalid_date_format} ->
            message = message ++ ["Invalid Suspension Date, date must be in mm/dd/yyyy format"]
            suspend_validations(6, data, message)

          {:invalid_suspend_and_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            suspend_validations(6, data, message)
          {:invalid_suspend_date} ->
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            suspend_validations(6, data, message)
          {:invalid_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            suspend_validations(6, data, message)
        end

      # validate suspend date
      6 ->
        suspend_date  = data["Suspension Date"]
        member_id = data["Member ID"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
        {:valid_suspend_date} <- validate_suspension_date(suspend_date,
            member_id) do
            # On success returns no error
            suspend_validations(7, data, message)
          else
            {:invalid_id} ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(7, data, message)
            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              suspend_validations(7, data, message)
            {:invalid_date_format} ->
              message = message ++ ["Invalid Suspension Date, date must be in mm/dd/yyyy format"]
              suspend_validations(7, data, message)
            {:invalid_date_for_future_member_movement} ->
              message = message ++ ["Suspension Date must not be greater than or equal to the future cancellation"]
              suspend_validations(7, data, message)
            {:invalid_date_for_expiry} ->
              message = message ++ ["Invalid suspension date, suspension date should not be greater than or equal to the expiry date."]
              suspend_validations(7, data, message)
            {:invalid_date} ->
              message = message ++ ["Invalid suspension date, suspension date must be future dated."]
              suspend_validations(7, data, message)
          end
      _ ->
          if Enum.empty?(message) do
            {:passed}
          else
            {:failed, message}
          end
    end
  end

  def reactivate_parse_data(data, filename, user_id, upload_type) do
    batch_no =
      MemberContext.get_member_upload_logs()
      |> Enum.count()
      |> MemberContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      upload_type: upload_type,
      remarks: "ok"
    }
    {:ok, member_file_upload} =
      MemberContext.create_member_upload_file(file_params)

    # Batch Upload
    Enum.each(data, fn({_, data}) ->
      # raise validations(1, data, [])
      # try do
       with {:passed} <- reactivate_validations(1, data, []) do
         member = MemberContext.get_member(data["Member ID"])
        {:true, date} = validate_date(data["Reactivation Date"])
        reactivate_params = %{reactivate_date: date,
        reactivate_reason: data["Reason"]}
        MemberContext.reactivate_member(member, reactivate_params)
              data
              |> reactivate_logs_params()
              |> Map.put(:member_upload_file_id, member_file_upload.id)
              |> Map.put(:created_by_id, user_id)
              |> insert_log("success", "Member successfully reactivate")
       else
         {:failed, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> reactivate_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)

         {:ignored, message} ->
           message = Enum.join(Enum.uniq(message), ", ")
           data
           |> reactivate_logs_params()
           |> Map.put(:member_upload_file_id, member_file_upload.id)
           |> Map.put(:created_by_id, user_id)
           |> insert_log("failed", message)

       end
    end)
  end

  def reactivate_validations(step, data, message) do
    case step do
      # validate columns
      1 ->
        if {:complete} == validate_columns(data) do
          reactivate_validations(2, data, message)
        else
          {:missing, empty} = validate_columns(data)
          count_empty = empty |> String.split(",") |> Enum.count

         if count_empty > 0 do
            message = message ++ [empty]
            {:ignored, message}
          else
            message = message ++ [empty]
            reactivate_validations(2, data, message)
          end
        end

      # validate member
      2 ->
        member_id = data["Member ID"]
        with false <- member_id == "",
             {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data)
          do
            # On success returns no error
            reactivate_validations(3, data, message)
        else
            true ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(3, data, message)

            {:invalid_id} ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(3, data, message)

            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(3, data, message)
          end

      # validate member status
      3 ->
        if UtilityContext.valid_uuid?(data["Member ID"]) != {:invalid_id} do
        member = MemberContext.get_member(data["Member ID"])
        with {:valid_member} <- validate_member(data),
             true <- member.status == "Suspended"
        do
            # On success returns no error
            reactivate_validations(4, data, message)
          else
            false ->
              message = message ++ ["You are only allowed to reactivate suspended members"]
              reactivate_validations(4, data, message)

            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(4, data, message)
          end
        else
          message = message ++ ["You have entered an invalid Member ID"]
          reactivate_validations(4, data, message)
        end

      # validate reason
      4 ->
        if Enum.member?(["Reason 1", "Reason 2"], data["Reason"]) do
          reactivate_validations(5, data, message)
        else
          message = message ++ ["Invalid Reason"]
          reactivate_validations(5, data, message)
        end

      # validate reactivate date with account
      5 ->
        reactivate_date  = data["Reactivation Date"]
        member_id = data["Member ID"]
        reactivate_date  = data["Reactivation Date"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
        {:valid_date} <- validate_date_with_account(reactivate_date,
        member_id) do
          reactivate_validations(6, data, message)
        else
          {:invalid_id} ->
            message = message ++ ["You have entered an invalid Member ID"]
            reactivate_validations(6, data, message)

          {:invalid_member} ->
            message = message ++ ["You have entered an invalid Member ID"]
            reactivate_validations(6, data, message)

          {:invalid_date_format} ->
            message = message ++ ["Invalid Reactivation Date, date must be in mm/dd/yyyy format"]
            reactivate_validations(6, data, message)

          {:invalid_suspend_and_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            reactivate_validations(6, data, message)

          {:invalid_suspend_date} ->
            message = message ++ ["Date must not be greater than or equal to suspension date of account"]
            reactivate_validations(6, data, message)

          {:invalid_cancel_date} ->
            message = message ++ ["Date must not be greater than or equal to cancellation date of account"]
            reactivate_validations(6, data, message)

        end

      # validate reactivate date
      6 ->
        reactivate_date  = data["Reactivation Date"]
        member_id = data["Member ID"]
        with {:true, id} <- UtilityContext.valid_uuid?(member_id),
             {:valid_member} <- validate_member(data),
        {:valid_reactivate_date} <- validate_reactivation_date(reactivate_date,
        member_id) do
            # On success returns no error
            reactivate_validations(7, data, message)
          else
            {:invalid_id} ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(7, data, message)
            {:invalid_member} ->
              message = message ++ ["You have entered an invalid Member ID"]
              reactivate_validations(7, data, message)
            {:invalid_date_format} ->
              message = message ++ ["Invalid Reactivation Date, date must be in mm/dd/yyyy format"]
              reactivate_validations(7, data, message)
            {:invalid_date_for_future_member_movement} ->
              message = message ++ ["Reactivation Date must not be greater than or equal to the future cancellation date."]
              reactivate_validations(7, data, message)
            {:invalid_date_for_expiry} ->
              message = message ++ ["Invalid reactivation date, reactivation date should not be greater than or equal to the expiry date."]
              reactivate_validations(7, data, message)
            {:invalid_date} ->
              message = message ++ ["Invalid reactivation date, reactivation date must be future dated."]
              reactivate_validations(7, data, message)
          end
      _ ->
          if Enum.empty?(message) do
            {:passed}
          else
            {:failed, message}
          end
    end
  end

  # used by all maintenance
  # step 1
  def validate_columns(params) do
    values =
      params
      |> Map.values()

    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Enum.filter(fn({k, v}) -> is_nil(v) or v == "" end)
        |> Enum.into(%{}, fn({k, v}) -> {Enum.join(["Please enter ", k]), v} end)
        |> Map.keys
        |> Enum.join(", ")

      {:missing, empty}
    else
      {:complete}
    end
  end

  # step 2
  def validate_member(data) do
    member_id = data["Member ID"]
    member = MemberContext.get_member(member_id)
    if not is_nil(member) and member.step >= 5 do
      {:valid_member}
    else
      {:invalid_member}
    end
  end
  # end used by all maintenance

  # step 4
  def validate_cancellation_date(cancel_date, member_id) do
    member = MemberContext.get_member(member_id)
    suspension_date = member.suspend_date
    reactivation_date = member.reactivate_date
    expiry_date = member.expiry_date
    local_time = Ecto.DateTime.from_erl(:erlang.localtime)
    date_today = Ecto.DateTime.to_date(local_time)
    validate_date_today =
      with {:true, cancel_date} <- validate_date(cancel_date),
      :gt <- Ecto.Date.compare(cancel_date, date_today)
    do
      if :gt == Ecto.Date.compare(expiry_date, cancel_date) do
        {:valid_cancel_date}
      else
        {:invalid_date_for_expiry}
      end
    else
      {:invalid_date} ->
        {:invalid_date_format}
      :lt ->
        {:invalid_date}
      :eq ->
        {:invalid_date}
    end
    if validate_date_today == {:valid_cancel_date} do
      if not is_nil(suspension_date) do
        with {:true, cancel_date} <- validate_date(cancel_date),
             :gt <- Ecto.Date.compare(cancel_date, suspension_date)
        do
          {:valid_cancel_date}
        else
          {:invalid_date} ->
            {:invalid_date_format}
          :lt ->
            {:invalid_date_for_future_member_movement}
          :eq ->
            {:invalid_date_for_future_member_movement}
        end
      else
        validate_date_today
      end

      if not is_nil(reactivation_date) do
        with {:true, cancel_date} <- validate_date(cancel_date),
             :gt <- Ecto.Date.compare(cancel_date, reactivation_date)
        do
          {:valid_cancel_date}
        else
          {:invalid_date} ->
            {:invalid_date_format}
          :lt ->
            {:invalid_date_for_future_member_movement}
          :eq ->
            {:invalid_date_for_future_member_movement}
        end
      else
        validate_date_today
      end

      # cond do
      #   not is_nil(suspension_date) ->
      #     with {:true, cancel_date} <- validate_date(cancel_date),
      #        :gt <- Ecto.Date.compare(cancel_date, suspension_date)
      #     do
      #       {:valid_cancel_date}
      #     else
      #       {:invalid_date} ->
      #         {:invalid_date_format}
      #       :lt ->
      #         {:invalid_date_for_future_member_movement}
      #       :eq ->
      #         {:invalid_date_for_future_member_movement}
      #     end
      #   not is_nil(reactivation_date) ->
      #     with {:true, cancel_date} <- validate_date(cancel_date),
      #        :gt <- Ecto.Date.compare(cancel_date, reactivation_date)
      #     do
      #       {:valid_cancel_date}
      #     else
      #       {:invalid_date} ->
      #         {:invalid_date_format}
      #       :lt ->
      #         {:invalid_date_for_future_member_movement}
      #       :eq ->
      #         {:invalid_date_for_future_member_movement}
      #     end
      #   true ->
      #     validate_date_today
      # end
    else
      validate_date_today
    end
  end


  #step 4
  def validate_suspension_date(suspend_date, member_id) do
    member = MemberContext.get_member(member_id)
    cancellation_date = member.cancel_date
    expiry_date = member.expiry_date
    local_time = Ecto.DateTime.from_erl(:erlang.localtime)
    date_today = Ecto.DateTime.to_date(local_time)
    validate_date_today =
      with {:true, suspend_date} <- validate_date(suspend_date),
      :gt <- Ecto.Date.compare(suspend_date, date_today)
    do
      if :gt == Ecto.Date.compare(expiry_date, suspend_date) do
        {:valid_suspend_date}
      else
        {:invalid_date_for_expiry}
      end
    else
      {:invalid_date} ->
        {:invalid_date_format}
      :lt ->
        {:invalid_date}
      :eq ->
        {:invalid_date}
    end
    if validate_date_today == {:valid_suspend_date} do
      if not is_nil(cancellation_date) do
        with {:true, suspend_date} <- validate_date(suspend_date),
             :gt <- Ecto.Date.compare(cancellation_date, suspend_date)
        do
          {:valid_suspend_date}
        else
          {:invalid_date} ->
            {:invalid_date_format}
          :lt ->
            {:invalid_date_for_future_member_movement}
          :eq ->
            {:invalid_date_for_future_member_movement}
        end
      else
        validate_date_today
      end
    else
      validate_date_today
    end
  end

  #step 4
  def validate_reactivation_date(reactivate_date, member_id) do
    member = MemberContext.get_member(member_id)
    cancellation_date = member.cancel_date
    expiry_date = member.expiry_date
    local_time = Ecto.DateTime.from_erl(:erlang.localtime)
    date_today = Ecto.DateTime.to_date(local_time)
    validate_date_today =
      with {:true, reactivate_date} <- validate_date(reactivate_date),
      :gt <- Ecto.Date.compare(reactivate_date, date_today)
    do
      if :gt == Ecto.Date.compare(expiry_date, reactivate_date) do
        {:valid_reactivate_date}
      else
        {:invalid_date_for_expiry}
      end
    else
      {:invalid_date} ->
        {:invalid_date_format}
      :lt ->
        {:invalid_date}
      :eq ->
        {:invalid_date}
    end
    if validate_date_today == {:valid_reactivate_date} do
      if  not is_nil(cancellation_date) do
        with {:true, reactivate_date} <- validate_date(reactivate_date),
              :gt <- Ecto.Date.compare(cancellation_date, reactivate_date)
        do
          {:valid_reactivate_date}
        else
          {:invalid_date} ->
            {:invalid_date_format}
          :lt ->
            {:invalid_date}
          :eq ->
            {:invalid_date}
        end
      else
        validate_date_today
      end
    else
      validate_date_today
    end
  end

  def validate_date_with_account(date, member_id) do
    member = MemberContext.get_member(member_id)
    account = List.first(Enum.map(member.account_group.account, & (if &1.status == "Active", do: &1)))
    if validate_date(date) != {:invalid_date}  do
      {:true, date} = validate_date(date)
      error = []
      if not is_nil(account.cancel_date) do
        if Ecto.Date.compare(account.cancel_date, date) != :gt  do
          error = error ++ [{:invalid_cancel_date}]
        end
      end
      if not is_nil(account.suspend_date) do
        if Ecto.Date.compare(account.suspend_date, date) != :gt  do
          error = error ++ [{:invalid_suspend_date}]
        end
      end
      if error == [] do
        {:valid_date}
      else
        if Enum.count(error) == 2 do
          {:invalid_suspend_and_cancel_date}
        else
          List.first(error)
        end
      end
    else
      {:invalid_date_format}
    end
  end

  defp validate_date(date) do
    try do
      [mm, dd, yyyy] = String.split(date, "/")

      if String.length(dd) == 1, do: dd = "0#{dd}"
      if String.length(mm) == 1, do: mm = "0#{mm}"
      if String.length(yyyy) == 2, do: yyyy = "20#{yyyy}"

      date = Ecto.Date.cast!("#{yyyy}-#{mm}-#{dd}")

      {:true, date}
    rescue
      MatchError ->
        {:invalid_date}
      ArgumentError ->
        {:invalid_date}
      Ecto.CastError ->
        {:invalid_date}
      FunctionClauseError ->
        {:invalid_date}
      _ ->
        {:invalid_date}
    end
  end

  defp cancel_logs_params(data) do
    %{
      member_id: data["Member ID"],
      member_name: data["Member Name"],
      employee_no: data["Employee No"],
      card_no: data["Card No"],
      maintenance_date: data["Cancellation Date"],
      reason: data["Reason"]
    }
  end

  defp suspend_logs_params(data) do
    %{
      member_id: data["Member ID"],
      member_name: data["Member Name"],
      employee_no: data["Employee No"],
      card_no: data["Card No"],
      maintenance_date: data["Suspension Date"],
      reason: data["Reason"]
    }
  end

  defp reactivate_logs_params(data) do
    %{
      member_id: data["Member ID"],
      member_name: data["Member Name"],
      employee_no: data["Employee No"],
      card_no: data["Card No"],
      maintenance_date: data["Reactivation Date"],
      reason: data["Reason"]
    }
  end

  defp insert_log(params, status, remarks) do
    params
    |> Map.put(:status, status)
    |> Map.put(:remarks, remarks)
    |> MemberContext.create_member_maintenance_upload_log()
  end
end

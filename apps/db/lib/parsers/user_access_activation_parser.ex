defmodule Innerpeace.Db.Parsers.UserAccessActivationParser do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.User
  }

  alias Innerpeace.Db.Base.{
    UserContext
  }

  def parse(data, filename, user_id) do
    data = Enum.drop(data, 1)

    batch_no =
      UserContext.get_uaa_files()
      |> Enum.count()
      |> UserContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no
    }
    {:ok, uaa_file} = UserContext.user_access_activation_file(file_params)

    Enum.map(data, fn({_, data}) ->
      data = Map.put(data, "uaa_file_id", uaa_file.id)
      with {:passed} <- validations(1, data, []) do
        insert_log_success(data, filename, uaa_file.id, user_id)
      else
        {:failed, message} ->
          message = join_message(message)
          insert_log_failed(data, filename, uaa_file.id, user_id, message)
        {:ignored} ->
          "If all columns are empty"
      end
    end)
    {:ok, uaa_file}
  end

  def validations(step, data, message), do: step(step, data, message)

  def step(1, data, message) do
    if {:complete} == validate_columns(data) do
      validations(2, data, message)
    else
      {:missing, empty} = validate_columns(data)
      count_empty = empty |> String.split(",") |> Enum.count

      if count_empty >= 2 do
        {:ignored}
      else
        message = message ++ [empty]
        validations(2, data, message)
      end
    end
  end

  def step(2, data, message) do
    code = data["Code"]

    with false <- code == "",
         nil <- UserContext.get_by_payroll_code_log(String.trim(code), data["uaa_file_id"]),
         %User{} <- UserContext.get_by_payroll_code(String.trim(code))
    do
      validations(:final, data, message)
    else
      true ->
        validations(:final, data, message)
      nil ->
        message = message ++ ["Code does not exist."]
        validations(:final, data, message)
      _ ->
        message = message ++ ["Code has multiple records."]
        validations(:final, data, message)
    end
  end

  def step(:final, data, message) do
    message =
      message
      |> Enum.join(",")
      |> String.split(",")
      |> Enum.into([], &(String.trim(&1)))
      |> Enum.reject(&(&1 == ""))
      |> Enum.filter(fn(msg) -> msg != "" end)

    if Enum.empty?(message) do
      {:passed}
    else
      {:failed, message}
    end
  end

  def validate_columns(params) do
    values =
      params
      |> Map.values()

    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Enum.filter(fn({_k, v}) -> is_nil(v) or v == "" end)
        |> Enum.into(%{}, fn({k, v}) -> {Enum.join(["Please enter ", k]), v} end)
        |> Map.keys
        |> Enum.join(", ")

      {:missing, empty}
    else
      {:complete}
    end
  end

  defp join_message(message) do
    message
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  defp insert_log_failed(data, filename, uaa_file_id, user_id, message) do
    data
    |> logs_params()
    |> Map.put(:user_access_activation_file_id, uaa_file_id)
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("failed", message)
  end

  defp insert_log_success(data, filename, uaa_file_id, user_id) do
    data
    |> logs_params()
    |> Map.put(:user_access_activation_file_id, uaa_file_id)
    |> Map.put(:filename, filename)
    |> Map.put(:created_by_id, user_id)
    |> insert_log("success", "Uploaded successfully.")
  end

  defp insert_log(params, status, message) do
    params
    |> Map.put(:status, status)
    |> Map.put(:remarks, message)
    |> UserContext.user_access_activation_log()
  end

  defp logs_params(data) do
    %{
      code: data["Code"],
      employee_name: data["Employee Name"]
     }
  end
end

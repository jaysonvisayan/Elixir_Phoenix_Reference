defmodule Innerpeace.Db.Base.CaseRateContext do
  @moduledoc """

  """
  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.CaseRate,
    # Schemas.Diagnosis,
    Schemas.CaseRateLog
  }

  def insert_or_update_case_rate(params) do
    case_rate = get_case_rate_by_code(params.code)
    if is_nil(case_rate) do
      create_case_rate(params)
    else
      update_case_rate(case_rate.id, params)
    end
  end

  def get_case_rate_by_code(code) do
    CaseRate
    |> Repo.get_by(code: code)
  end

  def get_all_case_rate do
    CaseRate
    |> Repo.all
    |> Repo.preload([:case_rate_log])
  end

  def get_case_rate(id) do
    CaseRate
    |> Repo.get!(id)
    |> Repo.preload([:case_rate_log])
  end

  def create_case_rate(case_rate_param) do
    %CaseRate{}
    |> CaseRate.changeset(case_rate_param)
    |> Repo.insert
  end

  def update_case_rate(id, case_rate_param) do
    id
    |> get_case_rate()
    |> CaseRate.changeset(case_rate_param)
    |> Repo.update
  end

  def delete_case_rate(id) do
    id
    |> get_case_rate()
    |> Repo.delete
  end

  def create_case_rate_edit_logs(user, changeset) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes}."
      insert_log(%{
        case_rate_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_case_rate_logs(case_rate, user, params) do
      changes = insert_changes_to_string_case_rate(params)
      message = "#{user.username} created this case rate where #{changes}."
      insert_log(%{
        case_rate_id: case_rate.id,
        user_id: user.id,
        message: message
      })
  end

  def insert_changes_to_string_case_rate(params) do
    changes = for {key, new_value} <- params, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      new_value = if is_nil(new_value) do
        new_value = 0
      else
        new_value
      end

      key_val = if is_nil(Map.get(changeset.data, key)) do
        key_val = 0
      else
        Map.get(changeset.data, key)
      end

      "Case Rate #{transform_atom(key)} from #{key_val} to #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = CaseRateLog.changeset(%CaseRateLog{}, params)
    Repo.insert!(changeset)
  end

  def get_case_rate_logs(case_rate_id, message) do
    CaseRateLog
    |> where([crl], crl.case_rate_id == ^case_rate_id and like(crl.message, ^"%#{message}%"))
    |> order_by(desc: :inserted_at)
    |> Repo.all
  end

  def get_all_case_rate_logs(case_rate_id) do
    CaseRateLog
    |> where([crl], crl.case_rate_id == ^case_rate_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end
end

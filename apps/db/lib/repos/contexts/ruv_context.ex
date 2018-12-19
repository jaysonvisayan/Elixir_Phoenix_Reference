defmodule Innerpeace.Db.Base.RUVContext do
  @moduledoc """
    Functions for database logic
  """

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.RUV,
    Schemas.RUVLog
  }

  def get_ruvs do
    RUV
    |> Repo.all()
    |> Repo.preload([
      :benefit_ruvs,
      :facility_ruvs,
      :case_rates
    ])
  end

  def create_ruv(user_id, ruv_params) do
    ruv_params =
      ruv_params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    %RUV{}
    |> RUV.changeset(ruv_params)
    |> Repo.insert()
  end

  def get_ruv_codes do
    RUV
    |> select([r], r.code)
    |> Repo.all()
  end

  def get_ruv_by_id(id) do
    RUV
    |> Repo.get(id)
    |> Repo.preload([
      :benefit_ruvs,
      :facility_ruvs
    ])
  end

  def update_ruv(user_id, id, ruv_params) do
    ruv_params =
      ruv_params
      |> Map.put("updated_by_id", user_id)

    id
    |> get_ruv_by_id
    |> RUV.changeset(ruv_params)
    |> Repo.update
  end

  def delete_ruv(id) do
    RUV
    |> where([r], r.id == ^id)
    |> Repo.delete_all()
  end

  def create_ruv_log(user, ruv_changeset) do
    if Enum.empty?(ruv_changeset.changes) == false do
        changes = changes_to_string(ruv_changeset)
        message = "#{user.username} edited #{changes}."
        insert_log(%{
          ruv_id: ruv_changeset.data.id,
          user_id: user.id,
          message: message
        })
    end
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      column = cond do
        key == String.to_atom("description") ->
          "RUV Description "
        key == String.to_atom("effectivity_date") ->
          "Effectivity Date "
        key == String.to_atom("type") ->
          "RUV Type "
        key == String.to_atom("value") ->
          "Value "
      end

      Enum.join([column, "from #{Map.get(changeset.data, key)} to #{new_value}"], "")
    end

    changes |> Enum.join(", ")
  end

  def insert_log(params) do
    changeset = RUVLog.changeset(%RUVLog{}, params)
    Repo.insert(changeset)
  end

  def get_logs_by_ruv_id(ruv_id) do
    RUVLog
    |> where([rl], rl.ruv_id == ^ruv_id)
    |> select([rl], %{
      message:  rl.message,
      inserted_at:  rl.inserted_at
    })
    |> order_by([rl], desc: rl.inserted_at)
    |> Repo.all()
  end
  
  def get_ruv_by_code(code) do
    RUV
    |> Repo.get_by(code: code)
    |> Repo.preload([
      :benefit_ruvs,
      :facility_ruvs
    ])
  end

  def get_ruv_by_code_and_effectivity(code, effectivity) do
    RUV
    |> Repo.get_by(code: code, effectivity_date: effectivity)
    |> Repo.preload([
      :benefit_ruvs,
      :facility_ruvs
    ])
  end

end

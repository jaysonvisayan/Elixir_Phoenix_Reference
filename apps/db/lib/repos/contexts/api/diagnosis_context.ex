defmodule Innerpeace.Db.Base.Api.DiagnosisContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Diagnosis,
    Schemas.Coverage,
    Schemas.DiagnosisCoverage,
    Schemas.DiagnosisLog
  }

  alias Ecto.Changeset

  def search_all_diagnosis do
    Diagnosis
    |> Repo.all()
  end

  def search_diagnosis(params) do
    diagnosis = Diagnosis
    |> where([d],
      (is_nil(d.description) or like(fragment("lower(?)", d.description), fragment("lower(?)", ^"#{params["diagnosis"]}%"))) or
      (is_nil(d.code)  or like(fragment("lower(?)", d.code), fragment("lower(?)", ^"#{params["diagnosis"]}%"))))
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all
  end

  def validate_insert(user, params) do
    with {:ok, changeset} <- validate_general(params),
        {:ok, diagnoses} <- insert_diagnosis(changeset)
    do
      {:ok, diagnoses}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:not_found}
    end
  end

  defp validate_general(params) do
    data = %{}
    general_types = %{
      code: :string,
      name: :string,
      classification: :string,
      type: :string,
      group_description: :string,
      description: :string,
      congenital: :string,
      exclusion_type: :string,
      group_name: :string,
      group_code: :string,
      chapter: :string
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :code,
        :type,
        :group_description,
        :description,
        :congenital
      ])
      |> validate_diagnosis_code()
      |> validate_diagnosis_name()
      |> validate_inclusion(:congenital, ["Yes", "No"])
      |> validate_inclusion(:exclusion_type, ["General Exclusion", "Pre-existing condition"])
      |> validate_inclusion(:type, ["Non-Dreaded", "Dreaded"])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_diagnosis_code(changeset) do
    if is_nil(changeset.changes[:code])  do
      changeset
    else
      diagnosis_id = get_diagnosis_by_code(changeset.changes.code)
      if is_nil(diagnosis_id) do
        changeset
      else
        add_error(changeset, :code, "Diagnosis code already exist!")
      end
    end
  end

  defp validate_diagnosis_name(changeset) do
    if is_nil(changeset.changes[:name])  do
      changeset
    else
      diagnosis_id = get_diagnosis_by_name(changeset.changes.name)
      if is_nil(diagnosis_id) do
        changeset
      else
        add_error(changeset, :name, "Diagnosis name already exist!")
      end
    end
  end

  defp insert_diagnosis(diagnosis_param) do
    diagnosis_param =
      diagnosis_param.changes

    %Diagnosis{}
    |> Diagnosis.changeset(diagnosis_param)
    |> Repo.insert
  end

  defp get_diagnosis_by_code(code) do
    Diagnosis
    |> where([d], d.code == ^code)
    |> select([d], d.id)
    |> Repo.one()
  end

  defp get_diagnosis_by_name(code) do
    Diagnosis
    |> where([d], d.code == ^code)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_diagnosis(id) do
    Diagnosis
    |> Repo.get(id)
  end

  def get_diagnosis_using_name(name) do
    name = String.downcase("#{name}")
    Diagnosis
    |> where([d], like(fragment("lower(?)", d.description), ^"%#{name}%") or like(fragment("lower(?)", d.code), ^"%#{name}%"))
    |> limit(100)
    |> Repo.all()
  end

  def get_100_diagnosis do
    Diagnosis
    |> limit(100)
    |> Repo.all()
  end

end

defmodule Innerpeace.Db.Base.SpecializationContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Specialization,
    Base.TranslationContext
  }

  def insert_or_update_specialization(params) do
    specialization = get_specialization_by_name(params.name)
    if is_nil(specialization) do
      create_specialization(params)
    else
      update_specialization(specialization.id, params)
    end
  end

  def get_specialization_by_name(name) do
    Specialization
    |> Repo.get_by(name: name)
  end

  def get_all_specializations do
    Specialization
    |> Repo.all
  end

  def get_specialization(id) do
    Specialization
    |> Repo.get!(id)
  end

  def create_specialization(specialization_param) do
    %Specialization{}
    |> Specialization.changeset(specialization_param)
    |> Repo.insert
  end

  def update_specialization(id, specialization_param) do
    id
    |> get_specialization()
    |> Specialization.changeset(specialization_param)
    |> Repo.update
  end

  def delete_specialization(id) do
    id
    |> get_specialization()
    |> Repo.delete
  end

  def get_all_specializations_search do
    Specialization
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.name})
  end

  def get_translated_specializations(conn, specializations) do
    specializations =
      specializations
      |> Enum.into([], fn({sp_name, sp_val}) ->
        specialization = get_specialization_by_name(sp_name)
        name = TranslationContext.get_translated_values(conn, sp_name)
        if is_nil(name) do
          specialization = Map.put(specialization , :name, sp_name)
        else
          specialization = Map.put(specialization , :name, name)
        end
      end)
      |> Enum.map(&{&1.name, &1.name})
  end
end

defmodule Innerpeace.Db.Base.ProcedureCategoryContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.ProcedureCategory
  }

  def insert_or_update_procedure_category(params) do
    procedure_category = get_procedure_category_by_name(params.name)
    if is_nil(procedure_category) do
      create_procedure_category(params)
    else
      update_procedure_category(procedure_category.id, params)
    end
  end

  def get_procedure_category_by_name(name) do
    ProcedureCategory
    |> Repo.get_by(name: name)
  end

  def get_all_procedure_category do
    ProcedureCategory
    |> Repo.all
  end

  def get_procedure_category(id) do
    ProcedureCategory
    |> Repo.get!(id)
  end

  def create_procedure_category(procedure_category_param) do
    %ProcedureCategory{}
    |> ProcedureCategory.changeset(procedure_category_param)
    |> Repo.insert
  end

  def update_procedure_category(id, procedure_category_param) do
    id
    |> get_procedure_category()
    |> ProcedureCategory.changeset(procedure_category_param)
    |> Repo.update
  end

  def delete_procedure_category(id) do
    id
    |> get_procedure_category()
    |> Repo.delete
  end

end

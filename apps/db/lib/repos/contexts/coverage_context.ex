defmodule Innerpeace.Db.Base.CoverageContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Coverage
  }

 def insert_or_update_coverage(params) do
   coverage = get_coverage_by_name(params.name)
    if is_nil(coverage) do
      create_coverage(params)
    else
      update_coverage(coverage.id, params)
    end
 end

  def get_coverage_by_name(name) do
    Coverage
    |> Repo.get_by(name: name)
  end

  def get_coverage_by_id(id) do
    Coverage
    |> Repo.get(id)
  end

  def get_all_coverages do
    Coverage
    |> order_by([c], [c.name])
    |> Repo.all()
  end

  def get_all_coverages_in_upper(coverage_name) do
    Coverage
    |> where([c], fragment("UPPER(?)", c.name) == fragment("UPPER(?)", ^coverage_name))
    |> Repo.all()
  end

  def get_coverage(id) do
    Coverage
    |> Repo.get!(id)
  end

  def create_coverage(coverage_params) do
    %Coverage{}
    |> Coverage.changeset(coverage_params)
    |> Repo.insert()
  end

  def update_coverage(id, coverage_param) do
    id
    |> get_coverage()
    |> Coverage.changeset(coverage_param)
    |> Repo.update()
  end

  def delete_coverage(id) do
    id
    |> get_coverage()
    |> Repo.delete()
  end

  def get_coverage_name_by_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c.name)
    |> Repo.one!()
  end

  def get_coverage_by_code(code) do
    Coverage
    |> Repo.get_by(code: code)
  end

  def get_coverage_by_code_return_id(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c.id)
    |> Repo.one!()
  end

  def get_coverage_by_id(id) do
    Coverage
    |> where([c], c.id == ^id)
    |> Repo.all()
  end

  def get_coverage_id_by_name(name) do
    Coverage
    |> where([c], c.name == ^name)
    |> select([c], c.id)
    |> Repo.one!()
  rescue
    _ ->
      nil
  end

  def get_coverage_name_by_id(id) do
    Coverage
    |> where([c], c.id == ^id)
    |> select([c], c.name)
    |> Repo.one!()
  rescue
    _ ->
      nil
  end

  def repo_get_coverage_by_id(nil), do: nil
  def repo_get_coverage_by_id(id) do
    Coverage
    |> Repo.get(id)
  end

  def get_coverage_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> Repo.all()
  end

  def load_coverage_dropdown(type) do
    Coverage
    |> where([c], c.plan_type == ^type)
    |> select([c],
      %{
        "value" => c.id,
        "name" => c.name
      }
    )
    |> Repo.all()
  end

  def get_all_coverage_name do
    Coverage
    |> select([:name])
    |> Repo.all()
  end
end

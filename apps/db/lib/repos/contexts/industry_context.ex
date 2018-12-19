defmodule Innerpeace.Db.Base.IndustryContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Industry
  }

  def insert_or_update_industry(params) do
    industry = get_industry_by_code(params.code)
    if is_nil(industry) do
      create_industry(params)
    else
      update_industry(industry.id, params)
    end
  end

  def get_industry_by_code(code) do
    Industry
    |> Repo.get_by(code: code)
  end

  def get_all_industry do
    Industry
    |> Repo.all
  end

  def get_industry(id) do
    Industry
    |> Repo.get!(id)
  end

  def create_industry(industry_param) do
    %Industry{}
    |> Industry.changeset(industry_param)
    |> Repo.insert
  end

  def update_industry(id, industry_param) do
    id
    |> get_industry()
    |> Industry.changeset(industry_param)
    |> Repo.update
  end

  def delete_industry(id) do
    id
    |> get_industry()
    |> Repo.delete
  end

end

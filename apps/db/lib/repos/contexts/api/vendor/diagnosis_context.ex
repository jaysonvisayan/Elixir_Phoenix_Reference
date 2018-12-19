defmodule Innerpeace.Db.Base.Api.Vendor.DiagnosisContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Diagnosis,
  }

  alias Ecto.Changeset

  def search_diagnosis(params) do
    diagnosis = Diagnosis
    |> where([d],
      (is_nil(d.group_description) or like(fragment("lower(?)", d.group_description), fragment("lower(?)", ^"%#{params["diagnosis"]}%"))) or
      (is_nil(d.description) or like(fragment("lower(?)", d.description), fragment("lower(?)", ^"%#{params["diagnosis"]}%"))) or
      (is_nil(d.code)  or like(fragment("lower(?)", d.code), fragment("lower(?)", ^"%#{params["diagnosis"]}%"))))
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all()
  end

  def search_all_diagnosis do
    Diagnosis
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all()
  end

end

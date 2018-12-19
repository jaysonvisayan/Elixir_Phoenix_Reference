defmodule Innerpeace.Db.Base.Api.Vendor.ProcedureContext do
  @moduledoc false

  import Ecto.{Query}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure
  }

  alias Innerpeace.Db.Base.Api.{
    UtilityContext,
  }
  alias Ecto.Changeset

  def get_all_queried_payor_procedures(search_query) do
    procedure = PayorProcedure
    |> where([d],
      (is_nil(d.description) or like(fragment("lower(?)", d.description), fragment("lower(?)", ^"%#{search_query}%"))) or
      (is_nil(d.code)  or like(fragment("lower(?)", d.code), fragment("lower(?)", ^"%#{search_query}%"))))
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all
    |> Repo.preload([
      :package_payor_procedures,
      :payor,
      :procedure_logs,
      procedure: :procedure_category,
      facility_payor_procedures: [facility: [:category, :type]]
    ])
  end
end

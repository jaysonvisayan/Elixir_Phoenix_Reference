defmodule Innerpeace.Db.Base.Api.ProcedureContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure,
    Base.Api.ProcedureContext
  }
  test "get_all_queried_payor_procedure/1, loads all payor procedure with no search parameter" do
    search_query = ""
    query = "%#{search_query}%"
    pp_query = (
      from p in PayorProcedure,
      where: p.is_active == true
        and (ilike(p.description, ^query)
        or ilike(p.code, ^query)),
      select: p
    )

    pp =
      pp_query
      |> Repo.all
      |> Repo.preload([
        :package_payor_procedures,
        :payor,
        :procedure_logs,
        procedure: :procedure_category,
        facility_payor_procedures: [facility: [:category, :type]]
      ])

    payor_procedure = ProcedureContext.get_all_queried_payor_procedures("")
    assert pp == payor_procedure
  end

  test "get_all_queried_payor_procedure/1, loads all payor procedure with search parameter" do
    insert(:payor_procedure, description: "sample", code: "123")

    search_query = "sample"

    query = "%#{search_query}%"
    pp_query = (
      from p in PayorProcedure,
      where: p.is_active == true
        and (ilike(p.description, ^query)
        or ilike(p.code, ^query)),
      select: p
    )

    pp =
      pp_query
      |> Repo.all
      |> Repo.preload([
        :package_payor_procedures,
        :payor,
        :procedure_logs,
        procedure: :procedure_category,
        facility_payor_procedures: [facility: [:category, :type]]
      ])

    payor_procedure = ProcedureContext.get_all_queried_payor_procedures(search_query)
    assert pp == payor_procedure
  end
end

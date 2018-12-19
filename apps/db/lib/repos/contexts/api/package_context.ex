defmodule Innerpeace.Db.Base.Api.PackageContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Package,
    # Db.Schemas.PayorProcedure,
    Db.Schemas.PackagePayorProcedure,
    Db.Schemas.Benefit,
    Db.Schemas.BenefitPackage,
    Db.Schemas.PackageFacility,
    Db.Schemas.PayorProcedure,
    Db.Schemas.Procedure,
    Db.Schemas.Facility,
    Db.Schemas.PackageLog
  }

  alias Innerpeace.Db.Base.ProcedureContext
  alias Innerpeace.Db.Base.FacilityContext

  def get_packages_by_name_or_code(package) do
    if not is_nil(package) do
      Package
      |> where([p], (p.code == ^package or p.name == ^package))
      |> limit(1)
      |> preload([p], [package_payor_procedure: ^procedures_subquery])
      |> preload([p], [package_facility: ^facility_subquery])
      |> Repo.one()
    else
      {:invalid_package}
    end
  end

  defp facility_subquery do
    PackageFacility
    |> join(:inner, [pf], f in Facility, pf.facility_id == f.id)
    |> select([pf, f], %{
      code: f.code,
      name: f.name,
      rate: pf.rate
    })
  end

  defp procedures_subquery do
    PackagePayorProcedure
    |> join(:inner, [ppp], pp in PayorProcedure, ppp.payor_procedure_id == pp.id)
    |> join(:inner, [ppp, pp], p in Procedure, pp.procedure_id == p.id)
    |> select([ppp, pp, p], %{
      standard_cpt_code: p.code,
      standard_cpt_description: p.description,
      payor_cpt_code: pp.code,
      payor_cpt_description: pp.description,
      gender: [ppp.male, ppp.female],
      age_from: ppp.age_from,
      age_to: ppp.age_to
    })
  end

end

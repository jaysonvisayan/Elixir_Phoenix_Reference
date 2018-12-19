defmodule Innerpeace.PayorLink.Web.PackageView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.PackageContext
  alias Innerpeace.Db.Base.Api.UtilityContext

  def check_package_payor_procedure(package_payor_procedures, payor_procedure_id) do
    list = [] ++ for package_payor_procedure <- package_payor_procedures do
      package_payor_procedure.payor_procedure.id
    end
    Enum.member?(list, payor_procedure_id)
  end

  def map_procedures(package, payor_procedures) do
    package_payor_procedure = [] ++ for package_procedure <- package.package_payor_procedure do
      package_procedure.payor_procedure
    end

    package_payor_procedure =
      package_payor_procedure
      |> Enum.map(&({&1.description, &1.id}))

    payor_procedures =
      payor_procedures
      |> Enum.map(&({&1.description, &1.id}))

    payor_procedures -- package_payor_procedure
  end

  def map_facilities(package, facilities) do
    package_facility = [] ++ for package_procedure <- package.package_facility do
      package_procedure.facility
    end

    package_facility =
      package_facility
      |> Enum.map(&({&1.name, &1.id}))

    facilities =
      facilities
      |> Enum.map(&({&1.name, &1.id}))

    facilities -- package_facility
  end

  def map_facility_code(name) do
    facility =
    Facility
    |> Repo.get_by(name: name)

    _facility2 = facility.code

  end

  def count_package_payor_procedure(package_id) do
    PackageContext.get_package_payor_procedure_count(package_id)
  end

  def sanitize_log_message(value) do
    UtilityContext.sanitize_value(value)
  end
end

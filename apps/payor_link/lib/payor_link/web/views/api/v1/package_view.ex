defmodule Innerpeace.PayorLink.Web.Api.V1.PackageView do
  use Innerpeace.PayorLink.Web, :view

  def render("package.json", %{package: package}) do
    %{
      code: package.code,
      name: package.name,
      procedures: render_many(
        package.package_payor_procedure,
        Innerpeace.PayorLink.Web.Api.V1.PackageView,
        "package_payor_procedures.json", as: :package_payor_procedures
      ),
      facilities: render_many(
        package.package_facility,
        Innerpeace.PayorLink.Web.Api.V1.PackageView,
        "package_facility.json", as: :package_facility
      )
    }
  end

  def render("package_payor_procedures.json", %{package_payor_procedures: package_payor_procedures}) do
    %{
      standard_cpt_code: package_payor_procedures.standard_cpt_code,
      standard_cpt_description: package_payor_procedures.standard_cpt_description,
      payor_cpt_code: package_payor_procedures.payor_cpt_code,
      payor_cpt_description: package_payor_procedures.payor_cpt_description,
      gender: check_gender(package_payor_procedures.gender),
      age: check_age(package_payor_procedures.age_from, package_payor_procedures.age_to)
    }
  end

  defp check_gender(gender) do
    case gender do
       [true, true] ->
         ["male", "female"]
      [false, true] ->
        ["female"]
      ["false, false"] ->
        [""]
      [true, false] ->
        ["male"]
      _ ->
        [""]
    end
  end

  defp check_age(age_from, age_to) do
    if age_from == 0 do
      "0" <> "#{ - age_to}"
    else
      "#{age_from - age_to}"
    end
  end

  def render("package_facility.json", %{package_facility: package_facility}) do
    %{
      code: package_facility.code,
      name: package_facility.name,
      rate: package_facility.rate
    }
  end
end

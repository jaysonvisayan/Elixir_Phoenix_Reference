defmodule Innerpeace.PayorLink.Web.Api.V1.ProcedureView do
  use Innerpeace.PayorLink.Web, :view

  def render("load_all_procedures.json", %{payor_procedures: payor_procedures}) do
    %{
      procedures: render_many(
        payor_procedures,
        Innerpeace.PayorLink.Web.Api.V1.ProcedureView,
        "payor_procedure.json",
        as: :payor_procedure
      )}
  end

  def render("payor_procedure.json", %{payor_procedure: payor_procedure}) do
    %{
      id: payor_procedure.id,
      payor_code: payor_procedure.code,
      payor_description: payor_procedure.description,
      is_active: payor_procedure.is_active,
      standard_procedure: render_one(
        payor_procedure.procedure,
        Innerpeace.PayorLink.Web.Api.V1.ProcedureView,
        "procedure.json", as: :procedure
      )
    }
  end

  def render("procedure.json", %{procedure: procedure}) do
    %{
      id: procedure.id,
      code: procedure.code,
      description: procedure.description
    }
  end

  def render("procedures_index.json", %{procedure: procedure}) do
    %{
      description: procedure.description,
      code: procedure.code,
      facility_payor_procedures: render_many(
        procedure.facility_payor_procedures,
        Innerpeace.PayorLink.Web.Api.V1.ProcedureView,
        "facility_payor_procedure.json",
        as: :facility_payor_procedure
      ),
      package_payor_procedures: render_many(
        procedure.package_payor_procedures,
        Innerpeace.PayorLink.Web.Api.V1.ProcedureView,
        "package_payor_procedure.json",
        as: :package_payor_procedure
      ),
      exclusion_procedures: render_many(
        procedure.exclusion_procedures,
        Innerpeace.PayorLink.Web.Api.V1.ProcedureView,
        "exclusion_procedure.json",
        as: :exclusion_procedure
      )
    }
  end

  def render("procedure_logs.json", %{procedure_log: procedure_log}) do
    %{
      inserted_at: procedure_log.inserted_at,
      messaget: procedure_log.message
    }
  end

  def render("facility_payor_procedure.json", %{facility_payor_procedure: facility_payor_procedure}) do
    %{
      code: facility_payor_procedure.code,
      name: facility_payor_procedure.name,
      facility: %{
        code: facility_payor_procedure.facility.code,
        name: facility_payor_procedure.facility.name
      }
    }
  end

  def render("package_payor_procedure.json", %{package_payor_procedure: package_payor_procedure}) do
    %{
      age_from: package_payor_procedure.age_from
    }
  end

  def render("exclusion_procedure.json", %{exclusion_procedure: exclusion_procedure}) do
    %{
      procedure_id: exclusion_procedure.procedure_id
    }
  end

  def render("facility.json", %{facility: _facility}) do
    # TODO
  end

end

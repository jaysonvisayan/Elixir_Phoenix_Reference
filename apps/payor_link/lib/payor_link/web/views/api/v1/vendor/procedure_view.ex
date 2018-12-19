defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.ProcedureView do
  use Innerpeace.PayorLink.Web, :view

  def render("load_all_procedures.json", %{payor_procedures: payor_procedures}) do
    %{
      procedures: render_many(
        payor_procedures,
        Innerpeace.PayorLink.Web.Api.V1.Vendor.ProcedureView,
        "payor_procedure.json",
        as: :payor_procedure
      )}
  end

  def render("payor_procedure.json", %{payor_procedure: payor_procedure}) do
    %{
      id: payor_procedure.id,
      payor_code: payor_procedure.code,
      payor_description: payor_procedure.description,
      is_active: payor_procedure.is_active
      # standard_procedure: render_one(
      #   payor_procedure.procedure,
      #   Innerpeace.PayorLink.Web.Api.V1.Vendor.ProcedureView,
      #   "procedure.json", as: :procedure
      # )
    }
  end

  def render("procedure.json", %{procedure: procedure}) do
    %{
      id: procedure.id,
      code: procedure.code,
      description: procedure.description
    }
  end


end

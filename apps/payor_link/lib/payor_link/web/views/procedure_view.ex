defmodule Innerpeace.PayorLink.Web.ProcedureView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.Api.UtilityContext

  def filter_payor_procedures(payor_procedures, procedures) do
    payor_procedures =
      payor_procedures
      |> Enum.filter(&(&1.is_active))
      |> Enum.map(&{"#{&1.procedure.code} - #{&1.procedure.description}", &1.procedure.id})
      |> Enum.sort()
    procedures =
      procedures
      |> Enum.map(&{"#{&1.code} - #{&1.description}", &1.id})
      |> Enum.sort()
    procedures -- payor_procedures
  end

  def display_status(status) do
    if status do
      "Active"
    else
      "Inactive"
    end
  end

   def display_date(date) do
    "#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}"
  end

  def payor_procedure_codes_to_list(payor_procedures) do
    payor_procedures
    |> Enum.map(&(&1.code))
  end

  def render("load_search_procedures.json", %{payor_procedures: payor_procedures}) do
    for payor_procedure <- payor_procedures do
      %{
        id: payor_procedure.id,
        procedure_id: payor_procedure.procedure_id,
        code: payor_procedure.code,
        description: payor_procedure.description,
        procedure_code: payor_procedure.procedure.code,
        procedure_description: payor_procedure.procedure.description,
        is_active: payor_procedure.is_active
      }
    end
  end

  def render("logs.json", %{procedure: procedure}) do
    %{
      type: procedure.type,
      id:  procedure.id,
      description: procedure.description,
      code: procedure.code,
      procedure_logs: render_many(procedure.procedure_logs, Innerpeace.PayorLink.Web.ProcedureView, "procedure_logs.json", as: :procedure_log)
    }
  end

  def render("procedure_logs.json", %{procedure_log: procedure_log}) do
    %{
      message: UtilityContext.sanitize_value(procedure_log.message),
      inserted_at: UtilityContext.sanitize_value(procedure_log.inserted_at)
    }
  end

  def get_cpt_code(nil), do: ""
  def get_cpt_code(procedure) do
    procedure.cpt_code
  rescue
    _ ->
      ""
  end

end

defmodule Innerpeace.PayorLink.Web.Api.V1.ExclusionView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.Api.UtilityContext, as: UC

  def render("index.json", %{exclusions: exclusions}) do
    %{data: render_many(
      exclusions,
      Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
      "exclusion.json",
      as: :exclusion
    )}
  end

  def render("exclusion.json", %{exclusion: exclusion}) do
    %{
      id: exclusion.id,
      code: exclusion.code,
      name: exclusion.name,
      exclusion_procedures: render_many(
        exclusion.exclusion_procedures,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_procedure.json",
        as: :exclusion_procedure
      ),
      exclusion_diseases: render_many(
        exclusion.exclusion_diseases,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      )
    }
  end

  def render("exclusion_procedure.json", %{exclusion_procedure: exclusion_procedure}) do
    %{
      description: exclusion_procedure.procedure.description,
      code: exclusion_procedure.procedure.code
    }
  end

  def render("exclusion_disease.json", %{exclusion_disease: exclusion_disease}) do
    %{
      description: exclusion_disease.disease.description,
      code: exclusion_disease.disease.code,
      type: exclusion_disease.disease.type,
      congential: exclusion_disease.disease.congenital,
      exclusion_type: exclusion_disease.disease.exclusion_type,
      chapter: exclusion_disease.disease.chapter,
      group_description: exclusion_disease.disease.group_description
    }
  end

  def render("load_genex.json", %{exclusion: exclusion}) do
    %{
      disease: render_many(
        exclusion.disease,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "genex_disease.json",
        as: :disease
      ),
      procedures: render_many(
        exclusion.procedure,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "genex_procedure.json",
        as: :procedure
      )
    }
  end

  def render("genex_procedure.json", %{procedure: procedure}) do
    %{
      description: procedure.description,
      code: procedure.code
    }
  end

  def render("genex_disease.json", %{disease: disease}) do
    %{
      description: disease.description,
      code: disease.code
    }
  end

  def render("duration.json", %{duration: duration}) do
    value = if duration.covered_after_duration == "peso" do
      duration.cad_amount
    else
      duration.percentage
    end
    %{
      disease_type: duration.disease_type,
      duration: duration.duration,
      covered_after_duration: duration.covered_after_duration,
      value: value
    }
  end

  def render("precon_exclusion.json", %{exclusion: exclusion}) do
    %{
      id: exclusion.id,
      code: exclusion.code,
      name: exclusion.name,
      duration: render_many(
        exclusion.exclusion_durations,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "duration.json",
        as: :duration
      ),
      diseases: render_many(
        exclusion.exclusion_diseases,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      )
    }
  end

  def render("pre_existing.json", %{exclusion: exclusion, condition: condition}) do
    %{
      code: exclusion.code,
      name: exclusion.name,
      diagnosis: render_many(
        exclusion.diagnoses,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      ),
      conditions: render_conditions(exclusion, condition)
    }
  end

  defp render_conditions(exclusion, false) do
    render_many(
        exclusion.conditions,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_condition.json",
        as: :exclusion_condition
    )
  end

  defp render_conditions(exclusion, true), do: nil

  def render("exclusion_condition.json", %{exclusion_condition: exclusion_condition}) do
    %{
      within_grace_period: exclusion_condition.within_grace_period,
      member_type: exclusion_condition.member_type,
      diagnosis_type: exclusion_condition.diagnosis_type,
      duration: exclusion_condition.duration,
      limit_type: exclusion_condition.inner_limit,
      limit_amount: exclusion_condition.inner_limit_amount
    }
  end

  def render("sap_pre_existing.json", %{exclusions: exclusions}) do
    render_many(
      exclusions,
      Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
      "sap_exclusion.json",
      as: :exclusion
    )
  end

  def render("sap_exclusion.json", %{exclusion: exclusion}) do
    %{
      #id: exclusion.id,
      updated_by: exclusion.updated_by.username,
      updated_at: UC.convert_date_format(exclusion.updated_at),
      name: exclusion.name,
      code: exclusion.code,
      #applicability: display_applicability(exclusion),
      diagnosis: render_many(
        exclusion.exclusion_diseases,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      ),
      conditions: render_many(
        exclusion.exclusion_conditions,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_condition.json",
        as: :exclusion_condition
      )
    }
  end

  defp display_applicability(exclusion) do
    dependent = exclusion.is_applicability_dependent
    principal = exclusion.is_applicability_principal
    dependent = if dependent, do: ["Dependent"], else: []
    principal = if principal, do: ["Principal"], else: []
    principal ++ dependent
  end

  def render("create_sap_exclusion.json", %{exclusion: exclusion}) do
    %{
      id: exclusion.id,
      code: exclusion.code,
      name: exclusion.name,
      type: exclusion.name,
      classification_type: exclusion.name,
      diagnoses: render_many(
        exclusion.diagnoses,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      ),
      procedures: render_many(
        exclusion.procedures,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_procedure.json",
        as: :exclusion_procedure
      ),
      policy: exclusion.policy || []
    }
  end

  def render("get_sap_exclusion.json", %{exclusion: exclusion}) do
    %{
      id: exclusion.id,
      code: exclusion.code,
      name: exclusion.name,
      type: exclusion.name,
      classification_type: exclusion.name,
      diagnoses: render_many(
        exclusion.diagnoses,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_disease.json",
        as: :exclusion_disease
      ),
      procedures: render_many(
        exclusion.procedures,
        Innerpeace.PayorLink.Web.Api.V1.ExclusionView,
        "exclusion_procedure.json",
        as: :exclusion_procedure
      ),
      policy: exclusion.policy || [],
      last_update: UC.convert_date_format(exclusion.last_update),
      last_updated_by: exclusion.last_updated_by
    }
  end

end

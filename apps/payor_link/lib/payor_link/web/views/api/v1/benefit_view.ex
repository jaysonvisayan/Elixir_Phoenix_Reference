defmodule Innerpeace.PayorLink.Web.Api.V1.BenefitView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.Api.UtilityContext, as: UC

  def render("index.json", %{benefit: benefit}) do
    %{
      data: render_many(
        benefit,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit.json",
        as: :benefit)
    }
  end

  def render("benefit.json", %{benefit: benefit}) do
    %{
      id: benefit.id,
      name: benefit.name,
      type: benefit.type,
      code: benefit.code,
      loa_facilitated: convert_bool_to_string(benefit.loa_facilitated),
      reimbursement: convert_bool_to_string(benefit.reimbursement),
      classification: benefit.classification,
      acu_type: benefit.acu_type,
      acu_coverage: benefit.acu_coverage,
      all_procedure: "#{benefit.all_procedure}",
      all_diagnosis: "#{benefit.all_diagnosis}",
      provider_access: benefit.provider_access,
      risk_share_type: benefit.risk_share_type,
      risk_share_value: benefit.risk_share_value,
      member_pays_handling: benefit.member_pays_handling,
      coverages: render_many(
        benefit.benefit_coverages,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_coverage.json",
        as: :benefit_coverage
      ),
      condition: benefit.condition,
      procedures: render_many(
        benefit.benefit_procedures,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_procedure.json",
        as: :benefit_procedure
      ),
      diseases: render_many(
        benefit.benefit_diagnoses,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_disease.json",
        as: :benefit_disease
      ),
      ruvs: render_many(
        benefit.benefit_ruvs,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_ruv.json",
        as: :benefit_ruv
      ),
      limits: render_many(
        benefit.benefit_limits,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_limit.json",
        as: :benefit_limit
      ),
      packages: render_many(
        benefit.benefit_packages,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_package.json",
        as: :benefit_package
      )
    }
  end

  defp convert_bool_to_string(nil), do: ""
  defp convert_bool_to_string(bool), do: "#{bool}"

  def render("benefit_coverage.json", %{benefit_coverage: benefit_coverage}) do
    %{
      id: benefit_coverage.coverage.id,
      name: benefit_coverage.coverage.name,
      description: benefit_coverage.coverage.description
    }
  end

  def render("benefit_coverage_dental.json", %{benefit_coverage: benefit_coverage}) do
    %{
      id: benefit_coverage.coverage.id,
      code: benefit_coverage.coverage.code,
      name: benefit_coverage.coverage.name
    }
  end

  def render("benefit_coverage_v2.json", %{benefit_coverage: benefit_coverage}) do
    %{
      id: benefit_coverage.coverage.id,
      name: benefit_coverage.coverage.name,
      code: benefit_coverage.coverage.code
    }
  end

  def render("benefit_procedure.json", %{benefit_procedure: benefit_procedure}) do
    %{
      id: benefit_procedure.procedure.id,
      code: benefit_procedure.procedure.code,
      description: benefit_procedure.procedure.description
    }
  end

  def render("benefit_package.json", %{benefit_package: benefit_package}) do
    %{
      id: benefit_package.id,
      code: benefit_package.package.code,
      name: benefit_package.package.name
    }
  end

  def render("benefit_disease.json", %{benefit_disease: benefit_disease}) do
    %{
      id: benefit_disease.diagnosis.id,
      code: benefit_disease.diagnosis.code,
      name: benefit_disease.diagnosis.name,
      description: benefit_disease.diagnosis.description
    }
  end

  def render("benefit_disease_v2.json", %{benefit_disease: benefit_disease}) do
    %{
      id: benefit_disease.diagnosis.id,
      code: benefit_disease.diagnosis.code,
      description: benefit_disease.diagnosis.description
    }
  end

  def render("benefit_ruv.json", %{benefit_ruv: benefit_ruv}) do
    %{
      id: benefit_ruv.ruv.id,
      code: benefit_ruv.ruv.code,
      description: benefit_ruv.ruv.description,
      type: benefit_ruv.ruv.type,
      value: benefit_ruv.ruv.value,
      effectivity_date: benefit_ruv.ruv.effectivity_date
    }
  end

  def render("benefit_limit.json", %{benefit_limit: benefit_limit}) do
    %{
      id: benefit_limit.id,
      coverages: benefit_limit.coverages,
      limit_type: benefit_limit.limit_type,
      value: check_benefit_limit_amount(benefit_limit)
    }
  end

  def render("benefit_limit_v2.json", %{benefit_limit: benefit_limit}) do
    %{
      coverages: [benefit_limit.coverages],
      id: benefit_limit.id,
      limit_type: benefit_limit.limit_type,
      limit_amount: check_benefit_limit_amount_v2(benefit_limit),
      limit_percentage: check_benefit_limit_percentage(benefit_limit),
      limit_session: check_benefit_limit_session(benefit_limit),
      limit_classification: benefit_limit.limit_classification

    }
  end

  def render("benefit_dental_limit.json", %{benefit_limit: benefit_limit}) do
    %{
      coverages: [benefit_limit.coverages],
      limit_type: benefit_limit.limit_type,
      limit_amount: check_benefit_limit_amount_v2(benefit_limit),
      limit_session: check_benefit_limit_session(benefit_limit),
      limit_tooth: check_benefit_limit_tooth(benefit_limit),
      limit_classification: benefit_limit.limit_classification,
      limit_area_type: benefit_limit.limit_area_type,
      limit_area: benefit_limit.limit_area

    }
  end

  defp check_benefit_limit_amount(benefit_limit) do
    case benefit_limit.limit_type do
      "Sessions" ->
        benefit_limit.limit_session
      "Plan Limit Percentage" ->
        benefit_limit.limit_percentage
      "Peso" ->
        benefit_limit.limit_amount
      _ ->
        benefit_limit.limit_amount
    end
  end

  defp check_benefit_limit_session(benefit_limit) do
    case benefit_limit.limit_type do
      "Sessions" ->
        benefit_limit.limit_session
      _ ->
        benefit_limit.limit_session
    end
  end

  defp check_benefit_limit_tooth(benefit_limit) do
    case benefit_limit.limit_type do
      "Tooth" ->
        benefit_limit.limit_tooth
      _ ->
        benefit_limit.limit_tooth
    end
  end

  defp check_benefit_limit_amount_v2(benefit_limit) do
    case benefit_limit.limit_type do
      "Peso" ->
        benefit_limit.limit_amount
      _ ->
        benefit_limit.limit_amount
    end
  end

  defp check_benefit_limit_percentage(benefit_limit) do
    case benefit_limit.limit_type do
      "Plan Limit Percentage" ->
        benefit_limit.limit_percentage
      _ ->
        benefit_limit.limit_percentage
    end
  end

  defp get_benefit_limit_code(benefit_limit) do
    benefit_limit_code = benefit_limit.coverages
  end

  def render("get_benefits.json", %{benefits: benefits}) do
    %{
      id: benefits.id,
      name: benefits.name,
      code: benefits.code,
      type: benefits.type,
      category: benefits.category,
      loa_facilitated: benefits.loa_facilitated,
      reimbursement: benefits.reimbursement,
      classification: benefits.classification,
      all_procedures: benefits.all_procedure,
      all_diagnoses: benefits.all_diagnosis,
      maternity_type: benefits.maternity_type,
      acu_type: benefits.acu_type,
      acu_coverage: benefits.acu_coverage,
      peme: benefits.peme,
      provider_access: benefits.provider_access,
      covered_enrollees: benefits.covered_enrollees,
      waiting_time: benefits.waiting_period,
      risk_share_type: benefits.risk_share_type,
      risk_share_value: benefits.risk_share_value,
      member_pays_handling: benefits.member_pays_handling,
      coverages: render_many(
        benefits.benefit_coverages,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_coverage_v2.json",
        as: :benefit_coverage
      ),
      ruvs: render_many(
        benefits.benefit_ruvs,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_ruv.json",
        as: :benefit_ruv
      ),
      diseases: render_many(
        benefits.benefit_diagnoses,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_disease_v2.json",
        as: :benefit_disease
      ),
      procedures: render_many(
        benefits.benefit_procedures,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_procedure.json",
        as: :benefit_procedure
      ),
      limits: render_many(
        benefits.benefit_limits,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_limit_v2.json",
        as: :benefit_limit
      )

      }
  end

  def render("show_dental_benefit.json", %{benefits: benefits}) do
    %{
      id: benefits.id,
      code: benefits.code,
      name: benefits.name,
      category: benefits.category,
      type: benefits.type,
      loa_facilitated: benefits.loa_facilitated,
      reimbursement: benefits.reimbursement,
      frequency: benefits.frequency,
      limits: render_many(
        benefits.benefit_limits,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_dental_limit.json",
        as: :benefit_limit
      ),
      cdt: render_many(
        benefits.benefit_procedures,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_procedure.json",
        as: :benefit_procedure
      ),
      coverages: render_many(
        benefits.benefit_coverages,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_coverage_dental.json",
        as: :benefit_coverage
      )
    }
  end

  def render("sap_dental_benefit.json", %{benefit: benefit}) do
    %{
      id: benefit.id,
      name: benefit.name,
      code: benefit.code,
      type: benefit.type,
      category: benefit.category,
      loa_facilitated: benefit.loa_facilitated,
      reimbursement: benefit.reimbursement,
      frequency: benefit.frequency,
      coverages: render_many(
        benefit.benefit_coverages,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_coverage_v2.json",
        as: :benefit_coverage
      ),
      limits: render_many(
        benefit.benefit_limits,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_limit_sap_dental.json",
        as: :benefit_limit
      ),
      cdt: render_many(
        benefit.benefit_procedures,
        Innerpeace.PayorLink.Web.Api.V1.BenefitView,
        "benefit_procedure.json",
        as: :benefit_procedure
      ),
    }
  end

  def render("benefit_limit_sap_dental.json", %{benefit_limit: benefit_limit}) do
    %{
      coverages: [benefit_limit.coverages],
      id: benefit_limit.id,
      limit_type: benefit_limit.limit_type,
      limit_amount: check_benefit_limit_amount_v2(benefit_limit),
      limit_session: check_benefit_limit_session(benefit_limit),
      limit_area: benefit_limit.limit_area,
      limit_area_type: benefit_limit.limit_area_type
    }
  end
end

defmodule Innerpeace.PayorLink.Web.Api.V1.DiagnosisView do
  use Innerpeace.PayorLink.Web, :view

  def render("show.json", %{diagnoses: diagnoses}) do
    %{data: render_one(diagnoses, Innerpeace.PayorLink.Web.Api.V1.DiagnosisView, "diagnoses.json", as: :diagnoses)}
  end

  def render("index.json", %{diagnoses: diagnoses}) do
    %{data: render_many(diagnoses, Innerpeace.PayorLink.Web.Api.V1.DiagnosisView, "diagnoses.json", as: :diagnoses)}
  end

  def render("diagnoses.json", %{diagnoses: diagnoses}) do
    %{
        id: diagnoses.id,
        code: diagnoses.code,
        name: diagnoses.name,
        description: diagnoses.description,
        group_name: diagnoses.group_name,
        chapter: diagnoses.chapter,
        type: diagnoses.type,
        congenital: diagnoses.congenital,
        exclusion_type: diagnoses.exclusion_type,
        group_description: diagnoses.group_description,
        group_code: diagnoses.group_code,
        classification: diagnoses.classification
    }
  end

  def render("diagnosis_web.json", %{diagnoses: diagnoses}) do
    %{data: render_many(diagnoses, Innerpeace.PayorLink.Web.Api.V1.DiagnosisView, "diagnoses_web.json", as: :diagnoses),
      count: Enum.count(diagnoses)}
  end

  def render("diagnoses_web.json", %{diagnoses: diagnoses}) do
      %{
        text: diagnoses.code <> " | " <> diagnoses.description,
        value: diagnoses.id
      }
  end
end

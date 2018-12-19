defmodule Innerpeace.PayorLink.Web.DiagnosisView do
  use Innerpeace.PayorLink.Web, :view

  def filter_coverage(coverage) do
    _coverage =
      coverage
      |> Enum.sort()
      |> Enum.join(", ")
  end

  def render("load_search_diagnosis.json", %{diagnoses: diagnoses}) do
    %{diagnosis: render_many(diagnoses, Innerpeace.PayorLink.Web.DiagnosisView, "diagnosis.json", as: :diagnosis)}
  end

  def render("diagnosis.json", %{diagnosis: diagnosis}) do
    %{
      id: diagnosis.id,
      code: diagnosis.code,
      description: diagnosis.description,
      type: diagnosis.type,
      group_name: diagnosis.group_name,
      chapter: diagnosis.chapter,
      congenital: if diagnosis.congenital == "N" do "No" else "Yes" end,
      group_code: if Enum.any?([diagnosis.group_code == "",
                                is_nil(diagnosis.group_code)]
                              ) do "" end,
      group_description: diagnosis.group_description,
      diagnosis_coverages: unless is_nil(diagnosis.diagnosis_coverages) do
        diagnosis.diagnosis_coverages
        |> Enum.into([], &(&1.coverage.name))
        |> Enum.sort()
        |> Enum.join(", ")
      end
    }
  end

end

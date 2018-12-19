defmodule Innerpeace.PayorLink.Web.CaseRateView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Base.{
    DiagnosisContext,
    RUVContext,
    Api.UtilityContext
  }

  def filter_diagnosis(diagnoses, case_rates) do
    list = [] ++ for diagnosis <- diagnoses do
      diagnosis
    end

    list =
    	list
      |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})

    list2 = [] ++ for case_rate <- case_rates do #selected diagnosis
      if is_nil(case_rate.diagnosis_id) do
      else
        _case_rate = DiagnosisContext.get_diagnosis(case_rate.diagnosis_id)
      end
    end

    list2 =
      list2
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)
      |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})

    _list3 = list -- list2
  end

  def filter_ruv(ruvs, case_rates) do
    list = [] ++ for ruv <- ruvs do
      ruv
    end
    list =
      list
      |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})

    list2 = [] ++ for case_rate <- case_rates do #selected ruvs
      if is_nil(case_rate.ruv_id) do
      else
        _case_rate =
        RUVContext.get_ruv_by_id(case_rate.ruv_id)
      end
    end

    list2 =
      list2
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)
      |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})

    _list3 = list -- list2
  end

  def get_diagnosis_ruv(case_rates) do
      if case_rates.type == "ICD" do
        if is_nil(case_rates.diagnosis_id) do
        else
          diagnosis = DiagnosisContext.get_diagnosis(case_rates.diagnosis_id)
          _diagnosis = diagnosis.code
        end
      else
        if is_nil(case_rates.ruv_id) do
        else
          ruv = RUVContext.get_ruv_by_id(case_rates.ruv_id)
          _ruv = ruv.code
        end
      end
  end

  def get_diagnosis_ruv_code_description(case_rates) do
      if case_rates.type == "ICD" do
        if is_nil(case_rates.diagnosis_id) do
        else
          diagnosis = DiagnosisContext.get_diagnosis(case_rates.diagnosis_id)
          _diagnosis = diagnosis.code <> "/" <> diagnosis.description
        end
      else
        if is_nil(case_rates.ruv_id) do
        else
          ruv = RUVContext.get_ruv_by_id(case_rates.ruv_id)
          _ruv = ruv.code <> "/" <> ruv.description
        end
      end
  end

  def get_diagnosis_ruv_description(case_rates) do
      if case_rates.type == "ICD" do
        if is_nil(case_rates.diagnosis_id) do
        else
          diagnosis = DiagnosisContext.get_diagnosis(case_rates.diagnosis_id)
          _diagnosis = diagnosis.description
        end
      else
        if is_nil(case_rates.ruv_id) do
        else
          ruv = RUVContext.get_ruv_by_id(case_rates.ruv_id)
          _ruv = ruv.description
        end
      end
  end

  def render("case_rate_logs.json", %{case_rate_logs: case_rate_logs}) do
    %{
      case_rate_logs: render_many(
        case_rate_logs,
        Innerpeace.PayorLink.Web.CaseRateView,
        "crate_logs.json",
        as: :logs
      )
    }
  end

  def render("crate_logs.json", %{logs: logs}) do
    %{
      "message": UtilityContext.sanitize_value(logs.message),
      "inserted_at": UtilityContext.sanitize_value(logs.inserted_at)
    } 
  end
end

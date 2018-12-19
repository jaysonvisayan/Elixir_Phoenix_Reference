defmodule Innerpeace.PayorLink.Web.ExclusionView do
  use Innerpeace.PayorLink.Web, :view

  def check_disease(exclusion_diseases, disease_id) do
    list = [] ++ for exclusion_disease <- exclusion_diseases do
      exclusion_disease.disease.id
    end
    Enum.member?(list, disease_id)
  end

  def check_procedure(exclusion_procedures, procedure_id) do
    list = [] ++ for exclusion_procedure <- exclusion_procedures do
      exclusion_procedure.procedure.id
    end
    Enum.member?(list, procedure_id)
  end

  def pre_existing(coverage) do
    if coverage == "pre_existing" do
      nil
    else
      "display: None;"
    end
  end

  def exclusion(coverage) do
    if coverage == "exclusion" do
      nil
    else
      "display: None;"
    end
  end

    def section(coverage) do
    if coverage == "pre_existing" do
      "Add Pre-existing Condition"
    else
      "Add Exclusion"
    end
  end

  def filter_exclusion_procedures(exclusion_procedures, procedures) do
    exclusion_procedures = for exclusion_procedure <- exclusion_procedures, into: [] do
      %{
        id: exclusion_procedure.procedure.id,
        code: exclusion_procedure.procedure.code,
        description: exclusion_procedure.procedure.description,
        section: exclusion_procedure.procedure.procedure.procedure_category.name,
        exclusion_type: exclusion_procedure.procedure.exclusion_type
      }
    end
    procedures = for procedure <- procedures, into: [] do
      %{
        id: procedure.id,
        code: procedure.code,
        description: procedure.description,
        section: procedure.procedure.procedure_category.name,
        exclusion_type: procedure.exclusion_type
      }
    end
    procedures -- exclusion_procedures
    |> Enum.sort_by(&(&1.exclusion_type))
  end

  def filter_general_exclusion_diseases(exclusion_diseases, diseases) do
    exclusion_diseases = for exclusion_disease <- exclusion_diseases, into: [] do
      %{
        id: exclusion_disease.disease.id,
        code: exclusion_disease.disease.code,
        description: exclusion_disease.disease.description,
        type: exclusion_disease.disease.type,
        exclusion_type: exclusion_disease.disease.exclusion_type
      }
    end
    diseases = for disease <- diseases, into: [] do
      %{
        id: disease.id,
        code: disease.code,
        description: disease.description,
        type: disease.type,
        exclusion_type: disease.exclusion_type
      }
    end
    diseases -- exclusion_diseases
    |> Enum.sort_by(&(&1.code))
  end

  def filter_pre_existing_exclusion_diseases(exclusion_durations, exclusion_diseases, diseases) do
    non_dreaded = [] ++ for duration = %{disease_type: "Non-Dreaded"} <- exclusion_durations, do: duration
    dreaded = [] ++ for duration = %{disease_type: "Dreaded"} <- exclusion_durations, do: duration

    exclusion_diseases = for exclusion_disease <- exclusion_diseases, into: [] do
      %{
        id: exclusion_disease.disease.id,
        code: exclusion_disease.disease.code,
        description: exclusion_disease.disease.description,
        type: exclusion_disease.disease.type,
        exclusion_type: exclusion_disease.disease.exclusion_type
      }
    end
    diseases = for disease <- diseases, into: [] do
      %{
        id: disease.id,
        code: disease.code,
        description: disease.description,
        type: disease.type,
        exclusion_type: disease.exclusion_type,
      }
    end
    duration_sort =
    diseases -- exclusion_diseases
    |> Enum.sort_by(&(&1.code))
    if Enum.empty?(non_dreaded) == false and Enum.empty?(dreaded) == false do
      duration_sort
    else
      if Enum.empty?(dreaded) do
        Enum.reject(duration_sort, &(&1.type == "Dreaded"))
      else
        Enum.reject(duration_sort, &(&1.type == "Non-Dreaded"))
      end
    end
  end

  ### for CPT
  def batch_cpt_count(uploaded_file) do
    cpt_codes = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.payor_cpt_code
    end

    cpt_codes
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.count
  end

  def cpt_success_checker(uploaded_file) do
    cpt_status = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.payor_cpt_status
    end

    cpt_status
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.filter(fn(x) -> x == "success" end)
    |> Enum.count()
  end

  def cpt_failed_checker(uploaded_file) do
    cpt_status = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.payor_cpt_status
    end

    cpt_status
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.filter(fn(x) -> x == "failed" end)
    |> Enum.count()
  end

  ### for Diagnosis
  def batch_icd_count(uploaded_file) do
    icd_codes = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.diagnosis_code
    end
    icd_codes
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.count

  end

  def icd_success_checker(uploaded_file) do
    icd_status = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.diagnosis_status
    end

    icd_status
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.filter(fn(x) -> x == "success" end)
    |> Enum.count()
  end

  def icd_failed_checker(uploaded_file) do
    icd_status = for uploaded_logs <- uploaded_file.exclusion_general_upload_logs do
      uploaded_logs.diagnosis_status
    end

    icd_status
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.filter(fn(x) -> x == "failed" end)
    |> Enum.count()

  end

end

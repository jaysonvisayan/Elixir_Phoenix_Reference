defmodule Innerpeace.Db.Parsers.ExclusionGeneralParser do

  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure,
    Schemas.Diagnosis,
    Schemas.Payor,
    Schemas.ExclusionGeneralUploadFile,
    Schemas.ExclusionGeneralUploadLog
  }

  alias Innerpeace.Db.Base.{
    ExclusionContext,
    DiagnosisContext,
    ProcedureContext
  }

  def parse_data(data, filename, user_id) do
    batch_no = ExclusionContext.get_eg_upload_file()
               |> Enum.count
               |> ExclusionContext.generate_batch_no()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      batch_no: batch_no,
      remarks: "ok"
    }
    {:ok, eg_file_upload} = ExclusionContext.create_exclusion_upload_file(file_params)

    Enum.each(data, fn({_, map}) ->
       case validate(map) do
      {:ok, result} ->
        remarks = for {key, {status, message}} <- result do
          if status == :error do
            "#{message}"
          else
            case key do
              :payor_cpt_status ->
                "Payor CPT Successfully updated"
              :diagnosis_status ->
                "Diagnosis Successfully updated"
            end
          end
        end

        params = %{
          payor_cpt_status: checker(result.payor_cpt_status),
          diagnosis_status: checker(result.diagnosis_status),
          payor_cpt_remarks: msg_checker(result.payor_cpt_status),
          diagnosis_remarks: msg_checker(result.diagnosis_status),
          payor_cpt_code: map["Payor CPT Code"],
          diagnosis_code: map["Diagnosis Code"]
        }

        if params.payor_cpt_code == "" and params.diagnosis_code == "" do
          nil
        else
          params
          |> Map.put(:exclusion_general_upload_file_id, eg_file_upload.id)
          |> Map.put(:filename, filename)
          |> Map.put(:created_by_id, user_id)
          |> insert_log()
        end

      _ ->
         {:invalid_format}
       end

    end)
  end

  defp msg_checker(status) do
    case status do
      {:error, message} ->
        message
      {:ok, %PayorProcedure{}} ->
        "Payor Procedure successfully tagged"
      {:ok, %Diagnosis{}} ->
        "Diagnosis successfully tagged"
      _ ->
        ""
    end
  end

  defp checker(status) do
    case status do
      {:error, message} ->
        "failed"
      {:ok, struct} ->
        "success"
      _ ->
        ""
    end
  end

  def validate(params) do
    cond do

      params["Diagnosis Code"] == "" and params["Payor CPT Code"] == "" ->
        payor_cpt = case get_payor_procedure_by_code(params["Payor CPT Code"]) do
          {:ok, payor_procedure} ->
            #### update d2
            update_payor_procedure(payor_procedure)
            {:ok, payor_procedure}

          {:payor_procedure_not_existing, message} ->
            {:error, message}

          {:payor_procedure_already_tagged, message} ->
            {:error, message}
        end

        diagnosis = case get_diagnosis_by_code(params["Diagnosis Code"]) do
          {:ok, diagnosis} ->
            #### update d2
            update_diagnosis(diagnosis)
            {:ok, diagnosis}

          {:diagnosis_not_existing, message} ->
            {:error, message}

          {:diagnosis_already_tagged, message} ->
            {:error, message}
        end

        {:ok, %{payor_cpt_status: "", diagnosis_status: ""}}

      params["Diagnosis Code"] == "" ->
        payor_cpt = case get_payor_procedure_by_code(params["Payor CPT Code"]) do
          {:ok, payor_procedure} ->
            #### update d2
            update_payor_procedure(payor_procedure)
            {:ok, payor_procedure}

          {:payor_procedure_not_existing, message} ->
            {:error, message}

          {:payor_procedure_already_tagged, message} ->
            {:error, message}
        end
        {:ok, %{payor_cpt_status: payor_cpt, diagnosis_status: ""}}

      params["Payor CPT Code"] == "" ->
        diagnosis = case get_diagnosis_by_code(params["Diagnosis Code"]) do
          {:ok, diagnosis} ->
            #### update d2
            update_diagnosis(diagnosis)
            {:ok, diagnosis}

          {:diagnosis_not_existing, message} ->
            {:error, message}

          {:diagnosis_already_tagged, message} ->
            {:error, message}
        end
        {:ok, %{payor_cpt_status: "", diagnosis_status: diagnosis}}

      true ->
        payor_cpt = case get_payor_procedure_by_code(params["Payor CPT Code"]) do
          {:ok, payor_procedure} ->
            #### update d2
            update_payor_procedure(payor_procedure)
            {:ok, payor_procedure}

          {:payor_procedure_not_existing, message} ->
            {:error, message}

          {:payor_procedure_already_tagged, message} ->
            {:error, message}
        end

        diagnosis = case get_diagnosis_by_code(params["Diagnosis Code"]) do
          {:ok, diagnosis} ->
            #### update d2
            update_diagnosis(diagnosis)
            {:ok, diagnosis}

          {:diagnosis_not_existing, message} ->
            {:error, message}

          {:diagnosis_already_tagged, message} ->
            {:error, message}
        end

        {:ok, %{payor_cpt_status: payor_cpt, diagnosis_status: diagnosis}}

    end

  end

  def get_payor_procedure_by_code(code) do
    case Repo.get_by(PayorProcedure, code: code) do

      payor_procedure = %PayorProcedure{} ->
        cond do
          is_nil(payor_procedure.exclusion_type) ->
            {:ok, payor_procedure}

          payor_procedure.exclusion_type == "General Exclusion" ->
            {:payor_procedure_already_tagged, "Payor Procedure is already tagged as General Exclusion"}

          payor_procedure.exclusion_type == "Pre-existing condition" ->
            {:payor_procedure_already_tagged, "Payor Procedure is already tagged as Pre-existing condition"}

          true ->
            ### default
            {:payor_procedure_already_tagged, "Payor Procedure is already tagged"}
        end

      nil ->
        {:payor_procedure_not_existing, "Payor CPT Code does not exist"}
    end
  end

  def get_diagnosis_by_code(code) do
    case Repo.get_by(Diagnosis, code: code) do

      diagnosis = %Diagnosis{} ->
        cond do
          is_nil(diagnosis.exclusion_type) ->
            {:ok, diagnosis}

          diagnosis.exclusion_type == "General Exclusion" ->
            {:diagnosis_already_tagged, "Diagnosis is already tagged as General Exclusion"}

          diagnosis.exclusion_type == "Pre-existing condition" ->
            {:diagnosis_already_tagged, "Diagnosis is already tagged as Pre-existing condition"}

          true ->
            {:diagnosis_already_tagged, "Diagnosis is already tagged"}
        end

      nil ->
        {:diagnosis_not_existing, "Diagnosis Code does not exist"}
    end
  end

  def insert_log(params) do
    params
    |> ExclusionContext.create_exclusion_upload_log()
  end

  def update_diagnosis(diagnosis) do
    params = %{exclusion_type: "General Exclusion"}
    diagnosis
    |> Diagnosis.changeset_exclusion_type(params)
    |> Repo.update()
  end

  def update_payor_procedure(payor_procedure) do
    params = %{exclusion_type: "General Exclusion"}
    payor_procedure
    |> PayorProcedure.changeset_exclusion_type(params)
    |> Repo.update()
  end

  def check_exclusion_type?(struct) do
    if struct.exclusion_type do
      true
    else
      false
    end
  end

  def logs_params(map) do
    params = %{
      payor_cpt_code: map["Payor CPT Code"],
      diagnosis_code: map["Diagnosis Code"],
    }
  end

  def get_payor_procedure_by_code(code) do
    PayorProcedure
    |> Repo.get_by(code: code)
  end

  defp check_columns(params) do
    values = Map.values(params)
    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Enum.filter(fn({k, v}) -> is_nil(v) or v == "" end)
        |> Enum.into(%{}, fn({k, v}) -> {Enum.join(["Please enter ", k]), v} end)
        |> Map.keys
        |> Enum.join(", ")

      {:missing, empty}
    else
      {:complete}
    end
  end

  defp check_discount(discount) do
    if discount > 100 || discount == 0 do
      {:invalid_discount}
    else
      {:valid_discount}
    end
  end

end

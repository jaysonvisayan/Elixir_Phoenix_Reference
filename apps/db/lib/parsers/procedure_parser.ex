defmodule Innerpeace.Db.Parsers.ProcedureParser do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Procedure,
    Schemas.PayorProcedure,
    Schemas.Payor,
    # Schemas.PayorProcedureUploadLog,
    # Schemas.PayorProcedureUploadFile
    Schemas.ProcedureUploadLog,
    Schemas.ProcedureUploadFile
  }

  alias Innerpeace.Db.Base.{
    ProcedureContext,
    FacilityContext,
    Api.UtilityContext
  }

  # NOTE for refactor
  def loop_procedure([], filename, user_id, filename_id), do: {:ok}
  def loop_procedure([{_, cpt} | tail], filename, user_id, filename_id) do
    if Kernel.is_map(cpt) == true do
      procedure([{"", cpt} | tail], filename, user_id, filename_id)
    else
      {:error, "Invalid Template"}
    end
  end

  def validate_unwanted_1st_symbols(cpt, procedure_params, filename, user_id, filename_id) do
    procedure_params
    |> Enum.map(fn({key, value}) ->
      value
      |> String.at(0)
      |> UtilityContext.beginning_restricting_symbols(["+", "-", "=", "@"], {key, value})
    end)
    |> Enum.filter(fn({x, y}) -> x == false end)
  end

  def procedure([{_, cpt} | tail], filename, user_id, filename_id) do
    with true <- (Map.has_key?(cpt, "Standard CPT Code") && Map.has_key?(cpt, "Standard CPT Description") && Map.has_key?(cpt, "Standard CPT Type")),
         procedure_params <- %{code: cpt["Standard CPT Code"], description: cpt["Standard CPT Description"], type: cpt["Standard CPT Type"]},
         collected_error_symbols = validate_unwanted_1st_symbols(cpt, procedure_params, filename, user_id, filename_id),
         validate_already_exist_or_null(%{
           cpt: cpt,
           procedure_params: procedure_params,
           filename: filename,
           user_id: user_id,
           filename_id: filename_id,
           collected_error_symbols: collected_error_symbols
         }) # pul = procedure_upload_logs
    do
      tail
      |> loop_procedure(filename, user_id, filename_id)
    else
      _ ->
        {:error, "CSV contains missing fields. Please upload another file"}
    end

  end

  def validate_already_exist_or_null(%{
    cpt: cpt,
    procedure_params: procedure_params,
    filename: filename,
    user_id: user_id,
    filename_id: filename_id,
    collected_error_symbols: collected_error_symbols}) do

    cond do
      procedure_params.code != "" && procedure_params.description != "" ->
        procedure = ProcedureContext.get_procedure_by_code(procedure_params.code)
        is_existing_procedure?(%{
          cpt: cpt,
          procedure: procedure,
          procedure_params: procedure_params,
          filename: filename,
          user_id: user_id,
          filename_id: filename_id,
          collected_error_symbols: collected_error_symbols
        })

      procedure_params.code == "" && procedure_params.description == "" ->

        enclose(%{
          cpt: cpt,
          procedure_params: procedure_params,
          filename: filename,
          user_id: user_id,
          filename_id: filename_id
          })

      true ->
        enclose(%{
          cpt: cpt,
          procedure_params: procedure_params,
          filename: filename, user_id: user_id,
          filename_id: filename_id,
          collected_error_symbols: collected_error_symbols
          })

    end
  end

  def is_existing_procedure?(%{
    cpt: cpt,
    procedure: procedure,
    procedure_params: procedure_params,
    filename: filename,
    user_id: user_id,
    filename_id: filename_id,
    collected_error_symbols: collected_error_symbols})
  do
    with true <- empty_collected?(collected_error_symbols),
         true <- is_nil(procedure)
    do
      {:ok, p} = %Procedure{} |> Procedure.changeset(procedure_params) |> Repo.insert
      filename_params = %{
        filename: filename,
        user_id: user_id,
        status: "success",
        remarks: "Procedure successfully added",
        procedure_id: p.id,
        procedure_upload_file_id: filename_id
      }
      record_upload_log(procedure_params, filename_params)
    else
      false ->
        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          remarks: Enum.join([cpt["Standard CPT Code"], " already exists"]),
          procedure_id: "",
          procedure_upload_file_id: filename_id
        }
        record_upload_log(procedure_params, filename_params)

      {:false, collected_error_symbols} ->
        filename_params = %{
          filename: filename,
          user_id: user_id,
          status: "failed",
          remarks: collected_error_symbols,
          procedure_id: "",
          procedure_upload_file_id: filename_id
        }
        record_upload_log(procedure_params, filename_params)
    end
  end

  #

  def empty_collected?(collected_error_symbols) do
    if Enum.empty?(collected_error_symbols) do
      true
    else
      {:false,
        collected_error_symbols
        |> Enum.into([], fn({a, {x, y}}) -> "cpt_#{Atom.to_string(x)} #{y} is invalid" end)
        |> Enum.join(", ")
      }
    end
  end

  def enclose(%{cpt: cpt,
    procedure_params: procedure_params,
    filename: filename,
    user_id: user_id,
    filename_id: filename_id,
    collected_error_symbols: collected_error_symbols
  }) do

    error_remarks = ""

    if procedure_params.code == "" do
      error_remarks = Enum.join([error_remarks, "Standard CPT code is required", ","])
    end

    if procedure_params.description == "" do
      error_remarks = Enum.join([error_remarks, "Standard CPT description is required", ","])
    end

    error_length = String.length(error_remarks)
    error_remarks = String.slice(error_remarks, 0..error_length - 2)
    filename_params = %{
      filename: filename,
      user_id: user_id,
      status: "failed",
      remarks: error_remarks,
      procedure_id: "",
      procedure_upload_file_id: filename_id
    }
    record_upload_log(procedure_params, filename_params)
  end

  def enclose(%{
    cpt: cpt,
    procedure_params: procedure_params,
    filename: filename,
    user_id: user_id,
    filename_id: filename_id
    }) do

    error_remarks = ""

    if procedure_params.code == "" do
      error_remarks = Enum.join([error_remarks, "Standard CPT code is required", ","])
    end

    if procedure_params.description == "" do
      error_remarks = Enum.join([error_remarks, "Standard CPT description is required", ","])
    end

    error_length = String.length(error_remarks)
    error_remarks = String.slice(error_remarks, 0..error_length - 2)
    filename_params = %{
      filename: filename,
      user_id: user_id,
      status: "failed",
      remarks: error_remarks,
      procedure_id: "",
      procedure_upload_file_id: filename_id
    }
    record_upload_log(procedure_params, filename_params)
  end

  def parse_data(data, filename, user_id) do
    batch_no = ProcedureContext.get_pp_upload_logs
      |> Enum.count

    file_params = %{
     filename: filename,
      created_by_id: user_id,
      batch_number: ProcedureContext.generate_batch_no(batch_no),
      remarks: "ok"
    }
    # {:ok, f} = %PayorProcedureUploadFile{} |> PayorProcedureUploadFile.changeset(file_params) |> Repo.insert
    {:ok, f} = %ProcedureUploadFile{} |> ProcedureUploadFile.changeset(file_params) |> Repo.insert

    procedure_array =
      data
      |> Enum.to_list
      |> loop_procedure(filename, user_id, f.id)

  end

  def record_upload_log(procedure_params, filename_params) do
    procedure_log_params = %{
      filename: filename_params.filename,
      cpt_code: procedure_params.code,
      cpt_description: procedure_params.description,
      cpt_type: procedure_params.type,
      # payor_cpt_code: payor_procedure_params.code,
      # payor_cpt_description: payor_procedure_params.description,
      status: filename_params.status,
      remarks: filename_params.remarks,
      created_by_id: filename_params.user_id,
      procedure_id: filename_params.procedure_id,
      procedure_upload_file_id: filename_params.procedure_upload_file_id
    }
    # %PayorProcedureUploadLog{} |> PayorProcedureUploadLog.changeset(payor_procedure_log_params) |> Repo.insert
    %ProcedureUploadLog{} |> ProcedureUploadLog.changeset(procedure_log_params) |> Repo.insert
  end

  # defp check_description(cpt) do
  #   code = cpt["Standard CPT Code"]
  #   desc = cpt["Standard CPT Description"]

  #   if desc == "" do
  #     {:valid}
  #   else
  #     p = ProcedureContext.get_procedure_by_code_and_desc(code, desc)
  #     if length(p) == 0  do
  #       {:not_valid, "Standard CPT description does not match with Standard CPT Code"}
  #     else
  #       {:valid}
  #     end
  #   end
  # end

  # defp check_required_field(cpt) do
  #   # raise cpt

  #   if procedure_params.code == "" do
  #     {:not_valid_standard_cpt_code, "Standard CPT code is required"}
  #   end

  #   if procedure_params.description == "" do
  #     {:not_valid_standard_cpt_desc, "Standard CPT description is required"}
  #   end

  #   if procedure_params.code == "" do
  #     {:not_valid_standard_cpt_type, "Standard CPT type is required"}
  #   end
  #   # if cpt["Payor CPT Code"] == "" do
  #   #   {:not_valid_payor_cpt_code, "Payor CPT code is required"}
  #   # end

  #   # if cpt["Payor CPT Description"] == "" do
  #   #   {:not_valid_payor_cpt_desc, "Payor CPT description is required"}
  #   # end

  # end

end

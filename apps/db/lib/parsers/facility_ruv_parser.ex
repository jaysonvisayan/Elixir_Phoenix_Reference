defmodule Innerpeace.Db.Parsers.FacilityRUVParser do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.RUV,
    Schemas.FacilityRUV,
    Schemas.RUVUploadLog,
    Schemas.RUVUploadFile,
    Schemas.FacilityRUVUploadLog,
    Schemas.FacilityRUVUploadFile
  }

  alias Innerpeace.Db.Base.{
    FacilityContext,
    RUVContext
  }

  def parse_data(data, filename, facility_id, user_id) do

    batch_no =
      facility_id
      |> FacilityContext.get_fr_upload_logs()
      |> Enum.count()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      facility_id: facility_id,
      batch_no: FacilityContext.generate_ruv_batch_no(facility_id, batch_no),
      remarks: "ok"
    }

    {:ok, upload_file} = FacilityContext.create_fr_upload_file(file_params)

    # Batch Upload
    Enum.map(data, fn({_, data}) ->

      with {:passed} <- validations(1, data, []) do

      ruv_code = data["RUV Code"]
      ruv = RUVContext.get_ruv_by_code(ruv_code)
      params = %{
          facility_id: facility_id,
          code: data["Facility RUV Code"],
          name: data["Facility RUV Description"]
        }

      if not is_nil(ruv) do
        description = ruv.description
        type = ruv.type
        value = ruv.value
        effectivity_date = ruv.effectivity_date
      else
        description = data["RUV Description"]
        type = data["RUV Type"]
        value = data["Value"]
        effectivity_date = data["Effectivity Date"]
      end

      log_params = %{
        facility_ruv_upload_file_id: upload_file.id,
        filename: filename,
        ruv_code: data["RUV Code"],
        ruv_description: description,
        ruv_type: type,
        value: value,
        effectivity_date: effectivity_date,
        created_by_id: user_id
      }
      with {:complete} <- check_columns(data),
           # Check for empty fields

           %RUV{} <- ruv,
           # Check if ruv is existing

           nil <- FacilityContext.get_fr(ruv.id, facility_id),
           # Check if facility_ruv if existing

           {:ok, fr} <- FacilityContext.create_facility_ruv!(
                          Map.put(params, :ruv_id, ruv.id))
           # Insert facility_ruv

      do
        # IO.puts "Successfully Inserted.."
        {:ok, log} = insert_log(log_params, "success", "ok")
      else
        {:missing, empty} ->
          # IO.puts "Empty fields"
          insert_log(log_params, "failed", empty)

        nil ->
          # IO.puts "RUV does not exist."
          insert_log(log_params, "failed", "RUV does not exist.")
        %FacilityRUV{} = facility_ruv ->
          # IO.puts "Facility RUV already exist."
          insert_log(log_params, "failed", "Faciltiy RUV already exist.")
        {:error, changeset} ->
          fr_id = changeset.changes.facility_ruv_id
          FacilityContext.delete_facility_ruv(fr_id)
          # IO.puts "All fields are required!"
          insert_log(log_params, "failed", "Some errors in data")
      end
    else
    {:not_equal} ->
      {:not_equal}
    # {:invalid_date} ->
    #   {:invalid_date}
    end
    end)
    # Batch Upload End
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

  defp insert_log(params, status, remarks) do
    params
    |> Map.put(:status, status)
    |> Map.put(:remarks, remarks)
    |> FacilityContext.create_fr_upload_log()
  end

  defp validations(step, data, message) do
    case step do
      # validate columns
      1 ->
        if {:complete} == validate_columns(data) do
          validations(2, data, message)
        else
          {:missing, empty} = validate_columns(data)
          count_empty = empty |> String.split(",") |> Enum.count

          if count_empty >= 13 do
            {:ignored}
          else
            message = message ++ [empty]
            validations(2, data, message)
          end
        end

      # validate ruv type
      2 ->
          code = data["RUV Code"]
          with false <- code == ""  do
            # On success returns no error
            {:passed}
          else
            true ->
            # if ruv type is empty
              {:not_equal}
          end

      # validate effictivity_date
      # 3 ->
      #     code = data["Effectivity Date"]
      #     with false <- code == ""  do
      #       # On success returns no error
      #       {:passed}
      #     else
      #       true ->
      #       # if ruv type is empty
      #         {:not_equal}
      #     end
    end
  end

  def validate_columns(params) do
    values =
      params
      |> Map.drop(optional_keys())
      |> Map.values()

    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Map.drop(optional_keys())
        |> Enum.filter(fn({k, v}) -> is_nil(v) or v == "" end)
        |> Enum.into(%{}, fn({k, v}) -> {Enum.join(["Please enter ", k]), v} end)
        |> Map.keys
        |> Enum.join(", ")

      {:missing, empty}
    else
      {:complete}
    end
  end

  defp optional_keys do
    [
      "RUV Type"
      # "Effectivity Date"
    ]
  end

  # defp validate_date(date) do
  #   try do
  #     [mm, dd, yyyy] = String.split(date, "/")

  #     if String.length(dd) == 1, do: dd = "0#{dd}"
  #     if String.length(mm) == 1, do: mm = "0#{mm}"
  #     if String.length(yyyy) == 2, do: yyyy = "20#{yyyy}"

  #     date = Ecto.Date.cast!("#{yyyy}-#{mm}-#{dd}")

  #     {:true, date}
  #   rescue
  #     MatchError ->
  #       {:invalid_date}
  #     ArgumentError ->
  #       {:invalid_date}
  #     Ecto.CastError ->
  #       {:invalid_date}
  #     FunctionClauseError ->
  #       {:invalid_date}
  #     _ ->
  #       {:invalid_date}
  #   end
  # end

end

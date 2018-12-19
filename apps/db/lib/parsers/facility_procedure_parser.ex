defmodule Innerpeace.Db.Parsers.FacilityPayorProcedureParser do

  alias Innerpeace.Db.{
    # Repo,
    # Schemas.Procedure,
    Schemas.PayorProcedure,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityRoomRate,
    Schemas.FacilityPayorProcedureRoom,
    # Schemas.Payor,
    # Schemas.PayorProcedureUploadLog,
    # Schemas.PayorProcedureUploadFile
    # Schemas.FacilityPayorProcedureUploadLog,
    # Schemas.FacilityPayorProcedureUploadFile
  }

  alias Innerpeace.Db.Base.{
    ProcedureContext,
    FacilityContext
  }

  def parse_data(data, filename, facility_id, user_id) do
    batch_no =
      facility_id
      |> FacilityContext.get_fpp_upload_logs()
      |> Enum.count()

    file_params = %{
      filename: filename,
      created_by_id: user_id,
      facility_id: facility_id,
      batch_no: FacilityContext.generate_batch_no(facility_id, batch_no),
      remarks: "ok"
    }

    {:ok, upload_file} = FacilityContext.create_fpp_upload_file(file_params)

    # Batch Upload
    Enum.each(data, fn({_, data}) ->

    effective_date =
      if data["Effective Date"] == "" do
        data["Effective Date"]
      else
        eff_date = String.trim(data["Effective Date"])
        [mm, dd, yyyy] = String.split(eff_date, "/")

        dd =
          if String.length(dd) == 1 do
            "0#{dd}"
          else
            dd
          end
        mm =
          if String.length(mm) == 1 do
            "0#{mm}"
          else
            mm
          end
        yyyy =
          if String.length(yyyy) == 2 do
            "20#{yyyy}"
          else
            yyyy
          end

        Ecto.Date.cast!("#{yyyy}-#{mm}-#{dd}")
      end

      payor_procedure_code = data["Payor CPT Code"]
      room_code = data["Room Code"]
      params = %{
          facility_id: facility_id,
          code: data["Facility CPT Code"],
          name: data["Facility CPT Description"]
        }

      log_params = %{
        facility_payor_procedure_upload_file_id: upload_file.id,
        filename: filename,
        room_code: data["Room Code"],
        payor_cpt_code: data["Payor CPT Code"],
        #payor_cpt_name: data["Payor CPT Name"],
        provider_cpt_code: data["Facility CPT Code"],
        provider_cpt_name: data["Facility CPT Description"],
        amount: data["Amount"],
        discount: data["Discount"],
        start_date: effective_date,
        created_by_id: user_id
      }

      fpp_room_params = %{
        amount: data["Amount"],
        discount: data["Discount"],
        start_date: effective_date
      }

      payor_procedure = ProcedureContext.get_payor_procedure(payor_procedure_code)
      room = FacilityContext.get_facility_room_rate_by_code(facility_id, room_code)

      with {:complete} <- check_columns(data),
           # Check for empty fields

           {:valid_discount} <- check_discount(String.to_integer(data["Discount"])),
           # Validate Discount

           %FacilityRoomRate{} <- room,
           # Check if room is existing

           %PayorProcedure{} <- payor_procedure,
           # Check if payor_procedure is existing

           {:room_not_found} <- FacilityContext.get_facility_room_rate_by_id(room.id, payor_procedure.id, facility_id),
           # Check if Facility Payor Procedure room is existing

           nil <- FacilityContext.get_fpp(payor_procedure.id, facility_id),
           # Check if facility_payor_procedure if existing

           {:ok, fpp} <- FacilityContext.create_facility_payor_procedure!(
                          Map.put(params, :payor_procedure_id, payor_procedure.id)),
           # Insert facility_payor_procedure

           {:ok, _cfppr} <- FacilityContext.create_facility_payor_procedure_room(
                            fpp_room_params
                            |> Map.put(:facility_payor_procedure_id, fpp.id)
                            |> Map.put(:facility_room_rate_id, room.id))
          # Insert facility_payor_procedure_room

      do
        # IO.puts "Successfully Inserted.."
        insert_log(log_params, "success", "ok")
      else
        {:missing, empty} ->
          # IO.puts "Empty fields"
          insert_log(log_params, "failed", empty)

        {:invalid_discount} ->
          # IO.puts "Invalid Discount"
          insert_log(log_params, "failed", "Discount must only be 1-100")

        {:not_found} ->
          # IO.puts "Facility Room Rate does not exist."
          insert_log(log_params, "failed", "Room Code is not mapped yet to the Facility.")

        %FacilityPayorProcedureRoom{} ->
          # IO.puts "Facility Payor Procedure Room is already exist."
          insert_log(log_params, "failed", "Procedure already has a rate for this room type.")

        nil ->
          # IO.puts "Payor Procedure does not exist."
          insert_log(log_params, "failed", "Payor CPT code does not exist.")

        fpp = %FacilityPayorProcedure{} ->
          {:ok, _cfppr} =
            fpp_room_params
            |> Map.put(:facility_payor_procedure_id, fpp.id)
            |> Map.put(:facility_room_rate_id, room.id)
            |> FacilityContext.create_facility_payor_procedure_room()

            # IO.puts "Successfully Inserted.."
            insert_log(log_params, "success", "ok")

        {:error, changeset} ->
          fpp_id = changeset.changes.facility_payor_procedure_id
          FacilityContext.delete_facility_payor_procedure(fpp_id)
          # IO.puts "All fields are required!"
          insert_log(log_params, "failed", "Some errors in data")
      end
    end)
    # Batch Upload End
  end

  defp check_columns(params) do
    values = Map.values(params)
    if Enum.any?(values, fn(val) -> is_nil(val) or val == "" end) do
      empty =
        params
        |> Enum.filter(fn({_k, v}) -> is_nil(v) or v == "" end)
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

  defp insert_log(params, status, remarks) do
    params
    |> Map.put(:status, status)
    |> Map.put(:remarks, remarks)
    |> FacilityContext.create_fpp_upload_log()
  end

end

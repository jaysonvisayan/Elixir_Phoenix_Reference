defmodule Innerpeace.PayorLink.Web.FacilityView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.FacilityContext, as: FC

  def name(first_name, last_name, suffix) do
    Enum.join([first_name, last_name, suffix], "  ")
  end

  def filter_code_type(room, facility_room_rate) do
    room =
      room
      |> Enum.filter(&(&1.code))
      |> Enum.map(&{"#{&1.code}/#{&1.type}", &1.id})
      |> Enum.sort()
    facility_room_rate =
      facility_room_rate
      |> Enum.map(&{"#{&1.room.code}/#{&1.room.type}", &1.room.id})
      |> Enum.sort()
    _rooms = room -- facility_room_rate
  end

  def filter_ruv(ruv, facility_ruv) do
    ruv =
      ruv
      |> Enum.filter(&(&1.code))
      |> Enum.map(&{"#{&1.code}/#{&1.description}", &1.id})
      |> Enum.sort()
    facility_ruv =
      facility_ruv
      |> Enum.map(&{"#{&1.ruv.code}/#{&1.ruv.description}", &1.ruv.id})
      |> Enum.sort()
    ruvs = ruv -- facility_ruv
    if Enum.empty?(ruvs) do
      ["No RUV Records Found"]
    else
      ruvs
    end
  end

  def filter_payor_procedure(procedure, facility_id) do
    procedure -- FC.check_all_facility_payor_procedures(facility_id)
  end

  def count_result(fppul_id, status), do: Enum.count(FC.get_fpp_upload_logs_by_type(fppul_id, status))
  def count_ruv_result(frul_id, status), do: Enum.count(FC.get_fr_upload_logs_by_type(frul_id, status))
  def filter_facility_room_rate(facility_room_rates) do
    _data = for facility_room_rate <- facility_room_rates do
      {facility_room_rate.room.code <> "/" <> facility_room_rate.room.type, facility_room_rate.id}
    end
  end

  def filter_service_fee_coverages(facility_service_fees, coverages) do
    fsf = for facility_service_fee <- facility_service_fees do
      {facility_service_fee.coverage.name, facility_service_fee.coverage.id}
    end
    coverages =
      coverages
      |> Enum.map(&{&1.name, &1.id})
    coverages -- fsf
  end

  def map_service_fee_types(service_fee_types) do
    service_fee_types
    |> Enum.map(&{&1.text, &1.id})
  end

  def display_service_fee_rate(facility_service_fee) do
    case facility_service_fee.service_type.text do
      "MDR" ->
        facility_service_fee.rate_mdr
      "Fixed Fee" ->
        facility_service_fee.rate_fixed
      _ ->
        0
    end
  end

  def check_cf_fee(pf, ps_id) do
    if not Enum.empty?(pf.practitioner_facility_consultation_fees) do
      pfcf_record =
        for pfcf <- pf.practitioner_facility_consultation_fees do
          if pfcf.practitioner_specialization_id == ps_id do
            pfcf
          end
        end
        |> Enum.uniq
        |> List.delete(nil)
        |> List.first

      if is_nil(pfcf_record) or is_nil(pfcf_record.fee), do: "", else: pfcf_record.fee
    else
      ""
    end
  end

  def check_facility_status(status) do
    if String.downcase("#{status}") == "pending", do: "", else: "disabled"
  end

  def get_facility_text(data) do
    if is_nil(data) do
      ""
    else
      data.text
    end

  end

end

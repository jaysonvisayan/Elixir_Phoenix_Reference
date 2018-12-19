defmodule Innerpeace.Db.Base.FacilityContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.Parsers.
  {
    FacilityPayorProcedureParser,
    FacilityRUVParser
  }
  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.FacilityContact,
    Schemas.FacilityPayorProcedure,
    Schemas.PractitionerFacility,
    Schemas.ProductCoverageFacility,
    Schemas.ProductCoverage,
    Schemas.AccountProduct,
    Schemas.MemberProduct,
    Schemas.Dropdown,
    Schemas.FacilityPayorProcedureRoom,
    Schemas.FacilityPayorProcedureUploadLog,
    Schemas.FacilityPayorProcedureUploadFile,
    Schemas.FacilityRoomRate,
    Schemas.FacilityRUV,
    Schemas.Room,
    Schemas.RUV,
    Schemas.PayorProcedure,
    Schemas.FacilityFile,
    Schemas.FacilityServiceFee,
    Schemas.FacilityRUVUploadLog,
    Schemas.FacilityRUVUploadFile,
    Schemas.PractitionerSchedule,
    Schemas.FacilityLocationGroup,
    Schemas.FacilityUploadFile,
    Schemas.FacilityUploadLog,
    Schemas.User,
    Schemas.Contact,
    Schemas.LocationGroup
  }

  alias Innerpeace.Db.{
    Base.FileContext,
    Base.DropdownContext,
    Base.UserContext,
    Parsers.FacilityParser
  }

  def insert_or_update_facility(facility_params) do
      facility = get_facility_by_code(facility_params["code"])
      if is_nil(facility) do
        facility_params["created_by_id"]
        |> create_facility_seed(facility_params)
      else
        facility_params["created_by_id"]
        |> update_facility_seed(facility, facility_params)
      end
  end

  def get_facility_by_code(code) do
    Facility
    |> Repo.get_by(code: code)
    |> Repo.preload([
      :releasing_mode,
      :prescription_clause,
      :vat_status,
      :category,
      :payment_mode,
      :type
    ])
  end

  def create_facility(user_id, facility_params) do
    %Facility{}
    |> Facility.step1_changeset(facility_params)
    |> Repo.insert()
  end

  def format_date(date) do
    if date == "" || is_nil(date) do
      date
    else
      year =
        date
        |> String.slice(6, 4)

      month =
        date
        |> String.slice(0, 2)

      day =
        date
        |> String.slice(3, 2)

      Enum.join([year, month, day], "-")
    end
  end

  def create_facility_contact(params) do
    %FacilityContact{}
    |> FacilityContact.changeset(params)
    |> Repo.insert()
  end

  def update_step1_facility(user_id, facility, facility_params) do
    facility
    |> Facility.step1_changeset(facility_params)
    |> Repo.update()
  end

  def update_step2_facility(user_id, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("step", 3)
      |> Map.put("updated_by_id", user_id)

    if is_nil(facility_params["location_group_ids"]) do
    else
      delete_facility_location_groups(facility)

      Enum.each(facility_params["location_group_ids"], fn(location_group_id) ->
        insert_facility_location_group(%{
          facility_id: facility.id,
          location_group_id: location_group_id
        })
      end)
    end

    facility
    |> Facility.step2_changeset(facility_params)
    |> Repo.update()
  end

  def insert_facility_location_group(flg_params) do
    %FacilityLocationGroup{}
    |> FacilityLocationGroup.changeset(flg_params)
    |> Repo.insert()
  end

  def delete_facility_location_groups(facility) do
    FacilityLocationGroup
    |> where([flg], flg.facility_id == ^facility.id)
    |> Repo.delete_all()
  end

  def update_step4_facility(user_id, facility, facility_params) do
    facility_params =
      facility_params
      # Temporarily changed to step 6 (pending step 5)
      |> Map.put("step", 6)
      |> Map.put("updated_by_id", user_id)

    facility
    |> Facility.step4_changeset(facility_params)
    |> Repo.update()
  end

  def update_step_facility(facility, attrs) do
    facility
    |> Facility.changeset(attrs)
    |> Repo.update()
  end

  def update_general(facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put(
        "affiliation_date",
        format_date(facility_params["affiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "disaffiliation_date",
        format_date(facility_params["disaffiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_from",
        format_date(facility_params["phic_accreditation_from"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_to",
        format_date(facility_params["phic_accreditation_to"])
      )

    facility
    |> Facility.update_general_changeset(facility_params)
    |> Repo.update()
  end

  def update_address(%Facility{} = facility, params) do
    facility
    |> Facility.update_address_changeset(params)
    |> Repo.update()
  end

  def update_financial(%Facility{} = facility, params) do
    facility
    |> Facility.update_financial_changeset(params)
    |> Repo.update()
  end

  def get_all_facility do
    Facility
    |> Repo.all
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules: from(
          ps in PractitionerSchedule,
          select: %{
            time_from: fragment("CAST(? AS TEXT)", ps.time_from),
            time_to: fragment("CAST(? AS TEXT)", ps.time_to),
            day: ps.day,
            room: ps.room
          }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_all_facility! do
    Facility
    |> Repo.all
    |> Repo.preload([
      :type,
      :category
    ])
  end

  def get_all_facilities_with_code do
    Facility
    |> where([f], not is_nil(f.code) and f.code != "")
    |> Repo.all
  end

  def get_all_facility_where_code_has_value do
    Facility
    |> where([f], not is_nil(f.code) and f.code != "")
    |> select([:id, :name])
    |> Repo.all
  end

  def get_facility!(id) do
    Facility
    |> Repo.get!(id)
    |> Repo.preload([
      :type,
      :category,
      :vat_status,
      :prescription_clause,
      :payment_mode,
      :releasing_mode,
      [facility_files: :file],
      [facility_service_fees: [
          :coverage,
          :service_type
        ]
      ],
      [practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules: from(
          ps in PractitionerSchedule,
          select: %{
            time_from: fragment("CAST(? AS TEXT)", ps.time_from),
            time_to: fragment("CAST(? AS TEXT)", ps.time_to),
            day: ps.day,
            room: ps.room
          }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]],
      [facility_location_groups: :location_group]
    ])
  end

  def get_facility(id) do
    Facility
    |> Repo.get(id)
    |> Repo.preload([
      :type,
      :category,
      :vat_status,
      :prescription_clause,
      :payment_mode,
      :releasing_mode,
      [facility_files: :file],
      [facility_service_fees: [
          :coverage,
          :service_type
        ]
      ],
      [practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules: from(
          ps in PractitionerSchedule,
          select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
            room: ps.room
          }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ]
      ]]
    ])
  end

  def get_all_facility_contacts(facility_id) do
    fc =
      FacilityContact
      |> where([fc], fc.facility_id == ^facility_id)
      |> Repo.all

    if Enum.empty?(fc) do
      []
    else
      fc
      |> Ecto.assoc(:contact)
      |> Repo.all
      |> Repo.preload([:phones, :emails])
    end
  end

  def get_facility_by_contact_id(id) do
    fc = Repo.get_by FacilityContact, contact_id: id
    Repo.get! Facility, fc.facility_id
  end

  def get_facility_join_pf(practitioner_id) do
    query = PractitionerFacility
            |> where([pf], pf.practitioner_id == ^practitioner_id)
            |> select([pf], pf.facility_id)
            |> Repo.all()

    Facility
    |> where([f], f.id not in ^(query))
    |> Repo.all()
  end

  def get_all_facility_ruv(facility_id) do
    FacilityRUV
    |> where([fr], fr.facility_id == ^facility_id)
    |> Repo.all
    |> Repo.preload([:ruv, [facility: :category]])
  end

  def delete_fcontact(f_id, c_id) do
    FacilityContact
    |> where([fc], fc.facility_id == ^f_id
             and fc.contact_id == ^c_id)
    |> Repo.delete_all()
  end

  def get_facility_payor_procedure!(id) do
    FacilityPayorProcedure
    |> Repo.get!(id)
    |> Repo.preload([
      :payor_procedure,
      facility: [
        :practitioner_facilities,
        :category,
        :type
      ],
      facility_payor_procedure_rooms: [
        facility_room_rate: [
          :room,
          facility: [
            :category,
            :type
          ]
        ]
      ]
    ])
  end

def get_facility_payor_procedure(id) do
    FacilityPayorProcedure
    |> Repo.get(id)
    |> Repo.preload([
      :payor_procedure,
      facility: [
        :practitioner_facilities,
        :category,
        :type
      ],
      facility_payor_procedure_rooms: [
        facility_room_rate: [
          :room,
          facility: [
            :category,
            :type
          ]
        ]
      ]
    ])
  end

  def get_fpp_by_code(code) do
    FacilityPayorProcedure
    |> Repo.get_by(code: code)
    |> Repo.preload([
      :payor_procedure,
      facility: [
        :category,
        :type
      ],
      facility_payor_procedure_rooms: [
        facility_room_rate: [
          :room,
          facility: [
            :category,
            :type
          ]
        ]
      ]
    ])
  end

  def get_fpayor_procedure_id_and_code(facility_id) do
    FacilityPayorProcedure
    |> where([fpp], fpp.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload([
      facility: [
        :category,
        :type,
        facility_location_groups: :location_group
      ],
      facility_payor_procedure_rooms: [
        facility_room_rate: [
          facility: [
            :category,
            :type,
            facility_location_groups: :location_group
          ]
        ]
      ]
    ])
  end

  def get_all_facility_payor_procedures(facility_id) do
    FacilityPayorProcedure
    |> where([fpp], fpp.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload([
      :payor_procedure,
      facility: [
        :category,
        :type
      ],
      facility_payor_procedure_rooms: [
        facility_room_rate: [
          :room,
          facility: [
            :category,
            :type
          ]
        ]
      ]
    ])
  end

  def check_all_facility_payor_procedures(facility_id) do
   fpp =
    FacilityPayorProcedure
    |> where([fpp], fpp.facility_id == ^facility_id)
    |> Repo.all()

    if Enum.empty?(fpp)do
      []
    else
      fpp
      |> Ecto.assoc(:payor_procedure)
      |> Repo.all()
      |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})
    end
  end

  def create_facility_payor_procedure!(attrs \\ %{}) do
    %FacilityPayorProcedure{}
    |> FacilityPayorProcedure.changeset(attrs)
    |> Repo.insert()
  end

  def update_facility_payor_procedure!(
    %FacilityPayorProcedure{} = facility_payor_procedure,
    attrs
  ) do
    facility_payor_procedure
    |> FacilityPayorProcedure.changeset(attrs)
    |> Repo.update()
  end

  def change_facility_payor_procedure(
    %FacilityPayorProcedure{} = facility_payor_procedure
  ) do
    FacilityPayorProcedure.changeset(facility_payor_procedure, %{})
  end

  def get_facility_by_member_id(member_id) do
    product_coverages =
      Repo.all (from mp in MemberProduct,
                join: ap in AccountProduct,
                on: ap.id == mp.account_product_id,
                join: pc in ProductCoverage,
                on: pc.product_id == ap.product_id,
                where: mp.member_id == ^member_id,
                select: %{
                  type: pc.type,
                  pc_id: pc.id
                })

    pc_exceptions =
      product_coverages
      |> Enum.filter(fn(col) ->
        col.type == "exception"
      end)
      |> Enum.into([], fn(col) -> col.pc_id end)

    pc_inclusions =
      product_coverages
      |> Enum.filter(fn(col) ->
        col.type == "inclusion"
      end)
      |> Enum.into([], fn(col) -> col.pc_id end)

    inclusions =
      Repo.all(from pcf in ProductCoverageFacility,
               where: pcf.product_coverage_id in ^(pc_inclusions),
               select: %{
                 facility_id: pcf.facility_id,
                 pc_id: pcf.product_coverage_id
               })

    inclusions =
      inclusions
      |> Enum.into([], fn(col) -> col.facility_id end)
      |> Enum.uniq()

    if Enum.empty?(pc_exceptions) do
      facilities =
        Facility
        |> where([f],
                 f.id in ^(inclusions)
                 and f.status == "Affiliated"
                 and f.step == 7
        )
        |> select([f], %{
          "code" => f.code,
          "name" => f.name
        })
        |> order_by([f], f.name)
        |> Repo.all()

    else
      exceptions =
        Repo.all(from pcf in ProductCoverageFacility,
                 where: pcf.product_coverage_id in ^(pc_exceptions),
                 select: %{
                   facility_cnt: count(pcf.facility_id),
                   facility_id: pcf.facility_id,
                 },
                 group_by: pcf.facility_id)

      exceptions =
        exceptions
        |> Enum.filter(fn(col) ->
          col.facility_id not in (inclusions)
          and col.facility_cnt == length(pc_exceptions)
        end)
        |> Enum.into([], fn(col) -> col.facility_id end)

      facilities =
        Facility
        |> where([f],
                 f.id not in ^(exceptions)
                 and f.status == "Affiliated"
                 and f.step == 7
        )
        |> select([f], %{
          "code" => f.code,
          "name" => f.name
        })
        |> order_by([f], f.name)
        |> Repo.all()
    end
  end

  def search_facilities(%{
    "code" => code,
    "address" => address,
    "city" => city,
    "province" => province,
    "type" => facility_type,
    "status" => facility_status
  }) do

    query =
      Facility
      |> join(
        :inner,
        [f],
        c in Dropdown,
        c.type == "Facility Category" and c.id == f.fcategory_id
      )
      |> join(
        :inner,
        [f],
        t in Dropdown,
        t.type == "Facility Type" and t.id == f.ftype_id
      )
      |> where([f], f.step == 7)
      |> search_facilities_by_code(code)
      |> search_facilities_by_address(address)
      |> search_facilities_by_city(city)
      |> search_facilities_by_province(province)
      |> search_facilities_by_facility_status(facility_status)
      |> search_facilities_by_facility_type(facility_type)
      |> select(
        [f, c, t],
        %{
          "id" => f.id,
          "code" => f.code,
          "name" => f.name,
          "type" => t.text,
          "category" => c.text,
          "line_1" => f.line_1,
          "line_2" => f.line_2,
          "city" => f.city,
          "province" => f.province,
          "region" => f.region,
          "country" => f.country,
          "postal_code" => f.postal_code,
          "phone_no" => f.phone_no,
          "latitude" => f.latitude,
          "longitude" => f.longitude
        }
      )
      |> limit(50)
      |> Repo.all()

  end

  defp search_facilities_by_code(facility, ""), do: facility
  defp search_facilities_by_code(facility, code) do
    facility
    |> where(
      [f],
      (ilike(f.code, ^("%#{code}%")) or ilike(f.name, ^("%#{code}%")))
    )
  end

  defp search_facilities_by_address(facility, ""), do: facility
  defp search_facilities_by_address(facility, address) do
    facility
    |> where(
      [f],
      (ilike(
        fragment(
          "CONCAT(?, ' ', ?)",
          f.line_1,
          f.line_2
        ),
        ^("%#{address}%")
      )
      or ilike(f.line_1, ^("%#{address}%"))
      or ilike(f.line_2, ^("%#{address}%")))
    )
  end

  defp search_facilities_by_city(facility, ""), do: facility
  defp search_facilities_by_city(facility, city) do
    facility
    |> where(
      [f],
      ilike(f.city, ^("%#{city}%"))
    )
  end

  defp search_facilities_by_province(facility, ""), do: facility
  defp search_facilities_by_province(facility, province) do
    facility
    |> where(
      [f],
      ilike(f.province, ^("%#{province}%"))
    )
  end

  defp search_facilities_by_facility_type(facility, ""), do: facility
  defp search_facilities_by_facility_type(facility, facility_type) do
    facility
    |> where(
      [f, c, t],
      t.id == ^facility_type
    )
  end

  defp search_facilities_by_facility_status(facility, ""), do: facility
  defp search_facilities_by_facility_status(facility, facility_status) do
    facility
    |> where(
      [f],
      f.status == ^facility_status
    )
  end

  def delete_facility(facility_id) do
    Contact
    |> join(
      :inner, [c],
      fc in FacilityContact,
      c.id == fc.contact_id
    )
    |> where([c, fc], fc.facility_id == ^facility_id)
    |> Repo.delete_all()

    Facility
    |> where([f], f.id == ^facility_id)
    |> Repo.delete_all()
  end

  def create_fpp_export(payor_procedure_params, facility_id, user_id) do
    if String.ends_with?(payor_procedure_params["file"].filename, ["csv", "xls", "xlsx"]) do
      data =
        payor_procedure_params["file"].path
        |> File.stream!()
        |> CSV.decode(headers: true)

        keys = [
          "Payor CPT Code",
          "Facility CPT Code",
          "Facility CPT Description",
          "Room Code",
          "Amount",
          "Discount",
          "Effective Date"
        ]

        with true <- Enum.count(data) > 1,
             {:ok, map} <- Enum.at(data, 0),
             {:equal} <- column_checker(keys, map)
        do
          FacilityPayorProcedureParser.parse_data(
            data,
            payor_procedure_params["file"].filename,
            facility_id,
            user_id)
          {:ok}
        else
          false ->
            {:not_found}
          nil ->
            {:not_found}
          {:not_equal} ->
            {:not_equal}
        end
    else
    {:invalid_format}
    end
  end

  defp column_checker(keys, map) do
    if Enum.sort(keys) == Enum.sort(Map.keys(map)) do
      {:equal}
    else
      {:not_equal}
    end
  end

  def get_fpp(payor_procedure_id, facility_id) do
    fpp =
      FacilityPayorProcedure
      |> where([fpp],
               fpp.payor_procedure_id == ^payor_procedure_id
               and fpp.facility_id == ^facility_id
      )
      |> Repo.all()

    if Enum.empty?(fpp) do
      nil
    else
      Enum.at(fpp, 0)
    end
  end

  def create_fpp_upload_file(attrs) do
    %FacilityPayorProcedureUploadFile{}
    |> FacilityPayorProcedureUploadFile.changeset(attrs)
    |> Repo.insert()
  end

  def create_fpp_upload_log(attrs) do
    %FacilityPayorProcedureUploadLog{}
    |> FacilityPayorProcedureUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def get_fpp_upload_logs(facility_id) do
    FacilityPayorProcedureUploadFile
    |> where([fppuf], fppuf.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload(:facility_payor_procedure_upload_logs)
  end

  def get_fpp_upload_logs_by_type(fppul_id, status) do
    FacilityPayorProcedureUploadLog
    |> where([fppuf],
             fppuf.facility_payor_procedure_upload_file_id == ^fppul_id
             and fppuf.status == ^status
    )
    |> Repo.all()
  end

  def generate_batch_no(facility_id, batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no
      _ ->
        batch_no
    end

    with nil <-
          Repo.get_by(FacilityPayorProcedureUploadFile,
            facility_id: facility_id, batch_no: batch_no),
        false <- origin == 0
    do
      batch_no
    else
     %FacilityPayorProcedureUploadFile{} ->
        generate_batch_no(facility_id, origin + 1)
      true ->
        "0001"
    end
  end

  def generate_ruv_batch_no(facility_id, batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no
      _ ->
        batch_no
    end

    with nil <-
          Repo.get_by(FacilityRUVUploadFile, facility_id: facility_id, batch_no: batch_no),
        false <- origin == 0
    do
      batch_no
    else
     %FacilityRUVUploadFile{} ->
        generate_ruv_batch_no(facility_id, origin + 1)
      true ->
        "0001"
    end
  end

  def create_facility_payor_procedure_room(attrs) do
    %FacilityPayorProcedureRoom{}
    |> FacilityPayorProcedureRoom.changeset(attrs)
    |> Repo.insert()
  end

  def delete_facility_payor_procedure_room(fpp_id) do
    FacilityPayorProcedureRoom
    |> where([fppr], fppr.facility_payor_procedure_id == ^fpp_id)
    |> Repo.delete_all()
    {:ok, "deleted_all"}
  end

  def get_facility_payor_procedure_room(id) do
    FacilityPayorProcedureRoom
    |> Repo.get(id)
  end

  def create_many_facility_payor_procedure_room(room_params, id) do
    room_params =
      Enum.chunk_every(String.split(Enum.at(room_params, 0), ","), 4)
    room_params_inserted =
      for room_data <- room_params do
        if Enum.at(room_data, 2) == "" do
          attrs = %{
            facility_payor_procedure_id: id,
            facility_room_rate_id: Enum.at(room_data, 0),
            amount: Enum.at(room_data, 1),
            discount: "0",
            start_date: Enum.at(room_data, 3)
          }
        else
          attrs = %{
            facility_payor_procedure_id: id,
            facility_room_rate_id: Enum.at(room_data, 0),
            amount: Enum.at(room_data, 1),
            discount: Enum.at(room_data, 2),
            start_date: Enum.at(room_data, 3)
          }
        end
      create_facility_payor_procedure_room(attrs)
    end
    {:ok, room_params_inserted}
  end

  def get_facility_room_rate_by_code(facility_id, code) do
    frr =
      FacilityRoomRate
      |> join(:inner, [frr], r in Room, frr.room_id == r.id)
      |> where([frrr, r], r.code == ^code and frrr.facility_id == ^facility_id)
      |> Repo.all()

    if Enum.empty?(frr) do
      {:not_found}
    else
      List.first(frr)
    end
  end

  def get_facility_room_rate_by_id(frr_id, payor_procedure_id, facility_id) do
    frr =
      FacilityPayorProcedureRoom
      |> join(:inner,
              [fppr],
              frr in FacilityRoomRate,
              fppr.facility_room_rate_id == frr.id
      )
      |> join(:inner,
              [fppr, frr],
              fpp in FacilityPayorProcedure,
              fppr.facility_payor_procedure_id == fpp.id
      )
      |> join(:inner,
              [fppr, frr, fpp],
              f in Facility,
              fpp.facility_id == f.id
      )
      |> where([fppr, frr, fpp, f],
               f.id == ^facility_id
               and fppr.facility_room_rate_id == ^frr_id
               and fpp.payor_procedure_id == ^payor_procedure_id
      )
      |> Repo.one

    if is_nil(frr) do
      {:room_not_found}
    else
      frr
    end
  end

  def fpp_csv_download(params, facility_id) do
    param = params["search_value"]

    query = (
      from fppr in FacilityPayorProcedureRoom,
      join: frr in FacilityRoomRate, on: fppr.facility_room_rate_id == frr.id,
      join: r in Innerpeace.Db.Schemas.Room, on: frr.room_id == r.id,
      join: fpp in FacilityPayorProcedure,
        on: fppr.facility_payor_procedure_id == fpp.id,
      join: pp in PayorProcedure, on: fpp.payor_procedure_id == pp.id,
      where: fpp.facility_id == ^facility_id,

      # to be follow
      where:
      ilike(fragment("CONCAT(?, ' : ', ?)", pp.code, pp.description), ^("%#{param}%")) or
      ilike(fpp.code, ^("%#{param}%")) or
      ilike(fpp.name, ^("%#{param}%")) or
      ilike(r.code, ^("%#{param}%")) or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", fppr.start_date), ^("%#{param}%")) or
      ilike(fragment("CAST(? AS TEXT)", fppr.amount), ^("%#{param}%")) or
      ilike(fragment("CAST(? AS TEXT)", fppr.discount), ^("%#{param}%")),

      order_by: fpp.code,
      select: [
        pp.code,
        pp.description,
        fpp.code,
        fpp.name,
        r.code,
        fppr.amount,
        fppr.discount,
        fppr.start_date
      ]
    )

    query = Repo.all(query)

  end

  def get_all_completed_facility do
    query = from f in Facility,
      join: c in Dropdown,
      on: c.type == "Facility Category"
    and c.id == f.fcategory_id,
      join: t in Dropdown,
      on: t.type == "Facility Type"
    and t.id == f.ftype_id,
    where: f.step == 7,
      select:
    %{
      "id" => f.id,
      "code" => f.code,
      "name" => f.name,
      "title" => fragment("? || ? || ?", f.code, " | ", f.name),
      "type" => t.text,
      "category" => c.text,
      "line_1" => f.line_1,
      "line_2" => f.line_2,
      "city" => f.city,
      "province" => f.province,
      "region" => f.region,
      "country" => f.country,
      "postal_code" => f.postal_code,
      "phone_no" => f.phone_no,
      "latitude" => f.latitude,
      "longitude" => f.longitude
    },
      order_by: f.name

    Repo.all(query)
  end

  def get_all_facility_code do
    Facility
    |> select([f], f.code)
    |> Repo.all()
  end

  def get_batch_log(log_id, status) do
    query = (
      from fppul in FacilityPayorProcedureUploadLog,
      join: fppuf in FacilityPayorProcedureUploadFile,
      on: fppul.facility_payor_procedure_upload_file_id == fppuf.id,
      where:
        fppul.facility_payor_procedure_upload_file_id == ^log_id and
        fppul.status == ^status,
      select: [
        fppul.payor_cpt_code,
        fppul.provider_cpt_code,
        fppul.provider_cpt_name,
        fppul.room_code,
        fppul.amount,
        fppul.discount,
        fragment("TO_CHAR(?, 'MM/DD/YYYY')", fppul.start_date),
        fppul.remarks
      ]
    )
    result = Repo.all query
  end

  def delete_facility_payor_procedure(fpp_id) do
    fpp = Repo.get(FacilityPayorProcedure, fpp_id)
    Repo.delete(fpp)
  end

  def upload_facility_files(facility_id, files, type) do
    upload_status = for file <- files do
      with {:ok, inserted_file} <- FileContext.insert_file(),
           {:ok, uploaded_file} <-
            FileContext.upload_file(inserted_file, %{type: file})
      do
        params = %{
          facility_id: facility_id,
          file_id: inserted_file.id,
          type: type
        }
        insert_facility_file(params)
      else
        _ ->
          {:upload_error}
      end
    end
    if Enum.member?(upload_status, {:upload_error}) do
      {:upload_error}
    else
      {:ok}
    end
  end

  def insert_facility_file(params) do
    %FacilityFile{}
    |> FacilityFile.changeset(params)
    |> Repo.insert()
  end

  def delete_facility_files(file_ids) do
    file_ids =
      file_ids
      |> String.split(",")
      |> List.delete("")
    status = for file_id <- file_ids do
      with {:ok, facility_file} <- delete_facility_file(file_id),
           {:ok, file} <- FileContext.delete_file(file_id)
      do
        {:ok}
      else
        _ ->
          {:delete_error}
      end
    end
    if Enum.member?(status, {:delete_error}) do
      {:delete_error}
    else
      {:ok}
    end
  end

  def delete_facility_file(file_id) do
    FacilityFile
    |> where([ff], ff.file_id == ^file_id)
    |> Repo.one()
    |> Repo.delete()
  end

  def set_facility_ruv(attrs \\ %{}) do
    %FacilityRUV{}
    |> FacilityRUV.changeset(attrs)
    |> Repo.insert()
  end

  def create_facility_service_fee(params) do
    params = setup_service_fee_params(params)

    %FacilityServiceFee{}
    |> FacilityServiceFee.changeset(params)
    |> Repo.insert()
  end

  defp setup_service_fee_params(params) do
    service_type =
      DropdownContext.get_dropdown_value(params["service_type_id"]) || %{text: ""}

    case service_type.text do
      "No Discount Rate" ->
        params
      "Fixed Fee" ->
        Map.put(params, "rate_fixed", params["rate"])
      "Discount Rate" ->
        Map.put(params, "rate_mdr", params["rate"])
      _ ->
        %{}
    end
  end

  def get_facility_room_type(room_type, facility_code) do
    facility = get_facility_by_code(facility_code)
    FacilityRoomRate
    |> where([frr],
             frr.facility_room_type == ^room_type
             and frr.facility_id == ^facility.id
    )
    |> Repo.one()
  end

  def create_fr_export(ruv_params, facility_id, user_id) do
    if String.ends_with?(ruv_params["file"].filename, ["csv"]) do
      data =
        ruv_params["file"].path
        |> File.stream!()
        |> CSV.decode(headers: true)

      keys = [
        "RUV Code"
        # "Effectivity Date"
      ]

      with {:ok, map} <- Enum.at(data, 0),
           {:equal} <- column_checker(keys, map),
           true <- ruv_empty_checker(map)
      do
        FacilityRUVParser.parse_data(
          data,
          ruv_params["file"].filename,
          facility_id,
          user_id)
        {:ok}
      else
        false ->
          {:not_found}
        nil ->
          {:not_found}
        {:not_equal} ->
          {:not_equal}
      end
    else
      {:invalid_format}
    end
  end

  defp ruv_empty_checker(map) do
    if Enum.count(map) <= 1 do
      if map["RUV Code"] == "" do
        false
      else
        true
      end
    else
      true
    end
  end

  def get_fr(ruv_id, facility_id) do
    fr =
      FacilityRUV
      |> where([fr], fr.ruv_id == ^ruv_id and fr.facility_id == ^facility_id)
      |> Repo.all()

    if Enum.empty?(fr) do
      nil
    else
      Enum.at(fr, 0)
    end
  end

  def create_fr_upload_file(attrs) do
    %FacilityRUVUploadFile{}
    |> FacilityRUVUploadFile.changeset(attrs)
    |> Repo.insert()
  end

  def create_fr_upload_log(attrs) do
    %FacilityRUVUploadLog{}
    |> FacilityRUVUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def get_fr_upload_logs(facility_id) do
    FacilityRUVUploadFile
    |> where([fruf], fruf.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload(:facility_ruv_upload_logs)
  end

  def get_fr_upload_logs_by_type(frul_id, status) do
    FacilityRUVUploadLog
    |> where([fruf],
             fruf.facility_ruv_upload_file_id == ^frul_id
             and fruf.status == ^status
    )
    |> Repo.all()
  end

  def delete_facility_ruv(fr_id) do
    fr = Repo.get(FacilityRUV, fr_id)
    Repo.delete(fr)
  end

  def fr_csv_download(params, facility_id) do
    param = params["search_value"]

    query = (
      from fr in FacilityRUV,
      join: r in RUV, on: fr.ruv_id == r.id,
      where: fr.facility_id == ^facility_id,

      # to be follow
      where:
      ilike(r.code, ^("%#{param}%")) or
      ilike(r.description, ^("%#{param}%")) or
      ilike(r.type, ^("%#{param}%")) or
      ilike(fragment("text(?)", r.value), ^("%#{param}%")) or
      ilike(fragment("text(?)", r.effectivity_date), ^("%#{param}%")),

      order_by: r.code,
      select: [
        r.code,
        r.description,
        r.type,
        r.value,
        fragment("to_char(?, ?)", r.effectivity_date, "MM/DD/YYYY")
      ]
    )

    query = Repo.all(query)

  end

  def create_facility_ruv!(attrs \\ %{}) do
    %FacilityRUV{}
    |> FacilityRUV.changeset(attrs)
    |> Repo.insert()
  end

  def update_facility_ruv!(%FacilityRUV{} = facility_ruv, attrs) do
    facility_ruv
    |> FacilityRUV.changeset(attrs)
    |> Repo.update()
  end

  def change_facility_ruv(%FacilityRUV{} = facility_ruv) do
    FacilityRUV.changeset(facility_ruv, %{})
  end

  def get_ruv_batch_log(log_id, status) do
    query = (
      from frul in FacilityRUVUploadLog,
      join: fruf in FacilityRUVUploadFile,
      on: frul.facility_ruv_upload_file_id == fruf.id,
      where:
        frul.facility_ruv_upload_file_id == ^log_id and
        frul.status == ^status,
      select: [
        frul.ruv_code,
        frul.ruv_description,
        frul.ruv_type, frul.value,

        fragment("TO_CHAR(?, 'MM/DD/YYYY')", frul.effectivity_date),
        frul.remarks
      ]
    )
    result = Repo.all query
  end

  def create_facility_seed(user_id, facility_params) do
    facility_params =
      facility_params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    facility_params =
      facility_params
      |> Map.put(
        "affiliation_date",
        format_date(facility_params["affiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "disaffiliation_date",
        format_date(facility_params["disaffiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_from",
        format_date(facility_params["phic_accreditation_from"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_to",
        format_date(facility_params["phic_accreditation_to"])
      )

   %Facility{}
    |> Facility.changeset_facility_seed(facility_params)
    |> Repo.insert()
  end

  def update_facility_seed(user_id, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("updated_by_id", user_id)

    facility_params =
      facility_params
      |> Map.put(
        "affiliation_date",
        format_date(facility_params["affiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "disaffiliation_date",
        format_date(facility_params["disaffiliation_date"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_from",
        format_date(facility_params["phic_accreditation_from"])
      )

    facility_params =
      facility_params
      |> Map.put(
        "phic_accreditation_to",
        format_date(facility_params["phic_accreditation_to"])
      )

    facility
    |> Facility.changeset_facility_seed(facility_params)
    |> Repo.update()
  end

  # ACU
  def list_all_facility_rooms(facility_id) do
    FacilityRoomRate
    |> where([frr], frr.facility_id == ^facility_id)
    |> Repo.all()
    |> Repo.preload(:room)
  end

  def get_facility_room(facility_id, room_id) do
    room =
      FacilityRoomRate
      |> where([frr], frr.facility_id == ^facility_id
               and frr.room_id == ^room_id)
      |> Repo.one()
      |> Repo.preload(:room)

    %{
      room_rate: room.facility_room_rate,
      room_hierarchy: room.room.hierarchy
    }

    # room_rate =
    #   FacilityRoomRate
    #   |> where([frr], frr.facility_id == ^facility_id
    #            and frr.room_id == ^room_id)
    #   |> select([frr], frr.facility_room_rate)
    #   |> Repo.all()

    # if Enum.empty?(room_rate) do
    #   {:not_found}
    # else
    #   room_rate =
    #     room_rate
    #     |> Enum.uniq()
    #     |> List.delete(nil)
    #     |> List.first()
    # end
  end
  # End ACU
  #
  def get_facility_in_memberlink_api(facility_ids) do
    Facility
    |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
    |> where([f], f.id in ^facility_ids)
    |> where([f, d], f.step > 6 and f.status == "Affiliated" and
      (d.text == "HOSPITAL-BASED" or d.text == "CLINIC-BASED")
    )
    |> order_by([f], asc: f.name)
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
               time_from: fragment("CAST(? AS TEXT)", ps.time_from),
               time_to: fragment("CAST(? AS TEXT)", ps.time_to),
               day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_in_memberlink_by_name_api!(facility_ids, params) do
    facility_name = String.downcase(params["name"] || "")
    address = String.downcase(params["address"] || "")
    city = String.downcase(params["city"] || "")
    region = String.downcase(params["region"] || "")

    Facility
    |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
    |> where([f],
             f.id in ^facility_ids
             and ilike(fragment("lower(?)", f.name), ^"%#{facility_name}%")
             and ilike(fragment("lower(?)",
              fragment("concat(?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?)",
              f.line_1, f.line_2, f.city, f.postal_code, f.province, f.region, f.country)),
              ^"%#{address}%")
             and ilike(fragment("lower(?)", f.city), ^"%#{city}%")
             and ilike(fragment("lower(?)", f.region), ^"%#{region}%")
    )
    |> where([f], f.step > 6)
    |> where([f], f.status == "Affiliated")
    |> where([f, d], d.text == "HOSPITAL-BASED" or d.text == "CLINIC-BASED")
    |> order_by([f], asc: f.name)
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_in_memberlink!(facility_ids, params) do
    Facility
    |> join(:inner, [f],
            d in Dropdown, f.ftype_id == d.id)
    |> where([f, d], f.id in ^facility_ids)
    |> where([f, d], f.step > 6 and f.status == "Affiliated"
             and (d.text == "HOSPITAL-BASED"
              or d.text == "CLINIC-BASED"))
    |> order_by([f], asc: f.name)
    |> limit(10)
    |> offset(^params["offset"])
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
               time_from: fragment("CAST(? AS TEXT)", ps.time_from),
               time_to: fragment("CAST(? AS TEXT)", ps.time_to),
               day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_in_memberlink_by_name!(facility_ids, params) do
    search_params = params["search_param"]
    facility_name = String.downcase(search_params["name"] || "")
    address = String.downcase(search_params["address"] || "")
    if Enum.any?([search_params["type"] == "Hospital and Clinic",
                  search_params["type"] == ""]) do
      type = "-based"
    else
      if search_params["type"] == "Hospital" do
        type = "hospital-based"
      end
      if search_params["type"] == "Clinic" do
        type = "clinic-based"
      end
    end

    Facility
    |> join(:inner, [f],
            d in Dropdown, f.ftype_id == d.id)
    |> where([f, d],
             f.id in ^facility_ids
             and ilike(fragment(
              "lower(?)", f.name), ^"%#{facility_name}%")
             and ilike(fragment(
              "lower(?)",
              fragment("concat(?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?)",
              f.line_1, f.line_2, f.city, f.postal_code, f.province, f.region, f.country)),
              ^"%#{address}%")
             and ilike(fragment("lower(?)", d.text), ^"%#{type}%"))
    |> where([f], f.step > 6 and f.status == "Affiliated")
    |> order_by([f], asc: f.name)
    |> limit(10)
    |> offset(^params["offset"])
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
               time_from: fragment("CAST(? AS TEXT)", ps.time_from),
               time_to: fragment("CAST(? AS TEXT)", ps.time_to),
               day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_in_memberlink_acu!(facility_ids, params) do
    Facility
    |> where([f], f.id in ^facility_ids)
    |> where([f], f.step > 6 and f.status == "Affiliated")
    |> order_by([f], fragment("CASE ? WHEN ? then 1
               WHEN ? then 2
               WHEN ? then 3
               WHEN ? then 4
               WHEN ? then 5
               WHEN ? then 6
               WHEN ? then 7
               WHEN ? then 8
               WHEN ? then 9
               WHEN ? then 10
               WHEN ? then 11
               WHEN ? then 12
               WHEN ? then 13
               end", f.name, "MYHEALTH CLINIC - ALABANG",
               "PRIMARY CARE CENTER - MYHEALTH CLINIC ALABANG",
               "MYHEALTH CLINIC - SHANGRILA",
               "PRIMARY CARE CENTER - MYHEALTH CLINIC SHANGRILA",
               "MYHEALTH CLINIC - CEBU IT PARK",
               "MYHEALTH CLINIC - CEBU CYBERGATE",
               "MYHEALTH CLINIC - SM NORTH EDSA",
               "MYHEALTH CLINIC - CALAMBA",
               "MYHEALTH (ONSITE PHLEBOTOMY)",
               "MYHEALTH CLINIC - FILOMENA",
               "MYHEALTH CLINIC - CEBU CYBERGATE (MOBILE)",
               "MYHEALTH CLINIC - ROBINSONS MANILA",
               "MYHEALTH CLINIC - MCKINLEY"
    ))
    |> order_by([f], f.name)
    |> limit(10)
    |> offset(^params["offset"])
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
               time_from: fragment("CAST(? AS TEXT)", ps.time_from),
               time_to: fragment("CAST(? AS TEXT)", ps.time_to),
               day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_in_memberlink_by_name_acu!(facility_ids, params) do
    search_params = params["search_param"]
    facility_name = String.downcase(search_params["name"] || "")
    address = String.downcase(search_params["address"] || "")
    type = String.downcase(search_params["type"] || "")

    Facility
    |> join(:inner, [f],
            d in Dropdown, f.ftype_id == d.id)
    |> where([f, d],
             f.id in ^facility_ids
             and ilike(fragment(
              "lower(?)", f.name), ^"%#{facility_name}%")
             and ilike(fragment(
              "lower(?)",
              fragment("concat(?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?)",
              f.line_1, f.line_2, f.city, f.postal_code, f.province, f.region, f.country)),
              ^"%#{address}%")
             and ilike(fragment("lower(?)", d.text), ^"#{type}%"))
    |> where([f], f.step > 6 and f.status == "Affiliated")
    |> order_by([f], fragment("CASE ? WHEN ? then 1
               WHEN ? then 2
               WHEN ? then 3
               WHEN ? then 4
               WHEN ? then 5
               WHEN ? then 6
               WHEN ? then 7
               WHEN ? then 8
               WHEN ? then 9
               WHEN ? then 10
               WHEN ? then 11
               WHEN ? then 12
               WHEN ? then 13
               end", f.name, "MYHEALTH CLINIC - ALABANG",
               "PRIMARY CARE CENTER - MYHEALTH CLINIC ALABANG",
               "MYHEALTH CLINIC - SHANGRILA",
               "PRIMARY CARE CENTER - MYHEALTH CLINIC SHANGRILA",
               "MYHEALTH CLINIC - CEBU IT PARK",
               "MYHEALTH CLINIC - CEBU CYBERGATE",
               "MYHEALTH CLINIC - SM NORTH EDSA",
               "MYHEALTH CLINIC - CALAMBA",
               "MYHEALTH (ONSITE PHLEBOTOMY)",
               "MYHEALTH CLINIC - FILOMENA",
               "MYHEALTH CLINIC - CEBU CYBERGATE (MOBILE)",
               "MYHEALTH CLINIC - ROBINSONS MANILA",
               "MYHEALTH CLINIC - MCKINLEY"
    ))
    |> order_by([f], asc: f.name)
    |> limit(10)
    |> offset(^params["offset"])
    |> Repo.all()
    |> Repo.preload([
      practitioner_facilities: [
        :practitioner_status,
        practitioner_schedules:
        from(ps in PractitionerSchedule,
             select: %{
               time_from: fragment("CAST(? AS TEXT)", ps.time_from),
               time_to: fragment("CAST(? AS TEXT)", ps.time_to),
               day: ps.day,
               room: ps.room
             }
        ),
        practitioner: [
          practitioner_specializations: :specialization
        ],
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ]
    ])
  end

  def get_facility_by_long_lat(params, id) do
    Facility
    |> where([f],
             f.latitude == ^params["latitude"]
             and f.longitude == ^params["longitude"]
             and f.id != ^id
             and f.step == 7
    )
    |> limit(1)
    |> Repo.all()
  end

  def validate_step2_changeset(facility, facility_params) do
    changeset =
      facility
      |> Facility.step2_changeset(facility_params)

    {changeset.valid?, changeset}
  end

  #Facility Import
  def get_all_facility_upload_logs do
    FacilityUploadLog
    |> Repo.all
  end

  def get_facility_upload_logs(p_id, p_status) do
    facilities =
      FacilityUploadLog
      |> select([p], [p.remarks, p.facility_name, p.facility_code
                      ])
      |> where([p], p.status == ^p_status
        and p.facility_upload_file_id == ^p_id)
      |> Repo.all
  end

  def get_facility_upload_file do
    query =
      from pf in FacilityUploadFile,
      join: u in User, on: u.id == pf.created_by_id,
      join: pl in FacilityUploadLog,
      on: pf.id == pl.facility_upload_file_id,
      select: (%{:id => pf.id, :filename => pf.filename,
        :created_by => u.username,
        :batch_number => pf.batch_number,
        :total_count => (fragment("(SELECT count(*) FROM facility_upload_logs
          where facility_upload_file_id = ?)", pl.facility_upload_file_id)),
        :success => (fragment("(SELECT count(*) FROM facility_upload_logs
          where status = ? and facility_upload_file_id = ?)", "success", pl.facility_upload_file_id)),
        :failed => (fragment("(SELECT count(*) FROM facility_upload_logs
          where status = ? and facility_upload_file_id = ?)", "failed", pl.facility_upload_file_id)),
        :inserted_at => (fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", pf.inserted_at)),
        :date_finished => (fragment("(SELECT to_char(inserted_at,'MM/DD/YYYY HH24:MI:SS')
          FROM facility_upload_logs where facility_upload_file_id = ? order by inserted_at desc limit 1)", pl.facility_upload_file_id))
      }),
      group_by: [pl.facility_upload_file_id,
                 pf.id, pf.filename, u.username]

    Repo.all(query)
  end

  def create_facility_import(facility_params, user_id) do
    facility_params["file"].path
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> FacilityParser.parse_data(facility_params["upload_type"], facility_params["file"].filename, user_id)
  end

  def get_facility_upload_logs do
    FacilityUploadFile
    |> Repo.all()
    |> Repo.preload(:facility_upload_logs)
  end

  def get_f_upload_logs(p_id, p_status) do
    FacilityUploadLog
      |> select([p], [p.remarks, p.row, p.facility_code,
                      p.facility_name])
      |> where([p], p.status == ^p_status
        and p.facility_upload_file_id == ^p_id)
      |> Repo.all
  end

  def get_facilities_by_location_group(location_group_name) do
    Facility
    |> join(:inner, [f], flg in FacilityLocationGroup, f.id == flg.facility_id)
    |> join(:inner, [f, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where([f, flg, lg], lg.name == ^location_group_name)
    |> select([f, flg, lg], f.id)
    |> Repo.all()
  end

  def generate_facility_batch_no(batch_no) do
    origin = batch_no
    case Enum.count(Integer.digits(batch_no + 1)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no
      _ ->
        batch_no
    end

    with nil <- Repo.get_by(FacilityUploadFile, batch_number: batch_no),
        false <- origin == 0
    do
      batch_no
    else
     %FacilityUploadFile{} ->
        generate_facility_batch_no(origin + 1)
      true ->
        "0001"
    end
  end

  def load_facility_table(ids, provider_access) do
    Facility
    |> join(:left, [f], t in Dropdown, f.ftype_id == t.id)
    |> join(:left, [f], c in Dropdown, f.fcategory_id == c.id)
    |> where([f, t], t.text in ^provider_access)
    |> check_empty_ids(ids)
    |> select([f, t, c],
      %{
        id: f.id,
        code: f.code,
        name: f.name,
        region: f.region,
        type: t.text,
        line1: f.line_1,
        line2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        category: c.text
      }
    )
    |> Repo.all()
    |> insert_table_buttons([])
  end

  defp check_empty_ids(facility, ids) when ids == [""], do: facility
  defp check_empty_ids(facility, ids) when ids != [""], do: facility |> where([f], f.id not in ^ids)

  defp insert_table_buttons([head | tails], tbl) do
    address = "#{head.line1} #{head.line2} #{head.city} #{head.province} #{head.region} #{head.country}"

    tbl =
      tbl ++ [[
        "<input type='checkbox' style='width:20px; height:20px' class='facility_chkbx' facility_id='#{head.id}' code='#{head.code}' facility_name='#{head.name}' facility_type='#{head.type}' region='#{head.region}' address='#{address}' category='#{head.category}' />",
        "<span class='green'>#{head.code}</span>",
        "<strong>#{head.name}</strong>",
        "<span class='dim small'>#{address}</span>",
        "<span class='small'>#{head.type}</span>",
        "<span class='small'>#{head.region}</span>"
      ]]

    insert_table_buttons(tails, tbl)
  end
  defp insert_table_buttons([], tbl), do: tbl

  def load_limit_threshold_facilities(ids, provider_access, type, selected_lt_codes) do
    Facility
    |> join(:left, [f], t in Dropdown, f.ftype_id == t.id)
    |> where([f, t], t.text in ^provider_access)
    |> where([f], f.code not in ^selected_lt_codes)
    |> check_type(ids, type)
    |> select([f], %{
      "value" => f.code,
      "name" => f.name
    })
    |> Repo.all()
  end

  defp check_type(facility, ids, type) when type == "All Affiliated Facilities", do: facility |> where([f], f.id not in ^ids)
  defp check_type(facility, ids, type) when type == "Specific Facilities", do: facility |> where([f], f.id in ^ids)

  def facility_dropdown do
    Facility
    |> where([f], f.status == "Affiliated")
    |> select([f], %{
      "value" => f.id,
      "name" => f.name
    })
    |> Repo.all()
  end

  def get_facility_prescription_term(id) do
    Facility
    |> where([f], f.id == ^id)
    |> select([f], %{prescription_term: f.prescription_term})
    |> Repo.one()
  end

  # FACILITY DATATABLE

  def facility_count(ids, provider_access) do
    # Returns total count of data without filter and search value.

    ids
    |> initialize_query(provider_access)
    |> select([f, t, c], count(f.id))
    |> Repo.one()
  end

  def facility_data(
    ids,
    facility_params,
    offset,
    limit,
    search_value
  ) do
    # Returns table data according to table's offset and limit.
    ids
    |> initialize_query(facility_params["provider_access"])
    |> where([f, t, c],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%")
    )
    |> select([f, t, c],
    %{
      id: f.id,
      code: f.code,
      name: f.name,
      region: f.region,
      type: t.text,
      line1: f.line_1,
      line2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      category: c.text
    }
  )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_buttons([], ids, facility_params["selected_facility_ids"])
  end

  def facility_filtered_count(
    ids,
    search_value,
    provider_access
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> initialize_query(provider_access)
    |> where([f, t, c],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%")
    )
    |> select([f, t, c], count(f.id))
    |> Repo.one()
  end

  defp initialize_query(ids, provider_access) do
    # Sets initial query of the table.

    Facility
    |> join(:left, [f], t in Dropdown, f.ftype_id == t.id)
    |> join(:left, [f], c in Dropdown, f.fcategory_id == c.id)
    |> where([f, t], t.text in ^provider_access)
    |> distinct(true)
    |> filter_ids(ids)
  end

  defp filter_ids(procedure, ids) when ids == [""], do: procedure
  defp filter_ids(procedure, ids) when ids != [""] do
    procedure
    |> where([b, bc, c, bl], b.id not in ^ids)
  end

  defp insert_table_buttons([head | tails], tbl, facility_ids, selected_facility_ids) do
    address = "#{head.line1} #{head.line2} #{head.city} #{head.province} #{head.region} #{head.country}"
    if Enum.member?(selected_facility_ids, head.id) do
      tbl =
        tbl ++ [[
          "<input type='checkbox' checked='true' style='width:20px; height:20px' class='facility_chkbx' facility_id='#{head.id}' code='#{head.code}' facility_name='#{head.name}' facility_type='#{head.type}' region='#{head.region}' address='#{address}' category='#{head.category}' />",
          "<span class='green'>#{head.code}</span>",
          "<strong>#{head.name}</strong>",
          "<span class='dim small'>#{address}</span>",
          "<span class='small'>#{head.type}</span>"
        ]]

      insert_table_buttons(tails, tbl, facility_ids, selected_facility_ids)
    else
      tbl =
        tbl ++ [[
          "<input type='checkbox' style='width:20px; height:20px' class='facility_chkbx' facility_id='#{head.id}' code='#{head.code}' facility_name='#{head.name}' facility_type='#{head.type}' region='#{head.region}' address='#{address}' category='#{head.category}' />",
          "<span class='green'>#{head.code}</span>",
          "<strong>#{head.name}</strong>",
          "<span class='dim small'>#{address}</span>",
          "<span class='small'>#{head.type}</span>"
        ]]

      insert_table_buttons(tails, tbl, facility_ids, selected_facility_ids)
    end

  end

  defp insert_table_buttons([], tbl, facility_ids, selected_facility_ids), do: tbl
end

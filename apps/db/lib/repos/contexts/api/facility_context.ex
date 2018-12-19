defmodule Innerpeace.Db.Base.Api.FacilityContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
   alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.FacilityCategory,
    Schemas.FacilityContact,
    Schemas.FacilityPayorProcedure,
    Schemas.PractitionerFacility,
    Schemas.ProductCoverageFacility,
    Schemas.ProductCoverage,
    Schemas.AccountProduct,
    Schemas.MemberProduct,
    Schemas.Phone,
    Schemas.Email,
    Schemas.Contact,
    Schemas.Coverage,
    Schemas.Dropdown,
    Schemas.Member,
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
    Schemas.Dropdown,
    Schemas.Product,
    Schemas.ProductFacility,
    Schemas.PractitionerSchedule,
   }
  alias Innerpeace.Db.Base.FacilityContext
  alias Innerpeace.Db.Base.MemberContext
  alias Innerpeace.Db.Base.CoverageContext
  alias Innerpeace.Db.Base.AuthorizationContext
  alias Innerpeace.Db.Base.TranslationContext

  def validate_insert(user, params)do
    with {:ok, changeset} <- validate_general(params),
        {:ok, facility} <- insert_facility(changeset, user),
        contact_array <- insert_contact(params),
        facility_contact_array <-
          insert_facility_contacts(facility.id, contact_array),
        financial <- update_facility(user, facility, changeset),
        service_fee <- insert_service_fee(facility, changeset),
        room <- insert_facility_room(facility, changeset),
        payor_procedure <- insert_payor_procedure(facility, changeset),
        ruv <- insert_ruv(facility, changeset)
    do
      {:ok, facility}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:not_found}
    end
  end

  defp validate_general(params) do
    data = %{}
    general_types = %{
      code: :string,
      name: :string,
      type: :string,
      license_name: :string,
      phic_accreditation_from: Ecto.Date,
      phic_accreditation_to: Ecto.Date,
      phic_accreditation_no: :string,
      status: :string,
      affiliation_date: Ecto.Date,
      disaffiliation_date: Ecto.Date,
      phone_no: :string,
      email_address: :string,
      facility_type: :string,
      facility_category: :string,
      website: :string,
      line_1: :string,
      line_2: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      postal_code: :string,
      longitude: :string,
      latitude: :string,
      tin: :string,
      vat_status: :string,
      prescription_clause: :string,
      prescription_term: :string,
      credit_term: :string,
      credit_limit: :string,
      no_of_beds: :string,
      bond: :decimal,
      payee_name: :string,
      withholding_tax: :string,
      bank_account_no: :string,
      balance_biller: :boolean,
      authority_to_credit: :boolean,
      mode_of_payment: :string,
      mode_of_releasing: :string,
      contact: {:array, :map},
      service_fee: {:array, :map},
      rooms: {:array, :map},
      procedures: {:array, :map},
      ruv: {:array, :string}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :code,
        :name,
        :type,
        :status,
        :affiliation_date,
        :disaffiliation_date,
        :city,
        :province,
        :region,
        :country,
        :postal_code,
        :longitude,
        :latitude,
        :tin,
        :prescription_term,
        :credit_term,
        :credit_limit,
        :withholding_tax,
        :balance_biller,
        :authority_to_credit,
        :vat_status,
        :prescription_clause,
        :mode_of_payment,
        :mode_of_releasing,
        :contact,
        :facility_category,
        :facility_type,
        :prescription_clause
      ])
      |> Changeset.validate_format(:phone_no, ~r/^[0-9]*$/)
      |> Changeset.validate_format(
          :website, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> Changeset.validate_format(
          :email_address, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_inclusion(:status, ["Pending", "Affiliated"])
      |> validate_inclusion(:balance_biller, [true, false])
      |> validate_inclusion(:authority_to_credit, [true, false])
      |> validate_inclusion(:mode_of_payment, ["Bank", "Check", "Auto-Credit"])
      |> validate_inclusion(:vat_status, ["20% VAT-able", "Fully VAT-able", "Others", "VAT Exempt", "VAT-able", "Zero-Rated"])
      |> validate_length(:phic_accreditation_no, is: 12)
      |> validate_length(:tin, is: 12)
      |> validate_contact()
      |> validate_facility_type()
      |> validate_facility_category()
      |> validate_vat_status()
      |> validate_prescription_clause()
      |> validate_service_fee()
      |> validate_rooms()
      |> validate_procedures()
      |> validate_ruvs()
      |> validate_line_address()
      |> validate_financial()

      new_changeset =
      changeset.changes
      |> Map.put_new(:no_of_beds, "")
      |> Map.put_new(:phic_accreditation_no, "")
      |> Map.put_new(:prescription_term, "")
      |> Map.put_new(:credit_term, "")
      |> Map.put_new(:credit_limit, "")
      |> Map.put_new(:tin, "")

      changeset =
        validate_all_number_fields(new_changeset.prescription_term,
          :prescription_term, changeset)
      changeset =
        validate_all_number_fields(new_changeset.credit_term,
          :credit_term, changeset)
      changeset =
        validate_all_number_fields(new_changeset.credit_limit,
          :credit_limit, changeset)
      changeset =
        validate_all_number_fields(new_changeset.no_of_beds,
          :no_of_beds, changeset)
      changeset =
        validate_all_number_fields(new_changeset.phic_accreditation_no,
          :phic_accreditation_no, changeset)
      changeset = validate_all_number_fields(new_changeset.tin, :tin, changeset)
      changeset = validate_financial(changeset)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_financial(changeset) do
    if is_nil(changeset.changes[:mode_of_payment]) do
      changeset
    else
      payment_mode =  changeset.changes.mode_of_payment
      case payment_mode do
      "Bank" ->
        changeset =
          changeset
          |> Changeset.validate_required([
            :bank_account_no
          ])
      "Check" ->
        changeset =
          changeset
          |> Changeset.validate_required([
            :payee_name
          ])
      "Auto-Credit" ->
        changeset =
          changeset
          |> Changeset.validate_required([
            :bank_account_no
          ])
        _ ->
          changeset
      end
    end
  end

  defp validate_line_address(changeset) do
    if is_nil(changeset.changes[:line_1]) and
      is_nil(changeset.changes[:line_2]) do
      changeset =
        changeset
        |> validate_required([:line_1, :line_2])
    else
      changeset
    end
  end

  defp validate_ruvs(changeset) do
    if is_nil(changeset.changes[:ruv]) do
      changeset
    else
      ruvs = Changeset.get_field(changeset, :ruv)
      ruv_checker = for ruv <- ruvs do
        ruv_id = get_ruv_by_code(ruv)
        if is_nil(ruv_id) do
          false
        else
          true
        end
      end
      if Enum.all?(ruv_checker, &(&1 == true)) do
        changeset
      else
        add_error(changeset, :ruv, "Invalid RUV code!")
      end
    end
  end

  defp validate_procedures(changeset) do
    if is_nil(changeset.changes[:procedures]) do
      changeset
    else
      procedures = Changeset.get_field(changeset, :procedures)
      if procedures == [] do
        add_error(changeset, :procedures, "No parameters found!")
      else
        procedure_code = for procedure <- procedures do
          procedure["payor_procedure_code"]
        end

        valid_procedure =
          for procedure <- procedures,
            do: procedure_field(procedure)
        with true <- Enum.all?(valid_procedure, &(&1 == true)),
             true <- Enum.empty?(procedure_code -- Enum.uniq(procedure_code))
        do
          changeset
        else
          _ ->
            add_error(changeset, :procedures, "Invalid procedures parameters!")
        end
      end
    end
  end

  defp procedure_field(params) do
    data = %{}
    room_types = %{
      payor_procedure_code: :string,
      facility_cpt_code: :string,
      facility_cpt_name: :string,
      rooms: {:array, :map}
    }
    changeset =
      {data, room_types}
      |> Changeset.cast(params, Map.keys(room_types))
      |> Changeset.validate_required([
        :payor_procedure_code,
        :facility_cpt_code,
        :facility_cpt_name,
        :rooms
      ])
      |> validate_payor_procedure_code()
      |> validate_procedure_rooms()

    changeset.valid?
  end

  defp validate_payor_procedure_code(changeset) do
    if is_nil(changeset.changes[:payor_procedure_code]) do
      changeset
    else
      payor_procedure_id =
        get_payor_procedure_by_code(
          changeset.changes.payor_procedure_code)
      if is_nil(payor_procedure_id)
      do
        add_error(changeset, :procedures, "Invalid Payor Procedure!")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :procedure_ids,
            payor_procedure_id))
      end
    end
  end

  defp validate_procedure_rooms(changeset) do
    if is_nil(changeset.changes[:rooms]) do
      changeset
    else
      procedure_rooms = Changeset.get_field(changeset, :rooms)
      if procedure_rooms == [] do
        add_error(changeset, :rooms, "No parameters found!")
      else
        procedure_room_code = for procedure_room <- procedure_rooms do
          procedure_room["code"]
        end

        valid_procedure_room =
          for procedure_room <- procedure_rooms,
            do: procedure_room_field(procedure_room)
        with true <- Enum.all?(valid_procedure_room, &(&1 == true)),
             true <-
              Enum.empty?(procedure_room_code -- Enum.uniq(procedure_room_code))
        do
          changeset
        else
          _ ->
            add_error(changeset, :rooms, "Invalid room parameters")
        end
      end
    end
  end

  defp procedure_room_field(params) do
    data = %{}
    room_types = %{
      code: :string,
      amount: :string,
      discount: :string,
      effectivity_date: :string
    }
    changeset =
      {data, room_types}
      |> Changeset.cast(params, Map.keys(room_types))
      |> Changeset.validate_required([
        :code,
        :amount,
        :effectivity_date
      ])
      |> validate_room()
      |> validate_discount()

    if is_nil(changeset.changes[:discount]) do
      changeset
    else
      changeset =
        validate_all_number_fields(
          changeset.changes.discount, :discount, changeset)
    end

    if is_nil(changeset.changes[:amount]) do
      changeset
    else
      changeset =
        validate_all_number_fields(changeset.changes.amount,
          :amount, changeset)
    end
    changeset.valid?
  end

  defp validate_discount(changeset) do
    if is_nil(changeset.changes[:discount]) do
      changeset
    else
      discount_val = changeset.changes.discount
      if String.to_integer(discount_val) > 100 do
        add_error(changeset, :discount, "Discount value must be less than 100.")
      else
        changeset
      end
    end
  end

  defp validate_rooms(changeset) do
    if is_nil(changeset.changes[:rooms]) do
      changeset
    else
      rooms = Changeset.get_field(changeset, :rooms)
      if rooms == [] do
        add_error(changeset, :rooms, "No parameters found!")
      else
        room_code = for room <- rooms do
          room["code"]
        end

        valid_room = for room <- rooms, do: room_field(room)
        with true <- Enum.all?(valid_room, &(&1 == true)),
             true <- Enum.empty?(room_code -- Enum.uniq(room_code))
        do
          changeset
        else
          _ ->
            add_error(changeset, :rooms, "Invalid room parameters")
        end
      end
    end
  end

  defp room_field(params) do
    data = %{}
    room_types = %{
      code: :string,
      facility_room_type: :string,
      facility_room_rate: :string
    }
    changeset =
      {data, room_types}
      |> Changeset.cast(params, Map.keys(room_types))
      |> Changeset.validate_required([
        :code,
        :facility_room_type,
        :facility_room_rate
      ])
      |> validate_room()

    if is_nil(changeset.changes[:facility_room_rate]) do
      changeset
    else
      changeset =
        validate_all_number_fields(
          changeset.changes.facility_room_rate,
            :facility_room_rate, changeset)
    end

    changeset.valid?
  end

  defp validate_room(changeset) do
    if is_nil(changeset.changes[:code]) do
      changeset
    else
      room_id = get_room_by_code(changeset.changes.code)
      if is_nil(room_id)
      do
        add_error(changeset, :rooms, "Invalid rooms")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :room_ids,
            room_id))
      end
    end
  end

  defp validate_service_fee(changeset) do
    if is_nil(changeset.changes[:service_fee]) do
      changeset
    else
      service_fees = Changeset.get_field(changeset, :service_fee)
      if service_fees == [] do
        add_error(changeset, :service_fee, "No parameters found!")
      else
        valid_service_fee =
          for service_fee <- service_fees,
            do: service_fee_field(service_fee)
        with true <- Enum.all?(valid_service_fee, &(&1 == true))
        do
          changeset
        else
          _ ->
            add_error(changeset, :service_fee, "Invalid service fee parameters")
        end
      end
    end
  end

  defp service_fee_field(params) do
    data = %{}
    service_fee_types = %{
      coverage: :string,
      payment_mode: :string,
      service_fee: :string,
      rate: :string
    }
    changeset =
      {data, service_fee_types}
      |> Changeset.cast(params, Map.keys(service_fee_types))
      |> Changeset.validate_required([
        :coverage,
        :payment_mode,
        :service_fee,
        :rate
      ])
      |> validate_inclusion(:payment_mode, ["Umbrella", "Individual"])
      |> validate_inclusion(:service_fee, ["Fixed Fee", "Discount Rate", "No Discount Rate"])
      |> validate_service_fee_coverage()

    new_changeset =
      changeset.changes
      |> Map.put_new(:rate, "")

    changeset = validate_all_number_fields(new_changeset.rate, :rate, changeset)
    changeset.valid?
  end

  defp validate_service_fee_coverage(changeset) do
    if is_nil(changeset.changes[:coverage]) do
      changeset
    else
      coverage_id = get_coverage_by_name(changeset.changes.coverage)
      if is_nil(coverage_id)
      do
        add_error(changeset, :coverage, "Invalid coverage")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :coverage_ids,
            coverage_id))
      end
    end
  end

  defp validate_facility_type(changeset) do
    if is_nil(changeset.changes[:facility_type]) do
      changeset
    else
      facility_types =
        get_facility_type_by_text(
          changeset.changes.facility_type)
      if is_nil(facility_types) do
        add_error(changeset, :facility_type, "Invalid facility type")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :facility_type_ids,
            facility_types))
      end
    end
  end

  defp validate_facility_category(changeset) do
    if is_nil(changeset.changes[:facility_category]) do
      changeset
    else
      facility_categories =
        get_facility_category_by_text(
          changeset.changes.facility_category)
      if is_nil(facility_categories) do
        add_error(changeset, :facility_category, "Invalid facility category")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :facility_category_ids,
            facility_categories))
      end
    end
  end

  defp validate_vat_status(changeset) do
    if is_nil(changeset.changes[:vat_status]) do
      changeset
    else
      vat_status = get_vat_status_by_text(changeset.changes.vat_status)
      if is_nil(vat_status) do
        add_error(changeset, :vat_status, "Invalid vat status")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :vat_status_ids,
            vat_status))
      end
    end
  end

  defp validate_prescription_clause(changeset) do
    if is_nil(changeset.changes[:prescription_clause]) do
      changeset
    else
      prescription_clause =
        get_prescription_clause_by_text(
          changeset.changes.prescription_clause)
      if is_nil(prescription_clause) do
        add_error(changeset, :prescription_clause, "Invalid prescription clause")
      else
        Map.put(changeset, :changes,
          Map.put(changeset.changes, :prescription_clause_ids,
            prescription_clause))
      end
    end
  end

  defp validate_contact(changeset) do
    if is_nil(changeset.changes[:contact]) do
      changeset
    else
      check_error_contact(changeset)
    end
  end

  defp check_error_contact(changeset) do
    contacts = Changeset.get_field(changeset, :contact)
    if contacts == [] do
      add_error(changeset, :contact, "No parameters found!")
    else
      valid_contact = for contact <- contacts, do: contact_field(contact)
      with true <- Enum.all?(valid_contact, &(&1 == true))
      do
        changeset
      else
        _ ->
           mobile =  Enum.map(valid_contact, fn(x) ->
            if not is_nil(x.errors[:mobile]) do
              {message, _} = x.errors[:mobile]
               message
            end
            end)
           telephone = Enum.map(valid_contact, fn(x) ->
             if not is_nil(x.errors[:telephone]) do
                {message, _} = x.errors[:telephone]
                 message
              end
            end)
          fax =  Enum.map(valid_contact, fn(x) ->
            if not is_nil(x.errors[:fax]) do
              {message, _} = x.errors[:fax]
               message
            end
            end)
          if Enum.empty?(List.delete(telephone, nil)) == false do
            changeset = add_error(changeset, :telephone, Enum.at(telephone, 0))
          end
          if Enum.empty?(List.delete(mobile, nil)) == false do
            changeset = add_error(changeset, :mobile, Enum.at(mobile, 0))
          end
          if Enum.empty?(List.delete(fax, nil)) == false do
            changeset = add_error(changeset, :fax, Enum.at(fax, 0))
          end
          changeset
      end
    end
  end
   defp contact_field(params) do
    data = %{}
    contact_types = %{
      first_name: :string,
      last_name: :string,
      designation: :string,
      email: :string,
      department: :string,
      mobile: {:array, :map},
      telephone: {:array, :map},
      fax: {:array, :map}
    }
    changeset =
      {data, contact_types}
      |> Changeset.cast(params, Map.keys(contact_types))
      |> Changeset.validate_required([
        :first_name,
        :last_name,
        :email,
        :mobile
      ])
      |> Changeset.validate_format(
          :email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> validate_telephones()
      |> validate_fax()
      |> validate_mobiles()

    if changeset.valid? == true do
      true
    else
      changeset
    end
  end

  defp validate_telephones(changeset) do
    if Map.has_key?(changeset.changes, :telephone) do
      with :valid_tn <- validate_telephone_number(changeset),
           :valid_cc <- validate_country_code(changeset, "telephone"),
           :valid_ac <- validate_area_code(changeset, "telephone"),
           :valid_l <- validate_local(changeset, "telephone")
            # true <- Enum.all?(changeset.changes.telephone,
            # &(String.length(&1) == 7)),
            # true <- Enum.all?(
            # validate_number_field(changeset.changes.telephone))
      do
        changeset
      else
        :invalid_cc ->
          add_error(changeset, :telephone, "country_code is required")
        :invalid_cc_length ->
          add_error(changeset, :telephone, "country_code should be at most four (4) digit number")
        :invalid_ac_length ->
          add_error(changeset, :telephone, "area_code should be at most three (3) digit number")
        :invalid_l_length ->
          add_error(changeset, :telephone, "local should be at most two (2) digit number")
        :invalid_tn ->
          add_error(changeset, :telephone, "At least one telephone_number is required")
        :invalid_tn_length ->
          add_error(changeset, :telephone, "telephone_number should be a seven (7) digit number")
        _ ->
        add_error(changeset, :telephone, "Invalid params")
      end
    else
      changeset
    end
  end

  defp validate_mobiles(changeset) do
    if is_nil(changeset.changes[:mobile]) do
      changeset
    else
      with false <- Enum.empty?(changeset.changes.mobile),
           # true <- Enum.all?(changeset.changes.mobile,
           # &(String.length(&1) == 11)),
           # true <- Enum.all?(validate_number_field(changeset.changes.mobile))
           :valid_mn <- validate_mobile_number(changeset),
           :valid_cc <- validate_country_code(changeset, "mobile")
      do
        changeset
      else
        true ->
          add_error(changeset, :mobile, "At least one mobile is required")
        :invalid_cc ->
          add_error(changeset, :mobile, "country_code is required")
        :invalid_cc_length ->
          add_error(changeset, :mobile, "country_code should be at most four (4) digit number")
        :invalid_mn ->
          add_error(changeset, :mobile, "mobile_number is required")
        :invalid_mn_length ->
          add_error(changeset, :mobile, "mobile_number should be a ten (10) digit number")
        _ ->
          add_error(changeset, :mobile, "Invalid params")
      end
    end
  end

  defp validate_fax(changeset) do
    if Map.has_key?(changeset.changes, :fax) do
      with :valid_fn <- validate_fax_number(changeset),
           :valid_cc <- validate_country_code(changeset, "fax"),
           :valid_ac <- validate_area_code(changeset, "fax"),
           :valid_l <- validate_local(changeset, "fax")

            # true <- Enum.all?(changeset.
            # changes.fax, &(String.length(&1) == 7)),
            # true <- Enum.all?(
            # validate_number_field(changeset.changes.fax))
      do
        changeset
      else
        :invalid_cc ->
          add_error(changeset, :fax, "country_code is required")
        :invalid_cc_length ->
          add_error(changeset, :fax, "country_code should be at most four (4) digit number")
        :invalid_ac_length ->
          add_error(changeset, :fax, "area_code should be at most three (3) digit number")
        :invalid_l_length ->
          add_error(changeset, :fax, "local should be at most two (2) digit number")
        :invalid_fn ->
          add_error(changeset, :fax, "At least one fax_number is required")
        :invalid_fn_length ->
          add_error(changeset, :fax, "fax_number should be a seven (7) digit number")
        _ ->
        add_error(changeset, :fax, "Invalid params")
      end
    else
      changeset
    end
  end

  defp validate_country_code(changeset, phone) do
    map =
      cond do
        phone == "mobile" ->
          changeset.changes.mobile
        phone == "telephone" ->
          changeset.changes.telephone
        phone == "fax" ->
          changeset.changes.fax
      end
    cc = Enum.map(map, fn(x) ->
      Map.has_key?(x, "country_code")
    end)
    cond do
      Enum.member?(cc, false) ->
        :invalid_cc
      Enum.all?(Enum.map(map, fn(x) ->
        String.length(x["country_code"]) end),
          fn(x) -> x > 4 end) ->
        :invalid_cc_length
      true ->
        :valid_cc
    end
  end

  defp validate_area_code(changeset, phone) do
    map =
      if phone == "telephone" do
          changeset.changes.telephone
      else
          changeset.changes.fax
      end
    ac = Enum.map(map, fn(x) ->
      if Map.has_key?(x, "area_code") do
        x["area_code"]
      else
        ""
      end
    end)

    cond do
      Enum.all?(Enum.map(ac, fn(x) ->
        String.length(x) end),
          fn(x) -> x == 0 end) ->
        :valid_ac
      Enum.all?(Enum.map(ac, fn(x) ->
        String.length(x) end),
          fn(x) -> x > 3 end) ->
        :invalid_ac_length
      true ->
        :valid_ac
    end
  end

defp validate_local(changeset, phone) do
    map =
      if phone == "telephone" do
          changeset.changes.telephone
      else
          changeset.changes.fax
      end
    ac = Enum.map(map, fn(x) ->
      if Map.has_key?(x, "local") do
        x["local"]
      else
        ""
      end
    end)

    cond do
      Enum.all?(Enum.map(ac, fn(x) ->
        String.length(x) end),
          fn(x) -> x == 0 end) ->
        :valid_l
      Enum.all?(Enum.map(ac, fn(x) ->
        String.length(x) end),
          fn(x) -> x > 2 end) ->
        :invalid_l_length
      true ->
        :valid_l
    end
  end

  defp validate_mobile_number(changeset) do
    mn = Enum.map(changeset.changes.mobile, fn(x) ->
      Map.has_key?(x, "mobile_number")
    end)
    cond do
      Enum.member?(mn, false) ->
        :invalid_mn
      Enum.all?(Enum.map(changeset.changes.mobile, fn(x) ->
        String.length(x["mobile_number"]) end),
          fn(x) -> x != 10 end) ->
        :invalid_mn_length
      true ->
        :valid_mn
    end
  end

  defp validate_telephone_number(changeset) do
    mn = Enum.map(changeset.changes.telephone, fn(x) ->
      Map.has_key?(x, "telephone_number")
    end)
    cond do
      Enum.member?(mn, false) ->
        :invalid_tn
      Enum.all?(Enum.map(changeset.changes.telephone, fn(x) ->
        String.length(x["telephone_number"]) end),
          fn(x) -> x != 7 end) ->
        :invalid_tn_length
      true ->
        :valid_tn
    end
  end

  defp validate_fax_number(changeset) do
    mn = Enum.map(changeset.changes.fax, fn(x) ->
      Map.has_key?(x, "fax_number")
    end)
    cond do
      Enum.member?(mn, false) ->
        :invalid_fn
      Enum.all?(Enum.map(changeset.changes.fax, fn(x) ->
        String.length(x["fax_number"]) end),
          fn(x) -> x != 7 end) ->
        :invalid_fn_length
      true ->
        :valid_fn
    end
  end

  defp validate_fax(changeset) do
    if Map.has_key?(changeset.changes, :fax) do
      with true <- Enum.all?(changeset.changes.fax, &(String.length(&1) == 7)),
         true <- Enum.all?(validate_number_field(changeset.changes.fax))
      do
        changeset
      else
        _ ->
        add_error(changeset, :fax, "Invalid params")
      end
    else
      changeset
    end
  end

  # Validate All Fields using Numbers

  defp validate_all_number_fields(changeset_field, field, changeset) do
    with true <- validate_a_number_field(changeset_field, field)
      do
        changeset
      else
        {:invalid_number_format, field} ->
        add_error(changeset, field, "Must be a number.")
      end
  end

  defp validate_a_number_field(numbers, field_name) do
      valid_format = validate_numbers(numbers)
      if valid_format do
        true
      else
        {:invalid_number_format, field_name}
      end
  end

  def validate_number_field(numbers) do
    for number <- numbers do
      valid_format = validate_numbers(number)
      if valid_format do
        true
      else
        false
      end
    end
  end

  defp validate_numbers(string) do
    Regex.match?(~r/^[0-9]*(\.[0-9]{1,90})?$/, string)
  end

  #End of Validate All Fields using Numbers

  defp insert_facility(params, user) do
  facility_category =
    get_facility_category_by_text(
      params.changes.facility_category)
  facility_type =
    get_facility_type_by_text(
      params.changes.facility_type)
      params =
        params.changes
        |> Map.merge(%{
        ftype_id: facility_type,
        fcategory_id: facility_category,
        step: "6",
        created_by_id: user.id,
        updated_by_id: user.id
      })

    %Facility{}
    |> Facility.changeset(params)
    |> Repo.insert()
  end

  defp update_facility(user, facility, facility_params) do
    vat_status_id = get_vat_status_by_text(facility_params.changes.vat_status)
    prescription_clause_id =
      get_prescription_clause_by_text(
        facility_params.changes.prescription_clause)
    payment_mode_id =
      get_payment_mode_by_text(facility_params.changes.mode_of_payment)
    releasing_mode_id =
      get_releasing_mode_by_text(facility_params.changes.mode_of_releasing)

    facility_params =
      facility_params.changes
      |> Map.merge(%{
        payment_mode_id: payment_mode_id,
        releasing_mode_id: releasing_mode_id,
        prescription_clause_id: prescription_clause_id,
        vat_status_id: vat_status_id,
        updated_by_id: user.id
      })

    facility
    |> Facility.step4_changeset(facility_params)
    |> Repo.update()
  end

  defp insert_contact(params) do
    for contact <- params["contact"] do
      inserted_contact =
        %Contact{}
        |> Contact.facility_contact_changeset(contact)
        |> Repo.insert!()
      if Map.has_key?(contact, "mobile"),
      do: insert_mobile(contact["mobile"], inserted_contact.id)
      if Map.has_key?(contact, "telephone"),
        do: insert_telephone(contact["telephone"], inserted_contact.id)
      if Map.has_key?(contact, "fax"),
        do: insert_fax(contact["fax"], inserted_contact.id)
      if Map.has_key?(contact, "email"),
        do: insert_email(contact["email"], inserted_contact.id)
      inserted_contact
    end
  end

  defp insert_mobile(mobile_array, contact_id) do
    for mobile <- mobile_array do
      params = %{
        type: "mobile",
        number: mobile["mobile_number"],
        country_code: mobile["country_code"],
        contact_id: contact_id
      }

      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp insert_email(email, contact_id) do
      create_email(%{
         contact_id: contact_id,
         address: email,
         type: ""
       })
  end

  defp insert_telephone(telephone_array, contact_id) do
    for telephone <- telephone_array do
      area_code =
        if Enum.member?(telephone, "area_code") do
          telephone["area_code"]
        else
          nil
        end
      local =
        if Enum.member?(telephone, "local") do
          telephone["area_code"]
        else
          nil
        end
      params = %{
        type: "telephone",
        number: telephone["telephone_number"],
        country_code: telephone["country_code"],
        area_code: area_code,
        local: local,
        contact_id: contact_id
      }

      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp insert_fax(fax_array, contact_id) do
    for fax <- fax_array do
      area_code =
        if Enum.member?(fax, "area_code") do
          fax["area_code"]
        else
          nil
        end
      local =
        if Enum.member?(fax, "local") do
          fax["area_code"]
        else
          nil
        end
      params = %{
        type: "fax",
        number: fax["fax_number"],
        country_code: fax["country_code"],
        area_code: area_code,
        local: local,
        contact_id: contact_id
      }

      %Phone{}
      |> Phone.changeset(params)
      |> Repo.insert!()
    end
  end

  defp create_email(params) do
    %Email{}
    |> Email.changeset(params)
    |> Repo.insert()
  end

  defp insert_facility_contacts(facility_id, contact_array) do
    for contact <- contact_array do
      contact_params = %{
        facility_id: facility_id,
        contact_id: contact.id
      }
      insert_facility_contact(contact_params)
    end
  end

  defp insert_facility_contact(params) do
    %FacilityContact{}
    |> FacilityContact.changeset(params)
    |> Repo.insert()
  end

  def insert_service_fee(facility, changeset) do
    if is_nil(changeset.changes[:service_fee]) do
      changeset
    else
      service_fees = changeset.changes.service_fee
      for service_fee <- service_fees do
        params = setup_service_fee_params(service_fee)
        service_type_id = get_facility_service_type_by_text(params["service_fee"])
        coverage_id = get_coverage_by_name(params["coverage"])
        params =
          params
          |> Map.merge(%{
            "service_type_id" => service_type_id,
            "coverage_id" => coverage_id,
            "facility_id" => facility.id
          })

          %FacilityServiceFee{}
          |> FacilityServiceFee.changeset(params)
          |> Repo.insert()
      end

    end
  end

  defp setup_service_fee_params(params) do
    service_type = params["service_fee"]
    case service_type do
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

  defp insert_facility_room(facility, changeset) do
    if is_nil(changeset.changes[:rooms]) do
      changeset
    else
      for room <- changeset.changes.rooms do
        room_id = get_room_by_code(room["code"])

        params = %{
          room_id: room_id,
          facility_id: facility.id,
          facility_room_type: room["facility_room_type"],
          facility_room_rate: room["facility_room_rate"]
        }

        %FacilityRoomRate{}
        |> FacilityRoomRate.changeset(params)
        |> Repo.insert()
      end
    end
  end

  defp insert_payor_procedure(facility, changeset) do
    if is_nil(changeset.changes[:procedures]) do
      changeset
    else
      for procedure <- changeset.changes.procedures do
        payor_procedure_id = get_payor_procedure_by_code(procedure["payor_procedure_code"])
        facility_payor_procedure_params = %{
            payor_procedure_id: payor_procedure_id,
            code: procedure["facility_cpt_code"],
            name: procedure["facility_cpt_name"],
            facility_id: facility.id
          }

          %FacilityPayorProcedure{}
          |> FacilityPayorProcedure.changeset(facility_payor_procedure_params)
          |> Repo.insert()

        for room <- procedure["rooms"] do
          room_id = get_room_by_code(room["code"])
          facility_room_rate_id =
            get_facility_room_rate_by_id(room_id, facility.id)
          facility_payor_procedure_id =
            get_facility_payor_procedure_by_id(
              payor_procedure_id, facility.id, procedure["facility_cpt_code"])

          procedure_room_params = %{
            facility_room_rate_id: facility_room_rate_id,
            facility_payor_procedure_id: facility_payor_procedure_id,
            amount: room["amount"],
            discount: room["discount"],
            start_date: room["effectivity_date"]
          }

          %FacilityPayorProcedureRoom{}
          |> FacilityPayorProcedureRoom.changeset(procedure_room_params)
          |> Repo.insert()
        end
      end
    end
  end

  defp insert_ruv(facility, changeset) do
    if is_nil(changeset.changes[:ruv]) do
      changeset
    else
      for ruv <- changeset.changes.ruv do
        ruv_id = get_ruv_by_code(ruv)
        params = %{
          ruv_id: ruv_id,
          facility_id: facility.id
        }
        %FacilityRUV{}
          |> FacilityRUV.changeset(params)
          |> Repo.insert()
      end
    end
  end

  defp get_dropdown_value(id) do
    Dropdown
    |> where([d], d.id == ^id)
    |> Repo.one()
  end

  defp get_coverage_by_name(name) do
    Coverage
    |> where([c], c.description == ^name)
    |> select([c], c.id)
    |> Repo.one()
  end

  defp get_ruv_by_code(code) do
    RUV
    |> where([r], r.code == ^code)
    |> select([r], r.id)
    |> Repo.one()
  end

  defp get_facility_payor_procedure_by_id(payor_procedure_id, facility_id, code) do
    FacilityPayorProcedure
    |> where([fpp],
      fpp.payor_procedure_id == ^payor_procedure_id and
      fpp.facility_id == ^facility_id and fpp.code == ^code)
    |> select([fpp], fpp.id)
    |> Repo.one()
  end

  defp get_facility_room_rate_by_id(room_id, facility_id) do
    FacilityRoomRate
    |> where([frr], frr.room_id == ^room_id and frr.facility_id == ^facility_id)
    |> select([frr], frr.id)
    |> Repo.one()
  end

  defp get_payor_procedure_by_code(code) do
    PayorProcedure
    |> where([pp], pp.code == ^code)
    |> select([pp], pp.id)
    |> Repo.one()
  end

  defp get_room_by_code(code) do
    Room
    |> where([r], r.code == ^code)
    |> select([r], r.id)
    |> Repo.one()
  end

  def get_facility_service_type_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Facility Service Fee" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_facility_type_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Facility Type" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_facility_category_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Facility Category" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_vat_status_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"VAT Status" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_prescription_clause_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Prescription Clause" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_payment_mode_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Payment Mode" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_releasing_mode_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Releasing Mode" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_mode_of_payment_by_text(text) do
    Dropdown
    |> where([d], d.type == ^"Mode of Payment" and d.text == ^text)
    |> select([d], d.id)
    |> Repo.one()
  end

  def get_facility_code_by_vendor_code(vendor_code) do
    facility =
      Facility
      |> where([f], f.vendor_code == ^vendor_code)
      |> Repo.one

    if is_nil(facility) do
      ""
    else
      facility.code
    end
  end
  
  #def search_all_facility do
  #  Facility
  #  |> Repo.all
  #  |> Repo.preload([
  #      :type,
  #      :category,
  #      :vat_status,
  #      :prescription_clause,
  #      :payment_mode,
  #      :releasing_mode,
  #      [practitioner_facilities: :practitioner],
  #      [facility_files: :file],
  #      [
  #        facility_service_fees: [
  #          :coverage,
  #          :service_type
  #        ]
  #      ]
  #    ])
  #end

  def search_all_facility do
    Facility
    |> Repo.all
    |> Repo.preload([
        [practitioner_facilities: :practitioner],
        [facility_files: :file],
        [
          facility_service_fees: [
            :coverage,
            :service_type
          ]
        ]
      ])
  end

  def search_facility(params) do
    Facility
    |> where([f],
      (is_nil(f.name) or like(fragment("lower(?)", f.name),
        fragment("lower(?)", ^"#{params["facility"]}%"))) or
      (is_nil(f.code)  or like(fragment("lower(?)", f.code),
        fragment("lower(?)", ^"#{params["facility"]}%")))
      )
    |> order_by([f], asc: f.inserted_at)
    |> Repo.all
    |> Repo.preload([
        [practitioner_facilities: :practitioner],
        [facility_files: :file],
        [
          facility_service_fees: [
            :coverage,
            :service_type
          ]
        ]
      ])
  end

  #Start of Memberlink
  def search_facility_memberlink_for_acu(member_id, params) do
    coverage = CoverageContext.get_coverage_by_name("ACU")
    checker_acu = AuthorizationContext.check_coverage_in_product(member_id, coverage.id)
    if not Enum.empty?(checker_acu) do
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = if inclusion == [] do
        get_all_facility_id -- exception
      else
        inclusion
      end
      facilities =
        FacilityContext.get_facility_in_memberlink_by_name_acu!(
        facilities_id, params)
    else
      []
    end
  end

  def search_facility_memberlink(member_id, params) do
    if params["search_param"]["loa_type"] == "acu" do
      search_facility_memberlink_for_acu(member_id, params)
    else
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = get_all_facility_id -- exception
      facilities_id =
        facilities_id ++ inclusion
        |> Enum.uniq()
      facilities =
        FacilityContext.get_facility_in_memberlink_by_name!(
        facilities_id, params)
    end
  end

  def get_all_facility_id do
    Facility
    |> select([f], f.id)
    |> Repo.all()
  end

  def search_all_facility_member_for_acu(member_id, params) do
    coverage = CoverageContext.get_coverage_by_name("ACU")
    checker_acu = AuthorizationContext.check_coverage_in_product(member_id, coverage.id)
    if not Enum.empty?(checker_acu) do
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()
      facilities_id = if inclusion == [] do
        get_all_facility_id -- exception
      else
        inclusion
      end
      facilities =
        FacilityContext.get_facility_in_memberlink_acu!(facilities_id, params)
    else
      []
    end
  end

  def search_all_facility_member(member_id, params) do
    if params["loa_type"] == "acu" do
      search_all_facility_member_for_acu(member_id, params)
    else
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = get_all_facility_id -- exception
      facilities_id =
        facilities_id ++ inclusion
        |> Enum.uniq()
      facilities =
        FacilityContext.get_facility_in_memberlink!(facilities_id, params)
    end
  end

  def load_all_facility_for_intellisense_for_acu(member_id, params) do
    coverage = CoverageContext.get_coverage_by_name("ACU")
    checker_acu = AuthorizationContext.check_coverage_in_product(member_id, coverage.id)
      if not Enum.empty?(checker_acu) do
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = if inclusion == [] do
        get_all_facility_id -- exception
      else
        inclusion
      end

      facilities =
        Facility
        |> join(:inner, [f],
              d in Dropdown, f.ftype_id == d.id)
        |> where([f, d], f.id in ^facilities_id)
        |> where([f, d], f.step > 6 and f.status == "Affiliated"
              and (d.text == "HOSPITAL-BASED"
                or d.text == "CLINIC-BASED"))
        |> order_by([f], asc: f.name)
        |> Repo.all()
        |> Repo.preload([
          practitioner_facilities: :practitioner
        ])
    else
      []
    end
  end

  def load_all_facility_for_intellisense(member_id, params) do
    if params["loa_type"] == "acu" do
      load_all_facility_for_intellisense_for_acu(member_id, params)
    else
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception")
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = get_all_facility_id -- exception
      facility_ids =
        facilities_id ++ inclusion
        |> Enum.uniq()

    facilities = Facility
      |> join(:inner, [f],
            d in Dropdown, f.ftype_id == d.id)
      |> where([f, d], f.id in ^facility_ids)
      |> where([f, d], f.step > 6 and f.status == "Affiliated"
             and (d.text == "HOSPITAL-BASED"
              or d.text == "CLINIC-BASED"))
      |> order_by([f], asc: f.name)
      |> Repo.all()
      |> Repo.preload([
        practitioner_facilities: :practitioner
      ])
    end
  end

  defp search_facility_by_name(member_id, params) do
    # member = MemberContext.get_a_member!(member_id)
    # inclusion_product = for mp <- member.products do
    #   for pc <- mp.account_product.product.product_coverages do
    #     if pc.type == "inclusion" do
    #       pc.product_coverage_facilities
    #     end
    #   end
    # end
    # inclusion_product =
    #   inclusion_product
    #   |> List.flatten()
    #   |> Enum.uniq()
    #   |> List.delete(nil)
    # inclusion_facilities_id = for ip <- inclusion_product do
    #   facility = FacilityContext.get_facility_in_memberlink!(ip.facility_id)
    #   if facility.step >= 6 do
    #     ip.facility_id
    #   end
    # end
    # inclusion_facilities = Enum.uniq(inclusion_facilities_id)
    # exception_product = for mp <- member.products do
    #   for pc <- mp.account_product.product.product_coverages do
    #     if pc.type == "exception" do
    #       pc
    #     end
    #   end
    # end
    # exception_product =
    #   exception_product
    #   |> List.flatten()
    #   |> Enum.uniq()
    #   |> List.delete(nil)
    # exeception_facilities = if exception_product == [] do
    #   nil
    # else
    #   exception_facilities_id = for ep <- exception_product do
    #     for pcf <- ep.product_coverage_facilities do
    #       pcf.facility_id
    #     end
    #   end
    #   exception_facilities_id =
    #     exception_facilities_id
    #     |> List.flatten()
    #     |> Enum.uniq()
    #     |> List.delete(nil)
    #   exception_facilities_id = Enum.uniq(exception_facilities_id)
    #   facilities = FacilityContext.get_all_facility
    #   facilities_id = for facility <- facilities do
    #     if facility.step >= 6 do
    #       facility.id
    #     end
    #   end
    #   facilities_id =
    #     facilities_id
    #     |> List.flatten()
    #     |> Enum.uniq()
    #     |> List.delete(nil)
    #   exception_facilities = facilities_id -- exception_facilities_id
    # end
    # member_facilities = if exception_facilities == nil do
    #   inclusion_facilities
    # else
    #   member_facilities = inclusion_facilities ++ exception_facilities
    #   Enum.uniq(member_facilities)
    # end
    # facility = for f_id <- member_facilities do
    #   facility = FacilityContext.get_facility_in_memberlink!(f_id)
    #   facility_address = Enum.join([
    #     facility.line_1,
    #     facility.line_2,
    #     facility.city,
    #     facility.province,
    #     facility.region,
    #     facility.country
    #   ], " ")
    #   cond do
    #     (not is_nil(facility_name) and facility_name != "") and
    # (not is_nil(address) and address != "") ->
    #       if String.contains?(String.downcase(facility.name),
    #    String.downcase(facility_name))
    #    and String.contains?(String.downcase(facility_address),
    #    String.downcase(address)) do
    #       facility
    #     end
    #     not is_nil(facility_name) and facility_name != "" ->
    #     if String.contains?(String.downcase(facility.name),
    #                                         String.downcase(facility_name)) do
    #                                           facility
    #                                         end
    #     not is_nil(address) and address != "" ->
    #     if String.contains?(String.downcase(facility_address),
    #                                         String.downcase(address)) do
    #                                           facility
    #                                         end
    #     true ->
    #       #facility = search_all_facility_member(member.id)
    #   end
    # end
  end

  def search_all_facility_member_api(member_id) do
    inclusion =
      Facility
      |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
      |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
      |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
      |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
      |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion")
      |> select([f], f.id)
      |> Repo.all
      |> Enum.uniq()

    exception =
      Facility
      |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
      |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
      |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
      |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
      |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception")
      |> select([f], f.id)
      |> Repo.all
      |> Enum.uniq()

    facilities_id = get_all_facility_id -- exception
    facilities_id =
      facilities_id ++ inclusion
      |> Enum.uniq()
    facilities = FacilityContext.get_facility_in_memberlink_api(facilities_id)
  end

  def search_facility_memberlink_api(params, member_id) do
    inclusion =
      Facility
      |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
      |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
      |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
      |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
      |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion")
      |> select([f], f.id)
      |> Repo.all
      |> Enum.uniq()

    exception =
      Facility
      |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
      |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
      |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
      |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
      |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception")
      |> select([f], f.id)
      |> Repo.all
      |> Enum.uniq()

    facilities_id = get_all_facility_id -- exception
    facilities_id =
      facilities_id ++ inclusion
      |> Enum.uniq()
    facilities =
      FacilityContext.get_facility_in_memberlink_by_name_api!(
        facilities_id, params)
  end

  def get_facility_by_name_memberlink(name) do
    Facility
    |> Repo.get_by(name: name)
    |> Repo.preload([
      [practitioner_facilities:
        [:practitioner_status, practitioner_schedules:
          from(ps in PractitionerSchedule, select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
        room: ps.room}
      ), practitioner:  [practitioner_specializations: :specialization]]]
    ])
  end

  def get_translated_facilities(conn, facilities) do
    facilities =
      facilities
      |> Enum.into([], fn(facility) ->
        if not is_nil(facility.name) do
          name = TranslationContext.get_translated_values(conn, facility.name)
          if is_nil(name) do
            facility = Map.put(facility, :name, facility.name)
          else
          facility = Map.put(facility, :name, name)
          end
        end

        if not is_nil(facility.line_1) do
          line_1 =
            TranslationContext.get_translated_values(
              conn, facility.line_1)
          if is_nil(line_1) do
            facility = Map.put(facility, :line_1, facility.line_1)
          else
            facility = Map.put(facility, :line_1, line_1)
          end
        end

        if not is_nil(facility.line_2) do
          line_2 =
            TranslationContext.get_translated_values(
              conn, facility.line_2)
          if is_nil(line_2) do
            facility = Map.put(facility, :line_2, facility.line_2)
          else
            facility = Map.put(facility, :line_2, line_2)
          end
        end

        if not is_nil(facility.city) do
          city = TranslationContext.get_translated_values(conn, facility.city)
          if is_nil(city) do
            facility = Map.put(facility, :city, facility.city)
          else
            facility = Map.put(facility, :city, city)
          end
        end

        if not is_nil(facility.province) do
          province =
            TranslationContext.get_translated_values(
              conn, facility.province)
          if is_nil(province) do
            facility = Map.put(facility, :province, facility.province)
          else
            facility = Map.put(facility, :province, province)
          end
        end

      end)

    facilities =
      facilities
      |> Enum.into([], fn(facility) ->
        prac_fac =
          Enum.into(facility.practitioner_facilities,
            [], fn(prac_fac) ->
          last_name =
            TranslationContext.get_translated_values(
              conn, prac_fac.practitioner.last_name)
          if is_nil(last_name) do
            practitioner =
              Map.put(prac_fac.practitioner,
                :last_name, prac_fac.practitioner.last_name)
            prac_fac =
              prac_fac
              |> Map.delete(:practitioner)
              |> Map.put(:practitioner, practitioner)
          else
          practitioner = Map.put(prac_fac.practitioner, :last_name, last_name)
          prac_fac =
            prac_fac
            |> Map.delete(:practitioner)
            |> Map.put(:practitioner, practitioner)
          end

          first_name =
            TranslationContext.get_translated_values(
              conn, prac_fac.practitioner.first_name)
          if is_nil(first_name) do
            practitioner =
              Map.put(prac_fac.practitioner,
                :first_name, prac_fac.practitioner.first_name)
            prac_fac =
              prac_fac
              |> Map.delete(:practitioner)
              |> Map.put(:practitioner, practitioner)
          else
          practitioner = Map.put(prac_fac.practitioner, :first_name, first_name)
          prac_fac =
            prac_fac
            |> Map.delete(:practitioner)
            |> Map.put(:practitioner, practitioner)
          end
        end)
        facility
        |> Map.delete(:practitioner_facilities)
        |> Map.put(:practitioner_facilities, prac_fac)
      end)

  end

  #End of Memberlink

  def get_facility_by_code(code) do
    Facility
    |> where([f], f.code == ^code)
    |> Repo.one()
    |> Repo.preload([:category, :type])
  end

  def search_all_facility_filtered_from_member_coverage(member_id, coverage_id) do
    checker_coverage = AuthorizationContext.check_coverage_in_product(member_id, coverage_id)
    coverage = CoverageContext.get_coverage(coverage_id)
    if not Enum.empty?(checker_coverage) do
      inclusion =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      exception =
        Facility
        |> join(:inner, [f],
            pcf in ProductCoverageFacility, pcf.facility_id == f.id)
        |> join(:inner, [f, pcf],
            pc in ProductCoverage, pc.id == pcf.product_coverage_id)
        |> join(:inner, [f, pcf, pc],
            p in Product, p.id == pc.product_id)
        |> join(:inner, [f, pcf, pc, p],
            ac in AccountProduct, ac.product_id == p.id)
        |> join(:inner, [f, pcf, pc, p, ac],
            mp in MemberProduct, ac.id == mp.account_product_id)
        |> join(:inner, [f, pcf, pc, p, ac, mp],
            m in Member, m.id == mp.member_id)
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and
                     pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()
      facilities_id = if inclusion == [] do
        get_all_facility_id -- exception
      else
        inclusion
      end
      facilities =
        get_facility_with_many_id(facilities_id)
    else
      []
    end
  end

  def get_facility_with_many_id(facility_ids) do
    Facility
    |> where([f], f.id in ^facility_ids)
    |> order_by([f], asc: f.name)
    |> Repo.all()
  end

  def search_facility_by_location(params) do
    Facility
    |> join(:inner, [f],
              d in Dropdown, f.ftype_id == d.id)
    |> where([f, d], f.step > 6 and f.status == "Affiliated" and
              (d.text == "HOSPITAL-BASED"
                or d.text == "CLINIC-BASED") and
              (like(fragment("lower(?)", f.city),
                fragment("lower(?)", ^"%#{params["facility"]}%"))
              ) or
              (like(fragment("lower(?)", f.line_1),
                fragment("lower(?)", ^"%#{params["facility"]}%"))
              ) or
              (like(fragment("lower(?)", f.line_2),
                fragment("lower(?)", ^"%#{params["facility"]}%"))
              )
            )
    |> order_by([f], asc: f.name)
    |> Repo.all
    |> Repo.preload([
      [practitioner_facilities: :practitioner],
      [facility_files: :file],
      [
        facility_service_fees: [
          :coverage,
          :service_type
        ]
      ]
    ])
  end

end

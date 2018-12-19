defmodule Innerpeace.Db.Base.Api.PractitionerContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias Innerpeace.Db.{
    Repo,
    Schemas.Practitioner,
    Schemas.PractitionerSpecialization,
    Schemas.PractitionerContact,
    Schemas.Contact,
    Schemas.Phone,
    Schemas.Fax,
    Schemas.Bank,
    Schemas.PractitionerFacility,
    Schemas.PractitionerFacilityPractitionerType,
    Schemas.PractitionerFacilityContact,
    Schemas.PractitionerAccount,
    Schemas.PractitionerAccountContact,
    Schemas.PractitionerSchedule,
    Schemas.AccountGroupAddress,
    Schemas.PractitionerFacilityRoom,
    Schemas.FacilityRoomRate,
    Schemas.PractitionerLog,
    Schemas.Specialization,
    Schemas.Facility,
    Schemas.AccountGroup,
    Schemas.Account,
    Schemas.Email
  }

  alias Innerpeace.Db.Base.{
    PractitionerContext,
    EmailContext,
    PhoneContext,
    BankContext,
    FacilityContext,
    DropdownContext
  }

  alias Innerpeace.Db.Base.Api.{
    UtilityContext
  }

  def validate_details(params) do
    with {true} <- validate_params(params),
    {:ok, practitioner_id} <- check_practitioner_params(params),
     %Practitioner{} = practitioner <-
      practitioner_validated?(practitioner_id),
     practitioner_contact <-
      PractitionerContext.list_practitioner_contact(
        practitioner_id.id),
     practitioner_account <-
      PractitionerContext.list_practitioner_account(
        practitioner_id.id),
     practitioner_facility <-
      PractitionerContext.list_practitioner_facility(
        practitioner_id.id),
     practitioner_specialization <-
      PractitionerContext.list_practitioner_specialization(
        practitioner_id.id),
     practitioner_bank <-
      (if is_nil(practitioner_id.bank_id), do: [],
        else: PractitionerContext.list_practitioner_bank(
          practitioner_id.bank_id))
    do
      {:ok,
        practitioner,
        practitioner_contact,
        practitioner_account,
        practitioner_facility,
        practitioner_specialization,
        practitioner_bank
      }
    else
      {:practitioner_not_found} ->
        {:error, "The details you have entered is invalid"}
      {:first_name_error} ->
        {:error, "First Name is required"}
      {:last_name_error} ->
        {:error, "Last Name is required"}
      {:prc_no_error} ->
        {:error, "PRC Number is required"}
      nil ->
        {:error, "The Practitioner you have entered is not affiliated"}
      _ ->
        {:error, "Not found"}
    end
  end

  defp check_practitioner_params(params) do
    if Map.has_key?(params, "extension") do
    else
      params =
        params
        |> Map.put("extension", "")
    end

    if Map.has_key?(params, "middle_name") do
    else
      params =
        params
        |> Map.put("middle_name", "")
    end

    validate_practitioner_all_details(params)
  end

  defp validate_params(params) do
    has_first_name = Map.has_key?(params, "first_name")
    has_last_name = Map.has_key?(params, "last_name")
    has_prc_no = Map.has_key?(params, "prc_no")

    cond do
      params["first_name"] == "" ->
        {:first_name_error}
      params["last_name"] == "" ->
        {:last_name_error}
      params["prc_no"] == "" ->
        {:prc_no_error}
      has_first_name == false ->
        {:first_name_error}
      has_last_name == false ->
        {:last_name_error}
      has_prc_no == false ->
        {:prc_no_error}
      true ->
        {true}
    end

  end

  defp validate_practitioner_required_details(params) do
    practitioner = Practitioner
      |> where([p],
        (is_nil(p.first_name) or p.first_name == ^params["first_name"]) and
        (is_nil(p.last_name) or p.last_name == ^params["last_name"]) and
        (is_nil(p.prc_no) or p.prc_no == ^params["prc_no"]))
      |> Repo.all
      |> preload()

    if Enum.empty?(practitioner) do
      {:practitioner_not_found}
    else
      {:ok, List.first(practitioner)}
    end
  end

  defp validate_practitioner_other_details(params) do
       Practitioner
      |> where([p],
        ((is_nil(p.first_name) or p.first_name == ^params["first_name"]) and
        (is_nil(p.last_name) or p.last_name == ^params["last_name"]) and
        (is_nil(p.prc_no) or p.prc_no == ^params["prc_no"])) and
        ((is_nil(p.middle_name) or p.middle_name == ^params["middle_name"]) or
        (is_nil(p.suffix) or p.suffix == ^params["extension"])))
      |> Repo.all
      |> preload()
      |> validate_practitioner_other_details_v2()
  end

  defp validate_practitioner_other_details_v2([]), do: {:practitioner_not_found}
  defp validate_practitioner_other_details_v2(practitioner), do: {:ok, List.first(practitioner)}

  defp validate_practitioner_all_details(params) do
    practitioner = Practitioner
      |> where([p],
        fragment("coalesce(?,?)", p.first_name, "") == ^params["first_name"] and
        fragment("coalesce(?,?)", p.last_name, "") == ^params["last_name"] and
        fragment("coalesce(?,?)", p.prc_no, "") == ^params["prc_no"] and
        fragment("coalesce(?,?)", p.middle_name, "") == ^params["middle_name"] and
        fragment("coalesce(?,?)", p.suffix, "") == ^params["extension"])
      |> Repo.all
      |> preload()

    if Enum.empty?(practitioner) do
      {:practitioner_not_found}
    else
      {:ok, List.first(practitioner)}
    end
  end

  defp preload(practitioner) do
    Repo.preload(practitioner,
      [:bank, [practitioner_facilities: :facility],
        [practitioner_specializations: :specialization],
          [practitioner_contact: [contact: [:phones]]]])
  end

  defp practitioner_validated?(practitioner_id) do
    Practitioner
    |> where([p], p.id == ^practitioner_id.id and p.affiliated == "Yes")
    |> Repo.one()
  end

  # for practitioner/new

  def validate_new_practitioner(user, params) do
    case params["payment_type"] do

      "MediLink XP Card" ->
        with {:ok, changeset} <- validate_api_medilink_xp(params),
             {:ok, practitioner} <- insert_practitioner_step1(changeset, user),
             {:ok} <- contact_step2(changeset, practitioner, params),
             {:ok, practitioner} <- financial_step3(changeset, practitioner),
             ## creation of practitioner_facility
             {:ok} <- pf_insert(changeset, practitioner, user, params)
        do
          {:ok, practitioner}
        else
          {:error, changeset} ->
            {:error, changeset}
        end

      "Check" ->

        with {:ok, changeset} <- validate_api_check(params),
             {:ok, practitioner} <- insert_practitioner_step1(changeset, user),
             {:ok} <- contact_step2(changeset, practitioner, params),
             {:ok, practitioner} <- financial_step3(changeset, practitioner),
             ## creation of practitioner_facility
             {:ok} <- pf_insert(changeset, practitioner, user, params)
        do
          {:ok, practitioner}
        else
          {:error, changeset} ->
            {:error, changeset}
        end

      "Bank" ->

        with {:ok, changeset} <- validate_api_bank(params),
             {:ok, practitioner} <- insert_practitioner_step1(changeset, user),
             {:ok} <- contact_step2(changeset, practitioner, params),
             {:ok, practitioner} <- financial_step3(changeset, practitioner),
             ## creation of practitioner_facility
             {:ok} <- pf_insert(changeset, practitioner, user, params)
        do
          {:ok, practitioner}
        else
          {:error, changeset} ->
            {:error, changeset}
        end

        _ ->

        {:payment_type_error,
          "You can only use ['MediLink XP Card', 'Check', 'Bank'] in payment_type param"}

    end

  end

  defp validate_api_medilink_xp(params) do

    data = %{}
    general_types = %{
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      birth_date: Ecto.Date,
      effectivity_from: Ecto.Date,
      effectivity_to: Ecto.Date,
      suffix: :string,
      gender: :string,
      affiliated: :string,
      prc_no: :string,
      step: :integer,
      code: :string,
      status: :string,
      specialization_name: :string,
      sub_specialization_name: {:array, :string},
      exclusive: {:array, :string},
      vat_status: :string,
      prescription_period: :string,
      tin: :string,
      withholding_tax: :string,
      payment_type: :string,
      xp_card_no: :string,
      payee_name: :string,
      account_no: :string,
      bank_name: :string,
      contact: {:array, :map},
      practitioner_facilities: {:array, :map}

    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        ## for step1 general
        :code,
        :first_name,
        :last_name,
        :birth_date,
        :prc_no,
        :effectivity_from,
        :effectivity_to,
        :specialization_name,
        :affiliated,
        ##  for step2 contacts
        :contact,
        ## for step3 financial
        :exclusive,
        :vat_status,
        :tin,
        :xp_card_no,
        :practitioner_facilities
      ])
      |> validate_inclusion(:affiliated, ["Yes", "No"])
      |> validate_practitioner_facilities()
      |> exclusive_field_list_null?()
      # |> contact_checker()
      # |> email_checker()
      # |> fax_checker()
      # |> mobile_no_checker()
      # |> tel_no_checker()
      |> validate_contact()
      |> unique_code?()

    if changeset.valid? do
      {:ok}
    else
      {:error, changeset}
    end
  end

  defp validate_api_bank(params) do

    data = %{}
    general_types = %{
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      birth_date: Ecto.Date,
      effectivity_from: Ecto.Date,
      effectivity_to: Ecto.Date,
      suffix: :string,
      gender: :string,
      affiliated: :string,
      prc_no: :string,
      step: :integer,
      code: :string,
      status: :string,
      specialization_name: :string,
      sub_specialization_name: {:array, :string},
      exclusive: {:array, :string},
      vat_status: :string,
      prescription_period: :string,
      tin: :string,
      withholding_tax: :string,
      payment_type: :string,
      xp_card_no: :string,
      payee_name: :string,
      account_no: :string,
      bank_name: :string,
      contact: {:array, :map},
      practitioner_facilities: {:array, :map}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        ## for step1 general
        :code,
        :first_name,
        :last_name,
        :birth_date,
        :prc_no,
        :effectivity_from,
        :effectivity_to,
        :specialization_name,
        :affiliated,
        ## for step2 contacts
        :contact,
        ## for step3 financial
        :exclusive,
        :vat_status,
        :tin,
        :bank_name,
        :account_no,
        :practitioner_facilities
      ])
      |> validate_inclusion(:affiliated, ["Yes", "No"])
      |> validate_practitioner_facilities()
      |> transform_bank_name()
      |> exclusive_field_list_null?()
      # |> contact_checker()
      # |> email_checker()
      # |> fax_checker()
      # |> mobile_no_checker()
      # |> tel_no_checker()
      |> validate_contact()
      |> unique_code?()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_api_check(params) do

    data = %{}
    general_types = %{
      first_name: :string,
      middle_name: :string,
      last_name: :string,
      birth_date: Ecto.Date,
      effectivity_from: Ecto.Date,
      effectivity_to: Ecto.Date,
      suffix: :string,
      gender: :string,
      affiliated: :string,
      prc_no: :string,
      step: :integer,
      code: :string,
      status: :string,
      specialization_name: :string,
      sub_specialization_name: {:array, :string},
      exclusive: {:array, :string},
      vat_status: :string,
      prescription_period: :string,
      tin: :string,
      withholding_tax: :string,
      payment_type: :string,
      xp_card_no: :string,
      payee_name: :string,
      account_no: :string,
      bank_name: :string,
      contact: :map,
      practitioner_facilities: {:array, :map}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        ## for step1 general
        :code,
        :first_name,
        :last_name,
        :birth_date,
        :prc_no,
        :effectivity_from,
        :effectivity_to,
        :specialization_name,
        :affiliated,
        ##  for step2 contacts
        :contact,
        ## for step3 financial
        :exclusive,
        :vat_status,
        :tin,
        :payee_name,
        :practitioner_facilities
      ])
      |> validate_inclusion(:affiliated, ["Yes", "No"])
      |> validate_practitioner_facilities()
      |> exclusive_field_list_null?()
      # |> contact_checker()
      |> email_checker()
      |> fax_checker()
      |> mobile_no_checker()
      |> tel_no_checker()
      |> unique_code?()

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def unique_code?(changeset) do
    if Map.has_key?(changeset.changes, :code) do
      if get_practitioner_by_code(changeset.changes.code) do
        ### error changeset code already existing
        Changeset.add_error(
          changeset, :code, "Practitioner code already existing!")
      else
        ### success code
        changeset
      end
    else
      ### error changeset code cant be blank
      changeset
    end
  end

  def get_practitioner_by_code(code) do
    Practitioner
    |> Repo.get_by(code: code)
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities:
        [practitioner_facility_rooms: :facility_room],
      practitioner_facilities:
        [:facility, :practitioner_facility_practitioner_types,
          :practitioner_schedules, practitioner_facility_contacts:
          [contact: [:phones, :emails]]],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  # For changeset custom validation

  # start of contact checker for practitioner
  # def contact_checker(changeset) do
  #   if changeset.changes.contact["email"] ==
  #   [] and changeset.changes.contact["mobile_no"] == []
  # and changeset.changes.contact["fax"] == [] and
  # changeset.changes.contact["tel_no"] == [] do
  #     Changeset.add_error(
  # changeset, :contact, "Please input atleast one contact")
  #   else
  #     changeset
  #   end
  # end

  def email_checker(changeset) do
    if Map.has_key?(changeset.changes.contact, "email") do
      if changeset.changes.contact["email"] == "" do
        Changeset.add_error(
          changeset, :contact, "Email param is not a list")
      else
        changeset
      end
    else
      Changeset.add_error(
        changeset, :contact, "Email param was missing")
    end
  end

  def fax_checker(changeset) do
    if Map.has_key?(changeset.changes.contact, "fax") do
      if changeset.changes.contact["fax"] == "" do
        Changeset.add_error(
          changeset, :contact, "Fax param is not a list")
      else
        changeset
      end
    else
      Changeset.add_error(
        changeset, :contact, "Fax param was missing")
    end
  end

  def mobile_no_checker(changeset) do
    if Map.has_key?(changeset.changes.contact, "mobile_no") do
      if changeset.changes.contact["mobile_no"] == "" do
        Changeset.add_error(
          changeset, :contact, "Mobile No. param is not a list")
      else
        changeset
      end
    else
      Changeset.add_error(
        changeset, :contact, "Mobile No. param was missing")
    end
  end

  def tel_no_checker(changeset) do
    if Map.has_key?(changeset.changes.contact, "tel_no") do
      if changeset.changes.contact["tel_no"] == "" do
        Changeset.add_error(
          changeset, :contact, "Telephone param is not a list")
      else
        changeset
      end
    else
      Changeset.add_error(
        changeset, :contact, "Telephone param was missing")
    end
  end

  # end of contact checker for practitioner

  # start of pf_contact checker for practitioner_facility

  def pf_contact_checker(changeset) do
    if Map.has_key?(changeset.changes, "pf_contact") do
      if changeset.changes.pf_contact["email"] == [] and
          changeset.changes.pf_contact["mobile_no"] == [] and
            changeset.changes.pf_contact["fax"] == [] and
              changeset.changes.pf_contact["tel_no"] == [] do
        Changeset.add_error(
          changeset, :pf_contact, "Please input atleast one contact")
      else
        changeset
      end
    else
      changeset
    end
  end

  def pf_email_checker(changeset) do
    if Map.has_key?(changeset.changes, "pf_contact") do
      if Map.has_key?(changeset.changes.pf_contact, "email") do
        if changeset.changes.pf_contact["email"] == "" do
          Changeset.add_error(
            changeset, :pf_contact, "Email param is not a list")
        else
          changeset
        end
      else
        Changeset.add_error(
          changeset, :pf_contact, "Email param was missing")
      end
    else
      changeset
    end
  end

  def pf_fax_checker(changeset) do
    if Map.has_key?(changeset.changes, "pf_contact") do
      if Map.has_key?(changeset.changes.pf_contact, "fax") do
        if changeset.changes.pf_contact["fax"] == "" do
          Changeset.add_error(
            changeset, :pf_contact, "Fax param is not a list")
        else
          changeset
        end
      else
        Changeset.add_error(
          changeset, :pf_contact, "Fax param was missing")
      end

    else
      changeset
    end
  end

  def pf_mobile_no_checker(changeset) do
    if Map.has_key?(changeset.changes, "pf_contact") do
      if Map.has_key?(changeset.changes.pf_contact, "mobile_no") do
        if changeset.changes.pf_contact["mobile_no"] == "" do
          Changeset.add_error(
            changeset, :pf_contact, "Mobile No. param is not a list")
        else
          changeset
        end
      else
        Changeset.add_error(
          changeset, :pf_contact, "Mobile No. param was missing")
      end

    else
      changeset
    end
  end

  def pf_tel_no_checker(changeset) do
    if Map.has_key?(changeset.changes, "pf_contact") do
      if Map.has_key?(changeset.changes.pf_contact, "tel_no") do
        if changeset.changes.pf_contact["tel_no"] == "" do
          Changeset.add_error(
            changeset, :pf_contact, "Telephone param is not a list")
        else
          changeset
        end
      else
        Changeset.add_error(
          changeset, :pf_contact, "Telephone param was missing")
      end

    else
      changeset
    end
  end

   # end of pf_contact checker for practitioner_facility

  def exclusive_field_list_null?(changeset) do
    if changeset.changes.exclusive == [] do
      Changeset.add_error(
        changeset, :exclusive, "Please input atleast one exclusive")
    else
      changeset
    end
  end

  def if_param_schedule_existing(changeset) do
    with true <- Map.has_key?(changeset.changes, :schedule)

    do
      if changeset.changes.schedule == [] do
        Changeset.add_error(
          changeset, :schedule, "Please input atleast one schedule")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  def transform_bank_name(changeset) do
    with true <- Map.has_key?(changeset.changes, :bank_name) do
      if bank = BankContext.get_bank_by_name(changeset.changes.bank_name) do
        Changeset.put_change(changeset, :bank_id, bank.id)
      else
        Changeset.add_error(changeset, :bank_name, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  def transform_facility_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :facility_code)

    do
      if facility =
          FacilityContext.get_facility_by_code(
            changeset.changes.facility_code)
      do
        Changeset.put_change(changeset, :facility_id, facility.id)
      else
        Changeset.add_error(changeset, :facility_code, "not existing")
      end

    else
      _ ->
        changeset
    end

  end

  defp validate_practitioner_facilities(changeset) do
    if is_nil(changeset.changes.practitioner_facilities) do
      changeset
    else
      practitioner_facilities =
        Changeset.get_field(changeset, :practitioner_facilities)

      validate_pfs =
        for practitioner_facility <- practitioner_facilities do
        practitioner_facility_field(practitioner_facility,
          practitioner_facility["facility_code"])
      end

      set_of_pfs = for validate_pf <- validate_pfs do
        validate_pf.changes
      end

      with true <- Enum.all?(validate_pfs, &(&1.valid? == true))

      do
        Changeset.put_change(changeset, :practitioner_facilities, set_of_pfs)
      else
        _ ->
          errors = array_changeset_errors(validate_pfs)
          add_error(changeset, :practitioner_facilities, errors)
      end

    end
  end

  def array_changeset_errors(practitioner_facilities) do

   errors = for practitioner_facility <- practitioner_facilities do
     if practitioner_facility.valid? == false do
       UtilityContext.changeset_errors_string_colon(
        practitioner_facility.errors)
      end
   end
  |> List.delete(nil) |> Enum.join(", ")

  end

  defp practitioner_facility_field(params, facility_code) do
    data = %{}
     practitioner_facility_types = %{
      # practitioner_facility step1 general
      practitioner_type: {:array, :string},
      facility_code: :string,
      pf_status: :string, ## pstatus_id
      affiliation_date: Ecto.Date,
      disaffiliation_date: Ecto.Date,
      payment_mode: :string,
      credit_term: :integer,
      ## practitioner_facility step2 contacts
      pf_contact: :map,
      ## practitioner_facility step3 rates
      coordinator: :boolean,
      consultation_fee: :decimal,
      coordinator_fee: :decimal,
      cp_clearance_name: :string,
      ## eg: Medical Indication, Operative Monitoring, Routine, Regular
      cp_clearance_rate: :decimal,
      fixed: :boolean,
      fixed_fee: :decimal,
      pf_room_rate: {:array, :map},
      ## practitioner_facility step4 schedule
      schedule: {:array, :map},
    }
    changeset =
      {data, practitioner_facility_types}
      |> Changeset.cast(params, Map.keys(practitioner_facility_types))
      |> Changeset.validate_required([
        ## for practitioner_facility step1
        :practitioner_type,
        :facility_code,
        :pf_status,
        :payment_mode,
        ## for practitioner_facility step2
        :pf_contact,
        ## for practitioner_facility step3
        :coordinator, #Yes / No
        :fixed, ## Yes / No
        :consultation_fee,
        ## for practitioner_facility step4
        :schedule
      ])
      |> validate_inclusion(:payment_mode, ["Umbrella", "Individual"])
      |> transform_facility_code()
      |> transform_pf_status()
      |> transform_cp_clearance_name()
      |> transform_practitioner_type()
      |> if_param_schedule_existing()
      |> pf_contact_checker()
      |> pf_email_checker()
      |> pf_fax_checker()
      |> pf_mobile_no_checker()
      |> pf_tel_no_checker()
      |> pf_room_rate_checker(facility_code)

    changeset
  end

  #### if facility room type is existing?
  def  pf_room_rate_checker(changeset, facility_code) do

    if Map.has_key?(changeset.changes, :facility_code) do
      facility =
        FacilityContext.get_facility_by_code(changeset.changes.facility_code)

      if Map.has_key?(changeset.changes, :pf_room_rate) and facility do

        pf_room_rates = Changeset.get_field(changeset, :pf_room_rate)

        validated_pf_rr = for  pf_room_rate <- pf_room_rates do
          pf_room_rate_field(pf_room_rate,  changeset.changes.facility_code)
        end

        with true <- Enum.all?(validated_pf_rr, &(&1.valid? == true))

        do
          changeset
        else
          _ ->
            add_error(changeset, :pf_room_rate,
              "facility_room_type data is not existing")
        end

      else
        changeset
      end
    else
      changeset
    end

  end

  def pf_room_rate_field(params, facility_code) do
    data = %{}
     pf_room_rate_types = %{
      rate: :decimal,
      facility_room_type: :string
    }

    changeset =
      {data, pf_room_rate_types}
      |> Changeset.cast(params, Map.keys(pf_room_rate_types))
      |> Changeset.validate_required([
        :rate,
        :facility_room_type
      ])
      |> frt_checker(facility_code)

    changeset
  end

  def frt_checker(changeset, facility_code) do
    with true <- Map.has_key?(changeset.changes, :facility_room_type)

    do

      if facility_room_rate =
        FacilityContext.get_facility_room_type(
          changeset.changes.facility_room_type, facility_code)
      do
        changeset
      else
        Changeset.add_error(changeset, :facility_room_type, "is invalid")
      end

    else
      _ ->
        changeset
    end
  end

  def transform_pf_status(changeset) do
    ## facility_code => facility_id, pf_status =>
    # pstatus_id, cp_clearance_name => cp_clearance_id
    with true <- Map.has_key?(changeset.changes, :pf_status)

    do
      if status =
        DropdownContext.get_practitioner_status(
          changeset.changes.pf_status)
      do
        Changeset.put_change(changeset, :pstatus_id, status.id)
      else
        Changeset.add_error(changeset, :pf_status, "is invalid")
      end

    else
      _ ->
        changeset
    end
  end

  def transform_cp_clearance_name(changeset) do
    ## facility_code => facility_id, pf_status =>
    # pstatus_id, cp_clearance_name => cp_clearance_id
    with true <- Map.has_key?(changeset.changes, :cp_clearance_name)

    do
      if status =
          DropdownContext.get_cp_clearance(
            changeset.changes.cp_clearance_name)
      do
        Changeset.put_change(
          changeset, :cp_clearance_id, status.id)
      else
        Changeset.add_error(
          changeset, :cp_clearance_name, "is invalid")
      end

    else
      _ ->
        changeset
    end
  end

  def transform_practitioner_type(changeset) do
    ## facility_code => facility_id, pf_status =>
     # pstatus_id, cp_clearance_name => cp_clearance_id
    with true <- Map.has_key?(changeset.changes, :practitioner_type)

    do
      if changeset.changes.practitioner_type == [] do
        Changeset.add_error(
          changeset, :practitioner_type,
          "Please input atleast one: 'Primary Care' or 'Specialist'")
      else
        Changeset.put_change(
          changeset, :types, changeset.changes.practitioner_type)
      end
    else
      _ ->
        changeset
    end
  end

  # For Practitioner Insertion ####################################

  def insert_practitioner_step1(practitioner_params \\ %{}, user) do
    specialization =
      get_specialization_by_name(
        practitioner_params.changes.specialization_name)
    sub_specialization_ids =
      for sub_specialization <-
        practitioner_params.changes.sub_specialization_name
      do
      get_specialization_id(sub_specialization)
    end

    practitioner_params =
      practitioner_params.changes
      |> Map.merge(%{
        step: 5,
        created_by_id: user.id,
        updated_by_id: user.id,
        specialization_ids: [specialization.id]
      })

    case %Practitioner{}
          |> Practitioner.changeset_api_step1(practitioner_params)
          |> Repo.insert()
    do
      {:ok, practitioner} ->
        PractitionerContext.set_practitioner_specializations(
          practitioner.id, [specialization.id], sub_specialization_ids)
        {:ok, practitioner}
      {:error, changeset} ->
        {:error, changeset}
    end

  end

  def contact_step2(changeset, practitioner, params) do
    for contact <- params["contact"] do
      inserted_contact =
        %Contact{}
        |> Contact.changeset_practitioner(contact)
        |> Repo.insert!()
      if Map.has_key?(contact, "mobile"),
      do: insert_mobile(contact["mobile"], inserted_contact.id)
      if Map.has_key?(contact, "telephone"),
        do: insert_telephone(contact["telephone"], inserted_contact.id)
      if Map.has_key?(contact, "fax"),
        do: insert_fax(contact["fax"], inserted_contact.id)
      if Map.has_key?(contact, "email"),
        do: insert_email(contact["email"], inserted_contact.id)
      PractitionerContext.create_practitioner_contact(%{
            practitioner_id: practitioner.id,
            contact_id: inserted_contact.id
          })
    end
    {:ok}
  end

  def financial_step3(changeset, practitioner) do
    {:ok, practitioner} =
      practitioner
      |> Practitioner.changeset_financial(changeset.changes)
      |> Repo.update()
  end

  # for Practitioner Facility Insertion

  def pf_insert(changeset, practitioner, user, params) do
    for changeset_practitioner_facility <-
      changeset.changes.practitioner_facilities
    do
      changeset_practitioner_facility =
        changeset_practitioner_facility
        |> Map.merge(%{
          step: 6,
          created_by_id: user.id,
          updated_by_id: user.id,
          practitioner_id: practitioner.id
        })

      {:ok, pf} =
        %PractitionerFacility{}
        |> PractitionerFacility.step1_changeset(changeset_practitioner_facility)
        |> Repo.insert()

      with :ok <- pf_type_insert(changeset_practitioner_facility, pf),
           {:ok} <- pf_room_rate(changeset_practitioner_facility, pf),
           {:ok, pfc} <-
              pf_contact_step2(changeset_practitioner_facility, pf, params),
           {:ok} <- pf_scheduling(changeset_practitioner_facility, pf)
      do
        {:ok}
      end

    end
    {:ok}
  end

  def pf_type_insert(changeset, pf) do
   PractitionerContext.insert_practitioner_facility_type_api(
    changeset.types, pf)
  end

  def pf_room_rate(changeset, pf) do

    if Map.has_key?(changeset, :pf_room_rate) == true do
      if changeset.pf_room_rate == [] do
        changeset = Changeset.add_error(changeset, :pf_room_rate, "Please input atleast one practitioner facility room rate")
        {:error, changeset}
      else
        for room_rate <- changeset.pf_room_rate do
          facility_room_rate = get_facility_room_rate(room_rate["facility_room_type"])

          params = %{
            rate: room_rate["rate"],
            practitioner_facility_id: pf.id,
            facility_room_id: facility_room_rate.id
          }

          %PractitionerFacilityRoom{}
          |> PractitionerFacilityRoom.changeset(params)
          |> Repo.insert()
        end

        {:ok}
      end

    else
      {:ok}
    end

  end

  def pf_contact_step2(changeset, pf, params) do
    empty = %{}
    {:ok, contact} =
    %Contact{}
    |> Contact.pfcontact_changeset(empty)
    |> Repo.insert()

    email = changeset.pf_contact["email"]
    fax = changeset.pf_contact["fax"]
    mobile_no = changeset.pf_contact["mobile_no"]
    tel_no = changeset.pf_contact["tel_no"]

    Enum.each(fax, fn(fax) ->
      PhoneContext.create_phone(%{
        contact_id: contact.id,
        number: fax,
        type: "fax"
      })
    end)

    Enum.each(mobile_no, fn(mobile_no) ->
      PhoneContext.create_phone(%{
        contact_id: contact.id,
        number: mobile_no,
        type: "mobile"
      })
    end)

    Enum.each(tel_no, fn(tel_no) ->
      PhoneContext.create_phone(%{
        contact_id: contact.id,
        number: String.replace(tel_no, "-", ""),
        type: "telephone"
      })
    end)

    Enum.each(email, fn(email) ->
      EmailContext.create_email(%{
        contact_id: contact.id,
        address: email,
        type: "email"
      })
    end)

    PractitionerContext.create_practitioner_facility_contact(%{
      "practitioner_facility_id" => pf.id,
      "contact_id" => contact.id
    })

  end

  def pf_scheduling(changeset, pf) do
    for schedule <- changeset.schedule do
      time_from = String.split(schedule["time_from"], ":")
      time_to = String.split(schedule["time_to"], ":")

      params = %{
        day: schedule["day"],
        room: schedule["room"],
        time_from:
          Ecto.Time.cast!(
            %{hour: Enum.at(time_from, 0),
              minute: Enum.at(time_from, 1)}),
        time_to:
          Ecto.Time.cast!(
            %{hour: Enum.at(time_to, 0),
              minute: Enum.at(time_to, 1)}),
        practitioner_facility_id: pf.id
      }

      %PractitionerSchedule{}
      |> PractitionerSchedule.changeset_pf(params)
      |> Repo.insert()

    end

    {:ok}

  end

  def get_practitioner_code_by_vendor_code(vendor_code) do
    practitioner =
      Practitioner
      |> where([p], p.vendor_code == ^vendor_code)
      |> Repo.one

    if is_nil(practitioner) do
      ""
    else
      practitioner.code
    end
  end

  #################################################################

  def get_specialization_by_name(specialization_name) do
    Specialization
    |> where([s], s.name == ^specialization_name)
    |> Repo.one()
  end

  def get_specialization_id(specialization_name) do
    Specialization
    |> where([s], s.name == ^specialization_name)
    |> select([s], s.id)
    |> Repo.one()
  end

  def get_facility_room_rate(fr_type) do
    FacilityRoomRate
    |> where([frr], frr.facility_room_type == ^fr_type)
    |> Repo.one()
  end

  ## to avoid get! in main practitioner_context
  def get_practitioner(id) do
    Practitioner
    |> Repo.get(id)
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities:
        [practitioner_facility_rooms: :facility_room],
      practitioner_facilities:
        [:facility, :practitioner_facility_practitioner_types,
          :practitioner_schedules, practitioner_facility_contacts:
          [contact: [:phones, :emails]]],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  ##################################################################

  def get_all_practitioners do
    Practitioner
    |> Repo.all()
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities: [
        :practitioner_schedules,
        :facility,
        :practitioner_facility_practitioner_types,
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  def get_all_practitioners(full_name) do
    full_name = full_name |> String.downcase()
    Practitioner
    |> where([p],
        like(fragment("LOWER(?)",
          fragment("CONCAT(?,?,?)",
            p.first_name, " ",
          fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END",
            p.middle_name, p.last_name,
          fragment("CONCAT(?,?,?)",
            p.middle_name, " ", p.last_name)))), ^"%#{full_name}%") or
        ilike(p.code, ^"%#{full_name}%")
      )
    |> Repo.all()
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities: [
        :practitioner_schedules,
        :facility,
        :practitioner_facility_practitioner_types,
        practitioner_facility_contacts: [
          contact: [
            :phones,
            :emails
          ]
        ]
      ],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

#Validate Contact

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
      email: :string,
      mobile: {:array, :map},
      telephone: {:array, :map},
      fax: {:array, :map}
    }
    changeset =
      {data, contact_types}
      |> Changeset.cast(params, Map.keys(contact_types))
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

  def get_practitioner_specializations(practitioner_id) do
    PractitionerSpecialization
    |> where([ps], ps.practitioner_id == ^practitioner_id)
    |> Repo.all()
    |> Repo.preload(:specialization)
  end

end

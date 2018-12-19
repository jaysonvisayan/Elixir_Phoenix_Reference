defmodule Innerpeace.Db.Base.PractitionerContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Practitioner,
    Schemas.PractitionerSpecialization,
    Schemas.PractitionerContact,
    Schemas.Contact,
    Schemas.Phone,
    # Schemas.Fax,
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
    Schemas.MemberProduct,
    Schemas.Member,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.PractitionerFacilityConsultationFee,
    Schemas.Dropdown,
    Base.MemberContext,
    Base.FacilityContext,
    Base.TranslationContext,
    Base.DropdownContext,
    Base.AccountContext,
    Base.ContactContext,
    Base.CoverageContext,
    Base.AuthorizationContext
  }
  alias Innerpeace.Db.Base.Api.FacilityContext, as: ApiFacilityContext
  alias Innerpeace.Db.Base.Api.UtilityContext

  def search(params) do
    Practitioner
    |> where([p], p.first_name == ^params.first_name)
  end

  def get_all_practitioners do
    Practitioner
    |> Repo.all
    |> Repo.preload([
      practitioner_facilities:
        [:facility, :practitioner_schedules, :practitioner_status],
      practitioner_specializations: :specialization,
      practitioner_accounts: [:account_group, :practitioner_schedules],
      practitioner_contact: [contact: :phones]])

  end

  def get_practitioner(id) do
    Practitioner
    |> Repo.get(id)
    |> Repo.preload([
      :logs,
      :bank,
      :dropdown_vat_status,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities:
        [[practitioner_facility_contacts:
          [contact: [:phones, :emails]]],
            :practitioner_schedules,
            :practitioner_status,
            :facility
      ],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  def get_practitioner_by_prc(prc_no) do
    Practitioner
    |> Repo.get_by(prc_no: prc_no)
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities:
        [practitioner_facility_contacts:
          [contact: [:phones, :emails]]],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  def get_a_practitioner(id) do
    Practitioner
    |> Repo.get(id)
    |> Repo.preload([
      :logs,
      :bank,
      practitioner_accounts: :account_group,
      practitioner_specializations: :specialization,
      practitioner_facilities:
        [practitioner_facility_contacts:
          [contact: [:phones, :emails]]],
      practitioner_contact: [contact: [:phones, :emails]]
    ])
  end

  def get_practitioner_contacts(id) do
    pc =
      PractitionerContact
      |> where([pc], pc.practitioner_id == ^id)
      |> Repo.all
    if Enum.empty?(pc) do
      []
    else
      pc
      |> Ecto.assoc(:contact)
      |> Repo.all
      |> Repo.preload([:phones, :emails])
    end
  end

  def list_practitioner_bank(id) do
     Bank
      |> where([b], b.id == ^id)
      |> Repo.all
  end

  def list_practitioner_account(id) do
     PractitionerAccount
      |> where([pa], pa.practitioner_id == ^id)
      |> Repo.all
      |> Repo.preload([:account_group])
  end

  def list_practitioner_facility(id) do
     PractitionerFacility
      |> where([pf], pf.practitioner_id == ^id)
      |> Repo.all
      |> Repo.preload([
          :facility,
          :practitioner_schedules,
          practitioner_facility_contacts:
            [contact: [:phones, :emails]]])
  end

  def list_practitioner_specialization(id) do
     PractitionerSpecialization
      |> where([ps], ps.practitioner_id == ^id)
      |> Repo.all
      |> Repo.preload([:specialization])
  end

  def list_practitioner_contact(id) do
     PractitionerContact
      |> where([pc], pc.practitioner_id == ^id)
      |> Repo.all
      |> Repo.preload([contact: [:phones, :emails]])
  end

  def get_practitioner_contact(practitioner_contact_id) do
    PractitionerContact
    |> Repo.get!(practitioner_contact_id)
    |> Repo.preload([contact: [:phones, :emails]])
  end

  def get_practitioner_using_contact(id) do
    pc =
      PractitionerContact
      |> where([pc], pc.contact_id == ^id)
      |> Repo.one
    Practitioner
    |> Repo.get!(pc.practitioner_id)
    |> Repo.preload([
      :bank,
      practitioner_specializations: :specialization,
      practitioner_contact: [contact: [:phones, :emails]]
    ])

  end

  def get_practitioner_type(practitioner_facility_id) do
    PractitionerFacilityPractitionerType
    |> Repo.get_by(practitioner_facility_id: practitioner_facility_id)
  end

  def create_practitioner(practitioner_params) do

    if practitioner_params["affiliated"] ==  "No" do
      practitioner_params  =
        practitioner_params
        |> Map.put("effectivity_from", "")
        |> Map.put("effectivity_to", "")
        |> Map.put("hidden_eff", "")
        |> Map.put("hidden_exp", "")
    end

    %Practitioner{}
    |> Practitioner.changeset(practitioner_params)
    |> Repo.insert()
  end

  def update_practitioner_photo(%Practitioner{} = practitioner, attrs) do
    practitioner
    |> Practitioner.changeset_photo(attrs)
    |> Repo.update()
  end

  def update_practitioner(id, practitioner_params) do
    if practitioner_params["affiliated"] ==  "No" do
      practitioner_params  =
        practitioner_params
        |> Map.put("effectivity_from", "")
        |> Map.put("effectivity_to", "")
        |> Map.put("hidden_eff", "")
        |> Map.put("hidden_exp", "")
    end

    if practitioner_params["phic_accredited"] == "No" do
      practitioner_params = Map.put(practitioner_params, "phic_date", "")
    end

    # raise practitioner_params

    id
    |> get_practitioner()
    |> Practitioner.changeset_general_edit(practitioner_params)
    |> Repo.update()
  end

  def update_practitioner_step(id, step_params) do
    practitioner = get_practitioner(id)
    practitioner
    |> Practitioner.changeset_step(step_params)
    |> Repo.update()
  end

  def update_practitioner_status(%Practitioner{} = practitioner, attrs) do
    practitioner
    |> Practitioner.changeset_status(attrs)
    |> Repo.update()
  end

  def delete_practitioner(id) do
    id
    |> get_practitioner()
    |> Repo.delete
  end

  def delete_practitioner_contact(contact_id) do
    PractitionerContact
    |> where([pc], pc.contact_id == ^contact_id)
    |> Repo.delete_all()
    Contact
    |> where([c], c.id == ^contact_id)
    |> Repo.delete_all()
  end

  def change_practitioner(%Practitioner{} = practitioner) do
    Practitioner.changeset(practitioner, %{})
  end

  def change_practitioner_financial(%Practitioner{} = practitioner) do
    Practitioner.changeset_financial(practitioner, %{})
  end

  def set_practitioner_specializations(practitioner_id, specialization_ids, sub_specialization_ids) do
    old_ps_primary =
      PractitionerSpecialization
      |> where([ps], ps.practitioner_id == ^practitioner_id and ps.type == "Primary")
      |> Repo.one

    old_ps_secondary =
      PractitionerSpecialization
      |> where([ps], ps.practitioner_id == ^practitioner_id and ps.type == "Secondary")
      |> Repo.all

    # Updating Practitioner Specialization -- Primary
    new_ps_primary =
      specialization_ids
      |> List.first

    if is_nil(old_ps_primary) do
      insert_ps_primary(practitioner_id, new_ps_primary)
    else
      if new_ps_primary != old_ps_primary.specialization_id do
        old_ps_secondary_to_delete = Enum.map(old_ps_secondary, &(&1.id))

        delete_pfcf(practitioner_id, [old_ps_primary.id])
        delete_pfcf(practitioner_id, old_ps_secondary_to_delete)
        delete_ps(practitioner_id, [old_ps_primary.specialization_id])
        insert_ps_primary(practitioner_id, new_ps_primary)
      end
    end
    # End of updating Practitioner Specialization -- Primary

    # Updating Practitioner Specialization -- Secondary

    old_ps_secondary_s_ids =
      old_ps_secondary
      |> Enum.map(&(&1.specialization_id))

    if sub_specialization_ids != "" do
      secondary_to_delete = old_ps_secondary_s_ids -- sub_specialization_ids
      secondary_to_add =  sub_specialization_ids -- old_ps_secondary_s_ids

      secondary_ps_to_delete = for ps <- old_ps_secondary do
        if Enum.member?(secondary_to_delete, ps.specialization_id), do: ps.id
      end
      |> Enum.uniq
      |> List.delete(nil)

      delete_pfcf(practitioner_id, secondary_ps_to_delete)
      delete_ps(practitioner_id, secondary_to_delete)
      insert_ps_secondary(practitioner_id, secondary_to_add)
    else
      ps_id =
        old_ps_secondary
        |> Enum.map(&(&1.id))

      s_id =
        old_ps_secondary
        |> Enum.map(&(&1.specialization_id))

      delete_pfcf(practitioner_id, ps_id)
      delete_ps(practitioner_id, s_id)
    end
    # End of updating Practitioner Specialization -- Secondary
  end

  defp insert_ps_primary(practitioner_id, specialization_id) do
    params =
      %{practitioner_id: practitioner_id,
      specialization_id: specialization_id,
      type: "Primary"}
    changeset =
      PractitionerSpecialization.changeset(
        %PractitionerSpecialization{}, params)
    Repo.insert!(changeset)
  end

  defp insert_ps_secondary(practitioner_id, sub_specialization_ids) do
    for sub_specialization_id <- sub_specialization_ids do
      params =
        %{practitioner_id: practitioner_id,
          specialization_id: sub_specialization_id,
          type: "Secondary"}
      changeset =
        PractitionerSpecialization.changeset(
          %PractitionerSpecialization{}, params)
      Repo.insert!(changeset)
    end
  end

  defp delete_pfcf(practitioner_id, specialization_ids) do
    for specialization_id <- specialization_ids do
      PractitionerFacilityConsultationFee
      |> where([pfcf],
        pfcf.practitioner_specialization_id == ^specialization_id)
      |> Repo.delete_all
    end
  end

  defp delete_ps(practitioner_id, specialization_ids) do
    for specialization_id <- specialization_ids do
      PractitionerSpecialization
      |> where([ps], ps.practitioner_id == ^practitioner_id and
          ps.specialization_id == ^specialization_id)
      |> Repo.delete_all
    end
  end

  def create_contact_practitioner(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset_practitioner(attrs)
    |> Repo.insert()
  end

  def update_contact_practitioner(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset_practitioner(attrs)
    |> Repo.update()
  end

  def create_practitioner_contact(attrs \\ %{}) do
    %PractitionerContact{}
    |> PractitionerContact.changeset(attrs)
    |> Repo.insert!()
    |> Repo.preload([contact: [:phones, :emails]])
  end

  def create_no(attrs \\ %{}) do
    %Phone{}
    |> Phone.changeset(attrs)
    |> Repo.insert()
  end

  def create_practitioner_financial(id, practitioner_params) do
    practitioner_params =
      practitioner_params
      |> Map.put("payee_name", practitioner_params["payee_name"])
      |> Map.put("xp_card_no", practitioner_params["xp_card_no"])
      |> Map.put("account_no", practitioner_params["account_no"])
      |> Map.put("bank_id", practitioner_params["bank_id"])

    _practitioner =
      id
      |> get_practitioner()
      |> Practitioner.changeset_financial(practitioner_params)
      |> Repo.update()
  end

  def get_bank_by_practitioner_id(id) do
    Repo.get_by(Bank, practitioner_id: id)
  end

  def update_practitioner_bank_account(id, attrs) do
    _bank =
      id
      |> get_bank_by_practitioner_id()
      |> Bank.changeset_practitioner(attrs)
      |> Repo.update()
  end

  def delete_practitioner_bank_account(id) do
    Bank
    |> where([pc], pc.practitioner_id == ^id)
    |> Repo.delete_all()
  end

  def create_practitioner_facility(pf_params, user_id, practitioner) do
    pf_params =
      pf_params
      |> Map.put("practitioner_id", practitioner.id)
      |> Map.put("step", 2)
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    %PractitionerFacility{}
    |> PractitionerFacility.step1_changeset(pf_params)
    |> Repo.insert()
  end

  def update_practitioner_facility_step1(user_id, params, practitioner_facility, practitioner) do
    params =
      params
      |> Map.put("practitioner_id", practitioner.id)
      |> Map.put("updated_by_id", user_id)

    practitioner_facility
    |> PractitionerFacility.step1_changeset(params)
    |> Repo.update()
  end

  def update_practitioner_facility_step3(pf_params, pf, user_id, practitioner, edit) do
    if edit do
      pf_params =
        pf_params
        |> Map.put("practitioner_id", practitioner.id)
        |> Map.put("updated_by_id", user_id)
    else
      pf_params =
        pf_params
        |> Map.put("practitioner_id", practitioner.id)
        |> Map.put("step", 4)
        |> Map.put("updated_by_id", user_id)
    end

    if pf_params["fixed"] == "false" || pf_params["coordinator"] == "false" do
      pf_params =
        pf_params
        |> Map.put("fixed_fee", nil)
    end

    if not is_nil(pf_params["rooms"]) do
      insert_practitioner_facility_room(pf_params["rooms"], pf)
    end

    consultation_fees = for key <- Map.keys(pf_params) do
      if key =~ "cf", do: %{"#{key}" => pf_params[key]}
    end
    |> Enum.uniq
    |> List.delete(nil)

    update_pf_fee(consultation_fees, pf.id)

    pf
    |> PractitionerFacility.step3_changeset(pf_params)
    |> Repo.update()
  end

  def update_pf_fee(consultation_fees, pf_id) do
    ps_records =
      PractitionerSpecialization
      |> select([ps], ps.id)
      |> Repo.all

    for cf <- consultation_fees do
      key =
        cf
        |> Map.keys
        |> List.first

      ps_id = String.replace(key, "cf_", "")
      ps_fee =
        if cf[key] =~ ",", do: String.replace(cf[key], ",", ""), else: cf[key]

      if Enum.member?(ps_records, ps_id) do
        ps =
          PractitionerSpecialization
          |> where([ps], ps.id == ^ps_id)
          |> Repo.one

        pfcf_record =
          PractitionerFacilityConsultationFee
          |> where([pfcf],
                   pfcf.practitioner_facility_id == ^pf_id and
                   pfcf.practitioner_specialization_id == ^ps.id
          )
          |> Repo.one

        if is_nil(pfcf_record) do
          params = %{
            practitioner_facility_id: pf_id,
            practitioner_specialization_id: ps.id,
            fee: ps_fee
          }
          %PractitionerFacilityConsultationFee{}
          |> PractitionerFacilityConsultationFee.changeset(params)
          |> Repo.insert
        else
          pfcf_record
          |> PractitionerFacilityConsultationFee.changeset(%{fee: ps_fee})
          |> Repo.update
        end
      end
    end
  end

  def get_practitioner_facilities(practitioner_id) do
    PractitionerFacility
    |> where([pf], pf.practitioner_id == ^practitioner_id)
    |> Repo.all()
    |> Repo.preload([
      :facility,
      :practitioner_status,
      :cp_clearance,
      :practitioner_facility_practitioner_types,
      :practitioner_facility_rooms,
      practitioner_schedules: from(ps in PractitionerSchedule, select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
        room: ps.room}),
      practitioner_facility_contacts: [contact: [:phones, :emails]]
    ])
  end

  def get_practitioner_facilities_by_facility_id(id) do
    PractitionerFacility
    |> where([pf], pf.facility_id == ^id)
    |> Repo.all()
    |> Repo.preload([
      :facility,
      [practitioner: [practitioner_contact: :contact,
      practitioner_specializations: :specialization]],
      :practitioner_status,
      :cp_clearance,
      :practitioner_facility_consultation_fees,
      :practitioner_facility_practitioner_types,
      :practitioner_facility_rooms,
      practitioner_schedules: from(ps in PractitionerSchedule, select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
        room: ps.room}),
      practitioner_facility_contacts: [contact: [:phones, :emails]]
    ])
  end

  def get_practitioner_facility(id) do
    PractitionerFacility
    |> Repo.get(id)
    |> Repo.preload([
      :facility,
      :practitioner_status,
      :cp_clearance,
      :practitioner_facility_practitioner_types,
      :practitioner_facility_consultation_fees,
      [practitioner_facility_rooms: [:facility_room]],
      [practitioner_schedules: from(ps in PractitionerSchedule, select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
        room: ps.room})],
      [practitioner_facility_contacts: [contact: [:phones, :emails]]],
      [practitioner: [practitioner_contact: [contact: [:phones, :emails]],
                      practitioner_specializations: [:specialization]
      ]
      ]
    ])
  end

  def delete_practitioner_facility(id) do
    PractitionerFacility
    |> where([pf], pf.id == ^id)
    |> Repo.delete_all()
  end

  def create_practitioner_facility_type(params) do
    %PractitionerFacilityPractitionerType{}
    |> PractitionerFacilityPractitionerType.changeset(params)
    |> Repo.insert()
  end

  def delete_practitioner_facility_type(id) do
    PractitionerFacilityPractitionerType
    |> where([pft], pft.practitioner_facility_id == ^id)
    |> Repo.delete_all()
  end

  def create_practitioner_account(params) do
    %PractitionerAccount{}
    |> PractitionerAccount.changeset(params)
    |> Repo.insert()
  end

  def update_practitioner_account(params, practitioner_account) do
    practitioner_account
    |> PractitionerAccount.changeset(params)
    |> Repo.update()
  end

  def get_practitioner_accounts(practitioner_id) do
    PractitionerAccount
    |> where([pa], pa.practitioner_id == ^practitioner_id)
    |> Repo.all()
    |> Repo.preload([
      :practitioner_schedules,
      [account_group:
       [
         [account_group_contacts: [contact: [:phones]]],
         [account_group_address:
          from(aga in AccountGroupAddress, order_by: aga.type)]
       ],
      ],
      [practitioner_account_contact:
       [contact:
        [:phones, :emails]
       ]
      ]
    ])
  end

  def get_practitioner_logs do
    PractitionerLog
    |> Repo.all()
    |> Repo.preload(:practitioner)
  end

  def get_practitioner_account(id) do
    PractitionerAccount
    |> Repo.get!(id)
    |> Repo.preload([:account_group,
        [practitioner_account_contact: [contact: [:phones, :emails]]]])
  end

  def get_practitioner_account_by_practitioner_id(practitioner_id) do
    PractitionerAccount
    |> where([pa], pa.practitioner_id == ^practitioner_id)
    |> Repo.all()
    |> List.first() #filter multiple results
    |> Repo.preload([:account_group,
        [practitioner_account_contact: [contact: [:phones, :emails]]]])
  end

  def delete_practitioner_specializations(practitioner_id) do
    PractitionerSpecialization
    |> where([ps], ps.practitioner_id == ^practitioner_id)
    |> Repo.delete_all()
  end

  def update_step(id, practitioner_params) do
    id
    |> get_practitioner()
    |> Practitioner.changeset_step(practitioner_params)
    |> Repo.update
  end

  def get_practitioner_facility_type(pf_id) do
    PractitionerFacilityPractitionerType
    |> where([pft], pft.practitioner_facility_id == ^pf_id)
    |> Repo.all()
  end

  def get_all_practitioner_facility_contacts(practitioner_facility_id) do
    pfc =
      PractitionerFacilityContact
      |> where([pfc], pfc.practitioner_facility_id == ^practitioner_facility_id)
      |> limit(1)
      |> Repo.all()

    if Enum.empty?(pfc) do
      []
    else
      pfc
      |> Ecto.assoc(:contact)
      |> Repo.all
      |> Repo.preload([:phones, :emails])
    end
  end

  def create_practitioner_facility_contact(params) do
    %PractitionerFacilityContact{}
    |> PractitionerFacilityContact.changeset(params)
    |> Repo.insert()
  end

  def get_practitioner_facility_by_contact_id(id) do
    pfc = Repo.get_by PractitionerFacilityContact, contact_id: id
    Repo.get! PractitionerFacility, pfc.practitioner_facility_id
  end

  def delete_pfcontact(pf_id, c_id) do
    PractitionerFacilityContact
    |> where([pfc], pfc.practitioner_facility_id == ^pf_id
             and pfc.contact_id == ^c_id)
             |> Repo.delete_all()
  end

  def update_step_pf(practitioner_facility, params) do
    practitioner_facility
    |> PractitionerFacility.changeset(params)
    |> Repo.update()
  end

  def get_practitioner_facility_schedules(pf_id) do
    PractitionerSchedule
    |> where([ps], ps.practitioner_facility_id ==  ^pf_id)
    |> order_by([ps], asc: ps.day, asc: ps.time_from)
    |> Repo.all()
  end

  def create_practitioner_facility_schedule(params) do
    %PractitionerSchedule{}
    |> PractitionerSchedule.changeset_pf(params)
    |> Repo.insert()
  end

  def get_practitioner_facility_schedule(ps_id) do
    PractitionerSchedule
    |> where([ps], ps.id ==  ^ps_id)
    |> Repo.one()
  end

  def delete_practitioner_facility_schedule(ps_id) do
    PractitionerSchedule
    |> where([ps], ps.id == ^ps_id)
    |> Repo.delete_all()
  end

  def update_practitioner_facility_schedule(params, ps) do
    ps
    |> PractitionerSchedule.changeset_pf(params)
    |> Repo.update()
  end

  def create_practitioner_facility_room(params) do
    %PractitionerFacilityRoom{}
    |> PractitionerFacilityRoom.changeset(params)
    |> Repo.insert()
  end

  def get_practitioner_facility_rooms(pf_id, facility_id) do
    query = from fr in FacilityRoomRate,
      where: fr.facility_id == ^facility_id,
      select: (%{:id => fr.id,
        :type => fr.facility_room_type,
        :rate => (fragment("(SELECT rate
FROM practitioner_facility_rooms
WHERE facility_room_id = ?
and practitioner_facility_id = ?)",
fr.id, type(^pf_id, Ecto.UUID)))})
    Repo.all(query)
  end

  def delete_practitioner_facility_rooms(pf_id) do
    PractitionerFacilityRoom
    |> where([pfr], pfr.practitioner_facility_id ==  ^pf_id)
    |> Repo.delete_all()
  end

  def insert_practitioner_facility_room(rooms, pf) do
    with true <- !is_nil(rooms)
    do
      delete_practitioner_facility_rooms(pf.id)
      Enum.each(rooms, fn({id, value}) ->
        if value != "" do
          create_practitioner_facility_room(%{
            rate: value,
            practitioner_facility_id: pf.id,
            facility_room_id: id
          })
        end
      end)
    else
      false ->
        nil
    end
  end

  def insert_practitioner_facility_type(pft_params, pf) do
    Enum.each(pft_params, fn(type) ->
      create_practitioner_facility_type(%{
        practitioner_facility_id: pf.id,
        type: type
      })
    end)
  end

  def insert_practitioner_facility_type_api(pft_params, pf) do
    Enum.each(pft_params, fn(type) ->
      create_practitioner_facility_type(%{
        practitioner_facility_id: pf.id,
        type: type
      })
    end)
  end

  def get_practitioner_account_schedule(pa_schedule_id) do
    PractitionerSchedule
    |> Repo.get!(pa_schedule_id)
  end

  def create_practitioner_account_schedule(params) do
    %PractitionerSchedule{}
    |> PractitionerSchedule.changeset_pa(params)
    |> Repo.insert()
  end

  def delete_practitioner_account_schedule(practitioner_account_schedule_id) do
    PractitionerSchedule
    |> where([ps], ps.id == ^practitioner_account_schedule_id)
    |> Repo.delete_all()
  end

  def update_practitioner_account_schedule(pa_schedule, params) do
    pa_schedule
    |> PractitionerSchedule.changeset_pa(params)
    |> Repo.update()
  end

  def create_practitioner_account_contact(attrs \\ %{}) do
    %PractitionerAccountContact{}
    |> PractitionerAccountContact.changeset(attrs)
    |> Repo.insert()
  end

  def delete_practitioner_account_contact(contact_id) do
    PractitionerAccountContact
    |> where([pac], pac.contact_id == ^contact_id)
    |> Repo.delete_all()
    Contact
    |> where([c], c.id == ^contact_id)
    |> Repo.delete_all()
  end

  def get_practitioner_account_contact(id) do
    PractitionerAccountContact
    |> Repo.get!(id)
    |> Repo.preload([practitioner_account: :practitioner])
    |> Repo.preload([contact: [:phones, :emails]])
  end

  def get_practitioner_account_schedules(pa_id) do
    PractitionerSchedule
    |> where([ps], ps.practitioner_account_id == ^pa_id)
    |> order_by(:day)
    |> Repo.all
  end

  def delete_practitioner_account(practitioner_account_id) do
    PractitionerAccount
    |> where([pa], pa.id == ^practitioner_account_id)
    |> Repo.delete_all()
  end

  def expired_practitioner(practitioner_id) do
    practitioners =
      Practitioner
      |> where([p], p.id == ^practitioner_id and p.status == ^"Affiliated")
      |> Repo.all
    for practitioner <- practitioners do
      expiry_date = if not is_nil(practitioner.effectivity_to) do
        practitioner.effectivity_to
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc())
      end
      if expiry_date == :eq || expiry_date == :lt do
        Practitioner
        |> where([p], p.id == ^practitioner.id)
        |> Repo.update_all([set: [status: "Disaffiliated", affiliated: "No"]])
      end
    end
  end

  def practitioner_csv_downloads(params) do
    param_code = params["practitioner_code"]
    query = for code <- param_code do
      practitioner =
        Practitioner
        |> Repo.get_by!(code: code)
        |> Repo.preload([
          :logs,
          :bank,
          practitioner_accounts: :account_group,
          practitioner_specializations: :specialization,
          practitioner_facilities: :facility,
          practitioner_contact: [contact: [:phones, :emails]]
        ])
      specialization =
        for practitioner_specialization <-
          Enum.reject(practitioner.practitioner_specializations,
            &(&1.type == "Secondary")) do
          "#{practitioner_specialization.specialization.name}"
        end
      sub_specialization =
        for practitioner_specialization <-
          Enum.reject(practitioner.practitioner_specializations,
              &(&1.type == "Primary")) do
          "#{practitioner_specialization.specialization.name}"
        end
      facility_name =
        for practitioner_facility <- practitioner.practitioner_facilities do
          "#{practitioner_facility.facility.name}"
        end
      facility_code =
        for practitioner_facility <- practitioner.practitioner_facilities do
          "#{practitioner_facility.facility.code}"
        end
      [practitioner.code,
        "#{practitioner.first_name} #{practitioner.middle_name} #{practitioner.last_name}",
        practitioner.status,
        Enum.join(specialization, ", "),
        Enum.join(sub_specialization, ", "),
        Enum.join(facility_code, ", "),
        Enum.join(facility_name, ", ")]
    end
    query
  end

  def list_all_accounts_in_practitioner do
    AccountGroup
    |> join(:inner, [ag], a in Account, ag.id == a.account_group_id)
    |> where([ag, a], a.status != "Draft")
    |> distinct(true)
    |> Repo.all
    |> Enum.map(&{&1.name, &1.id})
  end
  ######################## START -- Functions related to Logs.

  def create_practitioner_log(user, changeset, tab) do
    changes =
      changeset.changes
      |> Map.drop([:specialization_ids,
        :sub_specialization_ids, :udpated_by_id])
    if Enum.empty?(changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."
      insert_log(%{
        practitioner_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_affiliation_log(user, changeset, practitioner_id, tab, affiliation) do
   if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{affiliation}[#{tab}] tab."
      insert_log(%{
        practitioner_id: practitioner_id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_added_facility_affiliation_log(user, facility, practitioner_id) do
    facility_code = facility.code
    facility_name =
      FacilityContext.get_facility!(facility.id).name
      message = "#{user.username} added #{facility_code} #{facility_name} to affiliations."
      insert_log(%{
        practitioner_id: practitioner_id,
        user_id: user.id,
        message: message
      })
  end

  def create_added_account_affiliation_log(user, account, practitioner_id) do
    account_code = account.code
    account_name = account.name
      message = "#{user.username} added #{account_code} #{account_name} to affiliations."
      insert_log(%{
        practitioner_id: practitioner_id,
        user_id: user.id,
        message: message
      })
  end

  def create_affiliation_schedule_log(%{
    user: user,
    action: action,
    params: params,
    practitioner_id: practitioner_id,
    tab: tab,
    affiliation: affiliation})
  do
      message = "#{user.username} #{action} Schedule with day '#{params.day}', room name '#{params.room}', time from '#{params.time_from}' to '#{params.time_to}' in #{affiliation}[#{tab}] tab."
      insert_log(%{
        practitioner_id: practitioner_id,
        user_id: user.id,
        message: message
      })
  end

  defp changes_to_string(changeset) do
    changes =
      changeset.changes
      |> Map.drop([
        :specialization_ids,
        :sub_specialization_ids,
        :updated_by_id])
    changes = for {key, new_value} <- changes, into: [] do
      if key == :exclusive do
        old_value = changeset.data |> Map.get(key) |> Enum.join(", ")
        new_value = Enum.join(new_value, ", ")
        "#{transform_atom(key)} from #{old_value} to #{new_value}"
      else
        if transform_atom(key) == "Facility Id" do
          facility_new =
            FacilityContext.get_facility!(changeset.changes.facility_id).name
          "Facility from '#{changeset.data.facility.name}' to '#{facility_new}'"
        else
          if transform_atom(key) == "Account Group Id" do
            account_new =
              AccountContext.get_account_group(
                changeset.changes.account_group_id).name
            "Account from '#{changeset.data.account_group.name}' to '#{account_new}'"
          else
            if transform_atom(key) == "Pstatus Id" do
              status_new =
                DropdownContext.get_dropdown(changeset.changes.pstatus_id).text
              "Status from '#{changeset.data.practitioner_status.text}' to '#{status_new}'"
            else
              if transform_atom(key) == "Cp Clearance Id" do
                clearance_new =
                  DropdownContext.get_dropdown(
                    changeset.changes.cp_clearance_id).text
                "Clearance from '#{changeset.data.cp_clearance.text}' to '#{clearance_new}'"
              else
                "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
              end
            end
          end
      end
      end
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = PractitionerLog.changeset(%PractitionerLog{}, params)
    Repo.insert!(changeset)
  end

  def create_practitioner_contact_log(practitioner_id, old_contacts, current_user) do
    {old_phones, old_emails} = old_contacts
    practitioner = get_practitioner(practitioner_id)
    new_phones =
      for phone <-
        practitioner.practitioner_contact.contact.phones do
      {phone.number, phone.type}
    end
    new_emails =
      for email <-
        practitioner.practitioner_contact.contact.emails do
      email.address
    end
    Enum.each new_phones -- old_phones, fn(new_phone) ->
      {number, type} = new_phone
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} added new #{type} number #{number}"
      })
    end
    Enum.each old_phones -- new_phones, fn(removed_phone) ->
      {number, type} = removed_phone
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} removed #{type} number #{number}"
      })
    end
    Enum.each new_emails -- old_emails, fn(new_email) ->
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} added new email #{new_email}"
      })
    end
    Enum.each old_emails -- new_emails, fn(old_email) ->
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} removed email #{old_email}"
      })
    end
  end

  def create_affiliation_type_log(practitioner_facility_id, old_types, current_user, affiliation, tab) do

    {old_types} = old_types
    practitioner_facility = get_practitioner_facility(practitioner_facility_id)
    new_types =
      for type <-
        practitioner_facility.practitioner_facility_practitioner_types
      do
      {type.type}
    end
    Enum.each new_types -- old_types, fn(new_type) ->
      {type} = new_type
      insert_log(%{
        practitioner_id: practitioner_facility.practitioner_id,
        user_id: current_user.id,
        message: "#{current_user.username} added new Practitioner Type '#{type}'' in #{affiliation}[#{tab}] tab"
      })
    end
    Enum.each old_types -- new_types, fn(removed_type) ->
      {type} = removed_type
      insert_log(%{
        practitioner_id: practitioner_facility.practitioner_id,
        user_id: current_user.id,
        message: "#{current_user.username} removed Practitioner Type '#{type}'' in #{affiliation}[#{tab}] tab"
      })
    end
  end

  def create_affiliation_contact_log(%{
    practitioner_id: practitioner_id,
    contact_id: contact_id,
    old_contacts: old_contacts,
    current_user: current_user,
    affiliation: affiliation,
    tab: tab})
  do
    {old_phones, old_emails} = old_contacts
    practitioner = get_practitioner(practitioner_id)
    contact = ContactContext.get_contact!(contact_id)
    new_phones = for phone <- contact.phones do
      {phone.number, phone.type}
    end
    new_emails = for email <- contact.emails do
      email.address
    end

    Enum.each old_phones -- new_phones, fn(removed_phone) ->
      {number, type} = removed_phone
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} removed #{type} number '#{number}' in #{affiliation}[#{tab}] tab"
      })
    end
    Enum.each new_phones -- old_phones, fn(new_phone) ->
      {number, type} = new_phone
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} added new #{type} number '#{number}' in #{affiliation}[#{tab}] tab"
      })
    end
    Enum.each old_emails -- new_emails, fn(old_email) ->
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} removed email '#{old_email}' in #{affiliation}[#{tab}] tab"
      })
    end
    Enum.each new_emails -- old_emails, fn(new_email) ->
      insert_log(%{
        practitioner_id: practitioner.id,
        user_id: current_user.id,
        message: "#{current_user.username} added new email '#{new_email}' in #{affiliation}[#{tab}] tab"
      })
    end
  end

  ######################### END -- Functions related to Logs.

  # Authorization
  def get_all_practitioners_by_facility_id(f_id) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners =
      Repo.all(practitioners)

    ps = for p <- practitioners do
      for ps <- p.practitioner_specializations do
        {"#{p.code} | #{p.first_name} #{p.middle_name} #{p.last_name} | #{ps.specialization.name}", ps.id}
      end
    end
    List.flatten(ps)
  end

  def get_all_practitioners_by_facility_id_emergency(f_id) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners =
      Repo.all(practitioners)

    ps = for p <- practitioners do
      # for ps <- p.practitioner_specializations do
        {"#{p.code} | #{p.first_name} #{p.middle_name} #{p.last_name}", p.id}
      # end
    end
    List.flatten(ps)
  end

  def filter_practitioner_specialization(f_id, filter) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners =
      Repo.all(practitioners)

    ps = for p <- practitioners do
      for ps <- p.practitioner_specializations do
        if filter == ps.specialization.name do
          %{
            display: "#{p.code} | #{p.first_name} #{p.middle_name} #{p.last_name} | #{ps.specialization.name}",
            value: ps.id
          }
        end
      end
    end
    |> List.flatten
    |> Enum.uniq
    |> List.delete(nil)
  end

  def filter_practitioner_specialization_emergency(f_id) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners =
      Repo.all(practitioners)

    ps = for p <- practitioners do
      for ps <- p.practitioner_specializations do
        {"#{ps.specialization.name}", ps.specialization.id}
      end
    end
    |> List.flatten
    |> Enum.uniq
    |> List.delete(nil)
  end

  def filter_all_practitioner_specialization(f_id) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners =
      Repo.all(practitioners)

    ps = for p <- practitioners do
      for ps <- p.practitioner_specializations do
          %{
            display: "#{p.code} | #{p.first_name} #{p.middle_name} #{p.last_name} | #{ps.specialization.name}",
            value: ps.id
          }
      end
    end
    |> List.flatten
    |> Enum.uniq
    |> List.delete(nil)
  end

  def get_all_practitioners_by_facility_id_inpatient(f_id) do
    date_now = Ecto.DateTime.utc

    practitioners = (
      from p in Practitioner,
      join: pf in PractitionerFacility, on: pf.practitioner_id == p.id,
      where: pf.facility_id == ^f_id
      and p.effectivity_from <= ^date_now
      and p.effectivity_to >= ^date_now,
      preload: [
        practitioner_specializations: :specialization
      ]
    )

    practitioners
    |> Repo.all()
  end

  def get_consultation_fee(p_id, f_id) do
    _consultation_fee =
      PractitionerFacility
      |> where([pf], pf.practitioner_id == ^p_id and pf.facility_id == ^f_id)
      |> select([pf], pf.consultation_fee)
      |> Repo.all()
      |> List.first()
  end

  def get_specialization_consultation_fee(f_id , ps_id) do
    if is_nil(f_id) or is_nil(ps_id) do
      nil
    else
      practitioner_specialization = get_practitioner_id_by_speciliazation(ps_id)
      p_id = practitioner_specialization.practitioner.id
      practitioner_facility = get_pf_affiliation(p_id, f_id)

      if is_nil(practitioner_facility) do
        practitioner_facility
      else
        _consultation_fee =
        PractitionerFacilityConsultationFee
        |> where([pfcf],
            pfcf.practitioner_facility_id == ^practitioner_facility.id and
            pfcf.practitioner_specialization_id == ^ps_id)
        |> select([pfcf], pfcf.fee)
        |> Repo.all()
        |> List.first()
      end
    end

  end

  def get_pf_affiliation(p_id, f_id) do
    _consultation_fee =
      PractitionerFacility
      |> where([pf], pf.practitioner_id == ^p_id and pf.facility_id == ^f_id)
      |> select([pf], pf)
      |> Repo.all()
      |> Repo.preload(:practitioner_facility_consultation_fees)
      |> List.first()
  end

  def get_practitioner_id_by_speciliazation(ps_id) do
    PractitionerSpecialization
    |> where([ps], ps.id == ^ps_id)
    |> Repo.all()
    |> Repo.preload([:practitioner])
    |> List.first()
  end
  # End Authorization

  # Start of MemberLink
  def search_practitioner_api(params, member_id) do
    if not is_nil(params["availability"]) do
      schedule_param = params["availability"]
                       |> Timex.weekday()
                       |> Timex.day_name()
    else
      schedule_param = ""
    end

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

    facilities_id = ApiFacilityContext.get_all_facility_id -- exception
    facilities_id =
      facilities_id ++ inclusion
      |> Enum.uniq()

    practitioner_facility = query_search_practitioner_api(params, schedule_param, facilities_id)
  end

  defp query_search_practitioner_api(params, schedule_param, facilities_id) do
    PractitionerFacility
        |> join(:inner, [pf],
            p in Practitioner, p.id == pf.practitioner_id)
        |> join(:inner, [pf, p],
            f in Facility, f.id == pf.facility_id)
        |> join(:inner, [pf, p, f],
                d in Dropdown, f.ftype_id == d.id)
        |> join(:inner, [pf, p, f, d],
            pfs in PractitionerSchedule, pfs.practitioner_facility_id == pf.id)
        |> join(:inner, [pf, p, f, d, pfs],
            ps in PractitionerSpecialization, p.id == ps.practitioner_id)
        |> join(:inner, [pf, p, f, d, pfs, ps],
            s in Specialization, ps.specialization_id == s.id)
        |> where([pf, p, f, d, pfs, ps, s], pf.facility_id in ^facilities_id and
                (ilike(fragment("lower(?)",
                  fragment("concat(?, ' ', ?)", p.first_name, p.last_name)),
                    ^"%#{params["name"]}%") or
                ilike(fragment("lower(?)",
                  fragment("concat(?, ', ', ?)", p.last_name, p.first_name)),
                    ^"%#{params["name"]}%")) and
                ilike(fragment("lower(?)", f.name),
                  ^"%#{params["hospital"]}%") and
                ilike(fragment("lower(?)", pfs.day),
                  ^"%#{schedule_param}%") and
                (ilike((fragment("lower(?)", s.name)),
                  ^"#{params["specialization"]}%")) and
                ilike(fragment("lower(?)", p.gender), ^"#{params["gender"]}%"))
        |> where([pf, p, f, d], f.step > 6 and f.status == "Affiliated")
        |> where([pf, p, f, d], d.text == "HOSPITAL-BASED" or d.text == "CLINIC-BASED")
        |> where([pf, p, f], f.step > 6 and p.status == "Affiliated")
        |> select([pf, p, f, d, pfs, ps, s], ps)
        |> order_by([pf, p, f, d, pfs, ps, s], asc: p.last_name)
        |> Repo.all()
        |> Enum.uniq()
        |> Repo.preload([
          :specialization,
          practitioner: [
            practitioner_facilities: [:practitioner_schedules,
                                      :practitioner_status,
                                      :practitioner,
                                      [facility: :type]],
            practitioner_contact: [contact: :phones]
          ]
        ])
  end

  def search_all_practitioners_api(member_id) do
    _member = MemberContext.get_a_member!(member_id)
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

    facilities_id = ApiFacilityContext.get_all_facility_id -- exception
    facilities_id =
      facilities_id ++ inclusion
      |> Enum.uniq()
  _practitioners =
    PractitionerFacility
    |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
    |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
    |> join(:inner, [pf, p, f],
            d in Dropdown, f.ftype_id == d.id)
    |> join(:inner, [pf, p, f, d],
                    pfs in PractitionerSchedule, pfs.practitioner_facility_id == pf.id)
    |> join(:inner, [pf, p, f, d, pfs],
                    ps in PractitionerSpecialization, p.id == ps.practitioner_id)
    |> join(:inner, [pf, p, f, d, pfs, ps],
                    s in Specialization, ps.specialization_id == s.id)
    |> where([pf, p, f], pf.facility_id in ^facilities_id)
    |> where([pf, p, f, d], f.step > 6 and f.status == "Affiliated"
             and (d.text == "HOSPITAL-BASED"
              or d.text == "CLINIC-BASED"))
    |> select([pf, p, f, d, pfs, ps, s], ps)
    |> order_by([pf, p, f, d, pfs, ps, s], asc: p.last_name)
    |> Repo.all()
    |> Enum.uniq()
    |> Repo.preload([
      :specialization,
      practitioner: [
        practitioner_facilities: [:practitioner_schedules, :practitioner_status, :practitioner, [facility: :type]],
        practitioner_contact: [contact: :phones]
      ]
    ])
  end

  def search_all_practitioners_for_acu(member_id, params) do
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
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()
      facilities_id = if inclusion == [] do
        ApiFacilityContext.get_all_facility_id -- exception
      else
          inclusion
      end

    _practitioners =
      PractitionerFacility
      |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
      |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
      |> where([pf, p, f], pf.facility_id in ^facilities_id)
      |> where([pf, p, f], f.step > 6 and f.status == "Affiliated")
      |> order_by([pf, p, f], asc: p.last_name)
      |> limit(10)
      |> offset(^params["offset"])
      |> Repo.all()
      |> Enum.uniq()
      |> Repo.preload([
        :facility,
        :practitioner_schedules,
        :practitioner_status,
        [practitioner:
          [practitioner_specializations:
            :specialization, practitioner_accounts:
              [:account_group, :practitioner_schedules],
                practitioner_contact: [contact: :phones]
          ]]
      ])
    else
      []
    end
  end

  def search_all_practitioners(member_id, params) do
    if params["loa_type"] == "acu" do
      search_all_practitioners_for_acu(member_id, params)
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

      facilities_id = ApiFacilityContext.get_all_facility_id -- exception
      facilities_id =
        facilities_id ++ inclusion
        |> Enum.uniq()

    _practitioners =
      PractitionerFacility
      |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
      |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
      |> join(:inner, [pf, p, f],
                d in Dropdown, f.ftype_id == d.id)
      |> where([pf, p, f, d], pf.facility_id in ^facilities_id)
      |> where([pf, p, f, d], f.step > 6 and f.status == "Affiliated"
                 and (d.text == "HOSPITAL-BASED"
                  or d.text == "CLINIC-BASED"))
      |> order_by([pf, p, f, d], asc: p.last_name)
      |> limit(10)
      |> offset(^params["offset"])
      |> Repo.all()
      |> Enum.uniq()
      |> Repo.preload([
        :facility,
        :practitioner_schedules,
        :practitioner_status,
        [practitioner:
          [practitioner_specializations:
            :specialization, practitioner_accounts:
              [:account_group, :practitioner_schedules],
                practitioner_contact: [contact: :phones]
          ]]
      ])
    end
  end

  def search_box_practitioner_for_acu(params, member_id) do
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

      if inclusion == [] do
        facilities_id = ApiFacilityContext.get_all_facility_id -- exception
      else
        inclusion
      end
    else
      []
    end
  end

  def search_box_practitioner(params, member_id) do
    search_params = params["search_param"]
    facilities_id = if search_params["loa_type"] == "acu" do
      search_box_practitioner_for_acu(params, member_id)
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

      facilities_id = ApiFacilityContext.get_all_facility_id -- exception
      facilities_id =
        facilities_id ++ inclusion
        |> Enum.uniq()
    end
    filter_for_search_box_practitioner(facilities_id, search_params, params)
  end

  def filter_for_search_box_practitioner(facilities_id, search_params, params) do
    practitioners =
      PractitionerFacility
        |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
        |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
        |> join(:inner, [pf, p, f],
                d in Dropdown, f.ftype_id == d.id)
        |> join(:inner, [pf, p, f, d],
            ps in PractitionerSpecialization, p.id == ps.practitioner_id)
        |> join(:inner, [pf, p, f, d, ps],
            s in Specialization, ps.specialization_id == s.id)
        |> where([pf, p, f, d, ps, s], pf.facility_id in ^facilities_id and
          (ilike(fragment("lower(?)",
            fragment("concat(?, ' ', ?)", p.first_name, p.last_name)),
              ^"%#{search_params["name"]}%") or ilike(fragment("lower(?)",
            fragment("concat(?, ', ', ?)", p.last_name, p.first_name)),
              ^"%#{search_params["name"]}%")) and ilike(fragment("lower(?)",
            fragment("concat(?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?, ' ', ?)",
              f.line_1, f.line_2, f.city, f.postal_code, f.province, f.region, f.country)),
                ^"%#{search_params["address"]}%") and
            (ilike((fragment("lower(?)", s.name)),
              ^"#{search_params["specialization"]}%"))
        )
        |> where([pf, p, f, d, ps, s], f.step > 6 and f.status == "Affiliated"
                 and (d.text == "HOSPITAL-BASED"
                  or d.text == "CLINIC-BASED"))
        |> where([pf, p, f], f.step > 6 and p.status == "Affiliated")
        |> select([pf, p, f, d, ps], ps)
        |> order_by([pf, p, f, d, ps, s], asc: p.last_name)
        |> limit(10)
        |> offset(^params["offset"])
        |> Repo.all()
        |> Enum.uniq()
        |> Repo.preload([
          :specialization,
          practitioner: [
            practitioner_facilities: [:practitioner_schedules, :practitioner_status, :practitioner, [facility: :type]],
            practitioner_contact: [contact: :phones]
          ]
        ])
  end

  def load_all_doctors_for_intellisense_for_acu(member_id, params) do
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
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "inclusion" and pc.coverage_id == ^coverage.id)
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
        |> where([f, pcf, pc, p, ac, mp, m], m.id == ^member_id and pc.type == "exception" and pc.coverage_id == ^coverage.id)
        |> select([f], f.id)
        |> Repo.all
        |> Enum.uniq()

      facilities_id = if inclusion == [] do
        ApiFacilityContext.get_all_facility_id -- exception
      else
        inclusion
      end

      _practitioners =
        PractitionerFacility
        |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
        |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
        |> join(:inner, [pf, p, f],
                d in Dropdown, f.ftype_id == d.id)
        |> where([pf, p, f, d], pf.facility_id in ^facilities_id)
        |> where([pf, p, f, d], f.step > 6 and f.status == "Affiliated"
                 and (d.text == "HOSPITAL-BASED"
                  or d.text == "CLINIC-BASED"))
        |> order_by([pf, p, f], asc: p.last_name)
        |> Repo.all()
        |> Enum.uniq()
        |> Repo.preload([:practitioner, :facility])
    else
      []
    end
  end

  def load_all_doctors_for_intellisense(member_id, params) do
    if params["loa_type"] == "acu" do
      load_all_doctors_for_intellisense_for_acu(member_id, params)
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

      facilities_id = ApiFacilityContext.get_all_facility_id -- exception
      facilities_id =
        facilities_id ++ inclusion
        |> Enum.uniq()

      _practitioners =
        PractitionerFacility
        |> join(:inner, [pf], p in Practitioner, p.id == pf.practitioner_id)
        |> join(:inner, [pf, p], f in Facility, f.id == pf.facility_id)
        |> join(:inner, [pf, p, f],
                d in Dropdown, f.ftype_id == d.id)
        |> where([pf, p, f, d], pf.facility_id in ^facilities_id)
        |> where([pf, p, f, d], f.step > 6 and f.status == "Affiliated"
                 and (d.text == "HOSPITAL-BASED"
                  or d.text == "CLINIC-BASED"))
        |> order_by([pf, p, f], asc: p.last_name)
        |> Repo.all()
        |> Enum.uniq()
        |> Repo.preload([:practitioner, :facility])
    end
  end

  def get_translated_practitioners(conn, practitioners) do
    _practitioners =
      practitioners
      |> Enum.into([], fn(prac_fac) ->
          name =
            TranslationContext.get_translated_values(
              conn, prac_fac.facility.name)
          if is_nil(name) do
            facility = Map.put(prac_fac.facility, :name, prac_fac.facility.name)
            prac_fac =
              prac_fac
              |> Map.delete(:facility)
              |> Map.put(:facility, facility)
          else
          facility = Map.put(prac_fac.facility, :name, name)
          prac_fac =
            prac_fac
            |> Map.delete(:facility)
            |> Map.put(:facility, facility)
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
            practitioner =
              Map.put(prac_fac.practitioner, :first_name, first_name)
            prac_fac =
              prac_fac
              |> Map.delete(:practitioner)
              |> Map.put(:practitioner, practitioner)
          end

          last_name =
            TranslationContext.get_translated_values(
              conn, prac_fac.practitioner.last_name)
          if is_nil(last_name) do
            practitioner =
              Map.put(prac_fac.practitioner,
                :last_name, prac_fac.practitioner.last_name)
            _prac_fac =
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

        end)
  end

  #End of MemberLink

  #FOR SEEDS
  def create_practitioner_seed(practitioner_params) do
    %Practitioner{}
    |> Practitioner.changeset_practitioner_seed(practitioner_params)
    |> Repo.insert()
  end

  def update_practitioner_seed(practitioner, practitioner_params) do
    practitioner
    |> Practitioner.changeset_practitioner_seed(practitioner_params)
    |> Repo.update()
  end

  def insert_or_update_practitioner(params) do
    practitioner = get_practitioner_by_prc(params.prc_no)
    if not is_nil(practitioner) do
      practitioner
      |> update_practitioner_seed(params)
    else
      create_practitioner_seed(params)
    end
  end

  def insert_or_update_practitioner_specialization(params) do
    practitioner_specialization =
    get_ps_by_id(params.practitioner_id, params.specialization_id)
    if not is_nil(practitioner_specialization) do
      update_practitioner_specialization(practitioner_specialization.id, params)
    else
      create_practitioner_specialization(params)
    end
  end

  def create_practitioner_specialization(params) do
   %PractitionerSpecialization{}
   |> PractitionerSpecialization.changeset(params)
   |> Repo.insert()
  end

  def update_practitioner_specialization(id, params) do
    id
    |> get_practitioner_specializations()
    |> PractitionerSpecialization.changeset(params)
    |> Repo.update()
  end

  def get_ps_by_id(practitioner_id, specialization_id) do
    PractitionerSpecialization
    |> Repo.get_by(practitioner_id: practitioner_id,
      specialization_id: specialization_id)
  end

  def get_practitioner_specializations(id) do
    PractitionerSpecialization
    |> Repo.get(id)
  end

  def insert_or_update_practitioner_facility(params) do
    practitioner_facility =
      get_pf_by_id(params.practitioner_id, params.facility_id)
    if not is_nil(practitioner_facility) do
      update_practitioner_facility_seed(practitioner_facility.id, params)
    else
      create_practitioner_facility_seed(params)
    end
  end

  def create_practitioner_facility_seed(params) do
   %PractitionerFacility{}
   |> PractitionerFacility.changeset_pf_seed(params)
   |> Repo.insert()
  end

  def update_practitioner_facility_seed(id, params) do
    id
    |> get_practitioner_facility_seed()
    |> PractitionerFacility.changeset_pf_seed(params)
    |> Repo.update()
  end

  def get_pf_by_id(practitioner_id, facility_id) do
    PractitionerFacility
    |> Repo.get_by(practitioner_id: practitioner_id, facility_id: facility_id)
  end

  def get_practitioner_facility_seed(id) do
    PractitionerFacility
    |> Repo.get!(id)
  end

  def insert_or_update_pf_schedule(params) do
    pf_schedule = get_pfs_by_id(params.practitioner_facility_id)
    if not is_nil(pf_schedule) do
      update_pf_schedule_seed(pf_schedule.id, params)
    else
      create_pf_schedule_seed(params)
    end
  end

  def create_pf_schedule_seed(params) do
   %PractitionerSchedule{}
   |> PractitionerSchedule.changeset_pf(params)
   |> Repo.insert()
  end

  def update_pf_schedule_seed(id, params) do
    id
    |> get_pf_schedule_seed()
   |> PractitionerSchedule.changeset_pf(params)
   |> Repo.update()
  end

  def get_pfs_by_id(practitioner_facility_id) do
    PractitionerSchedule
    |> Repo.get_by(practitioner_facility_id: practitioner_facility_id,
      day: "Monday", room: "1")
  end

  def get_pf_schedule_seed(id) do
    PractitionerSchedule
    |> Repo.get!(id)
  end
  #END SEEDS

  def load_specializations(id) do
    Specialization
    |> where([s], s.id != ^id)
    |> Repo.all
  end

  def get_practitioner_facility_by_practitioner_and_facility(practitioner_id, facility_id) do
    PractitionerFacility
    |> where([pf], pf.practitioner_id == ^practitioner_id and pf.facility_id == ^facility_id)
    |> Repo.one()
    |> Repo.preload([
      :facility,
      :practitioner_status,
      :cp_clearance,
      :practitioner_facility_practitioner_types,
      :practitioner_facility_rooms,
      practitioner_schedules: from(ps in PractitionerSchedule, select: %{
        time_from: fragment("CAST(? AS TEXT)", ps.time_from),
        time_to: fragment("CAST(? AS TEXT)", ps.time_to),
        day: ps.day,
        room: ps.room}),
      practitioner_facility_contacts: [contact: [:phones, :emails]]
    ])
  end

  def get_specialization(id) do
    Specialization
    |> Repo.get!(id)
    |> Repo.preload([practitioner_specializations: [:practitioner, :specialization]])
  end

end

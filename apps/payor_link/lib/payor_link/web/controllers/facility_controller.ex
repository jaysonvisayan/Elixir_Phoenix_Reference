defmodule Innerpeace.PayorLink.Web.FacilityController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.PayorLink.Web.FacilityView
  alias Phoenix.View
  alias Innerpeace.Db.Schemas.{
    Facility,
    FacilityRoomRate,
    FacilityPayorProcedure,
    FacilityRUV
  }

  alias Innerpeace.Db.Base.{
    Api.UtilityContext,
    FacilityContext,
    PhoneContext,
    EmailContext,
    DropdownContext,
    RoomContext,
    FacilityRoomRateContext,
    ContactContext,
    ProcedureContext,
    PractitionerContext,
    RUVContext,
    CoverageContext,
    LocationGroupContext,
    UserContext
  }

  alias Innerpeace.Db.Datatables.FacilityDatatable

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{facilities: [:manage_facilities]},
       %{facilities: [:access_facilities]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{facilities: [:manage_facilities]},
     ]] when not action in [
       :index,
       :show,
       :new,
       :setup,
       :update_setup,
       :create,
       :goto_step,
       :create_step1,
       :step1,
       :update_step1,
       :step2,
       :update_step2,
       :step2_changeset_error_return,
       :step3,
       :create_contact,
       :update_contact,
       :insert_number,
       :next_contact,
       :get_contact,
       :delete_facility_contact,
       :step4,
       :update_step4,
       :step5,
       :update_step5,
       :step6,
       :submit_summary
     ]

  plug :valid_uuid?, %{origin: "facilities"}
  when not action in [:index]

  # Index functions start
  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["facilities"]
    user_role =
      UserContext.get_user_role_admin(conn.assigns.current_user.id)
    is_admin =
      if Enum.empty?(user_role) == false do
        true
      else
        false
      end
    # facilities = FacilityContext.get_all_facili()
    facilities = []
    render(conn, "index.html", facilities: facilities, is_admin: is_admin, permission: pem)
  end
  # Index functions end

  # Global functions start
 def setup(conn, %{"id" => id, "step" => step}) do
    facility = FacilityContext.get_facility!(id)
    if facility.step < String.to_integer(step) || facility.step == 7 do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: facility_path(conn, :index))
    else
      goto_step(step, conn, facility)
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Page not found!")
    |> redirect(to: facility_path(conn, :index))
  end

  defp goto_step(step, conn, facility) do
    case step do
      "1" ->
        step1(conn, facility)
      "2" ->
        step2(conn, facility)
      "3" ->
        step3(conn, facility)
      "4" ->
        step4(conn, facility)
      "5" ->
        step5(conn, facility)
      "6" ->
        step6(conn, facility)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: facility_path(conn, :index))
    end
  end

  def update_setup(conn, %{"id" => id, "step" => step, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    case step do
      "1" ->
        update_step1(conn, facility, facility_params)
      "2" ->
        update_step2(conn, facility, facility_params)
      "4" ->
        update_step4(conn, facility, facility_params)
      "5" ->
        update_step5(conn, facility, facility_params)
    end
  end

  def edit_setup(conn, params) do
    if Map.has_key?(params, "tab") do
      facility = FacilityContext.get_facility!(params["id"])

      case params["tab"] do
        "general" ->
            edit_general(conn, facility)
        "address" ->
            edit_address(conn, facility)
        "contact_details" ->
          edit_contact_details(conn, facility)
        "financial" ->
            edit_financial(conn, facility)
      end
    else
      conn
      |> put_flash(:error, "Page not found!")
      |> redirect(to: "/facilities/#{params["id"]}?active=profile")
    end
  end

  def update_edit_setup(conn, %{"id" => id, "tab" => tab, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    case tab do
      "general" ->
        update_edit_general(conn, facility, facility_params)
      "address" ->
        update_edit_address(conn, facility, facility_params)
      "contact_details" ->
        update_edit_contact_details(conn, facility, facility_params)
      "financial" ->
        update_edit_financial(conn, facility, facility_params)
    end
  end
  #Global functions end

  # Step 1 - General
  def new(conn, _params) do
    changeset = Facility.step1_changeset(%Facility{})
    facility_types = DropdownContext.get_all_facility_type()
    facility_categories = DropdownContext.get_all_facility_category()
    facility_codes = FacilityContext.get_all_facility_code()
    render conn, "step1.html",
      changeset: changeset,
      facility_types: facility_types,
      facility_categories: facility_categories,
      facility_codes: Poison.encode!(facility_codes)
  end

  def create_step1(conn, %{"facility" => facility_params}) do
    user = conn.assigns.current_user
    if facility_params["cutoff_time"] != "" do
      cutoff_time = String.split(facility_params["cutoff_time"], ":")
      cutoff_time = Ecto.Time.cast!(%{
        hour: Enum.at(cutoff_time, 0),
        minute: Enum.at(cutoff_time, 1),
        second: 00
      })

      facility_params = Map.put(facility_params, "cutoff_time", cutoff_time)
    end

    facility_params =
      facility_params
      |> translate_date_params()
      |> Map.put("step", 2)
      |> Map.put("updated_by_id", user.id)
      |> Map.put("created_by_id", user.id)

    with {:ok, facility} <-
      FacilityContext.create_facility(
        conn.assigns.current_user.id, facility_params),
         {:ok, facility} <-
           FacilityContext.update_step1_facility(
             conn.assigns.current_user.id, facility, facility_params)
    do
      conn
      |> put_flash(:info, "Facility general details has been successfully created.")
      |> redirect(to: "/facilities/#{facility.id}/setup?step=2")
    else
      {:error, changeset} ->
        facility_types = DropdownContext.get_all_facility_type()
        facility_categories = DropdownContext.get_all_facility_category()
        facility_codes = FacilityContext.get_all_facility_code()
        conn
        |> put_flash(:error, "Error creating facility! Please check the errors below.")
        |> render("step1.html",
                  changeset: changeset,
                  facility_types: facility_types,
                  facility_categories: facility_categories,
                  facility_codes: Poison.encode!(facility_codes))
    end
  end


  defp step1(conn, facility) do
    changeset = Facility.step1_changeset(facility, %{})
    facility_types = DropdownContext.get_all_facility_type()
    facility_categories = DropdownContext.get_all_facility_category()
    facility_codes = FacilityContext.get_all_facility_code()
    render conn, "step1_update.html",
      changeset: changeset,
      facility: facility,
      facility_types: facility_types,
      facility_categories: facility_categories,
      facility_codes: Poison.encode!(facility_codes)
  end

  defp update_step1(conn, facility, facility_params) do
    if facility_params["cutoff_time"] != "" do
      cutoff_time = String.split(facility_params["cutoff_time"], ":")
      cutoff_time = Ecto.Time.cast!(%{
        hour: Enum.at(cutoff_time, 0),
        minute: Enum.at(cutoff_time, 1),
        second: 00
      })

      facility_params = Map.put(facility_params, "cutoff_time", cutoff_time)
    end
    facility_params = translate_date_params(facility_params)
    with {:ok, facility} <-
      FacilityContext.update_step1_facility(
        conn.assigns.current_user.id, facility, facility_params)
    do
      conn
      |> put_flash(:info, "Facility general details has been successfully updated.")
      |> redirect(to: "/facilities/#{facility.id}/setup?step=2")
    else
      {:error, changeset} ->
        facility_types = DropdownContext.get_all_facility_type()
        facility_categories = DropdownContext.get_all_facility_category()
        facility_codes = FacilityContext.get_all_facility_code()

        conn
        |> put_flash(:error, "Error creating facility! Please check the errors below.")
        |> render("step1_update.html",
                  changeset: changeset,
                  facility: facility,
                  facility_types: facility_types,
                  facility_categories: facility_categories,
                  facility_codes: Poison.encode!(facility_codes))
    end
  end

  # Step 2 - Address
  defp step2(conn, facility) do
    changeset =
      facility
      |> Facility.step2_changeset()

    location_groups =
      facility.region
      |> LocationGroupContext.get_location_group_by_region()

    conn
    |> render(
      "step2.html",
      changeset: changeset,
      facility: facility,
      location_groups: location_groups,
      facility_location_groups: Poison.encode!(facility.facility_location_groups)
    )
  end

  defp update_step2(conn, facility, facility_params) do
    location_groups =
      facility.region
      |> LocationGroupContext.get_location_group_by_region()

    with {true, changeset} <- FacilityContext.validate_step2_changeset(facility, facility_params),
         false <- is_nil(facility_params["location_group_ids"]) && facility.facility_location_groups == [],
         [] <- FacilityContext.get_facility_by_long_lat(
           facility_params, facility.id),
         {:ok, facility} <-
           FacilityContext.update_step2_facility(
             conn.assigns.current_user.id, facility, facility_params)
    do
      conn
      |> put_flash(
        :info,
        "Facility address details has been successfully updated."
      )
      |> redirect(to: "/facilities/#{facility.id}/setup?step=3")
    else
      true ->

        changeset =
          facility
          |> Facility.step2_changeset()

        conn
        |> render(
          "step2.html",
          changeset: changeset,
          facility: facility,
          location_groups: location_groups,
          empty_location_group: "This is a required field",
          facility_location_groups: Poison.encode!(facility.facility_location_groups)
        )

      [%Facility{}] = [facility_loc] ->
        changeset =
          facility
          |> Facility.step2_changeset()

        conn
        |> render(
          "step2.html",
          changeset: changeset,
          facility: facility,
          location_groups: location_groups,
          invalid_long_lat:
            "#{facility_loc.code} #{facility_loc.name} is in the same location",
          facility_location_groups: Poison.encode!(facility.facility_location_groups)
        )
      {false, changeset} ->
        conn
        |> step2_changeset_error_return(changeset, facility, location_groups)
      {:error, changeset} ->
        conn
        |> step2_changeset_error_return(changeset, facility, location_groups)
    end
  end

  defp step2_changeset_error_return(conn, changeset, facility, location_groups) do
    conn
    |> put_flash(
      :error,
      "Error creating facility! Please check the errors below."
    )
    |> render(
      "step2.html",
      changeset: changeset,
      facility: facility,
      location_groups: location_groups,
      facility_location_groups: Poison.encode!(facility.facility_location_groups)
    )
  end

  # Step 3 - Contact Details
  defp step3(conn, facility) do
    changeset = Facility.changeset(facility, %{})
    contacts = FacilityContext.get_all_facility_contacts(facility.id)
    render(conn, "step3.html",
           changeset: changeset,
           facility: facility,
           contacts: contacts)
  end

  def create_contact(conn, %{"id" => id, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    with {:ok, contact} <- ContactContext.create_fcontact(facility_params),
         :ok <- Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          case param do
            "mobile" ->
              area_code = ""
              local = ""
            "telephone" ->
              area_code = facility_params["tel_area_code"]
              local = facility_params["tel_local"]
            "fax" ->
              area_code = facility_params["fax_area_code"]
              local = facility_params["fax_local"]
          end
           insert_number(%{
             contact_id: contact.id,
             number: facility_params[param],
             type: param,
             area_code: area_code,
             local: local
           })
         end),
         {:ok, _email} <- EmailContext.create_email(%{
           contact_id: contact.id,
           address: Map.get(facility_params, "email"),
           type: ""
         }),
         {:ok, _facility_contact} <- FacilityContext.create_facility_contact(%{
           "facility_id" => facility.id,
           "contact_id" => contact.id
         })
    do
      conn
      |> put_flash(:info, "Facility contact created successfully.")
      |> redirect(to: "/facilities/#{facility.id}/setup?step=3")
    else
      {:error, changeset} ->
        contacts = FacilityContext.get_all_facility_contacts(facility.id)

        conn
        |> put_flash(
          :error,
          "Error creating contact! Please check the errors below."
        )
        |> render("step3.html",
                  changeset: changeset,
                  facility: facility,
                  contacts: contacts)
    end
  end

  def update_contact(conn, %{"id" => id, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    contact = ContactContext.get_contact!(facility_params["contact_id"])
    with {:ok, contact} <-
            ContactContext.update_fcontact(contact, facility_params),
         {_, _del_phone} <- PhoneContext.delete_phone(contact.id),
         :ok <- Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          case param do
            "mobile" ->
              area_code = ""
              local = ""
            "telephone" ->
              area_code = facility_params["tel_area_code"]
              local = facility_params["tel_local"]
            "fax" ->
              area_code = facility_params["fax_area_code"]
              local = facility_params["fax_local"]
          end
           insert_number(%{
             contact_id: contact.id,
             number: facility_params[param],
             type: param,
             area_code: area_code,
             local: local
           })
         end),
         {_, _del_email} <- EmailContext.delete_email(contact.id),
         {:ok, _email} <- EmailContext.create_email(%{
           contact_id: contact.id,
           address: Map.get(facility_params, "email"),
           type: ""
         })
      do
        conn
        |> put_flash(:info, "Contact updated successfully.")
        |> redirect(to: "/facilities/#{facility.id}/setup?step=3")
    else
      {:error, changeset} ->
        contacts = FacilityContext.get_all_facility_contacts(id)

        conn
        |> put_flash(
          :error,
          "Error updating contact! Please check the errors below."
        )
        |> render("step3.html",
                  changeset: changeset,
                  facility: facility,
                  contacts: contacts)
      end
  end

  defp insert_number(params) do
      Enum.each(Enum.with_index(params.number, 0), fn({number, counter}) ->
      local =
      if params.type == "mobile" do
          nil
      else
        if is_nil(params.local) || params.local == "" do
          nil
        else
          Enum.at(params.local, counter)
        end
      end
      area_code =
      if params.type == "mobile" do
          nil
      else
        if is_nil(params.area_code) || params.area_code == "" do
          nil
        else
          Enum.at(params.area_code, counter)
        end
      end
      PhoneContext.create_phone(%{
        contact_id: params.contact_id,
        number: String.replace(number, "-", ""),
        local: local,
        area_code: area_code,
        country_code: "+63",
        type: params.type
      })
    end)
  end

  def next_contact(conn, %{"id" => id}) do
    facility = FacilityContext.get_facility!(id)
    contacts = FacilityContext.get_all_facility_contacts(facility.id)
    with false <- length(contacts) == 0
    do
      if facility.step == 3 do
        FacilityContext.update_step_facility(
          facility,
          %{step: 4, updated_by: conn.assigns.current_user.id}
        )
      end
    else
      true ->
        changeset = Facility.changeset(facility, %{})
        contacts = FacilityContext.get_all_facility_contacts(facility.id)
        conn
        |> put_flash(:error, "At least one contact should be added")
        |> render("step3.html",
        changeset: changeset,
        facility: facility,
        contacts: contacts)
    end

    conn
    |> redirect(to: "/facilities/#{id}/setup?step=4")
  end

  def get_contact(conn, %{"id" => id}) do
    contact = ContactContext.get_contact!(id)
    render(conn, Innerpeace.PayorLink.Web.Api.V1.FacilityView,
      "facility_contacts.json", facility_contacts: contact)
  end

  def delete_facility_contact(conn, %{"id" => id}) do
    facility =
      id
      |> FacilityContext.get_facility_by_contact_id()

    ContactContext.delete_contact(id)

    conn
    |> put_flash(:info, "Contact deleted successfully.")
    |> redirect(to: "/facilities/#{facility.id}/setup?step=3")
  end

  # Step 4 - Financial
  defp step4(conn, facility) do
    changeset = Facility.step4_changeset(facility, %{})
    vat_statuses = DropdownContext.get_all_vat_status()
    prescription_clauses = DropdownContext.get_all_prescription_clause()
    payment_modes = DropdownContext.get_all_mode_of_payment()
    releasing_modes = DropdownContext.get_all_releasing_mode()
    render conn, "step4.html",
    changeset: changeset,
      facility: facility,
      vat_statuses: vat_statuses,
      prescription_clauses: prescription_clauses,
      releasing_modes: releasing_modes,
      payment_modes: payment_modes
  end

  defp update_step4(conn, facility, facility_params) do
    with {:ok, facility} <-
            FacilityContext.update_step4_facility(
              conn.assigns.current_user.id, facility, facility_params),
         {:ok} <-
            FacilityContext.upload_facility_files(
              facility.id, facility_params["files"] || [], "financial"),
         {:ok} <-
            FacilityContext.delete_facility_files(
              facility_params["file_delete_ids"] || "")
    do
      conn
      |> redirect(to: "/facilities/#{facility.id}/setup?step=5")
    else
      {:error, changeset} ->
        vat_statuses = DropdownContext.get_all_vat_status()
        prescription_clauses = DropdownContext.get_all_prescription_clause()
        payment_modes = DropdownContext.get_all_payment_mode()
        releasing_modes = DropdownContext.get_all_releasing_mode()

        conn
        |> put_flash(
          :error,
          "Error creating facility! Please check the errors below."
        )
        |> render("step4.html",
        changeset: changeset,
        facility: facility,
        vat_statuses: vat_statuses,
        prescription_clauses: prescription_clauses,
        releasing_modes: releasing_modes,
        payment_modes: payment_modes)
      {:upload_error} ->
        conn
        |> put_flash(:error, "Error uploading files!")
        |> redirect(to: "/facilities/#{facility.id}/setup?step=4")
      {:delete_error} ->
        conn
        |> put_flash(:error, "Error removing files!")
        |> redirect(to: "/facilities/#{facility.id}/setup?step=4")
    end
  end

  defp step5(conn, facility) do
    coverages =  CoverageContext.get_all_coverages()
    service_fee_types = DropdownContext.get_all_facility_service_fee_types()
    render(conn, "step5.html",
           facility: facility,
           coverages: coverages,
           service_fee_types: service_fee_types)
  end

  defp update_step5(conn, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("facility_id", facility.id)
    case FacilityContext.create_facility_service_fee(facility_params) do
      {:ok, _facility_service_fee} ->
        conn
        |> put_flash(:info, "Successfully added Service Fee")
        |> redirect(to: "/facilities/#{facility.id}/setup?step=5")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error adding facility service fee")
        |> redirect(to: "/facilities/#{facility.id}/setup?step=5")
    end
  end

  # Summary
  defp step6(conn, facility) do
    contacts = FacilityContext.get_all_facility_contacts(facility.id)
    render conn, "step6.html", facility: facility, contacts: contacts
  end

  def submit_summary(conn, %{"id" => id}) do
    facility = FacilityContext.get_facility!(id)

    if facility.step == 6 do
      FacilityContext.update_step_facility(
        facility,
        %{step: 7, updated_by: conn.assigns.current_user.id}
      )
    end

    conn
    |> redirect(to: facility_path(conn, :show, facility, active: "profile"))
  end

  # Show
  def show(conn, %{"id" => id, "active" => active}) do
    facility = FacilityContext.get_facility(id)

    if is_nil(facility) do
      conn
      |> put_flash(:error, "Facility does not exist")
      |> redirect(to: facility_path(conn, :index))
    else
    pem = conn.private.guardian_default_claims["pem"]["facilities"]
    rooms = RoomContext.list_all_rooms()
    facility_room_rate = FacilityRoomRateContext.get_all_facility_room_rate(id)
    changeset =
      FacilityRoomRateContext.changeset_facility_room_rate(%FacilityRoomRate{})
    changeset_facility_payor_procedure =
      FacilityContext.change_facility_payor_procedure(%FacilityPayorProcedure{})
    facility_payor_procedure =
      FacilityContext.get_all_facility_payor_procedures(id)
    contacts =
      FacilityContext.get_all_facility_contacts(facility.id)
    practitioner_facilities =
      PractitionerContext.get_practitioner_facilities_by_facility_id(id)
    ruv = RUVContext.get_ruvs
    facility_ruv = FacilityContext.get_all_facility_ruv(id)
    render(
      conn,
      "show.html",
      facility: facility,
      facility_payor_procedure: facility_payor_procedure,
      contacts: contacts,
      room: rooms,
      payor_procedure: payor_procedure(),
      facility_room_rate: facility_room_rate ,
      practitioner_facilities: practitioner_facilities,
      ruv: ruv,
      facility_ruv: facility_ruv,
      changeset: changeset,
      active: active,
      changeset_facility_payor_procedure: changeset_facility_payor_procedure,
      permission: pem
    )
    end
  end

  def show(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Page not found!")
    |> redirect(to: facility_path(conn, :index))
  end

  # Edit General
  def edit_general(conn, facility) do
    changeset = Facility.update_general_changeset(facility, %{})
    facility_types = DropdownContext.get_all_facility_type()
    facility_categories = DropdownContext.get_all_facility_category()
    render conn, "edit/general.html",
    changeset: changeset,
      facility: facility,
      facility_types: facility_types,
      facility_categories: facility_categories
  end

  def update_edit_general(conn, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    with {:ok, facility} <-
              FacilityContext.update_general(facility, facility_params)
    do
      conn
      |> put_flash(:info, "Facility updated succesfully.")
      |> redirect(to: "/facilities/#{facility.id}/edit?tab=general")
    else
      {:error, changeset} ->
        facility_types = DropdownContext.get_all_facility_type()
        facility_categories = DropdownContext.get_all_facility_category()
        conn
        |> put_flash(
          :error,
          "Error updating facility! Please check the errors below."
        )
        |> render("edit/general.html",
        changeset: changeset,
        facility: facility,
        facility_types: facility_types,
        facility_categories: facility_categories)
    end
  end

  # Edit Address
  def edit_address(conn, facility) do
    changeset =
      facility
      |> Facility.update_address_changeset()

    location_groups =
      facility.region
      |> LocationGroupContext.get_location_group_by_region()

    conn
    |> render(
      "edit/address.html",
      changeset: changeset,
      facility: facility,
      location_groups: location_groups,
      facility_location_groups: Poison.encode!(facility.facility_location_groups)
    )
  end

  def update_edit_address(conn, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    with {:ok, facility} <-
      FacilityContext.update_address(facility, facility_params)
    do
      conn
      |> put_flash(:info, "Facility updated succesfully.")
      |> redirect(to: "/facilities/#{facility.id}/edit?tab=address")
    else
      {:error, changeset} ->
        conn
        |> put_flash(
          :error,
          "Error creating facility! Please check the errors below."
        )
        |> render("edit/address.html", changeset: changeset, facility: facility)
    end
  end

  # Edit Contact Details
  def edit_contact_details(conn, facility) do
   changeset = Facility.changeset(facility, %{})
    contacts = FacilityContext.get_all_facility_contacts(facility.id)
    render(conn, "edit/contact_details.html",
          changeset: changeset,
          facility: facility,
          contacts: contacts)
  end

  def update_edit_contact_details(conn, _facility, _facility_params) do
    conn
  end

  defp check_area_code(param, facility_params) do
    cond do
      param == "telephone" ->
        facility_params["tel_area_code"]
      param == "fax" ->
        facility_params["fax_area_code"]
      true ->
        ""
    end
  end

  defp check_local(param, facility_params) do
    cond do
      param == "telephone" ->
        facility_params["tel_local"]
      param == "fax" ->
        facility_params["fax_local"]
      true ->
        ""
    end
  end

  def for_edit_create_contact(conn, %{"id" => id, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    case ContactContext.create_fcontact(facility_params) do
      {:ok, contact} ->
        Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          area_code = check_area_code(param, facility_params)
          local = check_local(param, facility_params)

           insert_number(%{
             contact_id: contact.id,
             number: facility_params[param],
             type: param,
             area_code: area_code,
             local: local
           })
         end)

        EmailContext.create_email(%{
          contact_id: contact.id,
          address: Map.get(facility_params, "email"),
          type: ""
        })

        FacilityContext.create_facility_contact(%{
          "facility_id" => facility.id,
          "contact_id" => contact.id
        })

        conn
        |> redirect(to: "/facilities/#{facility.id}/edit?tab=contact_details")
      {:error, %Ecto.Changeset{} = changeset} ->
        contacts = FacilityContext.get_all_facility_contacts(facility.id)

        conn
        |> put_flash(:error, "Error creating contact! Please check the errors below.")
        |> render("edit/contact_details.html",
                  changeset: changeset,
                  facility: facility,
                  contacts: contacts)
    end
  end

  def for_edit_update_contact(conn, %{"id" => id, "facility" => facility_params}) do
    facility = FacilityContext.get_facility!(id)
    contact = ContactContext.get_contact!(facility_params["contact_id"])
    case ContactContext.update_fcontact(contact, facility_params) do
      {:ok, contact} ->
        PhoneContext.delete_phone(contact.id)
        Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          area_code = check_area_code(param, facility_params)
          local = check_local(param, facility_params)
           insert_number(%{
             contact_id: contact.id,
             number: facility_params[param],
             type: param,
             area_code: area_code,
             local: local
           })
         end)

        EmailContext.delete_email(contact.id)
        EmailContext.create_email(%{
          contact_id: contact.id,
          address: Map.get(facility_params, "email"),
          type: ""
        })

        conn
        |> put_flash(:info, "Contact updated successfully.")
        |> redirect(to: "/facilities/#{facility.id}/edit?tab=contact_details")
      {:error, %Ecto.Changeset{} = changeset} ->
        contacts = FacilityContext.get_all_facility_contacts(id)

        conn
        |> render("edit/contact_details.html",
                  changeset: changeset,
                  facility: facility,
                  contacts: contacts)
    end
  end

  def for_edit_delete_facility_contact(conn, %{"id" => id}) do
    facility = FacilityContext.get_facility_by_contact_id(id)
    PhoneContext.delete_phone(id)
    EmailContext.delete_email(id)
    FacilityContext.delete_fcontact(facility.id, id)
    ContactContext.delete_contact(id)

    conn
    |> put_flash(:info, "Contact deleted successfully.")
    |> redirect(to: "/facilities/#{facility.id}/edit?tab=contact_details")
  end

  # Edit Financial
  def edit_financial(conn, facility) do
    changeset = Facility.update_financial_changeset(facility, %{})
    vat_statuses = DropdownContext.get_all_vat_status()
    prescription_clauses = DropdownContext.get_all_prescription_clause()
    payment_modes = DropdownContext.get_all_mode_of_payment()
    releasing_modes = DropdownContext.get_all_releasing_mode()
    render conn, "edit/financial.html",
    changeset: changeset,
      facility: facility,
      vat_statuses: vat_statuses,
      prescription_clauses: prescription_clauses,
      releasing_modes: releasing_modes,
      payment_modes: payment_modes
  end

  def update_edit_financial(conn, facility, facility_params) do
    facility_params =
      facility_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    with {:ok, facility} <-
              FacilityContext.update_financial(facility, facility_params)
    do
        conn
        |> put_flash(:info, "Facility updated succesfully.")
        |> redirect(to: "/facilities/#{facility.id}/edit?tab=financial")
    else
      {:error, changeset} ->
        vat_statuses = DropdownContext.get_all_vat_status()
        prescription_clauses = DropdownContext.get_all_prescription_clause()
        payment_modes = DropdownContext.get_all_mode_of_payment()
        releasing_modes = DropdownContext.get_all_releasing_mode()

        conn
        |> put_flash(
          :error,
          "Error creating facility! Please check the errors below."
        )
        |> render("edit/financial.html",
          changeset: changeset,
          facility: facility,
          vat_statuses: vat_statuses,
          prescription_clauses: prescription_clauses,
          releasing_modes: releasing_modes,
          payment_modes: payment_modes)
    end
  end

  # FacilityProcedure
  def get_facility_payor_procedure(conn, %{"id" => facility_payor_procedure_id}) do
    facility_payor_procedure =
      FacilityContext.get_facility_payor_procedure(facility_payor_procedure_id)
    with true <- not is_nil(facility_payor_procedure) do
    render(conn, Innerpeace.PayorLink.Web.Api.V1.FacilityView,
           "facility_payor_procedure.json",
      facility_payor_procedure: facility_payor_procedure)
    else
      false ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not found")

    end
  end

  def ajax_fpprocedure_checker(conn, %{"id" => facility_id}) do
    facility_payor_procedure =
      FacilityContext.get_fpayor_procedure_id_and_code(facility_id)
    json conn, Poison.encode!(facility_payor_procedure)
  end

  def render_facility_payor_procedure(conn, %{"id" => facility_id}) do
    changeset_facility_payor_procedure =
      FacilityContext.change_facility_payor_procedure(%FacilityPayorProcedure{})
    facility = FacilityContext.get_facility!(facility_id)
    facility_room_rate =
      FacilityRoomRateContext.get_all_facility_room_rate(facility_id)
    render(conn, "modal_add_procedure.html",
           facility: facility,
           facility_room_rate: facility_room_rate,
           payor_procedure: payor_procedure(),
           changeset_facility_payor_procedure:
            changeset_facility_payor_procedure,
           action: facility_path(conn,
            :create_facility_payor_procedure, facility_id))
  end

  def render_edit_facility_payor_procedure(conn, %{"id" => facility_id, "facility_procedure_id" => fp_id}) do
    facility_payor_procedure =
      FacilityContext.get_facility_payor_procedure!(fp_id)
    changeset_facility_payor_procedure =
      FacilityContext.change_facility_payor_procedure(facility_payor_procedure)
    facility = FacilityContext.get_facility!(facility_id)
    facility_room_rate =
      FacilityRoomRateContext.get_all_facility_room_rate(facility_id)
    render(conn, "modal_update_procedure.html",
           facility: facility,
           facility_room_rate: facility_room_rate,
           payor_procedure: payor_procedure(),
           changeset_facility_payor_procedure:
            changeset_facility_payor_procedure,
           facility_payor_procedure: facility_payor_procedure,
           action: facility_path(conn,
            :update_facility_payor_procedure, facility_id))
  end

  def create_facility_payor_procedure(conn, %{"id" => facility_id, "facility_procedure" => fprocedure_params}) do
    fprocedure_params =
      fprocedure_params
      |> Map.put("facility_id", facility_id)

    with {:ok, facility_payor_procedure} <-
          FacilityContext.create_facility_payor_procedure!(fprocedure_params),
         {:ok, _facility_payor_procedure_rooms} <-
          FacilityContext.create_many_facility_payor_procedure_room(
            fprocedure_params["room_params"], facility_payor_procedure.id)
    do
        conn
        |> put_flash(:info, "Procedure successfully added.")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Check for errors")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    end
  end

  def update_facility_payor_procedure(conn, %{"id" => facility_id, "facility_procedure" => fprocedure_params}) do
    facility_payor_procedure =
    fprocedure_params["facility_payor_procedure_id"]
    |> FacilityContext.get_facility_payor_procedure!

    with {:ok, facility_payor_procedure} <-
          FacilityContext.update_facility_payor_procedure!(
            facility_payor_procedure, fprocedure_params),
         {:ok, "deleted_all"} <-
          FacilityContext.delete_facility_payor_procedure_room(
            facility_payor_procedure.id),
         {:ok, _facility_payor_procedure_rooms} <-
          FacilityContext.create_many_facility_payor_procedure_room(
            fprocedure_params["room_params"], facility_payor_procedure.id)
    do
        conn
        |> put_flash(:info, "Procedure successfully updated.")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Check for errors")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    end
  end

  def remove_facility_procedure(conn, %{"id" => facility_id, "fpp_id" => fpp_id}) do
    FacilityContext.delete_facility_payor_procedure(fpp_id)
    conn
    |> put_flash(:info, "Procedure successfully removed.")
    |> redirect(to: "/facilities/#{facility_id}?active=procedure")
  end

  defp payor_procedure do
    ProcedureContext.get_all_payor_procedures
    |> Enum.map(&{"#{&1.code}/#{(&1.description)}", &1.id})
  end

  def get_facility_by_member_id(conn, %{"id" => member_id}) do
    facilities = FacilityContext.get_facility_by_member_id(member_id)
    json conn, facilities
  end

  # Start of Print Summary
  def print_summary(conn, %{"id" => facility_id}) do
    facility = FacilityContext.get_facility!(facility_id)
    contacts = FacilityContext.get_all_facility_contacts(facility.id)

    html = View.render_to_string(FacilityView, "print_summary.html",
            facility: facility, contacts: contacts)

    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{facility.name}_#{unique_id}"

    with {:ok, content} <-
      PdfGenerator.generate_binary(html,
        page_size: "A4",
        filename: filename,
        delete_temporary: true)
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header(
        "content-disposition",
        "inline; filename=#{filename}.pdf"
      )
      |> send_resp(200, content)
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/facilities/#{facility_id}/setup?step=5")
    end
  end
  # End of Print Summary

  # Delete facility start
  def delete_facility(conn, %{"id" => facility_id}) do
    {cnt_deleted, _} =
      facility_id
      |> FacilityContext.delete_facility()

    if cnt_deleted == 0 do
      conn
      |> put_flash(:error, "Facility id does not exists.")
      |> redirect(to: "/facilities/")
    else
      conn
      |> put_flash(:info, "Facility deleted successfully.")
      |> redirect(to: "/facilities/")
    end
  end
  # Delete facility end
  #

  def new_import(conn, %{"id" => facility_id}) do
    facility = FacilityContext.get_facility!(facility_id)
    uploaded_files = FacilityContext.get_fpp_upload_logs(facility_id)
    changeset = FacilityPayorProcedure.changeset(%FacilityPayorProcedure{})
    render(conn, "import.html",
           changeset: changeset,
           facility: facility,
           uploaded_files: uploaded_files)
  end

  def import_facility_payor_procedure(conn, %{"id" => facility_id, "facility_payor_procedure" => fpp}) do
    case FacilityContext.create_fpp_export(
      fpp, facility_id, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/facilities/payor_procedure/#{facility_id}/import")
      {:not_found} ->
        conn
        |> put_flash(:error, "File uploaded is empty.")
        |> redirect(to: "/facilities/payor_procedure/#{facility_id}/import")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid excel file content!")
        |> redirect(to: "/facilities/payor_procedure/#{facility_id}/import")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files are .xls and .xlsx")
        |> redirect(to: "/facilities/payor_procedure/#{facility_id}/import")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    end
  end

  def import_facility_payor_procedure(conn, %{"id" => facility_id}) do
    conn
    |> put_flash(:error, "Please upload a file.")
    |> redirect(to: "/facilities/payor_procedure/#{facility_id}/import")
  end

  def download_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"CPT Rates Batch.csv\""
    )
    |> send_resp(200, template_content())
  end

  defp template_content do
    _csv_content =
    [['Payor CPT Code', 'Facility CPT Code', 'Facility CPT Description',
      'Room Code', 'Amount', 'Discount', 'Effective Date'],
      ['', '', '', '', '', '', '']]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  # download facility_payor_procedure
  def download_fpp(conn, %{"id" => id, "fpp_param" => download_param}) do
    data = [["Payor Cpt Code", "Payor Cpt Name", "Provider CPT Code", "Provider CPT Name", "Room Code", "Amount", "Discount", "Effectivity Date"]] ++
      FacilityContext.fpp_csv_download(download_param, id)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def fpp_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [["Payor Cpt Code", "Facility CPT Code", "Facility CPT Description", "Room Code", "Amount", "Discount", "Effective Date", "Remarks"]] ++
      FacilityContext.get_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)

  end

  def create_ruv(conn, %{"id" => facility_id, "facility_ruv" => facility_ruv_params}) do
    # with {:ok, {year, month, day}} <- get_mdy(facility_ruv_params["effectivity_date"]) do
      # effectivity_date = Ecto.DateTime.cast!({{year, month, day}, {0, 0, 0}})
    facility_ruv_params =
      facility_ruv_params
      |> Map.merge(%{"facility_id" => facility_id})
      # |> Map.put("effectivity_date", effectivity_date)
    case FacilityContext.set_facility_ruv(facility_ruv_params) do
      {:ok, _facility_ruv} ->
      conn
        |> put_flash(:info, "RUV Added Successfully")
        |> redirect(to: "/facilities/#{facility_id}?active=ruv")
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Error adding RUV")
        |> redirect(to: "/facilities/#{facility_id}?active=ruv")
    end
    # end
  end

  def ruv_import(conn, %{"id" => facility_id}) do
    facility = FacilityContext.get_facility!(facility_id)
    uploaded_files = FacilityContext.get_fr_upload_logs(facility_id)
    changeset = FacilityRUV.changeset(%FacilityRUV{})
    render(conn, "ruv_import.html",
           changeset: changeset,
           facility: facility,
           uploaded_files: uploaded_files)
  end

  def import_facility_ruv(conn, %{"id" => facility_id, "facility_ruv" => fr}) do
    case FacilityContext.create_fr_export(
      fr, facility_id, conn.assigns.current_user.id)
    do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/facilities/ruv/#{facility_id}/import")
      {:not_found} ->
        conn
        |> put_flash(:error, "File uploaded is empty.")
        |> redirect(to: "/facilities/ruv/#{facility_id}/import")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid excel file content!")
        |> redirect(to: "/facilities/ruv/#{facility_id}/import")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files are .csv only")
        |> redirect(to: "/facilities/ruv/#{facility_id}/import")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/facilities/#{facility_id}?active=procedure")
    end
  end

  def import_facility_ruv(conn, %{"id" => facility_id}) do
    conn
    |> put_flash(:error, "Please upload a file.")
    |> redirect(to: "/facilities/ruv/#{facility_id}/import")
  end

  def ruv_download_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"RUV Batch.csv\""
    )
    |> send_resp(200, ruv_template_content())
  end

  defp ruv_template_content do
    _csv_content = [['RUV Code'], ['']]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  # download facility_ruv
  def download_fr(conn, %{"id" => id, "fr_param" => download_param}) do
    data = [['RUV Code', 'RUV Description',
             'RUV Type', 'Value', 'Effectivity Date'
             ]] ++
      FacilityContext.fr_csv_download(download_param, id)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def fr_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [['RUV Code', 'RUV Description',
             'RUV Type', 'Value', 'Effectivity Date',
             'Remarks']] ++
      FacilityContext.get_ruv_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)

  end

  defp get_mdy(datetime) do
    {day, month, year} =
      datetime
      |> String.slice(0..9)
      |> String.split("/")
      |> List.to_tuple()
    {:ok, {year, month, day}}
  end

  def get_location_group_by_region(conn, %{"region_name" => region_name}) do
    location_group =
      region_name
      |> LocationGroupContext.get_location_group_by_region

    conn
    |> json(Poison.encode!(location_group))
  end

  def new_facility_upload_file(conn, _params) do
    facility_upload_logs = FacilityContext.get_all_facility_upload_logs()
    facility_upload_file = FacilityContext.get_facility_upload_file()
    changeset = Facility.changeset(%Facility{})
    render(conn, "facility_file_upload.html",
           changeset: changeset,
           facility_upload_logs: facility_upload_logs,
           facility_upload_file: facility_upload_file,
           )
  end

  def facility_import(conn, %{"facility" => facility_params}) do
    facility_upload_logs = FacilityContext.get_all_facility_upload_logs()
    facility_upload_file = FacilityContext.get_facility_upload_file()
    changeset = Facility.changeset(%Facility{})
    case FacilityContext.create_facility_import(facility_params, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, Enum.join([facility_params["file"].filename, " was successfully uploaded"]))
        |> redirect(to: facility_path(conn, :new_facility_upload_file))
      {:empty} ->
        conn
        |> put_flash(:error, "File uploaded is empty.")
        |> render("facility_file_upload.html", changeset: changeset,
           facility_upload_logs: facility_upload_logs,
           facility_upload_file: facility_upload_file)
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid excel file content!")
        |> render("facility_file_upload.html", changeset: changeset,
           facility_upload_logs: facility_upload_logs,
           facility_upload_file: facility_upload_file)
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("facility_file_upload.html", changeset: changeset,
           facility_upload_logs: facility_upload_logs,
           facility_upload_file: facility_upload_file,
           )
    end
  end

  def download_facility_template(conn, _params) do
    datetime_now =
      String.replace(String.replace(String.replace(DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    filename = Enum.join(["FacilityGeneralTemplate-", datetime_now, ".csv"])
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, facility_template_content())
  end

  def download_facility_contacts_template(conn, _params) do
    datetime_now =
      String.replace(String.replace(String.replace(DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    filename = Enum.join(["FacilityContactsTemplate-", datetime_now, ".csv"])
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, facility_contacts_template_content())
  end

  defp facility_template_content do
    _csv_content =
      [['Facility Code',
      'Facility Name',
      'Facility Type',
      'Facility Category',
      'License Name',
      'PHIC Accreditation From',
      'PHIC Accreditation To',
      'PHIC Accreditation Number',
      'Status',
      'Affiliation Date',
      'Phone Number',
      'Email Address',
      'Website',
      'Address Line 1',
      'Address Line 2',
      'City/Municpal',
      'Province',
      'Region',
      'Country',
      'Postal Code',
      'Longitude',
      'Latitude',
      'Location Group',
      'TIN',
      'VAT Status',
      'Prescription Term',
      'Prescription Clause',
      'Credit Term',
      'Credit Limit',
      'Mode of Payment',
      'Mode of Releasing',
      'Withholding Tax',
      'Number of Beds',
      'Bond',
      'Bank Account Number',
      'Payee Name',
      'Balance Biller',
      'Authority to Credit',
      'Service Fee Coverage',
      'Service Fee Mode of Payment',
      'Service Fee',
      'Service Fee Rate'
      ]]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  defp facility_contacts_template_content do
    _csv_content =
      [['Facility Code',
      'First Name',
      'Last Name',
      'Department',
      'Designation',
      'Telephone Country Code',
      'Telephone Area Code',
      'Telephone Number',
      'Telephone Local',
      'Mobile Country Code',
      'Mobile Number',
      'Fax Country Code',
      'Fax Area Code',
      'Fax Number',
      'Fax Local',
      'Email Address'
      ]]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  def new_facility_upload_file(conn, _params) do
    facility_upload_logs = FacilityContext.get_all_facility_upload_logs()
    facility_upload_file = FacilityContext.get_facility_upload_file()
    changeset = Facility.changeset(%Facility{})
    render("facility_file_upload.html", changeset: changeset,
           facility_upload_logs: facility_upload_logs,
           facility_upload_file: facility_upload_file)
  end

  def download_uploaded_facility_log(conn, %{"facility" => facility_params}) do
    datetime_now =
      String.replace(String.replace(String.replace(DateTime.to_string(DateTime.utc_now), ".", "-"), " ", "-"), ":", "-")
    _filename = Enum.join(["File_-", datetime_now, ".csv"])
    facilities =
      FacilityContext.get_f_upload_logs(Enum.at(facility_params["list"], 0), Enum.at(facility_params["list"], 1))
    csv_content = [['Remarks', 'Row Number', 'Facility Code', 'Facility Name']] ++ facilities
        |> CSV.encode
        |> Enum.to_list
        |> to_string
        conn
        |> json(csv_content)
  end

  def facility_index(conn, params) do
    count = FacilityDatatable.get_facilities_count(params["search"]["value"])
    accounts = FacilityDatatable.get_facilities(params["start"], params["length"], params["search"]["value"])

    json(conn, %{
      data: accounts,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: count
    })
  end

  defp translate_date_params(params) do
    params
    |> Map.put("phic_accreditation_from", to_valid_date(params["phic_accreditation_from"]))
    |> Map.put("phic_accreditation_to", to_valid_date(params["phic_accreditation_to"]))
    |> Map.put("affiliation_date", to_valid_date(params["affiliation_date"]))
    |> Map.put("disaffiliation_date", to_valid_date(params["disaffiliation_date"]))
  end

  defp to_valid_date(date) do
    UtilityContext.transform_string_dates(date)
  end

  def load_facilities(conn, params) do
    count = FacilityDatatable.get_facilities_count(params["search"]["value"])
    facilities = FacilityDatatable.get_facilities(params["start"], params["length"], params["search"]["value"])

    json(conn, %{
      data: facilities,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: count
    })
  end
end

defmodule Innerpeace.PayorLink.Web.PractitionerController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.PayorLink.Web.PractitionerView
  alias Phoenix.View
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Practitioner,
    Specialization,
    # PaymentAccount,
    PractitionerFacility,
    PractitionerAccount,
    AccountGroup,
    Bank,
    PractitionerSchedule
  }
  alias Innerpeace.Db.Base.{
    Api.UtilityContext,
    PractitionerContext,
    FacilityContext,
    DropdownContext,
    ContactContext,
    PhoneContext,
    EmailContext
    # AccountContext
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{practitioners: [:manage_practitioners]},
       %{practitioners: [:access_practitioners]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{practitioners: [:manage_practitioners]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "practitioners"}
  when not action in [:index]


  def index(conn, _params) do
    practitioners = PractitionerContext.get_all_practitioners()
    for practitioner <- practitioners do
      PractitionerContext.expired_practitioner(practitioner.id)
    end
    render(conn, "index.html", practitioners: practitioners)
  end

  def setup(conn, %{"step" => step, "id" => id}) do
    practitioner = PractitionerContext.get_practitioner(id)
    validate_step(conn, practitioner, step)
    case step do
      "1" ->
        step_1(conn, practitioner)
      "2" ->
        step_2(conn, practitioner)
      "3" ->
        step_3(conn, practitioner)
      "4" ->
        step_4(conn, practitioner)
      "5" ->
        step_5(conn, practitioner)

      _ ->
        conn
        |> redirect(to: practitioner_path(conn, :index))
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: practitioner_path(conn, :index))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "practitioner" => practitioner_params}) do
    practitioner = PractitionerContext.get_practitioner(id)
    case step do
      "1" ->
        update(conn, practitioner, practitioner_params)
      "3" ->
        update_step3(conn, practitioner, practitioner_params)
    end
  end

  def validate_step(conn, practitioner, step) do
    if practitioner.step < String.to_integer(step) do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: practitioner_path(conn, :index))
    end
  end


  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    practitioner = PractitionerContext.get_practitioner(id)
    case tab do
      "general" ->
          edit_general(conn, practitioner)
      "contact" ->
          edit_contact(conn, practitioner)
      "financial" ->
          edit_financial(conn, practitioner)
    end
  end

  def edit_setup(conn, %{"id" => id}) do
    practitioner = PractitionerContext.get_practitioner(id)
    conn
    |> put_flash(:error, "Invalid tab")
    |> redirect(to: practitioner_path(conn, :show, practitioner))
  end

  def update_edit_setup(conn, %{"id" => id, "tab" => tab, "practitioner" => practitioner_params}) do
    practitioner = PractitionerContext.get_practitioner(id)
    case tab do
      "general" ->
        update_edit_general(conn, practitioner, practitioner_params)
      "contact" ->
        update_edit_contact(conn, practitioner, practitioner_params)
      "financial" ->
        update_edit_financial(conn, practitioner, practitioner_params)
    end
  end

  def new(conn, _params) do
    specializations =
      Specialization
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})
    changeset = Practitioner.changeset(%Practitioner{})
    render(conn, "new.html", changeset: changeset, specializations: specializations)
  end

  def create(conn, %{"practitioner" => practitioner_params}) do
    practitioner_params = translate_date_params(practitioner_params)
    specializations =
      Specialization
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})

    practitioner_params =
      practitioner_params
      |> Map.put("step", 2)
      |> Map.put("status", "Draft")
      |> Map.put("created_by_id", conn.assigns.current_user.id)
    case PractitionerContext.create_practitioner(practitioner_params) do
      {:ok, practitioner} ->
        PractitionerContext.update_practitioner_photo(
          practitioner, practitioner_params)
        if is_nil(practitioner_params["sub_specialization_ids"]) == true do
          PractitionerContext.set_practitioner_specializations(
            practitioner.id, practitioner_params["specialization_ids"], "")
        else
          PractitionerContext.set_practitioner_specializations(
            practitioner.id, practitioner_params["specialization_ids"],
            practitioner_params["sub_specialization_ids"])
        end
        conn
        |> put_flash(:info, "Basic info added successfully.")
        |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating practitioner! Please check the errors below.")
        |> render("new.html", changeset: changeset, specializations: specializations)
    end
  end


  def show(conn, %{"id" => id, "active" => active_tab}) do

    pem = conn.private.guardian_default_claims["pem"]["practitioners"]
    practitioner = PractitionerContext.get_practitioner(id)
    with true <- not is_nil(practitioner),
         practitioner_facilities =
           PractitionerContext.get_practitioner_facilities(id),
         practitioner_accounts = PractitionerContext.get_practitioner_accounts(id),
         practitioner_logs = PractitionerContext.get_practitioner_logs(),
         accounts = PractitionerContext.list_all_accounts_in_practitioner()
    do
      render(conn, "show.html", practitioner: practitioner,
        practitioner_logs: practitioner_logs,
        practitioner_facilities: practitioner_facilities,
        practitioner_accounts: practitioner_accounts,
        accounts: accounts, active_tab: active_tab,
        permission: pem
      )
    else
      false
      ->
        conn
        |> put_flash(:error, "Invalid ID")
        |> redirect(to: "/practitioners")
    end
  end


  # def show(conn, %{"id" => id, "active" => active_tab}) do
  #   pem = conn.private.guardian_default_claims["pem"]["practitioners"]
  #   practitioner = PractitionerContext.get_practitioner(id)
  #   practitioner_facilities =
  #     PractitionerContext.get_practitioner_facilities(id)
  #   practitioner_accounts = PractitionerContext.get_practitioner_accounts(id)
  #   practitioner_logs = PractitionerContext.get_practitioner_logs()
  #   accounts = PractitionerContext.list_all_accounts_in_practitioner()
  #   render(conn, "show.html", practitioner: practitioner,
  #     practitioner_logs: practitioner_logs,
  #     practitioner_facilities: practitioner_facilities,
  #     practitioner_accounts: practitioner_accounts,
  #     accounts: accounts, active_tab: active_tab,
  #     permission: pem
  #   )
  #   # rescue
    #  # _ ->
    #  #    conn
    #  #    |> put_flash(:error, "Page not found.")
    #  #    |> redirect(to: "/practitioners/")
    # end

    def show(conn, %{"id" => id}) do
      show(conn, %{"id" => id, "active" => "profile"})
    end

  def step_1(conn, practitioner) do
    specializations =
      Specialization
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})
    practitioner_specialization =
      for test = %{type: "Primary"} <-
        practitioner.practitioner_specializations,
          into: [], do: test.specialization.id
    practitioner_sub_specialization =
      for test = %{type: "Secondary"} <-
        practitioner.practitioner_specializations,
          into: [], do: test.specialization.id
    practitioner =
      Map.put(practitioner, :specialization_ids, practitioner_specialization)
    practitioner =
      Map.put(practitioner, :sub_specialization_ids,
        practitioner_sub_specialization)
    changeset = PractitionerContext.change_practitioner(practitioner)
    render(conn, "new-update.html",
      practitioner: practitioner, changeset: changeset,
      specializations: specializations)
  end

  def update(conn, practitioner, practitioner_params) do
    practitioner_params = translate_date_params(practitioner_params)
    specializations =
      Specialization
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})
    practitioner_params =
      Map.put(practitioner_params, "updated_by_id", conn.assigns.current_user.id)
    case PractitionerContext.update_practitioner(
      practitioner.id, practitioner_params)
    do
      {:ok, practitioner} ->
        PractitionerContext.update_practitioner_photo(
          practitioner, practitioner_params)
        if is_nil(practitioner_params["sub_specialization_ids"]) == true do
          PractitionerContext.set_practitioner_specializations(
            practitioner.id, practitioner_params["specialization_ids"], "")
        else
          PractitionerContext.set_practitioner_specializations(
            practitioner.id, practitioner_params["specialization_ids"],
            practitioner_params["sub_specialization_ids"])
        end
        conn
        |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating Practitioner! Please check the errors below.")
        |> render("new-update.html",
            practitioner: practitioner, changeset: changeset,
            specializations: specializations)
    end
  end

  def step_2(conn, practitioner) do
    changeset = PractitionerContext.change_practitioner(practitioner)
    contacts = PractitionerContext.get_practitioner_contacts(practitioner.id)
    render(conn, "new-contact.html",
      practitioner: practitioner, changeset: changeset, contacts: contacts)
  end

  def create_contact(conn, %{"id" => practitioner, "practitioner" => practitioner_params}) do
    practitioner_params =
      practitioner_params
      |> Map.put("step", 3)
    practitioner = PractitionerContext.get_practitioner(practitioner)
    if practitioner_params["email"] == [""] && practitioner_params["fax"] == [""] &&
      practitioner_params["mobile"] == [""] && practitioner_params["telephone"] == [""] do
      conn
      |> put_flash(:error, "At least one contact number must be entered.")
      |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=2")
    else
      create_cp(conn, practitioner, practitioner_params)
    end
  end

  def step_3(conn, practitioner) do
    vat_statuses = DropdownContext.get_all_vat_status()
    banks =
      Bank
      |> Repo.all
      |> Enum.map(&{&1.account_name, &1.id})
    changeset = PractitionerContext.change_practitioner_financial(practitioner)
    render(conn, "new-financial.html",
      vat_statuses: vat_statuses, practitioner: practitioner,
      changeset: changeset, banks: banks)
  end

  def create_financial(conn, %{"id" => practitioner, "practitioner" => practitioner_params}) do
    vat_statuses = DropdownContext.get_all_vat_status()
    practitioner = PractitionerContext.get_practitioner(practitioner)
    practitioner_params =
      practitioner_params
      |> Map.put("step", 4)

    case PractitionerContext.create_practitioner_financial(
      practitioner.id, practitioner_params) do
      {:ok, practitioner} ->
        PractitionerContext.update_step(practitioner.id, practitioner_params)

        conn
        |> put_flash(:info, "Financial created successfully.")
        |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=4")
      {:error, %Ecto.Changeset{} = changeset} ->
        banks =
          Bank
          |> Repo.all
          |> Enum.map(&{&1.account_name, &1.id})
        practitioner = PractitionerContext.get_practitioner(practitioner.id)
        render(conn, "new-financial.html",
          vat_statuses: vat_statuses, practitioner: practitioner,
          changeset: changeset, banks: banks)
    end
  end

  def update_step3(conn, practitioner, practitioner_params) do
    practitioner = PractitionerContext.get_practitioner(practitioner.id)
    practitioner_params =
      practitioner_params
      |> Map.put("step", 4)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case PractitionerContext.create_practitioner_financial(
      practitioner.id, practitioner_params)
    do
      {:ok, practitioner} ->
      PractitionerContext.update_step(practitioner.id, practitioner_params)
      conn
      |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=4")
      {:error, %Ecto.Changeset{} = changeset} ->
      practitioner = PractitionerContext.get_practitioner(practitioner.id)
      render(conn, "new-financial.html",
        practitioner: practitioner, changeset: changeset, bank: nil)
    end
  end

  def step_4(conn, practitioner) do
    render(conn, "new-summary.html", practitioner: practitioner)
  end

  def create_summary(conn, %{"id" => practitioner}) do
    practitioner = PractitionerContext.get_practitioner(practitioner)
    if practitioner.step == 4 do
      cond do
        practitioner.affiliated == "Yes" ->
          PractitionerContext.update_practitioner_status(
            practitioner, %{"status" => "Affiliated"})
        practitioner.affiliated == "No" ->
          PractitionerContext.update_practitioner_status(
            practitioner, %{"status" => "Disaffiliated"})
      end
      PractitionerContext.update_step(practitioner.id, %{"step" => 5})
    end

    conn
    |> put_flash(:info, "Practitioner created successfully.")
    |> redirect(to: "/practitioners/#{practitioner.id}?active=profile")
  end

  def step_5(conn, practitioner) do
    render(conn, "print-summary.html", practitioner: practitioner)
  end

  def edit_general(conn, practitioner) do
    specializations =
      Specialization
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})
    practitioner_specialization =
      for test = %{type: "Primary"} <- practitioner.practitioner_specializations,
        into: [], do: test.specialization.id
    practitioner_sub_specialization =
      for test = %{type: "Secondary"} <- practitioner.practitioner_specializations,
        into: [], do: test.specialization.id
    practitioner =
      Map.put(practitioner, :specialization_ids, practitioner_specialization)
    practitioner =
      Map.put(practitioner, :sub_specialization_ids,
        practitioner_sub_specialization)
    changeset = PractitionerContext.change_practitioner(practitioner)
    render(conn, "edit/general.html",
      practitioner: practitioner, changeset: changeset,
      specializations: specializations)
  end

  def update_edit_general(conn, practitioner, practitioner_params) do
    practitioner_params = translate_date_params(practitioner_params)
    practitioner_params =
      Map.put(practitioner_params, "updated_by_id", conn.assigns.current_user.id)
    case PractitionerContext.update_practitioner(
      practitioner.id, practitioner_params)
    do
      {:ok, updated_practitioner} ->
        PractitionerContext.create_practitioner_log(
          conn.assigns.current_user,
          Practitioner.changeset_general_edit(
            practitioner, practitioner_params),
          "General"
        )
        PractitionerContext.update_practitioner_photo(
          updated_practitioner, practitioner_params)
        if is_nil(practitioner_params["sub_specialization_ids"]) == true do
          PractitionerContext.set_practitioner_specializations(
            updated_practitioner.id, practitioner_params["specialization_ids"], "")
        else
          PractitionerContext.set_practitioner_specializations(
            updated_practitioner.id, practitioner_params["specialization_ids"],
              practitioner_params["sub_specialization_ids"])
        end
        cond do
          updated_practitioner.affiliated == "Yes" ->
            PractitionerContext.update_practitioner_status(
              updated_practitioner, %{"status" => "Affiliated"})
          updated_practitioner.affiliated == "No" ->
            PractitionerContext.update_practitioner_status(
              updated_practitioner, %{"status" => "Disaffiliated"})
        end
        conn
        |> put_flash(:info, " General updated successfully.")
        |> redirect(to: "/practitioners/#{updated_practitioner.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset} ->
        specializations =
          Specialization
          |> Repo.all
          |> Enum.map(&{&1.name, &1.id})
        conn
        |> put_flash(:error, "Error creating Practitioner! Please check the errors below.")
        |> render("edit/general.html", practitioner: practitioner,
            specializations: specializations, changeset: changeset)
    end
  end

  def edit_contact(conn, practitioner) do
    changeset = PractitionerContext.change_practitioner(practitioner)
    contacts = PractitionerContext.get_practitioner_contacts(practitioner.id)
    render(conn, "edit/contact.html",
      practitioner: practitioner, changeset: changeset, contacts: contacts)
  end

  def update_edit_contact(conn, practitioner, practitioner_params) do
    practitioner_params =
      practitioner_params
      |> Map.put("step", 5)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    practitioner = PractitionerContext.get_practitioner(practitioner.id)

    if practitioner_params["email"] == [""] && practitioner_params["fax"] == [""] &&
      practitioner_params["mobile"] == [""] && practitioner_params["telephone"] == [""]
    do
      conn
      |> put_flash(:error, "At least one contact number must be entered.")
      |> redirect(to: "/practitioners/#{practitioner.id}/edit?tab=contact")
    else
      edit_create_cp(conn, practitioner, practitioner_params)
    end
  end

  def create_cp(conn, practitioner, practitioner_params) do
    if practitioner.practitioner_contact do
        practitioner_contact = PractitionerContext.get_practitioner_contact(practitioner.practitioner_contact.id)
        PhoneContext.delete_phone(practitioner_contact.contact_id)
        EmailContext.delete_email(practitioner_contact.contact_id)
        PractitionerContext.delete_practitioner_contact(practitioner_contact.contact_id)
      case PractitionerContext.create_contact_practitioner(
        practitioner_params)
      do
        {:ok, contact} ->
          insert_practitioner_contact(
            practitioner, contact, practitioner_params)

          PractitionerContext.create_practitioner_contact(%{
              practitioner_id: practitioner.id,
              contact_id: contact.id
            })

          PractitionerContext.update_practitioner_step(
            practitioner.id, %{step: 3})

          conn
          |> put_flash(:info, "Contact updated successfully.")
          |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=3")

        {:error, %Ecto.Changeset{} = _changeset} ->
          changeset = PractitionerContext.change_practitioner(practitioner)
          contacts =
            PractitionerContext.get_practitioner_contacts(practitioner.id)
          conn
          |> put_flash(:error, "Error creating Contact! Please check the errors below.")
          |> render("new-contact.html",
              practitioner: practitioner, changeset: changeset,
              contacts: contacts)
      end
    else
      case PractitionerContext.create_contact_practitioner(
        practitioner_params)
      do
        {:ok, contact} ->
          insert_practitioner_contact(
            practitioner, contact, practitioner_params)

          PractitionerContext.update_step(
            practitioner.id, practitioner_params)

          practitioner_contact =
            PractitionerContext.create_practitioner_contact(%{
              practitioner_id: practitioner.id,
              contact_id: contact.id
            })

          phones = for phone <- practitioner_contact.contact.phones do
            {phone.number, phone.type}
          end
          emails = for email <- practitioner_contact.contact.emails do
            email.address
          end

          PractitionerContext.create_practitioner_contact_log(
            practitioner.id, {phones, emails}, conn.assigns.current_user)

          conn
          |> put_flash(:info, "Contact Updated successfully.")
          |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=3")

        {:error, %Ecto.Changeset{} = _changeset} ->
          conn
          |> put_flash(:error, "Error updating Practitioner Contact! Please check the errors below.")
          |> redirect(to: "/practitioners/#{practitioner.id}/setup?step=2")
      end
    end
  end

  def edit_create_cp(conn, practitioner, practitioner_params) do
    if practitioner.practitioner_contact do
        practitioner_contact = PractitionerContext.get_practitioner_contact(practitioner.practitioner_contact.id)
        PhoneContext.delete_phone(practitioner_contact.contact_id)
        EmailContext.delete_email(practitioner_contact.contact_id)
        PractitionerContext.delete_practitioner_contact(practitioner_contact.contact_id)

      case PractitionerContext.create_contact_practitioner(
        practitioner_params) do
        {:ok, contact} ->
          insert_practitioner_contact(
            practitioner, contact, practitioner_params)

          PractitionerContext.create_practitioner_contact(%{
              practitioner_id: practitioner.id,
              contact_id: contact.id
            })

          PractitionerContext.update_practitioner_step(
            practitioner.id, %{step: 3})

          conn
          |> put_flash(:info, "Contact updated successfully.")
          |> redirect(to: "/practitioners/#{practitioner.id}/edit?tab=contact")

        {:error, %Ecto.Changeset{} = _changeset} ->
          changeset = PractitionerContext.change_practitioner(practitioner)
          contacts =
            PractitionerContext.get_practitioner_contacts(practitioner.id)
          conn
          |> put_flash(:error, "Error creating Contact! Please check the errors below.")
          |> render("contact.html",
              practitioner: practitioner, changeset: changeset,
              contacts: contacts)
      end
    else
      case PractitionerContext.create_contact_practitioner(
        practitioner_params) do
        {:ok, contact} ->
          insert_practitioner_contact(
            practitioner, contact, practitioner_params)

          PractitionerContext.update_step(practitioner.id, practitioner_params)

          practitioner_contact =
            PractitionerContext.create_practitioner_contact(%{
              practitioner_id: practitioner.id,
              contact_id: contact.id
            })

          phones = for phone <- practitioner_contact.contact.phones do
            {phone.number, phone.type}
          end
          emails = for email <- practitioner_contact.contact.emails do
            email.address
          end

          PractitionerContext.create_practitioner_contact_log(
            practitioner.id, {phones, emails}, conn.assigns.current_user)

          conn
          |> put_flash(:info, "Contact Updated successfully.")
          |> redirect(to: "/practitioners/#{practitioner.id}/edit?tab=contact")

        {:error, %Ecto.Changeset{} = _changeset} ->
          conn
          |> put_flash(:error, "Error updating Practitioner Contact! Please check the errors below.")
          |> redirect(to: "/practitioners/#{practitioner.id}/edit?tab=contact")
      end
    end
  end

  def insert_practitioner_contact(practitioner, contact, practitioner_params) do
    Enum.each(["mobile", "telephone", "fax"], fn(param) ->
      case param do
        "mobile" ->
          area_code = ""
          local = ""
        "telephone" ->
          area_code = practitioner_params["tel_area_code"]
          local = practitioner_params["tel_local"]
        "fax" ->
          area_code = practitioner_params["fax_area_code"]
          local = practitioner_params["fax_local"]
      end
       new_insert_number(%{
         contact_id: contact.id,
         number: practitioner_params[param],
         type: param,
         area_code: area_code,
         local: local
       })
     end)

    Enum.each(["email"], fn(param) ->
      insert_email(%{
        contact_id: contact.id,
        address: practitioner_params[param],
        type: param
      })
    end
    )
  end
  ## here
  def edit_financial(conn, practitioner) do
    vat_statuses = DropdownContext.get_all_vat_status()
    banks =
      Bank
      |> Repo.all
      |> Enum.map(&{&1.account_name, &1.id})
    changeset = PractitionerContext.change_practitioner_financial(practitioner)
    render(conn, "edit/financial.html",
      practitioner: practitioner, changeset: changeset,
      banks: banks, vat_statuses: vat_statuses)
  end

  def update_edit_financial(conn, practitioner, practitioner_params) do
    vat_statuses = DropdownContext.get_all_vat_status()
    practitioner_params =
      practitioner_params
      |> Map.put("step", 5)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case PractitionerContext.create_practitioner_financial(
      practitioner.id, practitioner_params) do
      {:ok, updated_practitioner} ->
        PractitionerContext.create_practitioner_log(
          conn.assigns.current_user,
          Practitioner.changeset_financial(practitioner, practitioner_params),
          "Financial"
        )
        PractitionerContext.update_step(
          updated_practitioner.id, practitioner_params)
        conn
        |> put_flash(:info, "Financial updated successfully.")
        |> redirect(to: "/practitioners/#{practitioner.id}/edit?tab=financial")
      {:error, %Ecto.Changeset{} = changeset} ->
        banks =
          Bank
          |> Repo.all
          |> Enum.map(&{&1.account_name, &1.id})
        practitioner = PractitionerContext.get_practitioner(practitioner)
        render(conn, "edit/financial.html",
          practitioner: practitioner, changeset: changeset,
          banks: banks, vat_statuses: vat_statuses)
    end
  end

  def delete(conn, %{"id" => id}) do
    _practitioner = PractitionerContext.get_practitioner(id)
    {:ok, _practitioner} = PractitionerContext.delete_practitioner(id)
    conn
    |> put_flash(:info, "Practitioner deleted successfully.")
    |> redirect(to: practitioner_path(conn, :index))
  end

  #Print Practitioner Sumamry
  def print_summary(conn, %{"id" => id}) do
    practitioner = PractitionerContext.get_practitioner(id)

    html = View.render_to_string(PractitionerView,
                                         "print-summary.html",
                                         practitioner: practitioner)

    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{id}_#{unique_id}"

    with {:ok, content} <-
      PdfGenerator.generate_binary(
        html, filename: filename, delete_temporary: true)
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print Practitioner Profile.")
        |> redirect(to: "/practitioners/#{practitioner.id}/?active=profile")
    end
  end
  #End Print

  # Start of PractitionerFacility Primary Care / Specialist
  def create_pf_setup(conn, %{"id" => pf_id, "step" => step}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    if pf.step < String.to_integer(step) || pf.step == 6 do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: practitioner_path(conn, :show, practitioner, active: "affiliation"))
    else
      case step do
        "1" ->
          new_pf_step1(conn, pf)
        "2" ->
          new_pf_step2(conn, pf)
        "3" ->
          new_pf_step3(conn, pf)
        "4" ->
          new_pf_step4(conn, pf)
        "5" ->
          new_pf_step5(conn, pf)
        _ ->
          conn
          |> put_flash(:error, "Invalid step!")
          |> redirect(to: practitioner_path(
            conn, :show, practitioner, active: "affiliation"))
      end
    end
  end

  def create_pf_setup(conn, %{"id" => pf_id}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)

    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)

    conn
    |> put_flash(:error, "Invalid Page")
    |> show(%{"id" => practitioner.id, "active" => "profile"})
  end

  def update_pf_setup(conn, %{"id" => pf_id, "step" => step, "practitioner_facility" => params}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    case step do
      "1" ->
        update_pf_step1(conn, practitioner, params, pf)
      "2" ->
        update_pf_step2(conn, practitioner, params, pf)
      "3" ->
        update_pf_step3(conn, practitioner, params, pf)
    end

  end

  def new_pf(conn, %{"id" => practitioner_id}) do
    practitioner = PractitionerContext.get_practitioner(practitioner_id)
    changeset = PractitionerFacility.step1_changeset(%PractitionerFacility{})
    facilities = FacilityContext.get_facility_join_pf(practitioner_id)
    statuses = DropdownContext.get_all_practitioner_status()

    render(conn, "facility/step1.html",
           changeset: changeset,
           practitioner: practitioner,
           facilities: facilities,
           statuses: statuses)
  end

  def create_pf(conn, %{"practitioner_facility" => pf_params, "id" => practitioner_id}) do
    pf_params = translate_date_params_v2(pf_params)
    practitioner = PractitionerContext.get_practitioner(practitioner_id)
    changeset = PractitionerFacility.step1_changeset(%PractitionerFacility{})
    facilities = FacilityContext.get_facility_join_pf(practitioner_id)
    statuses = DropdownContext.get_all_practitioner_status()

    valid = true
    cond do
      is_nil(pf_params["types"]) ->
        _pf_params =
          pf_params
          |> Map.put("types", [])

          conn
          |> put_flash(:error, "Please select at least one practitioner type.")
          |> render("facility/step1.html",
                    changeset: changeset,
                    practitioner: practitioner,
                    facilities: facilities,
                    statuses: statuses)
      pf_params["affiliation_date"] != "" && pf_params["disaffiliation_date"] == "" ->
        _pf_params =
          pf_params
          |> Map.put("disaffiliation_date", nil)

          conn
          |> put_flash(:error, "Please enter disaffiliation date.")
          |> render("facility/step1.html",
                    changeset: changeset,
                    practitioner: practitioner,
                    facilities: facilities,
                    statuses: statuses)
      pf_params["disaffiliation_date"] != "" && pf_params["affiliation_date"] == "" ->
        _pf_params =
          pf_params
          |> Map.put("affiliation_date", nil)

        conn
        |> put_flash(:error, "Please enter affiliation date.")
        |> render("facility/step1.html",
                  changeset: changeset,
                  practitioner: practitioner,
                  facilities: facilities,
                  statuses: statuses)
        valid == true ->
        with {:ok, pf} <-
            PractitionerContext.create_practitioner_facility(
              pf_params, conn.assigns.current_user.id, practitioner),
             :ok <-
                PractitionerContext.insert_practitioner_facility_type(
                  pf_params["types"], pf)
        do
          conn
          |> put_flash(:info, "Successfully created general")
          |> redirect(to: "/practitioners/#{pf.id}/pf/create?step=2")
        else
          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error in creating general!")
            |> render("facility/step1.html",
                      changeset: changeset,
                      practitioner: practitioner,
                      facilities: facilities,
                      statuses: statuses)
        end
    end
  end

  defp new_pf_step1(conn, pf) do
    pf_step1(conn, pf, false)
  end

  defp pf_step1(conn, pf, edit) do
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    statuses = DropdownContext.get_all_practitioner_status()
    changeset = PractitionerFacility.changeset(pf)
    facilities = FacilityContext.get_facility_join_pf(pf.practitioner_id)
    facility = FacilityContext.get_facility!(pf.facility_id)
    # Join current facility to the facilities
    # not yet assigned to the practitioner
    final_facility_list = List.insert_at(facilities, 0, facility)

    path =
      if edit do
        "facility/edit/tab1.html"
      else
        "facility/step1_update.html"
      end
    render(conn, path,
           changeset: changeset,
           facilities: final_facility_list,
           statuses: statuses,
           practitioner: practitioner,
           practitioner_facility: pf)
  end

  defp new_pf_step2(conn, pf) do
    pf_step2(conn, pf, false)
  end

  defp pf_step2(conn, pf, edit) do
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    changeset = PractitionerFacility.changeset(pf)
    contacts = PractitionerContext.get_all_practitioner_facility_contacts(pf.id)

    path =
      if edit do
        "facility/edit/tab2.html"
      else
        "facility/step2.html"
      end
    render(conn, path,
           changeset: changeset,
           practitioner_facility: pf,
           practitioner: practitioner,
           contacts: contacts)
  end

  defp new_pf_step3(conn, pf) do
    pf_step3(conn, pf, false)
  end

  defp pf_step3(conn, pf, edit) do
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    changeset = PractitionerFacility.changeset(pf)
    cp_clearances = DropdownContext.get_all_cp_clearance()
    pf_rooms =
      PractitionerContext.get_practitioner_facility_rooms(
        pf.id, pf.facility.id)

    path =
      if edit do
        "facility/edit/tab3.html"
      else
        "facility/step3.html"
      end

    render(conn, path,
           changeset: changeset,
           practitioner_facility: pf,
           practitioner: practitioner,
           cp_clearances: cp_clearances,
           pf_rooms: pf_rooms)
  end

  defp new_pf_step4(conn, pf) do
    pf_step4(conn, pf, false)
  end

  defp pf_step4(conn, pf, edit) do
    changeset = PractitionerFacility.changeset(pf)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    schedules = PractitionerContext.get_practitioner_facility_schedules(pf.id)

    path =
      if edit do
        "facility/edit/tab4.html"
      else
        "facility/step4.html"
      end

    render(conn, path,
           changeset: changeset,
           practitioner: practitioner,
           practitioner_facility: pf,
           schedules: schedules)
  end

  defp update_pf_step1(conn, practitioner, params, pf) do
    update_pf_step1(conn, practitioner, params, pf, false)
  end

  defp update_pf_step1(conn, practitioner, params, pf, edit) do
    params = translate_date_params_v2(params)
    path_redirect =
      if edit do
        "/practitioners/#{pf.id}/pf/edit?tab=general"
      else
        "/practitioners/#{pf.id}/pf/create?step=2"
      end

    path_render =
      if edit do
        "facility/edit/tab1.html"
      else
        "facility/step1_update.html"
      end

    changeset = PractitionerFacility.changeset(pf)
    statuses = DropdownContext.get_all_practitioner_status()
    facilities = FacilityContext.get_facility_join_pf(pf.practitioner_id)
    facility = FacilityContext.get_facility!(pf.facility_id)
    # Join current facility to the facilities
    # not yet assigned to the practitioner
    final_facility_list = List.insert_at(facilities, 0, facility)

    valid = true
      cond do
        is_nil(params["types"]) ->
          pf =
            pf
            |> Map.put(:practitioner_facility_practitioner_types, [])

            conn
            |> put_flash(:error, "Please select at least one practitioner type.")
            |> render(path_render,
                      changeset: changeset,
                      facilities: final_facility_list,
                      statuses: statuses,
                      practitioner: practitioner,
                      practitioner_facility: pf)
        params["affiliation_date"] != "" && params["disaffiliation_date"] == "" ->
          pf =
            pf
            |> Map.put(:disaffiliation_date, nil)

            conn
            |> put_flash(:error, "Please enter disaffiliation date.")
            |> render(path_render,
                      changeset: changeset,
                      facilities: final_facility_list,
                      statuses: statuses,
                      practitioner: practitioner,
                      practitioner_facility: pf)
        params["disaffiliation_date"] != "" && params["affiliation_date"] == "" ->
          pf =
            pf
            |> Map.put(:affiliation_date, nil)

          conn
          |> put_flash(:error, "Please enter affiliation date.")
          |> render(path_render,
                    changeset: changeset,
                    facilities: final_facility_list,
                    statuses: statuses,
                    practitioner: practitioner,
                    practitioner_facility: pf)
        valid == true ->
        with {:ok, practitioner_facility} <-
          PractitionerContext.update_practitioner_facility_step1(
            conn.assigns.current_user.id, params, pf, practitioner),
             {_, _del_pfpt} <-
              PractitionerContext.delete_practitioner_facility_type(
                practitioner_facility.id),
             :ok <- Enum.each(params["types"], fn(type) ->
               PractitionerContext.create_practitioner_facility_type(%{
                 practitioner_facility_id: practitioner_facility.id,
                 type: type
               })
             end)
           do

    types =
      for type <-
        practitioner_facility.practitioner_facility_practitioner_types
      do
        {type.type}
      end

    PractitionerContext.create_affiliation_type_log(
      practitioner_facility.id, {types}, conn.assigns.current_user,
        "Primary Care/Specialist", "General")

        if edit do
          PractitionerContext.create_affiliation_log(
            conn.assigns.current_user,
            PractitionerFacility.step1_changeset(pf, params),
            practitioner.id,
            "General",
            "Primary Care/Specialist"
          )
        end

           conn
           |> put_flash(:info, "Successfully updated general step.")
           |> redirect(to: path_redirect)
        else
          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error in updating general!")
            |> render(path_render,
                      changeset: changeset,
                      facilities: final_facility_list,
                      statuses: statuses,
                      practitioner: practitioner,
                      practitioner_facility: pf)
           end
      end
  end

  defp update_pf_step2(conn, practitioner, params, pf) do
    update_pf_step2(conn, practitioner, params, pf, false)
  end

  defp pf_path_redirect(pf_id, edit) when edit, do: "/practitioners/#{pf_id}/pf/edit?tab=contacts"
  defp pf_path_redirect(pf_id, edit), do: "/practitioners/#{pf_id}/pf/create?step=3"

  defp pf_path_render(edit) when edit, do: "facility/edit/tab2.html"
  defp pf_path_render(edit), do: "facility/step2.html"

  defp update_pf_step2(conn, practitioner, contact_params, pf, edit) do
    path_redirect = pf_path_redirect(pf.id, edit)
    path_render = pf_path_render(edit)

    if contact_params["email"] == [""] &&
       contact_params["fax"] == [""] &&
       contact_params["mobile"] == [""] &&
       contact_params["telephone"] == [""]
    do
        changeset = PractitionerFacility.changeset(pf)
        conn
        |> put_flash(:error, "At least one contact number must be entered.")
        |> render(
            path_render,
            changeset: changeset,
            practitioner_facility: pf,
            practitioner: practitioner,
            contacts: [])
    else
      if is_nil(contact_params["contact_id"]) do
        with {:ok, contact} <- ContactContext.create_pfcontact(contact_params),
             :ok <- Enum.each(["mobile", "telephone", "fax"], fn(param) ->
                      case param do
                        "mobile" ->
                          area_code = ""
                          local = ""
                        "telephone" ->
                          area_code = contact_params["tel_area_code"]
                          local = contact_params["tel_local"]
                        "fax" ->
                          area_code = contact_params["fax_area_code"]
                          local = contact_params["fax_local"]
                      end
                      new_insert_number(%{
                        contact_id: contact.id,
                        number: contact_params[param],
                        type: param,
                        area_code: area_code,
                        local: local
                      })
                    end),
             :ok <- Enum.each(["email"], fn(param) ->
                      insert_email(%{
                       contact_id: contact.id,
                       address: contact_params[param],
                       type: param
                      })
                    end),
             {:ok, _ptc} <-
                    PractitionerContext.create_practitioner_facility_contact(%{
                     "practitioner_facility_id" => pf.id,
                     "contact_id" => contact.id
                    })
        do
          if edit do
            PractitionerContext.update_step_pf(
              pf,
              %{updated_by: conn.assigns.current_user.id}
            )
          else
            PractitionerContext.update_step_pf(
              pf,
              %{step: 3, updated_by: conn.assigns.current_user.id}
            )
          end

          conn
          |> put_flash(:info, "Successfully updated contact")
          |> redirect(to: path_redirect)
        else
          {:error, changeset} ->
            contacts =
              PractitionerContext.get_all_practitioner_facility_contacts(pf.id)

            conn
            |> put_flash(:error, "Error creating contact! Please check the errors below.")
            |> render(path_render,
                      changeset: changeset,
                      practitioner_facility: pf,
                      practitioner: practitioner,
                      contacts: contacts)
        end
      else
        contact = ContactContext.get_contact!(contact_params["contact_id"])
        with {:ok, contact} <-
          ContactContext.update_pfcontact(contact, contact_params),
             {_, _del_phone} <- PhoneContext.delete_phone(contact.id),
             :ok <- Enum.each(["mobile", "telephone", "fax"], fn(param) ->
                      case param do
                        "mobile" ->
                          area_code = ""
                          local = ""
                        "telephone" ->
                          area_code = contact_params["tel_area_code"]
                          local = contact_params["tel_local"]
                        "fax" ->
                          area_code = contact_params["fax_area_code"]
                          local = contact_params["fax_local"]
                      end
                      new_insert_number(%{
                        contact_id: contact.id,
                        number: contact_params[param],
                        type: param,
                        area_code: area_code,
                        local: local
                      })
                    end),
             {_, _del_email} <- EmailContext.delete_email(contact.id),
             :ok <- Enum.each(["email"], fn(param) ->
                     insert_email(%{
                       contact_id: contact.id,
                       address: contact_params[param],
                       type: param
                     })
                    end)
        do
          if edit do
            PractitionerContext.update_step_pf(
              pf,
              %{updated_by: conn.assigns.current_user.id}
            )
          else
            PractitionerContext.update_step_pf(
              pf,
              %{step: 3, updated_by: conn.assigns.current_user.id}
            )
          end

          phones = for phone <- contact.phones do
            {phone.number, phone.type}
          end
          emails = for email <- contact.emails do
            email.address
          end

          log_parameters = %{
            practitioner_id: practitioner.id,
            contact_id: contact.id,
            old_contacts: {phones, emails},
            current_user: conn.assigns.current_user,
            affiliation: "Primary Care/Specialist",
            tab: "Contact"
          }
          PractitionerContext.create_affiliation_contact_log(log_parameters)
          # PractitionerContext.create_affiliation_contact_log(
          #   practitioner.id, contact.id, {phones, emails},
          #     conn.assigns.current_user, "Primary Care/Specialist", "Contact")

          conn
          |> put_flash(:info, "Contact updated successfully.")
          |> redirect(to: path_redirect)
        else
          {:error, changeset} ->
            contacts =
              PractitionerContext.get_all_practitioner_facility_contacts(pf.id)

            conn
            |> put_flash(:error, "Error updating contact! Please check the errors below.")
            |> render(path_render,
                      changeset: changeset,
                      practitioner_facility: pf,
                      practitioner: practitioner,
                      contacts: contacts)
        end
      end
    end
  end

  defp update_pf_step3(conn, practitioner, params, pf) do
    update_pf_step3(conn, practitioner, params, pf, false)
  end

  defp update_pf_step3(conn, practitioner, params, pf, edit) do

    path_redirect =
      if edit do
        "/practitioners/#{pf.id}/pf/edit?tab=rates"
      else
        "/practitioners/#{pf.id}/pf/create?step=4"
      end

    path_render =
      if edit do
        "facility/edit/tab3.html"
      else
        "facility/step3.html"
      end

    with {:ok, _practitioner_facility} <-
      PractitionerContext.update_practitioner_facility_step3(
        params, pf, conn.assigns.current_user.id, practitioner, edit) do

      if edit do
        PractitionerContext.create_affiliation_log(
          conn.assigns.current_user,
          PractitionerFacility.step3_changeset(pf, params),
          practitioner.id,
          "Rates",
          "Primary Care/Specialist"
        )
      end

      conn
      |> put_flash(:info, "Updated Rates!")
      |> redirect(to: path_redirect)

    else
      {:error, changeset} ->
        cp_clearances = DropdownContext.get_all_cp_clearance()
        pf_rooms =
          PractitionerContext.get_practitioner_facility_rooms(
            pf.id, pf.facility.id)

        conn
        |> put_flash(:error, "Error encountered upon saving rates.")
        |> render(path_render,
                  changeset: changeset,
                  practitioner_facility: pf,
                  practitioner: practitioner,
                  cp_clearances: cp_clearances,
                  pf_rooms: pf_rooms)
    end
  end

  def create_pf_schedule(conn, %{"id" => pf_id, "practitioner_facility" => pf_params}) do
    create_pf_schedule(conn, pf_id, pf_params, false)
  end

  defp create_pf_schedule(conn, pf_id, pf_params, edit) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    schedules = PractitionerContext.get_practitioner_facility_schedules(pf.id)

    path =
      if edit do
        "/practitioners/#{pf.id}/pf/edit?tab=schedule"
      else
        "/practitioners/#{pf.id}/pf/create?step=4"
      end

    rooms =
      pf_params["room"]
      |>  Enum.filter(fn({_day, val}) -> val != "" end)
      |>  Enum.map(fn({day, val}) -> {day, val} end)

    not_inserted = for {day, _val} <- rooms do
      time_from = String.split(pf_params["time_from"][day], ":")
      time_to = String.split(pf_params["time_to"][day], ":")
      pf_sched_params = %{
        day: day,
        room: pf_params["room"][day],
        time_from: Ecto.Time.cast!(%{
          hour: Enum.at(time_from, 0),
          minute: Enum.at(time_from, 1)
        }),
        time_to: Ecto.Time.cast!(%{
          hour: Enum.at(time_to, 0),
          minute: Enum.at(time_to, 1)
        }),
        practitioner_facility_id: pf.id
      }

      map = Enum.map schedules, fn schedule ->
        if pf_sched_params.day == schedule.day do
          if (pf_sched_params.time_from > schedule.time_from &&
              pf_sched_params.time_from < schedule.time_to) ||
            (pf_sched_params.time_to > schedule.time_from &&
              pf_sched_params.time_to < schedule.time_to) ||
              (pf_sched_params.time_from == schedule.time_from ||
                pf_sched_params.time_to == schedule.time_to) do
            pf_sched_params
          end
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pf_sched_params.day
          end
      end)

      if length(map) == 0 do
        affi_sched_log_params = %{
          user: conn.assigns.current_user,
          action: "added",
          params: pf_sched_params,
          practitioner_id: pf.practitioner_id,
          tab: "Schedule",
          affiliation: "Primary Care/Specialist"
        }
        PractitionerContext.create_affiliation_schedule_log(affi_sched_log_params)
    # PractitionerContext.create_affiliation_schedule_log(
    #    conn.assigns.current_user,
    #    "added",
    #    pf_sched_params,
    #    pf.practitioner_id,
    #    "Schedule",
    #    "Primary Care/Specialist"
    #  )
        PractitionerContext.create_practitioner_facility_schedule(
          pf_sched_params)
        _not_inserted = []
     else
        Enum.map [map], fn val ->
          if not is_nil(val) do
            pf_sched_params
          end
        end
      end
    end

    if length(not_inserted) == 0 || not_inserted == [[]] do
      conn
      |> put_flash(:info, "Schedule added successfully")
      |> redirect(to: path)
    else
      conn
      |> put_flash(:error, "Some/All of the entered schedule already exists")
      |> redirect(to: path)
    end

  end

  def update_pf_schedule(conn, %{"id" => pf_id, "practitioner_facility" => schedule_params}) do
    update_pf_schedule(conn, pf_id, schedule_params, false)
  end

  defp update_pf_schedule(conn, pf_id, schedule_params, edit) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    schedules =
      pf.id
      |> PractitionerContext.get_practitioner_facility_schedules()
      |> Enum.filter(fn val ->
        val.day == schedule_params["day"] && schedule_params["schedule_id"] != val.id
      end)

    path =
      if edit do
        "/practitioners/#{pf.id}/pf/edit?tab=schedule"
      else
        "/practitioners/#{pf.id}/pf/create?step=4"
      end

    ps =
      PractitionerContext.get_practitioner_facility_schedule(
        schedule_params["schedule_id"])

    time_from = String.split(schedule_params["time_from"], ":")
    time_to = String.split(schedule_params["time_to"], ":")

    pf_sched_params = %{
      day: schedule_params["day"],
      room: schedule_params["room"],
      time_from: Ecto.Time.cast!(%{
        hour: Enum.at(time_from, 0),
        minute: Enum.at(time_from, 1)
      }),
      time_to: Ecto.Time.cast!(%{
        hour: Enum.at(time_to, 0),
        minute: Enum.at(time_to, 1)
      }),
      practitioner_facility_id: pf.id,
      id: schedule_params["schedule_id"]
    }

    if pf_sched_params.time_from < pf_sched_params.time_to do
      map = Enum.map schedules, fn schedule ->
        if pf_sched_params.time_from > schedule.time_from &&
            pf_sched_params.time_from < schedule.time_to do
          pf_sched_params
        else
          if pf_sched_params.time_to > schedule.time_from &&
            pf_sched_params.time_to < schedule.time_to do
            pf_sched_params
          end
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pf_sched_params.day
          end
        end)

        if length(map) == 0 do
          PractitionerContext.update_practitioner_facility_schedule(
            pf_sched_params, ps)

          PractitionerContext.create_affiliation_log(
            conn.assigns.current_user,
            PractitionerSchedule.changeset_pf(ps, pf_sched_params),
            pf.practitioner_id,
            "Schedule",
            "Primary Care/Specialist")
          not_updated = []
        else
          not_updated = Enum.map [map], fn val ->
            if not is_nil(val) do
              pf_sched_params
            end
          end
        end

        type =
          if length(not_updated) == 0 do
            :info
          else
            :error
          end

        msg =
          if length(not_updated) == 0 do
            "Schedule updated successfully"
          else
            "Schedule already exists"
          end

        conn
        |> put_flash(type, msg)
        |> redirect(to: path)
    else
        conn
        |> put_flash(:error, "Time To must be greater than Time From")
        |> redirect(to: path)
    end
  end

  def next_pf_schedule(conn, %{"id" => id}) do
    practitioner_facility = PractitionerContext.get_practitioner_facility(id)
    _schedules =
      PractitionerContext.get_practitioner_facility_schedules(
        practitioner_facility.id)

    # with false <- length(schedules) == 0
    # do
    if practitioner_facility.step == 4 do
      PractitionerContext.update_step_pf(
        practitioner_facility,
        %{step: 5, updated_by: conn.assigns.current_user.id}
      )
    end

    conn
    |> redirect(to: "/practitioners/#{practitioner_facility.id}/pf/create?step=5")
    # else
    #   true ->
    #     changeset = PractitionerFacility.changeset(practitioner_facility)
    #     practitioner =
    # PractitionerContext.
    # get_practitioner(practitioner_facility.practitioner_id)
    #     schedules =
    # PractitionerContext.
    # get_practitioner_facility_schedules(practitioner_facility.id)

    #     conn
    #     |> put_flash(:error, "At least one schedule must be entered.")
    #     |> render("facility/step4.html",
    #               changeset: changeset,
    #               practitioner: practitioner,
    #               practitioner_facility: practitioner_facility,
    #               schedules: schedules)
    # end
  end

  def delete_pf_schedule(conn, %{"id" => ps_id}) do
    delete_pf_schedule(conn, ps_id, false)
  end

  defp delete_pf_schedule(conn, ps_id, edit) do
    schedule = PractitionerContext.get_practitioner_facility_schedule(ps_id)
    pf =
      PractitionerContext.get_practitioner_facility(
        schedule.practitioner_facility_id)
    PractitionerContext.delete_practitioner_facility_schedule(schedule.id)

    path =
      if edit do
        "/practitioners/#{pf.id}/pf/edit?tab=schedule"
      else
        "/practitioners/#{pf.id}/pf/create?step=4"
      end

    affi_sched_log_params = %{
      user: conn.assigns.current_user,
      action: "deleted",
      params: schedule,
      practitioner_id: pf.practitioner_id,
      tab: "Schedule",
      affiliation: "Primary Care/Specialist"
    }
    PractitionerContext.create_affiliation_schedule_log(affi_sched_log_params)
    # PractitionerContext.create_affiliation_schedule_log(
    #    conn.assigns.current_user,
    #    "deleted",
    #    schedule,
    #    pf.practitioner_id,
    #    "Schedule",
    #    "Primary Care/Specialist"
    #  )

    conn
    |> put_flash(:info, "Schedule deleted successfully.")
    |> redirect(to: path)
  end

  defp new_pf_step5(conn, pf) do
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)

    render(conn, "facility/step5.html",
           practitioner_facility: pf,
           practitioner: practitioner)
  end

  def pf_summary(conn, %{"id" => id}) do
    practitioner_facility = PractitionerContext.get_practitioner_facility(id)
    practitioner =
      PractitionerContext.get_practitioner(
        practitioner_facility.practitioner_id)

    if practitioner_facility.step == 5 do
      PractitionerContext.update_step_pf(
        practitioner_facility,
        %{step: 6, updated_by: conn.assigns.current_user.id}
      )
    end

    PractitionerContext.create_added_facility_affiliation_log(
      conn.assigns.current_user,
      practitioner_facility.facility,
      practitioner.id
    )
    conn
    |> put_flash(:info, "Affiliation created successfully.")
    |> redirect(to: "/practitioners/#{practitioner_facility.id}/pf/submitted")
  end

  def pa_summary(conn, %{"id" => id}) do
    practitioner_account =
      PractitionerContext.get_practitioner_account_by_practitioner_id(id)
    practitioner = PractitionerContext.get_practitioner(id)

    PractitionerContext.create_added_account_affiliation_log(
      conn.assigns.current_user,
      practitioner_account.account_group,
      practitioner.id)
    conn
    |> put_flash(:info, "Affiliation created successfully.")
    |> redirect(to: "/practitioners/#{practitioner.id}?active=affiliation")
  end

  def pf_submitted(conn, %{"id" => pf_id}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)

    render(conn, "facility/submitted.html",
           practitioner_facility: pf,
           practitioner: practitioner)
  end

  # Start of Print Summary
  def print_pf_summary(conn, %{"id" => pf_id}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)

    html = View.render_to_string(PractitionerView,
                                         "facility/print_summary.html",
                                         practitioner_facility: pf,
                                         practitioner: practitioner)

    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{pf.id}_#{unique_id}"

    with {:ok, content} <-
      PdfGenerator.generate_binary(
        html, filename: filename, delete_temporary: true)
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print facility.")
        |> redirect(to: "/practitioners/#{pf_id}/pf/submitted")
    end
  end
  # End of Print Summary

  # Start of Delete PF
  def pf_delete(conn, %{"id" => pf_id}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    PractitionerContext.delete_practitioner_facility(pf_id)

    conn
    |> put_flash(:info, "Primary Care/Specialist deleted successfully.")
    |> redirect(to: "/practitioners/#{practitioner.id}?active=affiliation")
  end
  # End of Delete PF

  def edit_pf_setup(conn, %{"id" => pf_id, "tab" => tab}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)
    case tab do
      "general" ->
        edit_pf_tab1(conn, pf)
      "contacts" ->
        edit_pf_tab2(conn, pf)
      "rates" ->
        edit_pf_tab3(conn, pf)
      "schedule" ->
        edit_pf_tab4(conn, pf)
    end
  end

  def edit_pf_setup(conn, %{"id" => pf_id}) do
    pf = PractitionerContext.get_practitioner_facility(pf_id)

    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)

    conn
    |> put_flash(:error, "Invalid Page")
    |> show(%{"id" => practitioner.id, "active" => "profile"})
  end


  def update_edit_pf_setup(conn, %{"id" => id, "tab" => tab, "practitioner_facility" => pf_params}) do
    pf = PractitionerContext.get_practitioner_facility(id)
    practitioner = PractitionerContext.get_practitioner(pf.practitioner_id)
    case tab do
      "general" ->
        update_edit_pf_tab1(conn, practitioner, pf_params, pf)
      "contacts" ->
        update_edit_pf_tab2(conn, practitioner, pf_params, pf)
      "rates" ->
        update_edit_pf_tab3(conn, practitioner, pf_params, pf)
    end
  end

  defp edit_pf_tab1(conn, pf) do
    pf_step1(conn, pf, true)
  end

  defp edit_pf_tab2(conn, pf) do
    pf_step2(conn, pf, true)
  end

  defp edit_pf_tab3(conn, pf) do
    pf_step3(conn, pf, true)
  end

  defp edit_pf_tab4(conn, pf) do
    pf_step4(conn, pf, true)
  end

  defp update_edit_pf_tab1(conn, practitioner, params, pf) do
    update_pf_step1(conn, practitioner, params, pf, true)
  end

  defp update_edit_pf_tab2(conn, practitioner, params, pf) do
    update_pf_step2(conn, practitioner, params, pf, true)
  end

  defp update_edit_pf_tab3(conn, practitioner, params, pf) do
    update_pf_step3(conn, practitioner, params, pf, true)
  end

  def edit_create_pf_schedule(conn, %{"id" => pf_id, "practitioner_facility" => pf_params}) do
    create_pf_schedule(conn, pf_id, pf_params, true)
  end

  def edit_update_pf_schedule(conn, %{"id" => pf_id, "practitioner_facility" => schedule_params}) do
    update_pf_schedule(conn, pf_id, schedule_params, true)
  end

  def edit_delete_pf_schedule(conn, %{"id" => ps_id}) do
    delete_pf_schedule(conn, ps_id, true)
  end
  # End of Practitioner Facility Primary Care / Specialist

  # Start of PractitionerAccount
  def create_pa_setup(conn, %{"id" => id, "step" => step}) do
    pa = PractitionerContext.get_practitioner_account(id)
    case step do
      "1" ->
        pa_step1(conn, pa)
      "2" ->
        pa_step2(conn, pa)
       "3" ->
        pa_step3(conn, pa)
    end
  end

  def update_pa_setup(conn, %{"id" => id, "step" => step, "practitioner_account" => params}) do
    pa = PractitionerContext.get_practitioner_account(id)
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    case step do
      "1" ->
        update_pa_step1(conn, practitioner, params, pa)
      "2" ->
        update_pa_step2(conn, practitioner, params, pa)
    end
  end

  def edit_pa_setup(conn, %{"id" => id, "tab" => tab}) do
    pa = PractitionerContext.get_practitioner_account(id)
    case tab do
      "general" ->
        edit_pa_general(conn, pa)
      "schedule" ->
        edit_pa_schedule(conn, pa)
    end
  end

  def update_edit_pa_setup(conn, %{"id" => id, "tab" => tab, "practitioner_account" => params}) do
    pa = PractitionerContext.get_practitioner_account(id)
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    case tab do
      "general" ->
        update_edit_pa_general(conn, practitioner, params, pa)
      "schedule" ->
        update_edit_pa_schedule(conn, practitioner, params, pa)
    end
  end

  def new_pa(conn, %{"id" => id}) do
    practitioner = PractitionerContext.get_practitioner(id)
    changeset = PractitionerAccount.changeset(%PractitionerAccount{})
    accounts = PractitionerContext.list_all_accounts_in_practitioner()
    render conn, "account_group/step1.html", changeset: changeset,
      practitioner: practitioner, accounts: accounts
  end

  defp pa_step1(conn, pa) do
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    changeset = PractitionerAccount.changeset(pa)
    accounts = PractitionerContext.list_all_accounts_in_practitioner()
    render conn, "account_group/step1_update.html", changeset: changeset,
      practitioner: practitioner, accounts: accounts, practitioner_account: pa
  end

  defp pa_step2(conn, pa) do
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    schedules = PractitionerContext.get_practitioner_account_schedules(pa.id)
    changeset = PractitionerAccount.changeset(pa)
    render conn, "account_group/step2.html", changeset: changeset,
      practitioner_account: pa, practitioner: practitioner, schedules: schedules
  end

  defp pa_step3(conn, pa) do
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    schedules = PractitionerContext.get_practitioner_account_schedules(pa.id)
    changeset = PractitionerAccount.changeset(pa)
    render conn, "account_group/step3.html", changeset: changeset,
      practitioner_account: pa, practitioner: practitioner, schedules: schedules
  end

  defp edit_pa_general(conn, pa) do
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    changeset = PractitionerAccount.changeset(pa)
    accounts =
      AccountGroup
      |> Repo.all
      |> Enum.map(&{&1.name, &1.id})
    render conn, "account_group/edit/general.html",
      changeset: changeset, practitioner: practitioner,
        accounts: accounts, practitioner_account: pa
  end

  defp edit_pa_schedule(conn, pa) do
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    schedules = PractitionerContext.get_practitioner_account_schedules(pa.id)
    changeset = PractitionerAccount.changeset(pa)
    render conn, "account_group/edit/schedule.html", changeset: changeset,
      practitioner_account: pa, practitioner: practitioner, schedules: schedules
  end

  def create_pa(conn, %{"practitioner_account" => params, "id" => practitioner_id}) do
    practitioner = PractitionerContext.get_practitioner(practitioner_id)
    if params["email"] == [""] && params["fax"] == [""] &&
        params["mobile"] == [""] && params["telephone"] == [""] do
      conn
      |> put_flash(:error, "At least one contact number must be entered.")
      |> redirect(to: "/practitioners/#{practitioner.id}/pa/new")

    else

      case PractitionerContext.create_practitioner_account(
        %{practitioner_id: practitioner.id, account_group_id: params["account_group_id"]})
      do
        {:ok, practitioner_account} ->

        {:ok, contact} =
          PractitionerContext.create_contact_practitioner(params)
        Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          insert_number(%{
            contact_id: contact.id,
            number: params[param],
            type: param
          })
        end
        )
        Enum.each(["email"], fn(param) ->
          insert_email(%{
            contact_id: contact.id,
            address: params[param],
            type: param
          })
        end
        )
        practitioner_account =
          PractitionerContext.get_practitioner_account(practitioner_account.id)

        PractitionerContext.create_practitioner_account_contact(%{
          practitioner_account_id: practitioner_account.id,
          contact_id: contact.id,
        })

        conn
        |> redirect(to: "/practitioners/#{practitioner_account.id}/pa/create?step=2")
        {:error, %Ecto.Changeset{} = changeset} ->
          accounts = PractitionerContext.list_all_accounts_in_practitioner()
            conn
            |> put_flash(:info, "Account already selected.")
            |> render("account_group/step1.html",
                changeset: changeset, practitioner: practitioner,
                accounts: accounts)
      end
    end
  end

  defp update_pa_step1(conn, practitioner, params, pa) do
    params =
      params
      |> Map.put("practitioner_id", practitioner.id)

    if params["email"] == [""] && params["fax"] == [""] &&
        params["mobile"] == [""] && params["telephone"] == [""] do
      conn
      |> put_flash(:error, "At least one contact number must be entered.")
      |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=1")

    else

      case PractitionerContext.update_practitioner_account(params, pa) do
        {:ok, practitioner_account} ->
          practitioner_account_contact =
            PractitionerContext.get_practitioner_account_contact(
              practitioner_account.practitioner_account_contact.id)
          PhoneContext.delete_phone(practitioner_account_contact.contact_id)
          EmailContext.delete_email(practitioner_account_contact.contact_id)
          PractitionerContext.delete_practitioner_account_contact(
            practitioner_account_contact.contact_id)

          {:ok, contact} =
            PractitionerContext.create_contact_practitioner(params)

        Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          insert_number(%{
            contact_id: contact.id,
            number: params[param],
            type: param
          })
        end
        )
        Enum.each(["email"], fn(param) ->
          insert_email(%{
            contact_id: contact.id,
            address: params[param],
            type: param
          })
        end
        )

        PractitionerContext.create_practitioner_account_contact(%{
          practitioner_account_id: practitioner_account.id,
          contact_id: contact.id,
        })
        conn
        |> redirect(to: "/practitioners/#{practitioner_account.id}/pa/create?step=2")
        {:error, %Ecto.Changeset{} = changeset} ->
          accounts = PractitionerContext.list_all_accounts_in_practitioner()
            conn
            |> put_flash(:info, "Account already selected.")
            |> render("account_group/edit/general.html",
                changeset: changeset, practitioner: practitioner,
                practitioner_account: pa, accounts: accounts)
      end
    end
  end

  defp update_pa_step2(conn, _practitioner, params, pa) do
    schedules = PractitionerContext.get_practitioner_account_schedules(pa.id)
    rooms =
      params["room"]
      |>  Enum.filter(fn({_day, val}) -> val != "" end)
      |>  Enum.map(fn({day, val}) -> {day, val} end)

    not_inserted = for {day, _val} <- rooms do
      time_from = String.split(params["time_from"][day], ":")
      time_to = String.split(params["time_to"][day], ":")
      pa_sched_params = %{
        day: day,
        room: params["room"][day],
        time_from: Ecto.Time.cast!(%{
          hour: Enum.at(time_from, 0),
          minute: Enum.at(time_from, 1)
        }),
        time_to: Ecto.Time.cast!(%{
          hour: Enum.at(time_to, 0),
          minute: Enum.at(time_to, 1)
        }),
        practitioner_account_id: pa.id
      }

      map = Enum.map schedules, fn schedule ->
        if pa_sched_params.day == schedule.day do
          if (pa_sched_params.time_from > schedule.time_from &&
              pa_sched_params.time_from < schedule.time_to) ||
            (pa_sched_params.time_to > schedule.time_from &&
              pa_sched_params.time_to < schedule.time_to) ||
            (pa_sched_params.time_from == schedule.time_from ||
              pa_sched_params.time_to == schedule.time_to) do
            pa_sched_params
          end
          if (pa_sched_params.time_from < schedule.time_from &&
              pa_sched_params.time_to > schedule.time_to) ||
            (pa_sched_params.time_from < schedule.time_to &&
              pa_sched_params.time_to > schedule.time_to) ||
            (pa_sched_params.time_from < schedule.time_from &&
              pa_sched_params.time_to > schedule.time_from) do
            conn
            |> put_flash(:error, "Schedule is invalid!")
            |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
          end
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pa_sched_params.day
          end
      end)

      if length(map) == 0 do
        PractitionerContext.create_practitioner_account_schedule(
          pa_sched_params)
        not_inserted = []
      else
        Enum.map [map], fn val ->
          if not is_nil(val) do
            pa_sched_params
          end
        end
      end
    end

    if length(not_inserted) == 0 || not_inserted == [[]] do
      conn
      |> put_flash(:info, "Schedule added successfully")
      |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
    else
      conn
      |> put_flash(:error, "Some/All of the entered schedule already exists")
      |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
    end
  end

  def update_pa_schedule(conn, %{"id" => practitioner_account_id, "step" => _step, "practitioner_account" => params}) do
    pa = PractitionerContext.get_practitioner_account(practitioner_account_id)
    schedules =
      pa.id
      |> PractitionerContext.get_practitioner_account_schedules()
      |> Enum.filter(fn val ->
        val.day == params["day"] && params["schedule_id"] != val.id
      end)
    pa_schedule =
      PractitionerContext.get_practitioner_account_schedule(params["schedule_id"])

    time_from = String.split(params["time_from"], ":")
    time_to = String.split(params["time_to"], ":")

    pa_sched_params = %{
      day: params["day"],
      room: params["room"],
      time_from: Ecto.Time.cast!(%{
        hour: Enum.at(time_from, 0),
        minute: Enum.at(time_from, 1)
      }),
      time_to: Ecto.Time.cast!(%{
        hour: Enum.at(time_to, 0),
        minute: Enum.at(time_to, 1)
      }),
      practitioner_account_id: pa.id,
      id: params["schedule_id"]
    }

    if pa_sched_params.time_from < pa_sched_params.time_to do
      map = Enum.map schedules, fn schedule ->
        if pa_sched_params.time_from > schedule.time_from &&
          pa_sched_params.time_from < schedule.time_to do
          pa_sched_params
        else
          if pa_sched_params.time_to > schedule.time_from &&
            pa_sched_params.time_to < schedule.time_to do
            pa_sched_params
          end
        end
        if (pa_sched_params.time_from < schedule.time_from &&
            pa_sched_params.time_to > schedule.time_to) ||
           (pa_sched_params.time_from < schedule.time_to &&
            pa_sched_params.time_to > schedule.time_to) ||
           (pa_sched_params.time_from < schedule.time_from &&
            pa_sched_params.time_to > schedule.time_from) do
             conn
             |> put_flash(:error, "Schedule is invalid!")
             |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pa_sched_params.day
          end
        end)

        if length(map) == 0 do
          PractitionerContext.update_practitioner_account_schedule(
            pa_schedule, pa_sched_params)
          not_updated = []
        else
          not_updated = Enum.map [map], fn val ->
            if not is_nil(val) do
              pa_sched_params
            end
          end
        end

        type =
          if length(not_updated) == 0 do
            :info
          else
            :error
          end

        msg =
          if length(not_updated) == 0 do
            "Schedule updated successfully"
          else
            "Schedule already exists"
          end

        conn
        |> put_flash(type, msg)
        |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
    else
        conn
        |> put_flash(:error, "Time To must be greater than Time From")
        |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
    end
  end

  def update_edit_pa_schedule_modal(conn, %{"id" => practitioner_account_id, "tab" => _tab, "practitioner_account" => params}) do
    pa = PractitionerContext.get_practitioner_account(practitioner_account_id)
    schedules =
      pa.id
      |> PractitionerContext.get_practitioner_account_schedules()
      |> Enum.filter(fn val ->
        val.day == params["day"] && params["schedule_id"] != val.id
      end)
    pa_schedule =
      PractitionerContext.get_practitioner_account_schedule(
        params["schedule_id"])

    time_from = String.split(params["time_from"], ":")
    time_to = String.split(params["time_to"], ":")

    pa_sched_params = %{
      day: params["day"],
      room: params["room"],
      time_from: Ecto.Time.cast!(%{
        hour: Enum.at(time_from, 0),
        minute: Enum.at(time_from, 1)
      }),
      time_to: Ecto.Time.cast!(%{
        hour: Enum.at(time_to, 0),
        minute: Enum.at(time_to, 1)
      }),
      practitioner_account_id: pa.id,
      id: params["schedule_id"]
    }

    if pa_sched_params.time_from < pa_sched_params.time_to do
      map = Enum.map schedules, fn schedule ->
        if pa_sched_params.time_from > schedule.time_from &&
            pa_sched_params.time_from < schedule.time_to do
          pa_sched_params
        else
          if pa_sched_params.time_to > schedule.time_from &&
            pa_sched_params.time_to < schedule.time_to do
            pa_sched_params
          end
        end
        if (pa_sched_params.time_from < schedule.time_from &&
            pa_sched_params.time_to > schedule.time_to) ||
           (pa_sched_params.time_from < schedule.time_to &&
            pa_sched_params.time_to > schedule.time_to) ||
           (pa_sched_params.time_from < schedule.time_from &&
            pa_sched_params.time_to > schedule.time_from) do
             conn
             |> put_flash(:error, "Schedule is invalid!")
             |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pa_sched_params.day
          end
        end)

        if length(map) == 0 do
          PractitionerContext.update_practitioner_account_schedule(
            pa_schedule, pa_sched_params)

          PractitionerContext.create_affiliation_log(
            conn.assigns.current_user,
            PractitionerSchedule.changeset_pa(pa_schedule, pa_sched_params),
            pa.practitioner_id,
            "Schedule",
            "Corporate Retainer")
          not_updated = []
        else
          not_updated = Enum.map [map], fn val ->
            if not is_nil(val) do
              pa_sched_params
            end
          end
        end

        type =
          if length(not_updated) == 0 do
            :info
          else
            :error
          end

        msg =
          if length(not_updated) == 0 do
            "Schedule updated successfully"
          else
            "Schedule already exists"
          end

        conn
        |> put_flash(type, msg)
        |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
    else
        conn
        |> put_flash(:error, "Time To must be greater than Time From")
        |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
    end
  end

  defp update_edit_pa_general(conn, practitioner, params, pa) do
    params =
      params
      |> Map.put("practitioner_id", practitioner.id)

    if params["email"] == [""] && params["fax"] == [""] &&
        params["mobile"] == [""] && params["telephone"] == [""] do
      conn
      |> put_flash(:error, "At least one contact number must be entered.")
      |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=general")

    else

      case PractitionerContext.update_practitioner_account(params, pa) do
        {:ok, practitioner_account} ->
          practitioner_account_contact =
            PractitionerContext.get_practitioner_account_contact(
              practitioner_account.practitioner_account_contact.id)
          PhoneContext.delete_phone(
            practitioner_account_contact.contact_id)
          EmailContext.delete_email(
            practitioner_account_contact.contact_id)
          PractitionerContext.delete_practitioner_account_contact(
            practitioner_account_contact.contact_id)

          {:ok, contact} =
            PractitionerContext.create_contact_practitioner(params)

        Enum.each(["mobile", "telephone", "fax"], fn(param) ->
          insert_number(%{
            contact_id: contact.id,
            number: params[param],
            type: param
          })
        end
        )
        Enum.each(["email"], fn(param) ->
          insert_email(%{
            contact_id: contact.id,
            address: params[param],
            type: param
          })
        end
        )

        PractitionerContext.create_practitioner_account_contact(%{
          practitioner_account_id: pa.id,
          contact_id: contact.id,
        })

    phones = for phone <- practitioner_account_contact.contact.phones do
      {phone.number, phone.type}
    end
    emails = for email <- practitioner_account_contact.contact.emails do
      email.address
    end

    PractitionerContext.create_affiliation_log(
      conn.assigns.current_user,
      PractitionerAccount.changeset(pa, params),
      practitioner.id,
      "General",
      "Corporate Retainer"
    )
    pa_log_parameters = %{
      practitioner_id: practitioner_account.practitioner_id,
      contact_id: contact.id,
      old_contacts: {phones, emails},
      current_user: conn.assigns.current_user,
      affiliation: "Corporate Retainer",
      tab: "General"
    }
    PractitionerContext.create_affiliation_contact_log(pa_log_parameters)
    #PractitionerContext.create_affiliation_contact_log(
    #  practitioner_account.practitioner_id, contact.id,
    #    {phones, emails}, conn.assigns.current_user, "Corporate Retainer", "General")

        conn
        |> put_flash(:info, "Corporate Retainer updated successfully!")
        |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=general")
        {:error, %Ecto.Changeset{} = changeset} ->
          accounts = PractitionerContext.list_all_accounts_in_practitioner()
            conn
            |> put_flash(:error, "Account already selected.")
            |> render("account_group/edit/general.html",
                changeset: changeset, practitioner: practitioner,
                practitioner_account: pa, accounts: accounts)
      end
    end
  end

  defp update_edit_pa_schedule(conn, _practitioner, params, pa) do
    schedules = PractitionerContext.get_practitioner_account_schedules(pa.id)
    rooms =
      params["room"]
      |>  Enum.filter(fn({_day, val}) -> val != "" end)
      |>  Enum.map(fn({day, val}) -> {day, val} end)

    not_inserted = for {day, _val} <- rooms do
      time_from = String.split(params["time_from"][day], ":")
      time_to = String.split(params["time_to"][day], ":")
      pa_sched_params = %{
        day: day,
        room: params["room"][day],
        time_from: Ecto.Time.cast!(%{
          hour: Enum.at(time_from, 0),
          minute: Enum.at(time_from, 1)
        }),
        time_to: Ecto.Time.cast!(%{
          hour: Enum.at(time_to, 0),
          minute: Enum.at(time_to, 1)
        }),
        practitioner_account_id: pa.id
      }

      map = Enum.map schedules, fn schedule ->
        if pa_sched_params.day == schedule.day do
          if (pa_sched_params.time_from > schedule.time_from &&
              pa_sched_params.time_from < schedule.time_to) ||
            (pa_sched_params.time_to > schedule.time_from &&
              pa_sched_params.time_to < schedule.time_to) ||
              (pa_sched_params.time_from == schedule.time_from ||
                pa_sched_params.time_to == schedule.time_to) do
            pa_sched_params
          end
          if (pa_sched_params.time_from < schedule.time_from &&
              pa_sched_params.time_to > schedule.time_to) ||
             (pa_sched_params.time_from < schedule.time_to &&
              pa_sched_params.time_to > schedule.time_to) ||
             (pa_sched_params.time_from < schedule.time_from &&
              pa_sched_params.time_to > schedule.time_from) do
               conn
               |> put_flash(:error, "Schedule is invalid!")
               |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
          end
        end
      end

      map =
        map
        |> Enum.filter(fn val ->
          if not is_nil(val) do
            val.day == pa_sched_params.day
          end
      end)

      if length(map) == 0 do
        affi_sched_log_params = %{
          user: conn.assigns.current_user,
          action: "added",
          params: pa_sched_params,
          practitioner_id: pa.practitioner_id,
          tab: "Schedule",
          affiliation: "Corporate Retainer"
        }
        PractitionerContext.create_affiliation_schedule_log(affi_sched_log_params)
        # PractitionerContext.create_affiliation_schedule_log(
        #   conn.assigns.current_user,
        #   "added",
        #   pa_sched_params,
        #   pa.practitioner_id,
        #   "Schedule",
        #   "Corporate Retainer"
        # )
        PractitionerContext.create_practitioner_account_schedule(
                              pa_sched_params)
        _not_inserted = []
     else
        Enum.map [map], fn val ->
          if not is_nil(val) do
            pa_sched_params
          end
        end
      end
    end

    if length(not_inserted) == 0 || not_inserted == [[]] do
      conn
      |> put_flash(:info, "Schedule added successfully")
      |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
    else
      conn
      |> put_flash(:error, "Some/All of the entered schedule already exists")
      |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
    end
  end

  def delete_pa_schedule(conn, %{"id" => practitioner_account_schedule_id}) do
    schedule =
      PractitionerContext.get_practitioner_account_schedule(
        practitioner_account_schedule_id)
    pa =
      PractitionerContext.get_practitioner_account(
        schedule.practitioner_account_id)
    PractitionerContext.delete_practitioner_account_schedule(schedule.id)

    affi_sched_log_params = %{
      user: conn.assigns.current_user,
      action: "deleted",
      params: schedule,
      practitioner_id: pa.practitioner_id,
      tab: "Schedule",
      affiliation: "Corporate Retainer"
    }
    PractitionerContext.create_affiliation_schedule_log(affi_sched_log_params)
        # PractitionerContext.create_affiliation_schedule_log(
        #   conn.assigns.current_user,
        #   "deleted",
        #   schedule,
        #   pa.practitioner_id,
        #   "Schedule",
        #   "Corporate Retainer"
        # )

    conn
    |> put_flash(:info, "Schedule deleted successfully.")
    |> redirect(to: "/practitioners/#{pa.id}/pa/create?step=2")
  end

  def delete_edit_pa_schedule(conn, %{"id" => practitioner_account_schedule_id}) do
    schedule =
      PractitionerContext.get_practitioner_account_schedule(
        practitioner_account_schedule_id)
    pa =
      PractitionerContext.get_practitioner_account(
        schedule.practitioner_account_id)
    PractitionerContext.delete_practitioner_account_schedule(schedule.id)

    affi_sched_log_params = %{
      user: conn.assigns.current_user,
      action: "deleted",
      params: schedule,
      practitioner_id: pa.practitioner_id,
      tab: "Schedule",
      affiliation: "Corporate Retainer"
    }
    PractitionerContext.create_affiliation_schedule_log(affi_sched_log_params)
        # PractitionerContext.create_affiliation_schedule_log(
        #   conn.assigns.current_user,
        #   "deleted",
        #   schedule,
        #   pa.practitioner_id,
        #   "Schedule",
        #   "Corporate Retainer"
        # )

    conn
    |> put_flash(:info, "Schedule deleted successfully.")
    |> redirect(to: "/practitioners/#{pa.id}/pa/edit?tab=schedule")
  end

  def delete_practitioner_account(conn, %{"id" => practitioner_account_id}) do
    pa = PractitionerContext.get_practitioner_account(practitioner_account_id)
    practitioner = PractitionerContext.get_practitioner(pa.practitioner_id)
    PractitionerContext.delete_practitioner_account(pa.id)

    conn
    |> put_flash(:info, "Corporate Retainer deleted successfully.")
    |> redirect(to: "/practitioners/#{practitioner.id}?active=affiliation")
  end

  # End of Practitioner Account

  # Start of Practitioner Download Results

  def download_practitioner(conn, %{"practitioner_param" => download_param}) do
    data = PractitionerContext.practitioner_csv_downloads(download_param)
    # conn
    json conn, Poison.encode!(data)
  end
  # End of Practitioner Download Results

  # Private Methods

  defp insert_email(params) do
    Enum.each(params.address, fn(address) ->
      EmailContext.create_email(%{
        contact_id: params.contact_id,
        address: address,
        type: params.type
      })
    end)
  end

  defp new_insert_number(params) do
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

  defp insert_number(params) do
    Enum.each(params.number, fn(number) ->
      PractitionerContext.create_no(%{
        contact_id: params.contact_id,
        number: String.replace(number, "-", ""),
        type: params.type
      })
    end)
  end

  def load_specializations(conn, %{"s_id" => s_id}) do
    specializations = PractitionerContext.load_specializations(s_id)
    render(conn, Innerpeace.PayorLink.Web.PractitionerView,
      "load_all_specializations.json", specializations: specializations)
  end

  def get_practitioners_by_specialization(conn, %{"id" => id}) do
    specialization = PractitionerContext.get_specialization(id)
    render(conn, Innerpeace.PayorLink.Web.PractitionerView,
      "specialization_practitioners.json", specialization_practitioners: specialization.practitioner_specializations)
  end

  def get_specializations_by_practitioner(conn, %{"id" => id}) do
    practitioner = PractitionerContext.get_practitioner(id)
    render(conn, Innerpeace.PayorLink.Web.PractitionerView,
      "practitioner_specializations.json", practitioner_specializations: practitioner.practitioner_specializations)
  end

  defp translate_date_params(params) do
    params
    |> Map.put("birth_date", to_valid_date(params["birth_date"]))
    |> Map.put("effectivity_from", to_valid_date(params["effectivity_from"]))
    |> Map.put("effectivity_to", to_valid_date(params["effectivity_to"]))
    |> Map.put("phic_date", to_valid_date(params["phic_date"]))
    |> Map.put("hidden_birth_date", to_valid_date(params["hidden_birth_date"]))
    |> Map.put("hidden_eff", to_valid_date(params["hidden_eff"]))
    |> Map.put("hidden_exp", to_valid_date(params["hidden_exp"]))
    |> Map.put("hidden_phic_date", to_valid_date(params["hidden_phic_date"]))
  end

  defp translate_date_params_v2(params) do
    params
    |> Map.put("disaffiliation_date", to_valid_date(params["disaffiliation_date"]))
    |> Map.put("affiliation_date", to_valid_date(params["affiliation_date"]))
    |> Map.put("hidden_ad", to_valid_date(params["hidden_ad"]))
    |> Map.put("hidden_dd", to_valid_date(params["hidden_dd"]))
  end

  defp to_valid_date(date) do
    UtilityContext.transform_string_dates(date)
  end
end

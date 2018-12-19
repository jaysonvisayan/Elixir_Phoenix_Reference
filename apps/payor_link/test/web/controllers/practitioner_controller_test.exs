defmodule Innerpeace.PayorLink.Web.PractitionerControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper
  alias Innerpeace.Db.Base.PractitionerContext

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_practitioners", module: "Practitioners"})
    conn = authenticated(conn, user)
    practitioner = insert(:practitioner, first_name: "test", exclusive: ["PCS", "PNA", "PSA"])
    # conn = sign_in(conn, user)
    {:ok, %{conn: conn, user: user, practitioner: practitioner}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, practitioner_path(conn, :index)
    assert html_response(conn, 200) =~ "Practitioners"
  end

  test "renders form for creating new practitioner general", %{conn: conn} do
    conn = get conn, practitioner_path(conn, :new)
    assert html_response(conn, 200) =~ "General"
  end

  test "creates new practitioner and redirects to step 2 when data is valid", %{conn: conn} do
    specialization = insert(:specialization, name: "Neurology")
    insert(:practitioner_specialization, specialization: specialization, type: "Primary")
    params = %{
      first_name: "Shane",
      last_name: "Dela Rosa",
      middle_name: "Dolot",
      birth_date: "Dec 12, 2019",
      effectivity_from: "Dec 12, 2017",
      effectivity_to: "Dec 12, 2018",
      gender: "Male",
      affiliated: "Yes",
      phic_accredited: "Yes",
      prc_no: "0000001",
      specialization_ids: [specialization.id]
    }
    conn = post conn, practitioner_path(conn, :create), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :setup, id, step: "2")
  end

  test "does not create practitioner general and renders errors when data is invalid", %{conn: conn} do
    invalid_params = %{
      first_name: ""
    }
    conn = post conn, practitioner_path(conn, :create), practitioner: invalid_params
    assert html_response(conn, 200) =~ "General"
  end

  test "renders form for creating new practitioner contact", %{conn: conn, practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :setup, practitioner, step: "2")
    assert html_response(conn, 200) =~ "Contact"
  end

  test "adds practitioner contact", %{conn: conn, practitioner: practitioner} do
    params = %{
      email: ["test@gmail.com"],
      fax: ["123123123"],
      mobile: ["09094567890"],
      telephone: ["6435328"]

    }
    conn = put conn, practitioner_path(conn, :create_contact, practitioner, step: "2"), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :setup, id, step: "3")
  end

  test "renders form for creating new practitioner financial", %{conn: conn, practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :setup, practitioner, step: "3")
    assert html_response(conn, 200) =~ "Financial"
  end

  test "creates practitioner financial and redirects to step 4 when data is valid", %{conn: conn, practitioner: practitioner} do

    vatable = insert(:dropdown, type: "VAT Status", text: "Vatable")
    params = %{
      exclusive: ["PCS"],
      payment_type: "Bank",
      prescription_period: "30",
      tin: "123111111111",
      vat_status: "Full VAT-able",
      withholding_tax: "12",
      account_name: "Shane",
      account_number: "1111111111111111",
      vat_status_id: vatable.id
    }
    conn = put conn, practitioner_path(conn, :create_financial, practitioner, step: "3"), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :setup, id, step: "4")
  end

  test "does not create practitioner financial and returns error", %{conn: conn, practitioner: practitioner} do
    params = %{
      exclusive: [""],
      payment_type: "Bank",
      prescription_period: "",
      tin: "123111111111",
      vat_status: nil,
      withholding_tax: "12",
      account_name: "Shane",
      account_number: "1111111111111111"
    }
    conn = put conn, practitioner_path(conn, :create_financial, practitioner, step: "3"), practitioner: params
    assert html_response(conn, 200) =~ "Financial"
  end

  test "renders practitioner summary", %{conn: conn} do
    vatable = insert(:dropdown, type: "VAT Status", text: "Vatable")
    bank = insert(:bank)
    practitioner = insert(:practitioner, exclusive: ["PCS", "NON-PCS"], bank: bank, dropdown_vat_status: vatable)
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    practitioner = PractitionerContext.get_practitioner(practitioner.id)
    conn = get conn, practitioner_path(conn, :setup, practitioner, step: "4")
    assert html_response(conn, 200) =~ "Summary"
  end

  test "update step3 creates practitioner financial and redirects to step 4", %{conn: conn, practitioner: practitioner} do

    vatable = insert(:dropdown, type: "VAT Status", text: "Vatable")
    params = %{
      exclusive: ["NON-PCS"],
      payment_type: "Bank",
      prescription_period: "12",
      tin: "123111111111",
      vat_status: "Full VAT-able",
      withholding_tax: "12",
      account_name: "Shane",
      account_number: "1111111111111111",
      vat_status_id: vatable.id
    }
    conn = put conn, practitioner_path(conn, :update_setup, practitioner, step: 3), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :setup, id, step: "4")
  end

  test "create summary successfully creates practitioner and redirects to show page", %{conn: conn, practitioner: practitioner} do
    params = %{
      step: 5
    }
    conn = get conn, practitioner_path(conn, :create_summary, practitioner), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :show, id, active: "profile")
  end

  test "renders practitioner summary print page", %{conn: conn} do
    bank = insert(:bank)
    practitioner = insert(:practitioner, exclusive: ["PCS", "NON-PCS"], bank: bank)
    contact = insert(:contact)
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    practitioner = PractitionerContext.get_practitioner(practitioner.id)
    conn = get conn, practitioner_path(conn, :setup, practitioner, step: "5")
    assert html_response(conn, 200) =~ "General"
  end

  test "deletes chosen practitioner", %{conn: conn} do
    practitioner = insert(:practitioner)
    conn = delete conn, practitioner_path(conn, :delete, practitioner)
    assert redirected_to(conn) == practitioner_path(conn, :index)
  end

  test "renders form for edit practitioner general", %{conn: conn,practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :edit_setup, practitioner.id, tab: "general")
    assert html_response(conn, 200) =~ "General"
  end

  test "renders form for edit practitioner contact", %{conn: conn,practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :edit_setup, practitioner.id, tab: "contact")
    assert html_response(conn, 200) =~ "Contact"
  end

  test "renders form for edit practitioner financial", %{conn: conn,practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :edit_setup, practitioner.id, tab: "financial")
    assert html_response(conn, 200) =~ "Financial"
  end

  test "update new practitioner general and redirects to tab general when data is valid", %{conn: conn} do
    specialization = insert(:specialization, name: "Neurology")
    insert(:practitioner_specialization, type: "Primary")
    params = %{
      first_name: "Shane",
      last_name: "Dela Rosa",
      middle_name: "Dolot",
      birth_date: "Dec 12, 2019",
      effectivity_from: "Dec 12, 2017",
      effectivity_to: "Dec 12, 2018",
      gender: "Male",
      affiliated: "Yes",
      phic_accredited: "Yes",
      prc_no: "0000001",
      specialization_ids: [specialization.id]
    }
    practitioner = insert(:practitioner)
    conn = put conn, practitioner_path(conn, :update_edit_setup, practitioner.id, tab: "general"), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :edit_setup, id, tab: "general")
  end


  test "update practitioner contact", %{conn: conn, practitioner: practitioner} do
    params = %{
      email: "test@gmail.com",
    }
    contact = insert(:contact, params)
    params1 = %{
      contact_id: contact.id,
      email: ["test@gmail.com"],
      mobile: ["09210052020", "09210050000"],
      telephone: ["6363", "6364"],
      fax: ["64", "12345"]
    }
    insert(:practitioner_contact, practitioner: practitioner, contact: contact)
    conn = put conn, practitioner_path(conn, :update_edit_setup, practitioner.id, tab: "contact"), practitioner: params1
    assert redirected_to(conn) == practitioner_path(conn, :edit_setup, practitioner.id, tab: "contact")
  end

  test "update practitioner financial and redirects to edit financial", %{conn: conn, practitioner: practitioner} do
    vatable = insert(:dropdown, type: "VAT Status", text: "Vatable")
    params = %{
      exclusive: ["NON-PCS"],
      payment_type: "Bank",
      prescription_period: "12",
      tin: "123111111111",
      vat_status: "Full VAT-able",
      withholding_tax: "12",
      account_name: "Shane",
      account_number: "1111111111111111",
      vat_status_id: vatable.id
    }
    conn = put conn, practitioner_path(conn, :update_edit_setup, practitioner, tab: "financial"), practitioner: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :edit_setup, id, tab: "financial")
  end

  test "new_pa/1 renders practitioner corporate retainer form", %{conn: conn, practitioner: practitioner} do
    conn = get conn, practitioner_path(conn, :new_pa, practitioner.id)
    assert html_response(conn, 200) =~ "General"
  end

  test "pa_step1/1 renders practitioner corporate retainer form", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    contact = insert(:contact)
    insert(:phone, contact: contact, type: "telephone", number: "0991311")
    insert(:phone, contact: contact, type: "fax", number: "0991311")
    insert(:phone, contact: contact, type: "mobile", number: "09991234311")
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    conn = get conn, practitioner_path(conn, :create_pa_setup, pa.id, step: 1)
    assert html_response(conn, 200) =~ "General"
  end

  test "pa_step2/1 renders practitioner corporate retainer schedule form", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    insert(:practitioner_schedule, practitioner_account: pa)
    conn = get conn, practitioner_path(conn, :create_pa_setup, pa.id, step: 2)
    assert html_response(conn, 200) =~ "Schedule"
  end

  test "pa_step3/1 renders practitioner corporate retainer summary", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    contact = insert(:contact)
    insert(:phone, contact: contact, type: "telephone", number: "0991311")
    insert(:phone, contact: contact, type: "fax", number: "0991311")
    insert(:phone, contact: contact, type: "mobile", number: "09991234311")
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    insert(:practitioner_schedule, practitioner_account: pa)
    conn = get conn, practitioner_path(conn, :create_pa_setup, pa.id, step: 3)
    assert html_response(conn, 200) =~ "Summary"
  end

  test "create_pa/2 creates practitioner account general and redirects when data is valid", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    params1 = %{
      email: ["test@gmail.com"],
      mobile: ["09210052020", "09210050000"],
      telephone: ["6363123", "6364123"],
      fax: ["64", "12345"]
    }
    params2 = %{account_group_id: account.id}
    params1 = Map.merge(params1, params2)
    conn = post conn, practitioner_path(conn, :create_pa, practitioner), practitioner_account: params1
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :create_pa_setup, id, step: "2")
  end

  test "update_pa_step1 updates general in practitioner account create", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    contact = insert(:contact)
    insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    params1 = %{
      email: ["test@gmail.com"],
      mobile: ["09210052020", "09210050000"],
      telephone: ["6363123", "6364123"],
      fax: ["64", "12345"]
    }
    params2 = %{account_group_id: account.id}
    params1 = Map.merge(params1, params2)
    conn = put conn, practitioner_path(conn, :update_pa_setup, pa, step: "1"), practitioner_account: params1
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_pa_setup, id, step: "2")
  end

  test "update_pa_step2 adds schedule in practitioner account create", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    params = %{
      day: ["Monday"],
      room: %{"Monday" => "123"},
      time_from: %{"Monday" => "18:00"},
      time_to: %{"Monday" => "18:00"}
    }
    conn = put conn, practitioner_path(conn, :update_pa_setup, pa, step: "2"), practitioner_account: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_pa_setup, id, step: "2")
  end

  test "update_pa_schedule2 updates schedule in practitioner account create", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    params = %{
      day: ["Monday"],
      room: %{"Monday" => "123"},
      time_from: %{"Monday" => "18:00"},
      time_to: %{"Monday" => "18:00"}
    }
    conn = put conn, practitioner_path(conn, :update_pa_setup, pa, step: "2"), practitioner_account: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_pa_setup, id, step: "2")
  end

  test "update_edit_pa_general/2 updates form step1 in practitioner account edit", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    contact = insert(:contact)
    insert(:practitioner_account_contact, practitioner_account: pa, contact: contact)
    params1 = %{
      email: ["test@gmail.com"],
      mobile: ["09210052020", "09210050000"],
      telephone: ["6363123", "6364123"],
      fax: ["64", "12345"]
    }
    params2 = %{account_group_id: account.id}
    params1 = Map.merge(params1, params2)
    conn = put conn, practitioner_path(conn, :update_edit_pa_setup, pa, tab: "general"), practitioner_account: params1
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_edit_pa_setup, id, tab: "general")
  end

  test "update_edit_pa_schedule/2 adds schedule in practitioner account edit", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    insert(:practitioner_schedule, practitioner_account: pa)
    params = %{
      day: ["Monday"],
      room: %{"Monday" => "123"},
      time_from: %{"Monday" => "18:00"},
      time_to: %{"Monday" => "18:00"}
    }
    conn = put conn, practitioner_path(conn, :update_edit_pa_setup, pa, tab: "schedule"), practitioner_account: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_edit_pa_setup, id, tab: "schedule")
  end

  test "delete_pa_schedule deletes selected schedule in practitioner account create",  %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    schedule = insert(:practitioner_schedule, practitioner_account: pa)
    conn = delete conn, practitioner_path(conn, :delete_pa_schedule, schedule)
    assert redirected_to(conn) == practitioner_path(conn, :update_pa_setup, pa.id, step: "2")
  end

  test "delete_edit_pa_schedule deletes selected schedule in practitioner account edit",  %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    schedule = insert(:practitioner_schedule, practitioner_account: pa)
    conn = delete conn, practitioner_path(conn, :delete_edit_pa_schedule, schedule)
    assert redirected_to(conn) == practitioner_path(conn, :update_edit_pa_setup, pa.id, tab: "schedule")
  end

  test "update_pa_edit_pa_schedule_modal updates schedule in practitioner account edit", %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    schedule = insert(:practitioner_schedule, practitioner_account: pa)
    params = %{
      day: "Monday",
      room: "123",
      time_from: "18:00" ,
      time_to: "18:00",
      schedule_id: schedule.id
    }
    conn = put conn, practitioner_path(conn, :update_edit_pa_schedule_modal, pa, tab: "schedule"), practitioner_account: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == practitioner_path(conn, :update_edit_pa_setup, id, tab: "schedule")
  end

  test "delete_practitioner_account deletes practitioner account",  %{conn: conn, practitioner: practitioner} do
    account = insert(:account_group)
    pa = insert(:practitioner_account, practitioner: practitioner, account_group: account)
    conn = delete conn, practitioner_path(conn, :delete_practitioner_account, pa)
    assert redirected_to(conn) == practitioner_path(conn, :show, practitioner.id, active: "affiliation")
  end
end


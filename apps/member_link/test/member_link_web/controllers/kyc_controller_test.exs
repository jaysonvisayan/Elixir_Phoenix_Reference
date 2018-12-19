defmodule MemberLinkWeb.KycControllerTest do
  use MemberLinkWeb.ConnCase
  # use Innerpeace.Db.SchemaCase, async: true

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Base.{
    UserContext
  }


  setup do
    usercreator = fixture()

    ag =
      insert(
        :account_group,
        name: "Jollibee Worldwide",
        branch: "Makati city",
        code: "C001"
      )

    member =
      insert(
        :member,
        first_name: "El Pablito",
        middle_name: "Escobar",
        last_name: "Gaviria",
        gender: "Male",
        type: "Principal",
        account_code: ag.code,
        created_by_id: usercreator.id,
        updated_by_id: usercreator.id,
        card_no: "1168011034280092",
        step: 2,
        birthdate: Ecto.Date.cast!("1990-10-10"),
        effectivity_date: Ecto.Date.cast!("1990-10-10"),
        expiry_date: Ecto.Date.cast!("2090-10-10"),
        civil_status: "Single",
        employee_no: "123123123",
        date_hired: Ecto.Date.cast!("2015-10-10"),
        is_regular: true,
        regularization_date: Ecto.Date.cast!("2015-10-10"),
        tin: "123456789012",
        philhealth: "123456789012",
        for_card_issuance: true,
        philhealth_type: "Not Covered",
        status: "Active"
      )

    {:ok, user} = UserContext.register_member(member, %{
      "member_id" => member.id,
      "username" => "memberlink_admin",
      "email" => "member_test@medi.com",
      "mobile" => "09199046601",
      "first_name" => "Shane",
      "last_name" => "Dolot",
      "middle_name" => "Dela Rosa",
      "birthday" => Ecto.Date.cast!("1995-01-01"),
      "gender" => "Male",
      "verification_code" => "1234",
      "verification" => true,
      "password" => "P@ssw0rd",
      "password_confirmation" => "P@ssw0rd"
    })

    conn = build_conn()
           |> authenticated(user)

    {:ok, %{conn: conn, user: user, member: member |> Repo.preload([:account_group]), account_group: ag}}
  end

  test "renders kyc/new", %{conn: conn, member: member} do
    conn = get conn, kyc_path(conn, :new, @locale)
    assert html_response(conn, 200) =~ "Bank KYC Requirements"
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ member.middle_name
    assert html_response(conn, 200) =~ member.last_name
    assert html_response(conn, 200) =~ member.card_no
    assert html_response(conn, 200) =~ member.account_group.name
    assert html_response(conn, 200) =~ member.account_group.branch
  end

  test "creates Bank KYC Requirments step1 with valid attributes", %{conn: conn} do
    params = %{
      "citizenship" => "filipino",
      "city_of_birth" => "Caloocan city",
      "civil_status" => "Single",
      "company_branch" => "Taguig Branch",
      "company_name" => "Jollibee Worldwide",
      "country_of_birth" => "Afghanistan",
      "educational_attainment" => "bsit",
      "mm_first_name" => "test1",
      "mm_last_name" => "test3",
      "mm_middle_name" => "test2",
      "nature_of_work" => "Office",
      "occupation" => "IT - web developer",
      "position_title" => "Chief Operating Manager",
      "source_of_fund" => "Income"
    }
    conn = post conn, kyc_path(conn, :create, @locale), kyc: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == kyc_path(conn, :setup, @locale, id, step: "2")
  end

  test "creates Bank KYC Requirments step1 with invalid attributes", %{conn: conn, member: member} do
    params = %{
      "citizenship" => "",
      "city_of_birth" => "",
      "civil_status" => "",
      "company_branch" => "",
      "company_name" => "",
      "country_of_birth" => "Afghanistan",
      "educational_attainment" => "bsit",
      "mm_first_name" => "test1",
      "mm_last_name" => "test3",
      "mm_middle_name" => "test2",
      "nature_of_work" => "Office",
      "occupation" => "IT - web developer",
      "position_title" => "Chief Operating Manager",
      "source_of_fund" => "Income"
    }
    conn = post conn, kyc_path(conn, :create, @locale), kyc: params
    assert html_response(conn, 200) =~ "Bank KYC Requirements"
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ member.middle_name
    assert html_response(conn, 200) =~ member.last_name
    assert html_response(conn, 200) =~ member.card_no
    assert html_response(conn, 200) =~ member.account_group.name
    assert html_response(conn, 200) =~ member.account_group.branch
  end

  test "renders kyc/:id/setup?step=1", %{conn: conn, member: member} do
    kyc = insert(:kyc_bank)
    conn = get conn, kyc_path(conn, :setup, @locale, kyc, step: "1")
    assert html_response(conn, 200) =~ "Bank KYC Requirements"
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ member.middle_name
    assert html_response(conn, 200) =~ member.last_name
    assert html_response(conn, 200) =~ member.card_no
    assert html_response(conn, 200) =~ member.account_group.name
    assert html_response(conn, 200) =~ member.account_group.branch
  end

  test "updates Bank KYC Requirments step1 with valid attributes", %{conn: conn} do
    kyc = insert(:kyc_bank)
    params = %{
      "citizenship" => "americano",
      "city_of_birth" => "Kansas city",
      "civil_status" => "Married",
      "company_branch" => "Taguig Branch",
      "company_name" => "Microsoft Inc.",
      "country_of_birth" => "United States of America",
      "educational_attainment" => "PHD, Master's in IT",
      "mm_first_name" => "Juan",
      "mm_last_name" => "Pablo",
      "mm_middle_name" => "Gaviria",
      "nature_of_work" => "Office",
      "occupation" => "IT - web developer",
      "position_title" => "Chief Operating Manager",
      "source_of_fund" => "Others",
      "others" => "Part time"
    }
    conn = put conn, kyc_path(conn, :update_setup, @locale, kyc, step: "1", kyc: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == kyc_path(conn, :setup, @locale, id, step: "2")
  end

  test "updates Bank KYC Requirments step1 with invalid attributes", %{conn: conn, member: member} do
    kyc = insert(:kyc_bank)
    params = %{
      "citizenship" => "",
      "city_of_birth" => "",
      "civil_status" => "",
      "company_branch" => "",
      "company_name" => "",
      "country_of_birth" => "United States of America",
      "educational_attainment" => "PHD, Master's in IT",
      "mm_first_name" => "Juan",
      "mm_last_name" => "Pablo",
      "mm_middle_name" => "Gaviria",
      "nature_of_work" => "Office",
      "occupation" => "IT - web developer",
      "position_title" => "Chief Operating Manager",
      "source_of_fund" => "Others",
      "others" => "Part time"
    }
    conn = put conn, kyc_path(conn, :update_setup, @locale, kyc, step: "1", kyc: params)
    assert html_response(conn, 200) =~ "Bank KYC Requirements"
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ member.middle_name
    assert html_response(conn, 200) =~ member.last_name
    assert html_response(conn, 200) =~ member.card_no
    assert html_response(conn, 200) =~ member.account_group.name
  end

  test "update contact information step2 with valid attributes", %{conn: conn} do
    kyc = insert(:kyc_bank)
    params = %{
      "street_no" => "1234",
      "subd_dist_town" => "Maharlika",
      "country" => "Philippines",
      "city" => "Manila",
      "zip_code" => "1200",
      "residential_line" => "1234567",
      "mobile1" => "12345678912",
      "mobile2" => "12345567675",
      "email1" => "1@y.com",
      "email2" => "1@y.com"
    }
    conn = put conn, kyc_path(conn, :update_setup, @locale, kyc, step: "2", kyc: params)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == kyc_path(conn, :setup, @locale, id, step: "3")
  end

  test "update contact information step2 with invalid attributes", %{conn: conn, member: member} do
    kyc = insert(:kyc_bank)
    params = %{
      "street_no" => "",
      "subd_dist_town" => "test",
      "country" => "",
      "city" => "makati",
      "zip_code" => "1",
      "residential_line" => "1234567",
      "mobile1" => "12345678912",
      "mobile2" => "12345567675",
      "email1" => "1@y.com",
      "email2" => "6@y.com"
    }
    conn = put conn, kyc_path(conn, :update_setup, @locale, kyc, step: "2", kyc: params)
    assert html_response(conn, 200) =~ "Update Contact Info"
    assert html_response(conn, 200) =~ member.first_name
    assert html_response(conn, 200) =~ member.middle_name
    assert html_response(conn, 200) =~ member.last_name
  end

end

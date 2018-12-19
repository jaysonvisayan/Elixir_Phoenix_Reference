defmodule MemberLinkWeb.SearchControllerTest do
  use MemberLinkWeb.ConnCase
  # use Innerpeace.Db.SchemaCase, async: true

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Base.{
    # MemberContext,
    UserContext
  }

  # alias Innerpeace.Db.{
  #   Repo,
  #   User
  # }

  setup do
    account_group = insert(:account_group, name: "account101")
    member = insert(:member, first_name: "Shane", last_name: "Dela Rosa", type: "Principal", account_group: account_group)
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

    facility = insert(:facility)
    product = insert(:product, name: "Sample")
    coverage = insert(:coverage, name: "ACU")
    pc = insert(:product_coverage, product: product, coverage: coverage)
    insert(:product_coverage_facility, product_coverage: pc, facility: facility)

    {:ok, %{conn: conn, user: user, product: product}}
  end

  test "search_doctors renders search page in Memberlink", %{conn: conn} do
    conn = get conn, search_path(conn, :search_doctors, @locale)
    assert html_response(conn, 200) =~ "Search"
  end

  # test "get_all_doctors renders search page for doctors in Memberlink", %{conn: conn} do
  #   conn = get conn, search_path(conn, :get_all_doctors, @locale)
  #   assert html_response(conn, 200) =~ "Doctors"
  # end

  # test "get_all_hospitals renders search page for hospitals in Memberlink", %{conn: conn} do
  #   conn = get conn, search_path(conn, :get_all_hospitals, @locale)
  #   assert html_response(conn, 200) =~ "Hospitals"
  # end

  test "load_affiliated_facilities/2, loads all affiliated facility", %{conn: conn, product: product} do
    conn = get(conn, search_path(conn, :load_affiliated_facilities, @locale, product))
    assert html_response(conn, 200) =~ "Affiliated Facilities"
  end
end

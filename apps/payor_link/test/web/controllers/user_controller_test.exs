defmodule Innerpeace.PayorLink.Web.UserControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    # user = insert(:user, is_admin: true, mobile: "09277435476")
    user = fixture(:user_permission, %{keyword: "manage_users", module: "Users"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  @create_attrs %{
    username: "test_username",
    email: "test@gmail.com",
    password: "P@ssw0rd",
    password_confirmation: "P@ssw0rd",
    mobile: "09061885901",
    first_name: "test",
    middle_name: "test",
    last_name: "test",
    # middle_name: "test",
    birthday: "1995-12-18",
    title: "test",
    gender: "test",
    status: "test",
    notify_through: "test"
  }
  @invalid_attrs %{username: nil}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, user_path(conn, :index)
    assert html_response(conn, 200) =~ "Users"
  end

  test "renders step 1 form for creating new user", %{conn: conn} do
    conn = get conn, user_path(conn, :new)
    assert html_response(conn, 200) =~ "General"
  end

  test "creates new user and redirects to step 2 when data is valid", %{conn: conn} do
    conn = post conn, user_path(conn, :create_basic), user: @create_attrs
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == user_path(conn, :setup, id, step: "2")
  end

  test "does not create new user and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, user_path(conn, :create_basic), user: @invalid_attrs
    assert html_response(conn, 200) =~ "General"
  end

  test "renders step 1 form for editing", %{conn: conn, user: user} do
    conn = get conn, user_path(conn, :setup, user, step: "1")
    assert html_response(conn, 200) =~ user.first_name
  end

  test "update_setup 1 and redirects to step 2 when data is valid", %{conn: conn, user: user} do
    conn = put conn, user_path(conn, :update_setup, user, step: "1", user: @create_attrs)
    assert redirected_to(conn) == user_path(conn, :setup, user, step: "2")
  end

  test "update_setup 1 renders errors when data is invalid", %{conn: conn, user: user} do
    conn = put conn, user_path(conn, :update_setup, user, step: "1", user: @invalid_attrs)
    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ user.first_name
  end

  test "renders step 2 form for editing", %{conn: conn, user: user} do
    conn = get conn, user_path(conn, :setup, user, step: "2")
    assert html_response(conn, 200) =~ "Roles"
  end

  test "update_setup 2 and redirects to step 3 when data is valid", %{conn: conn, user: user} do
    role = insert(:role)
    conn = put conn, user_path(conn, :update_setup, user, step: "2", user: %{roles: [role.id]})
    assert redirected_to(conn) == user_path(conn, :setup, user, step: "3")
  end

  test "update_setup 2 renders errors when data is invalid", %{conn: conn, user: user} do
    conn = put conn, user_path(conn, :update_setup, user, step: "2", user: %{some_param: "test"})
    assert redirected_to(conn) == user_path(conn, :setup, user, step: "2")
  end

  test "renders step 3 form for editing", %{conn: conn, user: user} do
    conn = get conn, user_path(conn, :setup, user, step: "3")
    assert html_response(conn, 200) =~ "Summary"
  end

  test "update_setup 3 saves user and redirects to index", %{conn: conn, user: user} do
    conn = put conn, user_path(conn, :update_setup, user, step: "3"), user: %{step: 4}
    assert redirected_to(conn) == user_path(conn, :index)
  end

  test "deletes chosen user", %{conn: conn} do
    user = insert(:user)
    conn = delete conn, user_path(conn, :delete, user)
    assert redirected_to(conn) == user_path(conn, :index)
  end

  test "ajax user validations", %{conn: conn, user: user} do
    conn = get conn, user_path(conn, :user_validate)
    params = Poison.encode!([%{first_name: user.first_name, last_name: user.last_name, email: user.email, mobile: user.mobile, username: user.username, middle_name: user.middle_name}])
    assert Poison.decode!(conn.resp_body) == "#{params}"
    assert conn.status == 200
  end

  # test "update_password updates user password when data is valid" do
  #   hashedpw = Comeonin.Bcrypt.hashpwsalt("P@ssw0rd")
  #   user = insert(:user, is_admin: true, mobile: "09277435476", hashed_password: hashedpw)
  #   params = %{
  #     "old_password" => "P@ssw0rd",
  #     "password" => "P@ssw0rd123",
  #     "password_confirmation" => "P@ssw0rd123"
  #   }
  #   conn = build_conn()
  #   conn = sign_in(conn, user)
  #   conn = put conn, user_path(conn, :update_password, user.id), user: params
  #   assert conn.private[:phoenix_flash]["info"] == "Password successfully updated."
  # end
end

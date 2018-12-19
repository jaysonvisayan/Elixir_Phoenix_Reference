defmodule MemberLinkWeb.Api.V1.ProfileControllerTest do
  use MemberLinkWeb.ConnCase
  # use Innerpeace.Db.SchemaCase

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Schemas.User

  setup do
    member = insert(:member)
    {:ok, user} = Repo.insert(%User{username: "masteradmin", password: "P@ssw0rd",
      member_id: member.id})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    {:ok, %{
      member: member,
      jwt: jwt,
      conn: conn,
      user: user
    }}
  end

  test "get_member returns member profile when member id is valid", %{conn: conn, jwt: jwt} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(profile_path(conn, :get_member))
      assert json_response(conn, 200)
      assert json_response(conn, 200)["id"]
  end

  test "get_member returns invalid user when member id is not found" do
    insert(:member)
    user = insert(:user)

    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(profile_path(conn, :get_member))
      assert json_response(conn, 400) == %{"message" => "Wrong User and Password", "code" => 400}
  end

  test "get_member returns Invalid User when user is invalid" do
    {:ok, user} = Repo.insert(%User{username: "masteradmin12", password: "P@ssw0rd"})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(profile_path(conn, :get_member))
      assert json_response(conn, 400) == %{"message" => "Wrong User and Password", "code" => 400}
  end

# test "update_member_profile returns member when params are valid", %{conn: conn, jwt: jwt} do
#   member = insert(:member)
#   params = %{
#     first_name: "Jayson",
#     last_name: "Visayan",
#     gender: "Male",
#     birth_date: "09/30/1990",
#     uploads: [
#       %{
#         "base_64_encoded" => "",
#         "type" => "",
#         "extension" => "",
#         "link" => ""
#       }
#     ]}
#   conn =
#     conn
#     |> put_req_header("authorization", "Bearer #{jwt}")
#     |> put(profile_path(conn, :update_member_profile, params))
#   assert json_response(conn, 200)
#   assert json_response(conn, 200)["id"]
# end

# test "update_member_profile returns invalid_datetime_format when date are invalid", %{conn: conn, jwt: jwt} do
#   member = insert(:member)
#    params = %{
#      first_name: "Jayson",
#      last_name: "Visayan",
#      gender: "Male"
#    }
#    conn =
#      conn
#      |> put_req_header("authorization", "Bearer #{jwt}")
#      |> put(profile_path(conn, :update_member_profile, params))
#    assert json_response(conn, 400) == %{"message" => "birth_date is a required field!", "code" => 400}

#  end

# test "update_member_profile returns changeset when params are invalid", %{conn: conn, jwt: jwt, member: member} do
#   params = %{
#     last_name: "Visayan",
#     gender: "Male",
#     birth_date: "09/30/1990"
#   }
#   conn =
#     conn
#     |> put_req_header("authorization", "Bearer #{jwt}")
#     |> put(profile_path(conn, :update_member_profile, params))
#   assert json_response(conn, 400)["message"]
# end


 test "update_member_profile returns wrong user and password when member id is not found" do
    insert(:member)
    {:ok, user} = Repo.insert(%User{username: "masteradmin123423", password: "P@ssw0rd"})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    params = %{
      first_name: "Jayson",
      last_name: "Visayan",
      gender: "Male",
      birth_date: "09/30/1990"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> put(profile_path(conn, :update_member_profile, params))
      assert json_response(conn, 400) == %{"message" => "Wrong User and Password", "code" => 400}
 end

  test "get_dependents returns dependents profile when member id is valid", %{conn: conn, jwt: jwt, user: user} do
    insert(:member, principal_id: user.member_id)
    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(profile_path(conn, :get_dependents))
      assert json_response(conn, 200)
  end

  test "get_dependents returns no dependents when there's no dependents in this user", %{conn: conn, jwt: jwt} do
    conn =
      conn
      |> put_req_header("authorization", "bearer #{jwt}")
      |> get(profile_path(conn, :get_dependents))
      assert json_response(conn, 400)
      assert json_response(conn, 400)["message"] == "No dependents found"
  end

  test "register_dependent returns dependent when params are valid", %{conn: conn, jwt: jwt} do
    params = %{
      salutation: "Sir",
      first_name: "Joeffrey",
      last_name: "Baratheon",
      gender: "Male",
      extension: "Jr.",
      relationship: "Bad Influence friend",
      birth_date: "09/30/1990"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(profile_path(conn, :register_dependent, params))
    assert json_response(conn, 200)
    assert json_response(conn, 200)["id"]
  end

  test "register_dependent returns changeset when params are invalid", %{conn: conn, jwt: jwt} do
    params = %{
      salutation: "Sir",
      first_name: "Joeffrey",
      last_name: "Baratheon",
      gender: "Male",
      extension: "Jr.",
      birth_date: "09/30/1990"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(profile_path(conn, :register_dependent, params))
    assert json_response(conn, 400)["message"]
  end

  test "register_dependent returns wrong user and password when member not found" do
    {:ok, user} = Repo.insert(%User{username: "masteradmin123423", password: "P@ssw0rd"})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    params = %{
      salutation: "Sir",
      first_name: "Joeffrey",
      last_name: "Baratheon",
      gender: "Male",
      extension: "Jr.",
      relationship: "Bad Influence friend",
      birth_date: "09/30/1990"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(profile_path(conn, :register_dependent, params))
      assert json_response(conn, 400) == %{"message" => "Wrong User and Password", "code" => 400}
  end

  test "register_dependent returns invalid birth_date format when date are invalid", %{conn: conn, jwt: jwt} do
    params = %{
      salutation: "Sir",
      first_name: "Joeffrey",
      last_name: "Baratheon",
      gender: "Male",
      extension: "Jr.",
      relationship: "Bad Influence friend",
      birth_date: "09/30/190"
    }
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(profile_path(conn, :register_dependent, params))
     assert json_response(conn, 400) == %{"message" => "Invalid Birth Date Format", "code" => 400}
  end

end

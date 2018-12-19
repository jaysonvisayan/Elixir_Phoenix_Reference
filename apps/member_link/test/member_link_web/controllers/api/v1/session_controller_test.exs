defmodule MemberLinkWeb.Api.V1.SessionControllerTest do
  # use Innerpeace.Db.SchemaCase, async: true
  use MemberLinkWeb.ConnCase

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User,
    Member
  }

  setup do
    {:ok, member} = Repo.insert(%Member{status: "Active", card_no: "1231231231231231"})
    {:ok, user} = Repo.insert(User.changeset(%User{}, %{
      username: "username",
      email: "test@email.com",
      mobile: "09271363106",
      first_name: "test",
      last_name: "test",
      gender: "female",
      is_admin: false,
      member_id: member.id
    }))
    {:ok, user} = Repo.update(User.password_changeset(user, %{
      password: "P@ssw0rd",
      password_confirmation: "P@ssw0rd"
    }))

    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    token = Plug.current_token(conn)

    {:ok, %{user: user, conn: conn, token: token, member: member}}
  end

  test "login with valid params and verified true", %{conn: conn, user: user} do
    {:ok, user} = Repo.update(User.changeset(user, %{
      verification: true
    }))

    conn = post conn, "/api/v1/user/login", %{
      username: "username",
      password: "P@ssw0rd"
    }

    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601

    left = json_response(conn, 200)
    right = %{"user_id" => user.id, "token" => "#{token}", "expiry" => exp, "verified" => user.verification}

    assert left == right
  end

  test "login with valid params and verified false", %{conn: conn, user: user} do
    {:ok, user} = Repo.update(User.changeset(user, %{
      verification: false
    }))

    conn = post conn, "/api/v1/user/login", %{
      username: "username",
      password: "P@ssw0rd"
    }

    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601

    left = json_response(conn, 200)
    right = %{"user_id" => user.id, "token" => "#{token}", "expiry" => exp, "verified" => user.verification}

    assert left == right
  end

  test "login with username not found", %{conn: conn} do
    conn = post conn, "api/v1/user/login", %{
      username: "usernamenotfound",
      password: "P@ssw0rd"
    }

    left = json_response(conn, 404)
    right = %{"message" => "User not found", "code" => 404}

    assert left == right
  end

  test "login with nil hashed_password", %{conn: conn, member: member} do
    {:ok, _user} = Repo.insert(%User{username: "test_user", password: "P@ssw0rd", member_id: member.id})

    conn = post conn, "/api/v1/user/login", %{
      username: "test_user",
      password: "P@ssw0rd"
    }

    left = json_response(conn, 400)
    right = %{"message" => "Wrong username and password", "code" => 400}

    assert left == right
  end

  test "login with invalid password", %{conn: conn} do
    conn = post conn, "/api/v1/user/login", %{
      username: "username",
      password: "P@ssw0rd1"
    }

    left = json_response(conn, 400)
    right = %{"message" => "Wrong username and password", "code" => 400}

    assert left == right
  end

  test "login with username and card number" , %{conn: conn, member: member, user: user} do
    conn = post conn, "/api/v1/user/login_card", %{
      username: "username",
      card_no: "1231231231231231"
    }
    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601

    left = json_response(conn, 200)
    right = %{"member_id" => member.id, "user_id" => user.id, "token" => "#{token}", "expiry" => exp, "verified" => user.verification}
    assert left == right
  end

  test "login with valid username only" , %{conn: conn, member: member, user: user} do
    conn = post conn, "/api/v1/user/login_card", %{
      username: "username"
    }
    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601

    left = json_response(conn, 200)
    right = %{"member_id" => member.id, "user_id" => user.id, "token" => "#{token}", "expiry" => exp, "verified" => user.verification}
    assert left == right
  end

  test "login with valid card_no only" , %{conn: conn, member: member, user: user} do
    conn = post conn, "/api/v1/user/login_card", %{
      card_no: "1231231231231231"
    }
    token = Plug.current_token(conn)
    claims = Plug.current_claims(conn)
    exp =
      claims
      |> Map.get("exp")
      |> Ecto.DateTime.from_unix!(:second)
      |> Ecto.DateTime.to_iso8601

    left = json_response(conn, 200)
    right = %{"member_id" => member.id, "user_id" => user.id, "token" => "#{token}", "expiry" => exp, "verified" => user.verification}
    assert left == right
  end

  test "login with invalid username only" , %{conn: conn} do
    conn = post conn, "/api/v1/user/login_card", %{
      username: "username1"
    }
    left = json_response(conn, 404)
    right = %{"message" => "User not found", "code" => 404}
    assert left == right
  end

  test "login with invalid card_no only" , %{conn: conn} do
    conn = post conn, "/api/v1/user/login_card", %{
      card_no: "12312321231231231"
    }
    left = json_response(conn, 404)
    right = %{"message" => "User not found", "code" => 404}
    assert left == right
  end

  test "login with no parameters" , %{conn: conn} do
    conn = post conn, "/api/v1/user/login_card", %{
    }
    left = json_response(conn, 400)
    right = %{"message" => "No Parameters found", "code" => 400}
    assert left == right
  end

  test "login with empty values" , %{conn: conn} do
    conn = post conn, "/api/v1/user/login_card", %{
      username: "",
      card_no: ""
    }
    left = json_response(conn, 400)
    right = %{"message" => "Username or Card No can't be blank", "code" => 400}
    assert left == right
  end
end

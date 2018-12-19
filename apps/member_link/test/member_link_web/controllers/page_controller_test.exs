defmodule MemberLinkWeb.PageControllerTest do
  use MemberLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User
  }

  setup do
    {:ok, user} = Repo.insert(%User{username: "test_user", password: "P@ssw0rd"})
    conn = Plug.sign_in(build_conn(), user)

    {:ok, %{conn: conn, user: user}}
  end

 #test "GET /", %{conn: conn} do
 #  conn = get conn, "/en"
 #  assert html_response(conn, 200) =~ "Medilink"
 #end
end

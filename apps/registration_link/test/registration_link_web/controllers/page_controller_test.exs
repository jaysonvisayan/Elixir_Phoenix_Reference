defmodule RegistrationLinkWeb.PageControllerTest do
  use RegistrationLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias RegistrationLink.Guardian.Plug
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User
  }

  setup do
    {:ok, user} = Repo.insert(%User{username: "test_user", password: "P@ssw0rd"})
    conn = Plug.sign_in(build_conn(), user)

    {:ok, %{conn: conn, user: user}}
  end

end

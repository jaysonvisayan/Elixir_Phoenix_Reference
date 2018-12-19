defmodule MemberLinkWeb.ConnCase do
  import Plug.Conn
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      use Innerpeace.Db.SchemaCase
      import MemberLinkWeb.Router.Helpers
      alias Innerpeace.Db.Base.{
        UserContext,
        AuthContext
      }

      # The default endpoint for testing
      @endpoint MemberLinkWeb.Endpoint
      @locale "en"

      def authenticated(conn, user) do
        random = Ecto.UUID.generate
        secure_random = "#{user.id}+#{random}"

        conn
        |> bypass_through(MemberLinkWeb.Router, [:browser])
        |> get("/en")
        |> add_random_cookie(random)
        |> MemberLink.Guardian.Plug.sign_in(secure_random)
        # |> put_req_header("referer", "http://localhost:4001")
        |> send_resp(200, "Logged in")
        |> recycle()
      end

      defp add_random_cookie(conn, random) do
        random
        |> encrypt256
        |> store_cookie(conn)
      end

      defp encrypt256(value) do
        :sha256
        |> :crypto.hash(value)
        |> Base.encode16()
      end

      defp store_cookie(value, conn) do
        conn
        |> put_resp_cookie("nova", value, [
            secure: false,
            http_only: true,
            domain: conn.host
           ])
      end

      def fixture() do
        # a = insert(:application, name: "payorlink")
        # p = insert(:permission, keyword: permission.keyword, application: a, module: permission.module)
        # r = insert(:role, name: "trial role")
        # rp = insert(:role_permission, role: r, permission: p)
        u = insert(:user, username: "blahblah")
        # insert(:user_role, role: r, user: u)
        u
      end
    end
  end

  setup _tags do
    {:ok,
      conn: Phoenix.ConnTest.build_conn()
      |> assign(:locale, "en")
    }
  end

end

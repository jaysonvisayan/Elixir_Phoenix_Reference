defmodule Innerpeace.PayorLink.Web.Api.V1.EmailControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  # alias Innerpeace.Db.Base.Api.DiagnosisContext
  alias PayorLink.Guardian.Plug

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_acu_schedules", module: "Acu_Schedules"})
    conn = authenticated(conn, user)
    # conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)

    wel = %{
      "id": Ecto.UUID.generate(),
      "job_name": "test1",
      "job_params": "test2",
      "module_name": "test3",
      "function_name": "test4",
      "error_description": "test5"
    }
    e = "test@test.com"

    {:ok, %{
      conn: conn,
      email: e,
      logs: wel,
      jwt: jwt
    }}
  end

  test "sends worker error logs", %{conn: conn, email: email, logs: logs, jwt: jwt} do
    _params = %{
      "params" => %{
        "logs" => encoded_params([logs]),
        "emails" => [email]
      }
    }

    #TODO:
    conn
    |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(api_email_path(conn, :send_error_logs, params))
  end

  defp encoded_params(params) do
    params
    |> Enum.into([], &(&1))
    |> Poison.encode!()
  end
end

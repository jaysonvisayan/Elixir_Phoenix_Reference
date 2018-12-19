defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.DiagnosisControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    conn = Plug.sign_in(build_conn(), user)
    jwt = Plug.current_token(conn)
    diagnosis2 = insert(:diagnosis, code: "A00.0", description: "Sample Description")

    {:ok, %{
      conn: conn,
      jwt: jwt,
      diagnosis: diagnosis2
    }}
  end

  # test "lists all entries on index", %{conn: conn, diagnosis: diagnosis2, jwt: jwt} do
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_diagnosis_path(conn, :index))
  #   assert %{"data" => json_response(conn, 200)["diagnosis"]} == render_json("index.json", diagnoses: [diagnosis2])
  # end



end

defmodule Innerpeace.Payorlink.Web.Api.V1.LocationGroupControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"

    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)
    insert(:location_group,
           name: "test location group",
           code: "test code",
           created_by_id: user.id,
           updated_by_id: user.id,
           description: "Test")

    {:ok, %{jwt: jwt}}
  end

  # test "create_lg/2, creates location group with valid parameters", %{conn: conn, jwt: jwt} do
  #   insert(:user)
  #   params = %{
  #     "name" => "samplename",
  #     "description" => "sampledesc",
  #     "region" => ["Region I - Ilocos Region",
  #                  "Region II - Cagayan Valley",
  #                  "Region III - Central Luzon",
  #                  "Region IV-A - CALABARZON"]
  #   }

  #   conn =
  #     build_conn()
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_location_group_path(conn, :create_lg), params)

  #   result = json_response(conn, 200)
  #   assert result["name"] == "samplename"
  # end

  # test "create_lg/2, create location group with invalid params", %{conn: conn, jwt: jwt} do
  #   insert(:user)
  #   params = %{
  #     "name" => "samplename",
  #     "description" => "sampledesc",
  #     "region" => ["Region I - Ilocossasa Region",
  #                  "Region II - Cagayan Valley",
  #                  "Region III - Central Luzon",
  #                  "Region IV-A - CALABARZON"]
  #   }
  #   conn =
  #     build_conn()
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_location_group_path(conn, :create_lg), params)

  #   result = json_response(conn, 404)
  #   assert List.first(result["errors"]["region"]) == "Region I - Ilocossasa Region is invalid."
  # end
end

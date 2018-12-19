defmodule Innerpeace.PayorLink.Web.Api.V1.BenefitControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Base.Api.BenefitContext

  alias PayorLink.Guardian.Plug
  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    {:ok, %{conn: conn, jwt: jwt}}
  end

  test "/benefits, loads all records of benefit", %{conn: conn} do
    benefit = BenefitContext.get_all_benefit()
    insert(:user)

    params = %{}

    conn =
      conn
      |> get(api_benefit_path(conn, :index, params))
    assert %{"data" => json_response(conn, 200)["data"]} == render_json("index.json", benefit: benefit)
  end

  # test "create benefit returns benefit struct when params are valid", %{conn: conn, jwt: jwt} do
  #   coverage = insert(:coverage, %{plan_type: "riders", name: "ACU", code: "ACU"})
  #   insert(:procedure)
  #   package = insert(:package, code: "package123")
  #   params = %{
  #     name: "test",
  #     code: "test",
  #     category: "Riders",
  #     coverages: [coverage.code],
  #     packages: [package.code],
  #     acu_type: "Executive",
  #     acu_coverage: "Inpatient",
  #     peme: true,
  #     provider_access: "Hospital/Clinic",
  #     condition: "ALL"
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_benefit_path(conn, :create, params))
  #   assert json_response(conn, 200)
  # end

  # test "create benefit returns errors when params are invalid", %{conn: conn, jwt: jwt} do
  #   _params = %{
  #   }
  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_benefit_path(conn, :create))
  #   assert json_response(conn, 400)
  #   ## ["error"]["message"] =~ "name is required"
  # end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.BenefitView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

end

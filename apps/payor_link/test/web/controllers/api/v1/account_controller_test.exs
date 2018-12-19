defmodule Innerpeace.PayorLink.Web.Api.V1.AccountControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Base.Api.AccountContext

  test "/accounts, loads all records of account group" do
    _search_query = ""
    account_group = AccountContext.get_all_accounts()
    user = insert(:user)

    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)

    params = %{}

    conn =
      conn
      |> get(api_account_path(conn, :index, params))
    assert %{"data" => json_response(conn, 200)["data"]} == render_json("index.json", account_group: account_group)
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.AccountView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end
end

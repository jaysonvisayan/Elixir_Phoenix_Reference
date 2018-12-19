defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.MemberController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext,
    Api.MemberContext
  }

  alias Ecto.Changeset
  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Endpoint

  def create(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      case MemberContext.create(params) do
        {:ok, member} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", changeset: changeset, code: 400)

        _ ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def create(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end
end

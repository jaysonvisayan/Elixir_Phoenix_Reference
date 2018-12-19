defmodule Innerpeace.PayorLink.Web.Api.V1.LocationGroupController do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.Api.{
    LocationGroupContext,
    LocationGroupRegionContext}

  alias Innerpeace.Db.Schemas.{
    LocationGroup,
    LocationGroupRegion}

  alias PayorLink.Guardian, as: PG

  def create_lg(
    conn,
    %{
      "name" => name,
      "description" => description,
      "region" => region
    })
  do

    param = %{
      name: name,
      description: description,
      region: region
    }

    case LocationGroupContext.create(PG.current_resource_api(conn), param) do
      {:ok, location_group} ->
        conn
        |> render(
          Innerpeace.PayorLink.Web.Api.V1.LocationGroupView,
          "location_group.json",
          location_group: location_group
        )
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:unauthorized} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Unauthorized")
    end
  end
end

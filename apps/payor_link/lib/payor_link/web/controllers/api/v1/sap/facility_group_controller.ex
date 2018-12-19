defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.FacilityGroupController do
    use Innerpeace.PayorLink.Web, :controller
    
    alias Innerpeace.Db.Base.Api.FacilityGroupContext
    alias PayorLink.Guardian, as: PG
    alias Innerpeace.PayorLink.Web.Endpoint
    alias Innerpeace.Db.Schemas.LocationGroup

    def facility_group(conn, params) do
        with %LocationGroup{} = facility_group <- FacilityGroupContext.get_facility_group(params) do
            conn
            |> put_status(200)
            |> render(Innerpeace.PayorLink.Web.Api.V1.LocationGroupView, "facility_group.json", facility_group: facility_group)
        else      
        [] ->
            conn
            |> put_status(404)
            |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Facility Group not found", code: 404)    
        {:error, changeset} ->
            conn
            |> put_status(404)
            |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Facility Group not found", code: 404)
        _->
            conn
            |> put_status(404)
            |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Facility Group not found", code: 404)
        end
    end

end
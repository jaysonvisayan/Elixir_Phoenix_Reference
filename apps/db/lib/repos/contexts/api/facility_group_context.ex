defmodule Innerpeace.Db.Base.Api.FacilityGroupContext do
    @moduledoc false

    import Ecto.Query
    alias Innerpeace.Db.Schemas.LocationGroup
    alias Innerpeace.Db.Repo

    def get_facility_group_by_code(struct, code) do
      struct
        |> where([fg], fg.code == ^code)
    end

    def get_facility_group_by_name(struct, name) do
      struct
        |> where([fg], fg.name == ^name)
    end

    def facility_group_details(struct) do
      struct 
        |> select([f], %{id: f.id, code: f.code, name: f.name})        
    end

    def get_facility_group(%{"code" => code, "name" => name}) do
      LocationGroup
        |> get_facility_group_by_code(code)
        |> get_facility_group_by_name(name)
        |> Repo.one()
        |> Repo.preload([location_group_region: :region, facility_location_group: :facility])
    end

end
defmodule Innerpeace.Db.Base.LocationGroupRegionContext do
  @moduledoc false
  import Ecto.Query

  alias Innerpeace.Db.{
    Repo,
    Schemas.LocationGroupRegion
  }

  def create_location_group_region(location_group_region_params) do
    %LocationGroupRegion{}
    |> LocationGroupRegion.changeset_create(location_group_region_params)
    |> Repo.insert()
  end

  def delete_location_group_region(location_group_id) do
    LocationGroupRegion
    |> where([l], l.location_group_id == ^location_group_id)
    |> Repo.delete_all()
  end

  def get_all_location_group_region(location_group_id) do
    LocationGroupRegion
    |> where([l], l.location_group_id == ^location_group_id)
    |> Repo.all()
  end

  def get_all_region_per_island_group(location_group_id, island_group) do
    LocationGroupRegion
    |> where([l], l.location_group_id == ^location_group_id and l.island_group == ^island_group)
    |> Repo.all()

  end

end

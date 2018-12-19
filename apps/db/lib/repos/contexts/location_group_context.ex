defmodule Innerpeace.Db.Base.LocationGroupContext do
  @moduledoc false
  import Ecto.Query

  alias Innerpeace.Db.{
    Repo,
    Schemas.LocationGroup,
    Schemas.LocationGroupRegion,
    Schemas.FacilityLocationGroup,
    Schemas.Facility,
    Schemas.Region,
    Base.Api.UtilityContext
  }

  def create_location_group(location_group_params) do
    %LocationGroup{}
    |> LocationGroup.changeset(location_group_params)
    |> Repo.insert()
  end

  def update_location_group(location_group_params, location_group) do
    delete_location_group_region(location_group)
    delete_location_group_facility(location_group)
    location_group
    |> LocationGroup.changeset_update(location_group_params)
    |> Repo.update()
  end

  def delete_location_group_region(location_group) do
    LocationGroupRegion
    |> where([lgr], lgr.location_group_id == ^location_group.id)
    |> Repo.delete_all()
  end

  def delete_location_group_facility(location_group) do
    FacilityLocationGroup
    |> where([lgf], lgf.location_group_id == ^location_group.id)
    |> Repo.delete_all()
  end

  # def create_location_group_region(location_group_region_params) do
  #   %LocationGroupRegion{}
  #   |> LocationGroupRegion.changeset_create(location_group_region_params)
  #   |> Repo.insert()
  # end

  def get_location_group(id) do
    LocationGroup
    |> Repo.get(id)
    |> Repo.preload([
      location_group_region: :region,
      facility_location_group: :facility
    ])
  end

  def get_location_group_by_id(id) do
    LocationGroup
    |> Repo.get(id)
  end

  def get_all_location_group do
    LocationGroup
    |> Repo.all()
  end

  def update_step2(location_group, location_group_params) do
    location_group
    |> LocationGroup.changeset_update_step2(location_group_params)
    |> Repo.update()
  end

  def update_step3(location_group, location_group_params) do
    location_group
    |> LocationGroup.changeset_update_step3(location_group_params)
    |> Repo.update()
  end

  def get_location_group_by_region(region_name) do
    LocationGroup
    |> join(
      :inner,
      [lg],
      lgr in LocationGroupRegion,
      lg.id == lgr.location_group_id
    )
    |> where(
      [lg, lgr],
      ilike(lgr.region_name, ^"%#{region_name}%")
      and lg.step == ^"4"
    )
    |> select([lg], %{
      id:  lg.id,
      name: lg.name
    })
    |> distinct([lg], lg.name)
    |> Repo.all()
  end

  def delete_lg(id) do
    lg =
      LocationGroup
      |> Repo.get!(id)

    LocationGroupRegion
    |> where([lgr], lgr.location_group_id == ^id)
    |> Repo.delete_all

    FacilityLocationGroup
    |> where([lgf], lgf.location_group_id == ^id)
    |> Repo.delete_all

    lg
    |> Repo.delete
  end

  def get_location_group_by_name(region_name) do
    LocationGroup
    |> Repo.get_by(name: region_name)
  end

  def get_facility_per_location_group(location_group_id) do
    query = (
      from f in Facility,
      join: flg in FacilityLocationGroup, on: flg.facility_id == f.id,
      where: flg.location_group_id == ^location_group_id,
      select: f
    )
    _query = Repo.all query
  end

  def get_all_location_group_name do
    LocationGroup
    |> select([:name])
    |> Repo.all()
  end

  def get_all_names do
    LocationGroup
    |> select([lg], lg.name)
    |> Repo.all()
  end

  def check_facility_group_name(facility_group_name) do
    LocationGroup
    |> where([lg], fragment("LOWER(?) = LOWER(?)", lg.name, ^facility_group_name))
    |> select([lg], lg.name)
    |> limit(1)
    |> Repo.one()
  end

  def insert_or_update_region(params) do
    region = get_region_by_region_and_island_group(params)
    if is_nil(region) do
      create_region(params)
    else
      update_region(region, params)
    end
  end

  def get_region_by_region_and_island_group(params) do
    Region
    |> Repo.get_by(region: params.region, island_group: params.island_group)
  end

  def get_all_region(island_group) do
    Region
    |> where([r], r.island_group == ^island_group and r.region != "All")
    |> select([r], %{id: r.id, island_group: r.island_group, region: r.region})
    |> Repo.all()
  end

  def get_all_region() do
    Region
    |> order_by(asc: :index)
    |> select([r], %{id: r.id, island_group: r.island_group, region: r.region, index: r.index})
    |> Repo.all()
  end

  def get_region(id) do
    Region
    |> Repo.get(id)
  end

  def create_region(params) do
    %Region{}
    |> Region.changeset(params)
    |> Repo.insert()
  end

  def update_region(region, params) do
    region
    |> Region.changeset(params)
    |> Repo.update()
  end

  def create_location_group_region_or_facility(location_group, params) do
    if params["selecting_type"] == "Region" do
      regions = Enum.reject(params["regions"], &(&1 == ""))
      with false <- Enum.empty?(regions) do
        region_params = Enum.map(regions, fn(rg) ->
          %{
            location_group_id: location_group.id,
            region_id:  rg,
            inserted_at: Ecto.DateTime.utc(),
            updated_at: Ecto.DateTime.utc()
          }
        end)
        {:ok, create_location_group_region(region_params)}
      else
        _ ->
          delete_lg(location_group.id)
          {:error_message, "Select atleast one(1) region"}
      end
    else
      with false <- Enum.empty?(params["facility_ids"]) do
        facility_params = Enum.map(params["facility_ids"], fn(fl) ->
          %{
            location_group_id: location_group.id,
            facility_id:  fl,
            inserted_at: Ecto.DateTime.utc(),
            updated_at: Ecto.DateTime.utc()
          }
        end)
        clear_location_group_facility(location_group.id) ## clearing of facility
        {:ok, create_location_group_facility(facility_params)}
      else
        _ ->
          delete_lg(location_group.id)
          {:error_message, "Add atleast one(1) facility"}
      end
    end
  end

  def clear_location_group_facility(location_group_id) do
    FacilityLocationGroup
    |> where([flg], flg.location_group_id == ^location_group_id)
    |> Repo.delete_all()
  end

  def create_location_group_region(location_group_region_params) do
    # %LocationGroupRegion{}
    # |> LocationGroupRegion.changeset(location_group_region_params)
    # |> Repo.insert()

    lgp_count =
      location_group_region_params
      |> Enum.count()

    if lgp_count >= 5000 do
      lists =
        location_group_region_params
        |> UtilityContext.partition_list(4999, [])

        Enum.map(lists, fn(x) ->
          LocationGroupRegion
          |> Repo.insert_all(x)
        end)
    else
      LocationGroupRegion
      |> Repo.insert_all(location_group_region_params)
    end
  end

  def create_location_group_facility(location_group_facility_params) do
    lgf_count =
      location_group_facility_params
      |> Enum.count()

    if lgf_count >= 5000 do
      lists =
        location_group_facility_params
        |> UtilityContext.partition_list(4999, [])

      Enum.map(lists, fn(x) ->
        FacilityLocationGroup
        |> Repo.insert_all(x)
      end)
    else
      FacilityLocationGroup
      |> Repo.insert_all(location_group_facility_params)
    end
  end

  def get_inserted_region(lg_id) do
    Region
    |> join(:inner, [r], lgr in LocationGroupRegion, r.id == lgr.region_id)
    |> join(:inner, [r, lgr], lg in LocationGroup, lgr.location_group_id == lg.id)
    |> select([r, lgr, lg], r.id)
    |> where([r, lgr, lg], lg.id == ^lg_id)
    |> Repo.all()
  end

  def load_facility_group_data(id) do
    LocationGroup
    |> Repo.get(id)
    |> preload_flg()
  end

  def preload_flg(struct) do
    struct
    |> Repo.preload([
      facility_location_group: [facility: [:category, :type]]
    ])
  end

end

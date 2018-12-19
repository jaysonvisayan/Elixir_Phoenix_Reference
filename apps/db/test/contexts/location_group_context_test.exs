defmodule Innerpeace.Db.Base.LocationGroupContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.{
    Repo,
    Schemas.LocationGroup,
    Base.LocationGroupContext
  }

  test "get_all_location_group/0, returns all location group " do
    location_group = insert(:location_group)
    assert LocationGroupContext.get_all_location_group() == [location_group]
  end

  test "get_location_group/1, returns all location group with given id" do
    location_group = insert(:location_group)
    location_group =
      location_group
      |> Repo.preload([
        location_group_region: :region,
        facility_location_group: :facility
      ])
    assert LocationGroupContext.get_location_group(
      location_group.id) == location_group
  end

  test "create_location_group/1, inserts location group record with valid parameters" do
    user = insert(:user)
    params = %{
      "created_by_id" => user.id,
      "description" => "sample desc",
      "name" => "joe",
      "step" => "1",
      "selecting_type" => "Region",
      "updated_by_id" => user.id
    }
    {:ok, location_group} = LocationGroupContext.create_location_group(params)
    assert location_group.name == params["name"]
    assert location_group.description == params["description"]
    assert location_group.step == params["step"]
    assert location_group.updated_by_id == params["updated_by_id"]
    assert location_group.created_by_id == params["created_by_id"]
  end

  test "create_location_group/1, inserts location group record with invalid parameters" do
    user = insert(:user)
    params = %{
      "created_by_id" => user.id,
      "description" => nil,
      "name" => "Joe",
      "step" => 9,
      "updated_by_id" => user.id
    }
    {:error, changeset} = LocationGroupContext.create_location_group(params)
    assert changeset.valid? == false
  end

  test "update_location_group/2, updated a location group record with valid parameters" do
    user = insert(:user)
    location_group = insert(:location_group)
    params = %{
      "created_by_id" => user.id,
      "description" => "new desc",
      "name" => "Glen",
      "step" => "9",
      "selecting_type" => "Region",
      "updated_by_id" => user.id
    }
    {:ok, location_group} = LocationGroupContext.update_location_group(params, location_group)
    assert location_group.name == params["name"]
    assert location_group.description == params["description"]
    assert location_group.step == params["step"]
    assert location_group.updated_by_id == params["updated_by_id"]
    assert location_group.created_by_id == params["created_by_id"]
  end

  test "update_location_group/2, updated a location group record with invalid parameters" do
    user = insert(:user)
    location_group = insert(:location_group)
    params = %{
      "created_by_id" => user.id,
      "description" => "new desc",
      "name" => nil,
      "step" => "9",
      "updated_by_id" => user.id
    }
    {:error, changeset} = LocationGroupContext.update_location_group(params, location_group)
     assert changeset.valid? == false
  end

  test "get_all_region/1, returns all region" do
    region = insert(:region)
    assert List.first(LocationGroupContext.get_all_region()).id == region.id
  end

  test "get_region/1, returns all region with given id" do
    region = insert(:region)

    assert LocationGroupContext.get_region(
      region.id) == region
  end

  test "create_region/1, creates a region with valid parameters" do
    params = %{
      "island_group" => "Luzon",
      "region" => "Region 1"
    }
    {:ok, region} = LocationGroupContext.create_region(params)
    assert region.island_group == params["island_group"]
    assert region.region == params["region"]
  end

  test "create_region/1, creates a region with invalid parameters" do
    params = %{
      "island_group" => "Luzon"
    }
    {:error, changeset} = LocationGroupContext.create_region(params)
     assert changeset.valid? == false
  end

  test "update_region/1, updates a region with valid parameters" do
    region = insert(:region)
    params = %{
      "island_group" => "Luzon",
      "region" => "Region 1"
    }
    {:ok, region} = LocationGroupContext.update_region(region, params)
    assert region.island_group == params["island_group"]
    assert region.region == params["region"]
  end

  test "update_region/1, updates a region with invalid parameters" do
    region = insert(:region)
    params = %{
      "island_group" => "Luzon"
    }
    {:error, changeset} = LocationGroupContext.update_region(region, params)
     assert changeset.valid? == false
  end

  # test "create_location_group_region/1, create a location group region record with valid parameters" do
  #   user = insert(:user)
  #   location_group = insert(:location_group)
  #   params = %{
  #     "created_by_id" => user.id,
  #     "region_name" => "Region Name",
  #     "location_group_id" => location_group.id,
  #     "updated_by_id" => user.id,
  #     "island_group" =>  "Isla"
  #   }
  #   {:ok, location_group_region} = LocationGroupContext.create_location_group_region(params)
  #   assert location_group_region.created_by_id == params["created_by_id"]
  #   assert location_group_region.updated_by_id == params["updated_by_id"]
  #   assert location_group_region.region_name == params["region_name"]
  #   assert location_group_region.location_group_id == params["location_group_id"]
  #   assert location_group_region.island_group == params["island_group"]
  # end

  # test "create_location_group_region/1, create a location group region record with invalid parameter" do
  #   user = insert(:user)
  #   location_group = insert(:location_group)
  #   params = %{
  #     "created_by_id" => user.id,
  #     "region_name" => nil,
  #     "location_group_id" => location_group.id,
  #     "updated_by_id" => user.id,
  #     "island_group" =>  "Isla"
  #   }
  #   {:error, changeset} = LocationGroupContext.create_location_group_region(params)
  #   assert changeset.valid? == false
  # end

  # test "update_step2/2, update step2 location group record with valid parameters" do
  #   location_group = insert(:location_group)
  #   params = %{
  #     "step" => "3"
  #   }
  #   {:ok, location_group} = LocationGroupContext.update_step2(location_group, params)
  #   assert location_group.step == "3"
  # end

  # test "update_step2/2, update step2 location group record with invalid params" do
  #   location_group = insert(:location_group)
  #   params = %{
  #    "step" => nil
  #   }
  #   {:error, changeset} = LocationGroupContext.update_step2(location_group, params)
  #   assert changeset.valid? == false
  # end

  test "delete_lg/1, delete location group" do
    location_group = insert(:location_group)
    params =  %{
     "id" => location_group.id
    }

    assert {:ok, _lg_result} = LocationGroupContext.delete_lg(params["id"])

    lg =
      LocationGroup
      |> Repo.get_by(id: location_group.id)

    assert is_nil(lg)
  end

  test "get_location_group_by_region/1, " do
    lg = insert(:location_group, step: "4", name: "sample")
    location_group_region = insert(:location_group_region, region_name: "Region Name", location_group_id: lg.id)
    location_group = LocationGroupContext.get_location_group_by_region(location_group_region.region_name)
    assert List.first(location_group).name == "sample"
  end

  test "check_location_group_name" do
    facility_group_name = "test_name"
    assert is_nil(LocationGroupContext.check_facility_group_name(facility_group_name))
  end
end

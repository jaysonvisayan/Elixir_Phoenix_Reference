defmodule Innerpeace.PayorLink.Web.Api.V1.LocationGroupView do
  use Innerpeace.PayorLink.Web, :view

  def render("location_group.json", %{location_group: location_group}) do
    %{
      name: location_group.name,
      description: location_group.description,
      region: render_many(
        location_group.location_group_region,
        Innerpeace.PayorLink.Web.Api.V1.LocationGroupView,
        "location_group_region.json", as: :location_group_region)
    }
  end

  def render("location_group_region.json", %{location_group_region: location_group_region}) do
    %{
      region_name: location_group_region.region_name,
      island_group: location_group_region.island_group
    }
  end

  def render("facility_group.json",  %{facility_group: facility_group}) do
    region_value = if facility_group.selecting_type == "Region" do
      %{
        region: render_many(
          facility_group.location_group_region,
          Innerpeace.PayorLink.Web.Api.V1.LocationGroupView,
          "location_group_region2.json", as: :location_group_region)
      }
    else
      %{
        facility: render_many(
          facility_group.facility_location_group,
          Innerpeace.PayorLink.Web.Api.V1.LocationGroupView,
          "facility_location_group.json", as: :facility_location_group)
      }
    end

    %{
      code: facility_group.code,
      name: facility_group.name,
      description: facility_group.description,
      selecting_type: facility_group.selecting_type,
      region_value: region_value
    }
  end

  def render("location_group_region2.json", %{location_group_region: location_group_region}) do
    %{
      region_name: location_group_region.region.region,
      island_group: location_group_region.region.island_group
    }
  end

  def render("facility_location_group.json", %{facility_location_group: facility_location_group}) do
    %{
      code: facility_location_group.facility.code,
      name: facility_location_group.facility.name
    }
  end

end

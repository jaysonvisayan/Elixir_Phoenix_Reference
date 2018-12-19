defmodule Innerpeace.PayorLink.Web.Main.FacilityGroupView do
  use Innerpeace.PayorLink.Web, :view

  def get_region(regions) do
    regions_v2 = Enum.reject(regions, &(&1.region == "All"))
    [
      Enum.filter(regions_v2, &(&1.island_group == "Luzon")),
      Enum.filter(regions_v2, &(&1.island_group == "Visayas")),
      Enum.filter(regions_v2, &(&1.island_group == "Mindanao")),
      Enum.filter(regions, &(&1.region == "All"))
    ]
  end

  def check_all(selected_regions, all_regions, island_group) do
    region = Enum.find(all_regions, &(&1.island_group == island_group))
    if Enum.member?(selected_regions, region.id) do
      "checked"
    end
  end

  def check([], region), do: ""
  def check(selected_regions, region) do
    if Enum.member?(selected_regions, region) do
      "checked"
    end
  end

  def region_checker_luzon(regions) do
    return = for region <- regions do
      if region.island_group == "Luzon" do
        true
      else
        false
      end
    end
    Enum.member?(return, true)
  end

  def region_checker_visayas(regions) do
    return = for region <- regions do
      if region.island_group == "Visayas" do
        true
      else
        false
      end
    end
    Enum.member?(return, true)
  end

  def region_checker_mindanao(regions) do
    return = for region <- regions do
      if region.island_group == "Mindanao" do
        true
      else
        false
      end
    end
    Enum.member?(return, true)
  end

  def render("load_facility_group.json", %{facility_group: facility_group}) do
    %{
      id: facility_group.id,
      code: facility_group.code,
      name: facility_group.name,
      description: facility_group.description,
      selecting_type: facility_group.selecting_type,
      status: facility_group.status,
      facility_location_groups: render_many(
        facility_group.facility_location_group,
        Innerpeace.PayorLink.Web.Main.FacilityGroupView,
        "facility_location_group.json", as: :facility_location_group
      )
    }
  end

  def render("facility_location_group.json", %{facility_location_group: facility_location_group}) do
    %{
      id: facility_location_group.id,
      facility_name: facility_location_group.facility.name,
      facility_code: facility_location_group.facility.code,
      facility_region: facility_location_group.facility.region,
      facility_category: check_facility_category(facility_location_group.facility.category),
      facility_type: facility_location_group.facility.type.text,
      facility_id: facility_location_group.facility.id
    }
  end

  defp check_facility_category(nil), do: ""
  defp check_facility_category(category), do: category.text

end

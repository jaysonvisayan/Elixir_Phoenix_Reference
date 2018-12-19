defmodule Innerpeace.PayorLink.Web.LocationGroupView do
  use Innerpeace.PayorLink.Web, :view

  def check_state(lcr_list, region) do
    if Enum.member?(lcr_list, region), do: "checked", else: ""
  end

  def check_region_state(lcr_list, region) do
    if lcr_list != [] do
      crs_level2(lcr_list, region)
    else
      ""
    end
  end

  def crs_level2(lcr_list, region) do
    # Check Region State 2

    luzon = [
      "Region I - Ilocos Region",
      "Region II - Cagayan Valley",
      "Region III - Central Luzon",
      "CAR - Cordillera Administrative Region",
      "NCR - National Capital Region",
      "Region IV-A - CALABARZON",
      "Region IV-B MIMAROPA - Southwestern Tagalog Region",
      "Region V - Bicol Region"
    ]

    visayas = [
      "Region VI - Western Visayas",
      "Region VII - Central Visayas",
      "Region VIII - Eastern Visayas"
    ]

    mindanao = [
      "Region IX - Zamboanga Peninsula",
      "Region X - Northern Mindanao",
      "Region XI - Davao Region",
      "Region XII - SOCCSKSARGEN",
      "Region XIII - Caraga Region",
      "ARMM - Autonomous Region in Muslim Mindanao"
    ]

      case region do
        "luzon" ->
          if luzon -- lcr_list == [], do: "checked", else: ""

        "visayas" ->
          if visayas -- lcr_list == [], do: "checked", else: ""

        "mindanao" ->
          if mindanao -- lcr_list == [], do: "checked", else: ""

        _ ->
          ""
      end
  end
end

defmodule Innerpeace.Db.RegionSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.RegionSeeder
  @region "Region I - Ilocos Region"

  test "seed region with new data" do
    [r1] = RegionSeeder.seed(data())
    assert r1.region == @region
  end

  test "seed region with existing data" do
    r = insert(:region, region: @region, island_group: "Luzon")
     [r1] = RegionSeeder.seed(data())
     assert r1.region == @region
   end

  defp data() do
    [
      %{
        island_group: "Luzon" ,
        region: @region
      }
    ]
  end

end

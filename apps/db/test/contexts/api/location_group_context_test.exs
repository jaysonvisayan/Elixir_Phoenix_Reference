defmodule Innerpeace.Db.Base.Api.LocationGroupContextTest do
 use Innerpeace.Db.SchemaCase

 alias Innerpeace.Db.Base.Api.LocationGroupContext

 # test "create/2, inserts a location group record with valid parameters" do
 #   user = insert(:user)

 #   params = %{
 #    "name" => "sample1",
 #    "description" => "sample desc",
 #    "region" => ["Region I - Ilocos Region",
 #        "Region II - Cagayan Valley",
 #        "Region III - Central Luzon"]
 #   }

 #   {result, _changeset} = LocationGroupContext.create(user, params)

 #   assert result == :ok
 # end

 #   test "create/2, inserts a location group with name already existing in database" do
 #     user = insert(:user)
 #     insert(:location_group, name: "sample")
 #     params = %{
 #       "name" => "sample",
 #       "description" => "sampledesc",
 #       "region" => ["Region I - Ilocos Region",
 #                    "Region II - Cagayan Valley",
 #                    "Region III - Central Luzon"]
 #     }

 #     {:error, changeset} = LocationGroupContext.create(user, params)
 #     assert changeset.valid? == false
 #   end

 #   test "create/2, inserts a location group without name and description" do
 #    user = insert(:user)
 #     params = %{
 #       "name" => "",
 #       "description" => "",
 #       "region" => ["Region I - Ilocos Region",
 #                    "Region II - Cagayan Valley",
 #                    "Region III - Central Luzon"]
 #     }

 #     {:error, changeset} = LocationGroupContext.create(user, params)
 #     assert changeset.valid? == false
 #   end

 #   test "create/2, inserts a location group with invalid regions" do
 #     user = insert(:user)
 #     params = %{
 #       "name" => "sample",
 #       "description" => "sampledesc",
 #       "region" => ["Region I - sampling",
 #                    "Region II - Cagayan Valley",
 #                    "Region III - Central Luzon"]
 #     }

 #     {:error, changeset} = LocationGroupContext.create(user, params)
 #     assert changeset.valid? == false
 #   end
 end

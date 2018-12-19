defmodule Innerpeace.Db.ProductSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ProductSeeder
  @name "Maxicare Product 1"
  @description "Health card for regular employee"
  @limit_applicability "Individual"
  @limit_type "MBL"
  @limit_amount 100000
  @phic_status "Required to file"
  @standard_product "Yes"


  # test "seed user with new data" do
  # insert(:payor, name: "Maxicare")
  #   [pr1] = ProductSeeder.seed(data())
  #   assert pr1["name"] == @name
  # end

  # test "seed user with existing data" do
  #   insert(:product, name: @name)
  #   #####  update data
  #   data = [
  #     %{
  #       "name" => "Maxicare Product 1",
  #       "description" => "Health card for regular employee",
  #       "limit_applicability" => "Individual",
  #       "type" => "Platinum",
  #       "limit_type" => "MBL",
  #       "limit_amount" => 100000,
  #       "phic_status" => "Required to file",
  #       "standard_product" => "Yes",
  #       "updated_by_id" => Ecto.UUID.generate(),
  #       "step" => "2",
  #       "member_type" => ["Principal"],
  #       "product_base" => "Exclusion-based"
  #     }
  #   ]
  #   [pa1] = ProductSeeder.seed(data)
  #   assert pa1["name"] == "Maxicare Product 1"
  # end

  #####  insert data
  defp data do
    [
      %{
        "name" => @name,
        "description" => @description,
        "limit_applicability" => @limit_applicability,
        "type" => "Premium",
        "limit_type" => @limit_type,
        "limit_amount" => @limit_amount,
        "phic_status" => @phic_status,
        "standard_product" => @standard_product,
        "step" => "2",
        "created_by_id" => Ecto.UUID.generate(),
        "member_type" => ["Principal"],
        "product_base" => "Exclusion-based"
      }
    ]
  end

end

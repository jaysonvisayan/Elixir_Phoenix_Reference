defmodule Innerpeace.Db.ProductBenefitSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ProductBenefitSeeder

  test "seed product benefit with new data" do
    benefit = insert(:benefit)
    product = insert(:product)
    [a1] = ProductBenefitSeeder.seed(data(benefit,product))
    assert a1.benefit_id == benefit.id
  end

  test "seed product benefit with existing data" do
    benefit = insert(:benefit)
    product = insert(:product, name: "Product Test")
    insert(:product_benefit)
    data = [
      %{
        benefit_id: benefit.id,
        product_id: product.id
      }
    ]
    [a1] = ProductBenefitSeeder.seed(data)
    assert a1.benefit_id == benefit.id
  end


  defp data(benefit, product) do
    [
      %{
         benefit_id: benefit.id,
         product_id: product.id
      }
    ]
  end

end

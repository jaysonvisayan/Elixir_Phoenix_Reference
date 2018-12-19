defmodule Innerpeace.Db.Schemas.ProductTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Product
  alias Ecto.UUID

  test "changeset_general with valid attributes" do
    params = %{
      name: "test_name",
      description: "test_desc",
      limit_applicability: "test limit_app",
      type: "test product type",
      limit_type: "test limit typej",
      limit_amount: 100.00,
      phic_status: "test phic_status",
      standard_product: "test standard product",
      payor_id: UUID.generate(),
      step: "2",
      created_by_id: UUID.generate(),
      member_type: ["Principal"],
      product_base: "Exclusion-based"
    }

    changeset_general = Product.changeset_general(%Product{}, params)
    assert changeset_general.valid?
  end

  test "changeset_general with invalid attributes" do
    params = %{
      name: "",
      description: "",
      limit_applicability: "",
      type: "",
      limit_type: "",
      limit_amount: nil,
      phic_status: "",
      standard_product: "",
      payor_id: nil
    }

    changeset_general = Product.changeset_general(%Product{}, params)
    refute changeset_general.valid?
  end

  test "random_pcode" do
    randomized_pcode = Product.random_pcode()
    assert randomized_pcode
  end

  test "changeset_condition with valid attributes" do
    params = %{
      principal_min_age: 18,
      principal_min_type: "Years",
      principal_max_age: 64,
      principal_max_type: "Years",
      adult_dependent_min_age: 18,
      adult_dependent_min_type: "Years",
      adult_dependent_max_age: 65,
      adult_dependent_max_type: "Years",
      minor_dependent_min_age: 15,
      minor_dependent_min_type: "Days",
      minor_dependent_max_age: 20,
      minor_dependent_max_type: "Days",
      overage_dependent_min_age: 66,
      overage_dependent_min_type: "Years",
      overage_dependent_max_age: 70,
      overage_dependent_max_type: "Years",
      adnb: 1000.00,
      adnnb: 1000.00,
      opmnb: 2500.00,
      opmnnb: 5000.00,
      nem_principal: 300,
      loa_facilitated: true,
      nem_dependent: 500,
      hierarchy_waiver: "Enforce",
      no_days_valid: 100,
      is_medina: true,
      smp_limit: 120.50
    }

    changeset_condition = Product.changeset_condition(%Product{}, params)
    assert changeset_condition.valid?
  end

  test "changeset_condition with invalid attributes" do
    params = %{
      principal_min_age: nil,
      principal_min_type: "",
      principal_max_age: nil,
      principal_max_type: "",
      adult_dependent_min_age: 18,
      adult_dependent_max_age: 65,
      adult_dependent_max_type: "Years",
      minor_dependent_min_age: 15,
      minor_dependent_min_type: "Days",
      minor_dependent_max_age: 20,
      minor_dependent_max_type: "Days",
      overage_dependent_min_age: "test",
      overage_dependent_min_type: "Years",
      overage_dependent_max_age: 70,
      overage_dependent_max_type: "Years",
      adnb: 1000.00,
      adnnb: 1000.00,
      opmnb: 2500.00,
      opmnnb: 5000.00,
      room_and_board: "Alternative",
      room_type: "Suite",
      room_limit_amount: 100_000.00,
      room_upgrade: 12,
      room_upgrade_time: "Hours"
    }

    changeset_condition = Product.changeset_condition(%Product{}, params)
    refute changeset_condition.valid?
  end

  test "changeset_facilities_included with valid attributes" do
    params = %{
      include_all_facilities: true
    }

    changeset_facilities_included = Product.changeset_facilities_included(%Product{}, params)
    assert changeset_facilities_included.valid?
  end

  test "changeset_facilities_included with invalid attributes" do
    params = %{
      include_all_facilities: nil
    }

    changeset_facilities_included = Product.changeset_facilities_included(%Product{}, params)
    refute changeset_facilities_included.valid?
  end

  test "changeset_update_coverege with valid attributes" do
    params = %{
      coverage_id: "943a9bbc-356c-469c-a7b3-03b6ba96cb44"
    }
    changeset_update_coverage = Product.changeset_update_coverage(%Product{}, params)
    assert changeset_update_coverage.valid?
  end

  test "changeset_update_coverege with invalid attributes" do
    params = %{
      coverage_id: nil
    }
    changeset_update_coverage = Product.changeset_update_coverage(%Product{}, params)
    refute changeset_update_coverage.valid?
  end

end

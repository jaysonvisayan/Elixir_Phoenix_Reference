defmodule Innerpeace.Db.Schemas.ProductTest do
    use Innerpeace.Db.SchemaCase
  
    alias Innerpeace.Db.Schemas.Product
    alias Ecto.UUID

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
            reimbursement: true,
            nem_dependent: 500,
            hierarchy_waiver: "Enforce",
            no_days_valid: 100,
            is_medina: true,
            smp_limit: 120.50,
            dental_funding_arrangement: "Full Risk",
            loa_validity: "60",
            loa_validity_type: "Days",
            special_handling_type: "Fee for Service",
            type_of_payment_type: "Charge to Aso"
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
            room_upgrade_time: "Hours",
            dental_funding_arrangement: "Full Risk",
            loa_validity: 60,
            loa_validity_type: "Days",
            special_handling_type: "Fee for Service",
            type_of_payment_type: "Charge to Aso"
          }

    changeset_condition = Product.changeset_condition(%Product{}, params)
    refute changeset_condition.valid?
    end
end
defmodule Innerpeace.Db.Validator.ACUValidatorTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.{
    Schemas.Embedded.ACU
    # Validators.ACUValidator
  }

  setup do
    user = insert(:user, username: "payorlink_user01")
    facility = insert(:facility, name: "MAKATI MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23",
                      created_by: user)
    coverage = insert(:coverage,
                      name: "ACU",
                      description: "ACU",
                      code: "ACU",
                      type: "A",
                      status: "A",
                      plan_type: "riders")
    payor_procedure = insert(:payor_procedure,
                             code: "95065",
                             description: "sample_procedure",
                             is_active: true,
                             deactivation_date: Ecto.Date.cast!("2050-12-12"),
                             exclusion_type: "No")
    package = insert(:package,
                     code: "Package01",
                     name: "Package01")
    insert(:package_payor_procedure,
           package: package,
           payor_procedure: payor_procedure,
           male: true,
           female: true,
           age_from: 18,
           age_to: 65)
    insert(:package_facility,
           package: package,
           facility: facility,
           rate: 500)
    benefit = insert(:benefit,
                     code: "ACU01",
                     name: "ACU Regular - Outpatient",
                     category: "Riders",
                     acu_type: "Regular",
                     acu_coverage: "Outpatient")
    benefit_limit = insert(:benefit_limit,
                           benefit: benefit,
                           limit_type: "Sessions",
                           limit_session: 1,
                           coverages: "ACU")
    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    benefit_package = insert(:benefit_package,
                             benefit: benefit,
                            package: package)
    product = insert(:product,
                     limit_amount: 50_000,
                     name: "Product01",
                     standard_product: "Yes", step: "7"
                     )
    insert(:product_coverage,
           product: product,
           coverage: coverage)
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            coverages: "ACU",
            limit_type: "Sessions",
            limit_session: 2)
    account_group = insert(:account_group,
                           name: "ACCOUNT01",
                           code: "ACCOUNT01")
    account = insert(:account,
                     status: "Active",
                     start_date: Ecto.Date.cast!("2017-10-01"),
                     end_date: Ecto.Date.cast!("2018-10-01"),
                     account_group: account_group)
    account_product = insert(:account_product,
                             account: account,
                             product: product)
    member = insert(:member,
                    effectivity_date: Ecto.Date.cast!("2017-10-01"),
                    expiry_date: Ecto.Date.cast!("2018-10-01"),
                    account_group: account_group,
                    created_by: user)
    insert(:member_product,
            member: member,
            account_product: account_product,
            tier: 1)
    authorization = insert(:authorization,
                           member: member,
                           facility: facility,
                           coverage: coverage,
                           created_by: user)

    {:ok,
      %{
        authorization: authorization,
        member: member,
        facility: facility,
        coverage: coverage,
        benefit_package: benefit_package
      }
    }
  end

  test "embedded acu changeset with valid params",
  %{
    authorization: authorization,
    member: member,
    facility: facility,
    coverage: coverage,
    benefit_package: benefit_package
  }
  do
    params = %{
      authorization_id: authorization.id,
      member_id: member.id,
      facility_id: facility.id,
      coverage_id: coverage.id,
      benefit_package_id: benefit_package.id
    }

    changeset = ACU.changeset(%ACU{}, params)

    assert changeset.valid? == true
  end

  test "embedded acu changeset with invalid params",
  %{
    authorization: authorization,
    member: member,
    facility: facility
  }
  do
    params = %{
      authorization_id: authorization.id,
      member_id: member.id,
      facility_id: facility.id
    }

    changeset = ACU.changeset(%ACU{}, params)

    assert changeset.valid? == false
  end

  # test "request acu with valid params" do

  # end
end

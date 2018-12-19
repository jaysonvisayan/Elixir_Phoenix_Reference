defmodule Innerpeace.Db.Base.Api.Vendor.MemberContextTest do
  @moduledoc false

  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.Api.Vendor.MemberContext, as: VendorMemberContext
  alias Innerpeace.Db.Base.{
    ProductContext,
    AccountContext
  }

  setup do
    account_group =
      insert(
        :account_group,
        name: "ACCOUNT101",
        code: "ACC101"
      )

    coverage =
      insert(
        :coverage,
        name: "OP Consult",
        description: "OP Consult",
        code: "OPC",
        type: "A",
        status: "Affiliated",
        plan_type: "health_plans"
      )

    coverage2 =
      insert(
        :coverage,
        name: "ACU",
        description: "ACU",
        code: "ACU",
        type: "A",
        status: "Affiliated",
        plan_type: "health_plans"
      )

    facility =
      insert(
        :facility,
        code: "cmc",
        name: "CALAMBA MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23"
      )

    facility2 =
      insert(
        :facility,
        code: "MDC",
        name: "MAKATI MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23"
      )

    member =
      insert(
        :member,
        card_no: "1111555588881111",
        first_name: "Byakuya",
        last_name: "Kuchiki",
        account_group: account_group
      )

    diagnosis =
      insert(
        :diagnosis,
        code: "Z71.1",
        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication",
        type: "Dreaded"
      )

    benefit =
      insert(
        :benefit,
        code: "B102",
        name: "Medilink Benefit",
        category: "Health"
      )

    benefit_limit =
      insert(
        :benefit_limit,
        benefit: benefit,
        limit_type: "Peso",
        limit_amount: 1000,
        coverages: "OPC"
      )

    insert(
      :benefit_coverage,
      benefit: benefit,
      coverage: coverage
    )

    insert(
      :benefit_diagnosis,
      benefit: benefit,
      diagnosis: diagnosis
    )

    account =
      insert(
        :account,
        account_group: account_group,
        start_date: Ecto.Date.cast!("2010-01-01"),
        end_date: Ecto.Date.cast!("2019-02-02"),
        status: "Active"
      )

    product =
      insert(
        :product,
        limit_amount: 10_000,
        name: "Maxicare Product 5",
        standard_product: "Yes",
        step: "7"
      )

    product_coverage = insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility)

    insert(
      :product_coverage_room_and_board,
      product_coverage: product_coverage,
      room_and_board: "Alternative",
      room_type: "Private Room",
      room_limit_amount: Decimal.new(10_000.50),
      room_upgrade: 10,
      room_upgrade_time: "Days"
    )

    insert(
      :product_coverage_room_and_board,
      product_coverage: product_coverage2,
      room_and_board: "Alternative",
      room_type: "Public Room",
      room_limit_amount: Decimal.new(50.50),
      room_upgrade: 10,
      room_upgrade_time: "Days"
    )

    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product =
      insert(:account_product,
        account: account,
        product: product
      )

    account_product2 =
      insert(:account_product,
        account: account,
        product: product2
      )

    insert(
      :member_product,
      member: member,
      account_product: account_product
    )

    insert(
      :member_product,
      member: member,
      account_product: account_product2
    )

    product_benefit =
      insert(
        :product_benefit,
        product: product,
        benefit: benefit
      )

    insert(
      :product_benefit_limit,
      product_benefit: product_benefit,
      benefit_limit: benefit_limit,
      limit_type: "Peso",
      limit_amount: 1000
    )

    practitioner =
      insert(
        :practitioner,
        first_name: "Daniel",
        middle_name: "Murao",
        last_name: "Andal",
        effectivity_from: "2017-11-13",
        effectivity_to: "2019-11-13"
      )

    practitioner_facility =
      insert(
        :practitioner_facility,
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-17",
        payment_mode: "Umbrella",
        coordinator: true,
        consultation_fee: 400,
        cp_clearance_rate: 400,
        fixed: true,
        fixed_fee: 400,
        coordinator_fee: 400,
        facility_id: facility.id,
        practitioner_id: practitioner.id
      )

    specialization =
      insert(
        :specialization,
        name: "Radiology"
      )

    practitioner_specialization =
      insert(
        :practitioner_specialization,
        practitioner: practitioner,
        specialization: specialization
      )

    insert(
      :practitioner_facility_consultation_fee,
      practitioner_facility: practitioner_facility,
      practitioner_specialization: practitioner_specialization,
      fee: 1000
    )

    insert(
      :authorization,
      coverage: coverage,
      member: member,
      facility: facility
    )

    {:ok, %{member: member}}
  end

  test "get_member_rnb/1 returns all member room and board based on his/her products" do
    params = %{
      "card_number" => "1111555588881111"
    }
    assert {:ok, _result} = VendorMemberContext.validate_params(params)
  end

  test "get_member_rnb/1 returns error if card_number is null" do
    params = %{
      "card_number" => ""
    }
    assert {:error, changeset} = VendorMemberContext.validate_params(params)
    assert changeset.errors == [card_number: {"can't be blank", [validation: :required]}]
  end

  test "get_member_rnb/1 returns error if card_number is not existing" do
    params = %{
      "card_number" => "4124114124133321"
    }
    assert {:error, changeset} = VendorMemberContext.validate_params(params)
    assert changeset.errors == [card_number: {"Card Number Doesn't Exist!", []}]
  end

  test "get_member_utilization/2, returns member utilization with valid parameters" do
    assert {:ok, _result} =
      VendorMemberContext.get_member_utilization(
        "1111555588881111",
        "op consult"
      )
  end

  test "get_member_utilization/2, returns member utilization with non-existing parameters" do
    assert false ==
      VendorMemberContext.get_member_utilization(
        "1111555588881112",
        "op consult"
      )
  end

end

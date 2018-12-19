defmodule Innerpeace.Db.Base.AcuScheduleContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.{
    AcuScheduleContext
  }

  test "get_acu_schedule_id/1 returns acu schedule" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )
    result = AcuScheduleContext.get_acu_schedule(acu_schedule.id)

    assert preload_acu_schedule(result) == preload_acu_schedule(acu_schedule)
  end

  test "get_acu_schedule_id/1 returns nil acu schedule if id is not found" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )
    result = AcuScheduleContext.get_acu_schedule(Ecto.UUID.generate())

    refute preload_acu_schedule(result) == preload_acu_schedule(acu_schedule)
    assert result == nil
  end

  test "get_all_acu_schedules returns all acu_schedules" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )
    result = AcuScheduleContext.get_all_acu_schedules()

    assert preload_acu_schedule(result) == [preload_acu_schedule(acu_schedule)]
  end

  test "get_all_acu_schedule_members/1 returns all acu_schedule_members" do
    member = insert(:member, first_name: "Shane", last_name: "dela Rosa")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_member = insert(:acu_schedule_member, member: member, acu_schedule: acu_schedule, status: nil)

    result = AcuScheduleContext.get_all_acu_schedule_members(acu_schedule.id)
    assert preload_acu_schedule_member(result) == [acu_schedule_member]
  end

  test "get_all_acu_schedule_members/1 returns empty list with invalid acu schedule id" do
    member = insert(:member, first_name: "Shane", last_name: "dela Rosa")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_member = insert(:acu_schedule_member, member: member, acu_schedule: acu_schedule)
    result = AcuScheduleContext.get_all_acu_schedule_members(Ecto.UUID.generate())

    refute preload_acu_schedule_member(result) == [acu_schedule_member]
    assert result == []
  end

  test "get_all_acu_schedule_products/1 returns all products in acu_schedule" do
    product = insert(:product, code: "PRD-1234567", name: "ACU PRODUCT")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_product = insert(:acu_schedule_product, product: product, acu_schedule: acu_schedule)
    result = AcuScheduleContext.get_all_acu_schedule_products(acu_schedule.id)

    assert preload_acu_schedule_product(result) == [acu_schedule_product]
  end

  test "get_all_acu_schedule_products/1 returns empty list with invalid acu schedule id" do
    product = insert(:product, code: "PRD-1234567", name: "ACU PRODUCT")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_product = insert(:acu_schedule_product, product: product, acu_schedule: acu_schedule)
    result = AcuScheduleContext.get_all_acu_schedule_products(Ecto.UUID.generate())

    refute preload_acu_schedule_product(result) == [acu_schedule_product]
    assert result == []
  end

  test "get_all_remove_acu_schedule_members/1 returns all members with removed status" do
    member = insert(:member, first_name: "Shane", last_name: "dela Rosa")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_member = insert(:acu_schedule_member, member: member, acu_schedule: acu_schedule, status: "removed")

    result = AcuScheduleContext.get_all_remove_acu_schedule_members(acu_schedule.id)

    assert preload_acu_schedule_member(result) == [acu_schedule_member]
  end

  test "get_all_remove_acu_schedule_members/1 does not return all members with nil status" do
    member = insert(:member, first_name: "Shane", last_name: "dela Rosa")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    facility = insert(:facility, code: "123123123123123asd", name: "MYHEALTH CLINIC")
    user = insert(:user, username: "masteradmin")
    acu_schedule = insert(:acu_schedule,
                          account_group: account_group,
                          facility: facility,
                          created_by: user,
                          updated_by: user
    )

    acu_schedule_member = insert(:acu_schedule_member, member: member, acu_schedule: acu_schedule, status: "")

    result = AcuScheduleContext.get_all_remove_acu_schedule_members(acu_schedule.id)

    refute preload_acu_schedule_member(result) == [acu_schedule_member]
    assert result == []
  end

  test "list_active_accounts_acu returns all accounts with active status and products with acu coverage" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT")
    insert(:account_product, account: account, product: product)
    coverage = insert(:coverage, code: "ACU", name: "ACU")
    insert(:product_coverage, product: product, coverage: coverage)

    result = AcuScheduleContext.list_active_accounts_acu()

    assert result == [account]
  end

  test "list_active_accounts_acu does not return accounts with products that has no acu coverage" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT")
    insert(:account_product, account: account, product: product)
    coverage = insert(:coverage, code: "MTRNTY", name: "MTRNTY")
    insert(:product_coverage, product: product, coverage: coverage)

    result = AcuScheduleContext.list_active_accounts_acu()

    refute result == [account]
    assert result == []
  end

  test "get_acu_products_by_account_code/1 returns product based on account" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)

    result = AcuScheduleContext.get_acu_products_by_account_code(account_group.code)

    assert result == [product.code]
  end

  test "get_acu_products_by_account_code/1 does not return product not included in account" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account_group2 = insert(:account_group, code: "C00919", name: "Mang Inasal")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    insert(:account,
           start_date: Ecto.Date.cast!("2017-01-01"),
           end_date: Ecto.Date.cast!("2099-01-01"),
           status: "Active",
           account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)

    result = AcuScheduleContext.get_acu_products_by_account_code(account_group2.code)

    refute result == [product.code]
    assert result == []
  end

  test "get_acu_facilities/1 returns facilities based on product" do
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")

    result = AcuScheduleContext.get_acu_facilities([product.code])

    assert result == [%{facility_code: facility.code, facility_name: facility.name, facility_id: facility.id}]
  end

  test "get_acu_facilities/1 returns empty list of facilities if facility type is not mobile" do
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Exclusion-based", loa_facilitated: false)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "HOSPITAL-BASED")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")

    result = AcuScheduleContext.get_acu_facilities([product.code])

    refute result == [%{facility_code: facility.code, facility_name: facility.name, facility_id: facility.id}]
    assert result == []
  end

  test "get_acu_facilities/1 returns empty list of facilities if provider access has not included mobile" do
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Exclusion-based", loa_facilitated: false)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Hospital/Clinic")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")

    result = AcuScheduleContext.get_acu_facilities([product.code])

    refute result == [%{facility_code: facility.code, facility_name: facility.name, facility_id: facility.id}]
    assert result == []
  end

  test "get_acu_facilities/1 returns empty list of facilities if package facility has no rate" do
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Exclusion-based", loa_facilitated: false)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: nil)
    insert(:benefit_package, benefit: benefit, package: package)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")

    result = AcuScheduleContext.get_acu_facilities([product.code])

    refute result == [%{facility_code: facility.code, facility_name: facility.name, facility_id: facility.id}]
    assert result == []
  end

  test "get_products_by_facility/2 returns products by facility" do
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")

    result = AcuScheduleContext.get_products_by_facility([product.code], facility.id)

    assert result == [product.code]
  end

  test "get_active_members_by_type/3 returns all active members in ACU Schedule" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100, male: true)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    result = AcuScheduleContext.get_active_members_by_type(
      facility.id,
      [member.type],
      [product.code],
      account_group.code
    )
    assert result == [%{authorization_id: nil, id: member.id}]
  end

  test "get_active_members_by_type/3 returns empty list if member is not active" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Cancelled",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    result = AcuScheduleContext.get_active_members_by_type(
      facility.id,
      [member.type],
      [product.code],
      account_group.code
    )
    refute result == [%{authorization_id: nil, id: member.id}]
    assert result == []
  end

  test "get_active_members_by_type/3 returns empty list if member's age is not eligible in benefit package" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 18, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("2002-03-04"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    result = AcuScheduleContext.get_active_members_by_type(
      facility.id,
      [member.type],
      [product.code],
      account_group.code
    )
    refute result == [preload_members(member)]
    assert result == []
  end

  test "create_acu_schedule/1 creates acu schedule with valid params" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)


    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    assert {:ok, acu_schedule} = AcuScheduleContext.create_acu_schedule(params, user.id)
    assert acu_schedule.account_group_id == account_group.id
  end

  test "create_acu_schedule/1 does not create acu schedule without account" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    params = %{
      "account_code" => "",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    message = {:account_not_found}
    assert message == AcuScheduleContext.create_acu_schedule(params, user.id)
  end

  test "create_acu_schedule/1 does not create acu schedule without facility" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => ""
    }

    assert {:error, %Ecto.Changeset{}} = AcuScheduleContext.create_acu_schedule(params, user.id)
  end

  test "create_acu_schedule/1 does not create acu schedule without date from and date to" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => nil,
      "date_to" => nil,
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    assert {:error, %Ecto.Changeset{}} = AcuScheduleContext.create_acu_schedule(params, user.id)
  end

  test "create_acu_schedule_product/1 creates acu_schedule product with valid params" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)


    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    assert {:ok, acu_schedule} = AcuScheduleContext.create_acu_schedule(params, user.id)
    assert {:ok, _acu_product} = AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, ["PRD-12354356"])
  end

  test "create_acu_schedule_product/1 does not create acu schedule product and adds error message on invalid params" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)


    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    assert {:ok, acu_schedule} = AcuScheduleContext.create_acu_schedule(params, user.id)
    {:ok, acu_products} = AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, ["PRD-1235432"])
    assert acu_products == []
  end

  test "create_acu_schedule_member/2 create acu_schedule member with valid params" do
    user = insert(:user, username: "masteradmin")
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100, male: true)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    params = %{
      "account_code" => "C00918",
      "time_from" => "08:00",
      "time_to" => "17:00",
      "number_of_members_val" => 1,
      "principal" => "Principal",
      "date_from" => Ecto.Date.utc(),
      "date_to" => Ecto.Date.utc(),
      "no_of_guaranteed" => 1,
      "facility_id" => facility.id
    }

    assert {:ok, acu_schedule} = AcuScheduleContext.create_acu_schedule(params, user.id)

    assert [_member] = AcuScheduleContext.create_acu_schedule_member(acu_schedule.id, [product.code], account_group.code)
  end

  test "member_benefit_package/1 returns benefit package of member in acu" do
    account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
    account = insert(:account,
                     start_date: Ecto.Date.cast!("2017-01-01"),
                     end_date: Ecto.Date.cast!("2099-01-01"),
                     status: "Active",
                     account_group: account_group
    )
    product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
    account_product = insert(:account_product, account: account, product: product)
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
    insert(:product_benefit,
           product: product,
           benefit: benefit)
    dropdown = insert(:dropdown, text: "MOBILE")
    facility = insert(:facility,
                      code: "123123123123123",
                      name: "ACU CLINIC",
                      type: dropdown,
                      step: 7,
                      status: "Affiliated",
    )
    coverage = insert(:coverage, name: "ACU", code: "ACU")
    package = insert(:package, code: "0-100 1", name: "0-100 1")
    insert(:package_facility, package: package, facility: facility, rate: 1000)
    insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    member = insert(:member,
                    first_name: "Shane",
                    last_name: "Dela Rosa",
                    status: "Active",
                    birthdate: Ecto.Date.cast!("1995-04-19"),
                    type: "Principal",
                    gender: "Male"
    )
    insert(:member_product, member: member, account_product: account_product)

    AcuScheduleContext.member_benefit_package(member)
  end

  # test "acu_schedule_api_params/1 adds parameters for acu schedule api" do
  #   user = insert(:user, username: "masteradmin")
  #   account_group = insert(:account_group, code: "C00918", name: "Jollibee Worldwide")
  #   account = insert(:account,
  #                    start_date: Ecto.Date.cast!("2017-01-01"),
  #                    end_date: Ecto.Date.cast!("2099-01-01"),
  #                    status: "Active",
  #                    account_group: account_group,
  #   )
  #   account_group_address = insert(:account_group_address,
  #                    line_1: "test1",
  #                    line_2: "test2",
  #                    city: "city",
  #                    province: "province",
  #                    region: "haha",
  #                    country: "phil",
  #                    postal_code: "1606",
  #                    type: "Account Address",
  #                    is_check: true,
  #                    account_group: account_group
  #   )
  #   product = insert(:product, code: "PRD-12354356", name: "ACU PRODUCT", product_base: "Benefit-based", loa_facilitated: true)
  #   account_product = insert(:account_product, account: account, product: product)
  #   benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Riders", provider_access: "Mobile")
  #   product_benefit = insert(:product_benefit,
  #                             product: product,
  #                             benefit: benefit)
  #   dropdown = insert(:dropdown, text: "MOBILE")
  #   facility = insert(:facility,
  #                     code: "123123123123123",
  #                     name: "ACU CLINIC",
  #                     type: dropdown,
  #                     step: 7,
  #                     status: "Affiliated",
  #   )
  #   coverage = insert(:coverage, name: "ACU", code: "ACU")
  #   package = insert(:package, code: "0-100 1", name: "0-100 1")
  #   package_facility = insert(:package_facility, package: package, facility: facility, rate: 1000)
  #   benefit_package = insert(:benefit_package, benefit: benefit, package: package, age_from: 0, age_to: 100)
  #   product_coverage = insert(:product_coverage, product: product, coverage: coverage, type: "exception")
  #   member = insert(:member,
  #                   first_name: "Shane",
  #                   last_name: "Dela Rosa",
  #                   status: "Active",
  #                   birthdate: Ecto.Date.cast!("1995-04-19"),
  #                   type: "Principal",
  #                   gender: "Male"
  #   )
  #   member_product = insert(:member_product, member: member, account_product: account_product)


  #   params = %{
  #     "account_code" => "C00918",
  #     "time_from" => "08:00",
  #     "time_to" => "17:00",
  #     "number_of_members_val" => 1,
  #     "principal" => "Principal",
  #     "date_from" => Ecto.Date.utc(),
  #     "date_to" => Ecto.Date.utc(),
  #     "no_of_guaranteed" => 1,
  #     "facility_id" => facility.id
  #   }

  #   assert {:ok, acu_schedule} = AcuScheduleContext.create_acu_schedule(params, user.id)
  #   AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, ["PRD-12354356"])
  #   asm =  AcuScheduleContext.create_acu_schedule_member(acu_schedule.id, [product.code], account_group.code)

  #   acu_schedule = AcuScheduleContext.get_acu_schedule(acu_schedule.id)
  #   product_codes = Enum.map(acu_schedule.acu_schedule_products, &(&1.product.code))
  #   packages = AcuScheduleContext.get_package_by_products_and_facility(product_codes, acu_schedule.facility_id)
  #   for package <- packages do
  #     params = %{
  #       acu_schedule_id: acu_schedule.id,
  #       package_id: Enum.at(package, 0),
  #       rate: Enum.at(package, 1),
  #       facility_id: Enum.at(package, 2)
  #     }
  #     AcuScheduleContext.insert_acu_schedule_packages(params)
  #   end
  # end


  #PRIVATE FUNCTIONS
  defp preload_acu_schedule(acu_schedule) do
    Repo.preload(acu_schedule, [
      :account_group,
      :cluster,
      :created_by,
      :updated_by,
      [facility: [:category,
                  :type,
                  :vat_status,
                  :prescription_clause,
                  :payment_mode,
                  :releasing_mode]],
      [acu_schedule_products: [
        product: [
          product_benefits: [
            benefit: [benefit_packages:
                      [package:
                       [package_payor_procedure: :payor_procedure
                       ]
                      ]
            ]
          ]
        ]
      ],
       acu_schedule_members: :member,
       acu_schedule_packages: :package
      ]
    ])
  end

  defp preload_members(member) do
    Repo.preload(member, [
      :authorizations,
      :products
    ])
  end

  defp preload_acu_schedule_member(member) do
    Repo.preload(member, [
      :member,
      [acu_schedule: [
        :account_group,
        :created_by,
        :updated_by,
        [facility: [:category,
                    :type,
                    :vat_status,
                    :prescription_clause,
                    :payment_mode,
                    :releasing_mode]],
      ]
      ]
    ])
  end

  defp preload_acu_schedule_product(product) do
    Repo.preload(product, [
      [product:
       :payor
      ],
      [acu_schedule: [
        :account_group,
        :created_by,
        :updated_by,
        [facility: [:category,
                    :type,
                    :vat_status,
                    :prescription_clause,
                    :payment_mode,
                    :releasing_mode]],
      ]
      ]
    ])
  end

  describe "Adds batch_id column to acu schedule" do
        test "With valid data" do
                batch = insert(
                        :batch,
                        batch_no: "001"
                      )
                acu_schedule = insert(
                        :acu_schedule,
                        batch_no: batch.batch_no
                      )
                {:ok, acu_schedule_result} = AcuScheduleContext.update_acu_schedule_batch_id(acu_schedule.batch_no,batch.id)
                assert acu_schedule.id == acu_schedule_result.id
              end
      end

end

defmodule Innerpeace.Db.Base.ProductContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Product,
    # ProductBenefit,
    ProductBenefitLimit,
    # Facility,
    # ProductFacility,
    # ProductExclusion,
    # ProductRiskShare,
    # ProductRiskShareFacility,
    # ProductRiskShareFacilityProcedure,
    # ProductCoverage,
    # ProductCoverageFacilities,
    ProductCoverageRiskShare,
    # ProductCoverageRiskShareFacility,
    # ProductCoverageRiskShareFacilityPayorProcedures,
    # ProductConditionHierarchyOfEligibleDependent,
    User
  }
  alias Innerpeace.Db.Base.{
    ProductContext,
    BenefitContext,
    FacilityContext,
    ProcedureContext
  }

  test "get_all_products_for_index" do
    products =
      :product
      |> insert()
      |> Repo.preload([
        :created_by,
        :updated_by,
        product_coverages: [
          :product_coverage_facilities
        ]
      ])
    assert ProductContext.get_all_products_for_index("", 0) == [products]
  end


  test "get_all_products/0 returns all benefits" do
    products =
      :product
      |> insert()
      |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: :procedure,
          benefit_coverages: :coverage
        ]
      ],
      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        product_coverage_facilities: [facility: [:category, :type]],
        product_coverage_risk_share: [product_coverage_risk_share_facilities: [:facility, product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]]]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]],
      ]
    )
    assert ProductContext.get_all_products() == [products]
  end

  test "get_product/1 returns the product with given id" do
    product = insert(:product)
    product =
      product
      |> Repo.preload([
        :account_products,
        :payor,
        :logs,
        :product_condition_hierarchy_of_eligible_dependents,
        product_benefits: [
          :product_benefit_limits,
          benefit: [
            :created_by,
            :updated_by,
            :benefit_limits,
            benefit_procedures: :procedure,
            benefit_coverages: :coverage
          ]
        ],
        product_coverages: [
          product_coverage_facilities: [facility: [:category, :type]],
          product_coverage_risk_share: [product_coverage_risk_share_facilities: [:facility, product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]]]
        ],
        product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]],
      ])
    assert ProductContext.get_product!(product.id) == product
  end

  test "create_product/1 creates product with valid attributes" do
    user = insert(:user)
    insert(:payor, name: "Maxicare")
    product_params = %{
      "name" => "produkto el dorado",
      "description" => "test desc",
      "limit_applicability" => "limit_app_test",
      "type" => "123",
      "limit_type" => "test",
      "limit_amount" => "2000",
      "phic_status" => "test_phic_status",
      "standard_product" => "Yes",
      "step" => "3",
      "created_by_id" => user.id,
      "member_type" => ["Principal"],
      "product_base" => "Exclusion-based"
    }
    assert {:ok, %Product{} = product} = ProductContext.create_product(product_params)
    assert product.name == "produkto el dorado"
  end


  test "create_product/1 creates product using invalid attributes returns errors" do
    insert(:payor, name: "Maxicare")
    product_params = %{
      "name" => "",
      "description" => "test desc",
      "limit_applicability" => "limit_app_test",
      "type" => "123",
      "limit_type" => "test",
      "limit_amount" => "2000",
      "phic_status" => "test_phic_status",
      "standard_product" => "Yes"
    }
    assert {:error, changeset} = ProductContext.create_product(product_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_product/2 updates product_general with valid attributes" do
    user = insert(:user)
    product = insert(:product,
                     name: "produkto el dorado",
                     description: "test desc",
                     limit_applicability: "limit_app_test",
                     type: "123",
                     limit_type: "test",
                     limit_amount: 2000,
                     phic_status: "test_phic_status",
                     standard_product: "Yes",
                     step: "2",
                     created_by_id: user.id,
                     member_type: ["Principal"],
                     product_base: "Exclusion-based"
    )

    benefit = insert(:benefit, name: "benefit101")
    benefit_limit = insert(:benefit_limit, benefit: benefit, coverages: "OPC", limit_amount: Decimal.new(5000.50), limit_type: "Peso")
    benefit = BenefitContext.get_benefit(benefit.id)
    product = ProductContext.get_product!(product.id)

    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:product_benefit_limit, product_benefit: product_benefit, benefit_limit: benefit_limit, coverages: benefit_limit.coverages, limit_type: benefit_limit.limit_type, limit_amount: benefit_limit.limit_amount)

    product = ProductContext.get_product!(product.id)

    product_params = %{
      "name" => "updated produkto",
      "description" => "test desc updated",
      "limit_applicability" => "Individual",
      "type" => "Platinum",
      "limit_type" => "ABL",
      "limit_amount" => Decimal.new(6000),
      "phic_status" => "test_phic_status_updated",
      "standard_product" => "No",
      "member_type" => ["Dependent"]
    }
    assert {:ok, %Product{} = product} = ProductContext.update_product(product, product_params)
    assert product.name == "updated produkto"
  end

  test "update_product/2 updates product with invalid attributes returns error" do
    user = insert(:user)
    product = insert(:product,
                     name: "produkto el dorado",
                     description: "test desc",
                     limit_applicability: "limit_app_test",
                     type: "123",
                     limit_type: "test",
                     limit_amount: 2000,
                     phic_status: "test_phic_status",
                     standard_product: "Yes",
                     step: "2",
                     created_by_id: user.id,
                     member_type: ["Principal"],
                     product_base: "Exclusion-based"
    )

    benefit = insert(:benefit, name: "benefit101")
    benefit_limit = insert(:benefit_limit, benefit: benefit, coverages: "OPC", limit_amount: Decimal.new(5000.50), limit_type: "Peso")
    benefit = BenefitContext.get_benefit(benefit.id)
    product = ProductContext.get_product!(product.id)

    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:product_benefit_limit, product_benefit: product_benefit, benefit_limit: benefit_limit, coverages: benefit_limit.coverages, limit_type: benefit_limit.limit_type, limit_amount: benefit_limit.limit_amount)

    product = ProductContext.get_product!(product.id)

    product_params = %{
      "name" => nil,
      "description" => nil,
      "limit_applicability" => "limit_app_test_updated",
      "type" => "123_updated",
      "limit_type" => "test_updated",
      "limit_amount" => Decimal.new(6000),
      "phic_status" => "test_phic_status_updated",
      "standard_product" => "No"
    }
    assert {:error, changeset} = ProductContext.update_product(product, product_params)
    refute Enum.empty?(changeset.errors)
  end

  test "update_product/2 updates product with invalid product limit amount returns error" do
    user = insert(:user)
    product = insert(:product,
                     name: "produkto el dorado",
                     description: "test desc",
                     limit_applicability: "limit_app_test",
                     type: "123",
                     limit_type: "test",
                     limit_amount: 2000,
                     phic_status: "test_phic_status",
                     standard_product: "Yes",
                     step: "2",
                     created_by_id: user.id,
                     member_type: ["Principal"],
                     product_base: "Exclusion-based"
    )

    benefit = insert(:benefit, name: "benefit101")
    benefit_limit = insert(:benefit_limit, benefit: benefit, coverages: "OPC", limit_amount: Decimal.new(5000.50), limit_type: "Peso")
    benefit = BenefitContext.get_benefit(benefit.id)
    product = ProductContext.get_product!(product.id)

    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:product_benefit_limit, product_benefit: product_benefit, benefit_limit: benefit_limit, coverages: benefit_limit.coverages, limit_type: benefit_limit.limit_type, limit_amount: benefit_limit.limit_amount)

    product = ProductContext.get_product!(product.id)

    product_params = %{
      "name" => "test",
      "description" => "test",
      "limit_applicability" => "limit_app_test_updated",
      "type" => "123_updated",
      "limit_type" => "test_updated",
      "limit_amount" => Decimal.new(3000),
      "phic_status" => "test_phic_status_updated",
      "standard_product" => "No"
    }
    assert {:error_product_limit, message} = ProductContext.update_product(product, product_params)
    assert message == "Plan Limit must be equal or greater than each benefit's limit. Plan cannot be saved., current highest pb amount is #{benefit_limit.limit_amount}"
  end

  test "delete_product/1 deletes the product" do
    product = insert(:product)

    assert {:ok, %Product{}} = ProductContext.delete_product(product.id)
    assert nil == ProductContext.get_product!(product.id)
  end

  test "set_product_benefits/2, inserting for product_benefit and product_benefit_limit" do
    user = insert(:user)
    product = insert(:product, product_category: "Regular Plan")
    benefit1 = insert(:benefit, name: "Benefit101")
    benefit2 = insert(:benefit, name: "Benefit102")
    benefits = [benefit1.id, benefit2.id]

    result = ProductContext.set_product_benefits(product, benefits, user.id)
    assert result == {:ok}
  end

  test "set_product_benefits/2, inserting for product_benefit and product_benefit_limit with invalid product category" do
    user = insert(:user)
    product = insert(:product, product_category: "")
    benefit1 = insert(:benefit, name: "Benefit101")
    benefit2 = insert(:benefit, name: "Benefit102")
    benefits = [benefit1.id, benefit2.id]

    result = ProductContext.set_product_benefits(product, benefits, user.id)
    assert result == {:error, "Error in Plan Category"}
  end

  test "clear_product_benefit/1, clearing product_benefit_limit(child) first before clearing product_benefit(parent)" do
    product =
      :product
      |> insert()
      |> Repo.preload([:product_benefits])
    ProductContext.clear_product_benefit(product)
  end

  test "get_product_benefit/1, for struct purposes that we will use for preloading product_benefit_limit" do
    product_benefit = insert(:product_benefit)
    ProductContext.get_product_benefit(product_benefit.id)
  end

  test "get_product_benefit_limit/1, for poison encode ajax purpose" do
    product_benefit_limit = insert(:product_benefit_limit)
    ProductContext.get_product_benefit_limit(product_benefit_limit.id)
  end

  test "update_product_benefit_limit/2, updating product_benefit_limit upon submiting active modal with valid attributes" do
    product_benefit_limit =
      insert(:product_benefit_limit, limit_amount: 100, coverages: "OPC EMRGNCY", limit_type: "Peso")
    product_params = %{
      amount: 200,
      coverages: "OPL, OPC",
      limit_type: "Plan Limit Percentage"
    }
    assert {:ok, %ProductBenefitLimit{}} = ProductContext.update_product_benefit_limit(product_benefit_limit, product_params)
  end

  test "update_product_benefit_limit/2, updating product_benefit_limit upon submiting active modal with invalid attrs returs error" do
    product_benefit_limit =
      insert(:product_benefit_limit, limit_amount: 100, coverages: "OPC EMRGNCY", limit_type: "Peso")
    product_params = %{
      amount: nil,
      coverages: "OPL OPC",
      limit_type: "Percentage of Plan Limit"
    }
    assert {:error, changeset} = ProductContext.update_product_benefit_limit(product_benefit_limit, product_params)
    refute Enum.empty?(changeset.errors)
  end

  test "get_list_of_facilities/0, loads all facilities" do
    insert(:facility)
    ProductContext.get_list_of_facilities()
  end

  test "get_product_facility/1, gets a product facility record according to its ID" do
    pf = insert(:product_facility)
    ProductContext.get_product_facility(pf.id)
  end

  test "clear_product_facility/1, clears product facility" do
    pf = insert(:product_coverage)
    ProductContext.clear_product_facility(pf.id)
  end

  test "set_product_facility/2, inserts a product facility record" do
    product_coverage = insert(:product_coverage)
    facility1 = insert(:facility, name: "Makati Med")
    facility2 = insert(:facility, name: "Chinese Med")
    facilities = [facility1.id, facility2.id]
    ProductContext.set_product_facility(product_coverage.id, facilities)
  end

  test "update_product_facilities_included/2, updating product upon submiting active modal with valid attributes" do
    fp = insert(:product, include_all_facilities: true)

    ProductContext.update_product_facilities_included(fp, fp.include_all_facilities)
  end

  test "update_product_facilities_included/2, updating product upon submiting active modal with invalid attributes" do
    fp = insert(:product, include_all_facilities: nil)

    assert {:error, changeset} = ProductContext.update_product_facilities_included(fp, fp.include_all_facilities)
    refute Enum.empty?(changeset.errors)
  end

  test "delete_product_facilities/1, delete all product_facility according to its coverage_id" do
    pc = insert(:product_coverage)

    ProductContext.delete_product_facilities(pc.id)
  end

  test "delete_product_facility/1, delete a product_facility record" do
    fp = insert(:product_facility)

    ProductContext.delete_product_facility(fp.id)
  end

  test "clear_genex/1, clearing general exclusions" do
    product = insert(:product)
    exclusion = insert(:exclusion, coverage: "Exclusion")
    insert(:product_exclusion, exclusion: exclusion, product: product)
    product = ProductContext.get_product!(product.id)
    ProductContext.clear_genex(product)
    deleted_product_exclusion = ProductContext.get_product!(product.id)
    assert Enum.empty?(deleted_product_exclusion.product_exclusions)
  end

  test "clear_pre_existing/1, clearing pre existing conditions" do
    product = insert(:product)
    exclusion = insert(:exclusion, coverage: "Pre-existing condition")
    insert(:product_exclusion, exclusion: exclusion, product: product)
    product = ProductContext.get_product!(product.id)
    ProductContext.clear_pre_existing(product)
    deleted_product_exclusion = ProductContext.get_product!(product.id)
    assert Enum.empty?(deleted_product_exclusion.product_exclusions)
  end

  test "set_genex/2, adding general exclusion" do
    product = insert(:product)
    exclusion1 = insert(:exclusion, coverage: "Exclusion")
    exclusion2 = insert(:exclusion, coverage: "Exclusion")
    exclusions = [exclusion1.id, exclusion2.id]
    test = ProductContext.set_genex(product.id, exclusions)
    assert Enum.at(test, 0).exclusion_id == exclusion1.id
    assert Enum.at(test, 1).exclusion_id == exclusion2.id
  end

  test "set_pre_existing/2, adding pre existing condition" do
    product = insert(:product)
    exclusion1 = insert(:exclusion, coverage: "Pre-existing condition", limit_type: "Peso", limit_amount: "1000")
    exclusion2 = insert(:exclusion, coverage: "Pre-existing condition", limit_type: "Peso", limit_amount: "1000")
    exclusions = [exclusion1.id, exclusion2.id]
    {:ok, test} = ProductContext.set_pre_existing(product.id, exclusions)
    ex1 = Enum.at(test, 0)
    ex2 = Enum.at(test, 1)
    assert ex1.product_exclusion.exclusion.id == exclusion1.id
    assert ex2.product_exclusion.exclusion.id == exclusion2.id
    assert ex1.product_exclusion.product.id == product.id
    assert ex2.product_exclusion.product.id == product.id
  end

  test "set_product_risk_share/2, insert or update for product_risk_share" do
    product = insert(:product)
    coverage_inpatient = insert(:coverage, name: "IP")
    coverage_opl = insert(:coverage, name: "OPL")
    coverage_opc = insert(:coverage, name: "OPC")
    params = %{
      "product_id" => product.id,
      "funding" => %{coverage_inpatient.id => "asootep", coverage_opl.id => "fulljm", coverage_opc.id => "fulltonton"},
      "adnb" => 10,
      "adnnb" => 10,
      "adult_dependent_max_age" => 10,
      "adult_dependent_max_type" => "Years",
      "adult_dependent_min_age" => 10,
      "adult_dependent_min_type" => "Years",
      "minor_dependent_max_age" => 10,
      "minor_dependent_max_type" => "Years",
      "minor_dependent_min_age" => 10,
      "minor_dependent_min_type" => "Years",
      "opmnb" => 10,
      "opmnnb" => 10,
      "overage_dependent_max_age" => 10,
      "overage_dependent_max_type" => "Years",
      "overage_dependent_min_age" => 10,
      "overage_dependent_min_type" => "Years",
      "principal_max_age" => 10,
      "principal_max_type" => "Years",
      "principal_min_age" => 10,
      "principal_min_type" => "Years",
      "room_and_board" => "test",
      "room_limit_amount" => 10,
      "room_type" => "test",
      "room_upgrade" => 10,
      "room_upgrade_time" => "Days"
    }

    product_risk_shares = ProductContext.set_product_risk_share(product, params)
    prs_list = for product_risk_share <- product_risk_shares do
      product_risk_share.fund
    end
    assert Enum.sort(prs_list) == Enum.sort(["fulljm", "fulltonton", "asootep"])
  end

   test "get_product_risk_shares/1, returns all product risk shares" do
     product1 = insert(:product)

     coverage1 = insert(:coverage, name: "OPL")
     product_coverage1 = insert(:product_coverage, product: product1, coverage: coverage1)
     product_coverage_risk_share1 = insert(:product_coverage_risk_share, product_coverage: product_coverage1)

     coverage2 = insert(:coverage, name: "OPC")
     product_coverage2 = insert(:product_coverage, product: product1, coverage: coverage2)
     product_coverage_risk_share2 = insert(:product_coverage_risk_share, product_coverage: product_coverage2)

     product_risk_shares = ProductContext.get_product_risk_shares(product1)

     list = for prs <- product_risk_shares do
       prs.id
     end
     assert Enum.sort(list) == Enum.sort([product_coverage_risk_share1.id, product_coverage_risk_share2.id])
   end

   test "update_product_risk_share/2, updates the product risk share" do
     user = insert(:user)
     product1 = insert(:product)
     coverage1 = insert(:coverage, name: "OPL")
     product_coverage1 = insert(:product_coverage, product: product1, coverage: coverage1)
     product_risk_share = insert(:product_coverage_risk_share, product_coverage: product_coverage1)
     params = %{
       "af_covered_percentage" => "22",
       "af_type" => "N/A",
       "af_value" => "22",
       "naf_covered_percentage" => "22",
       "naf_reimbursable" => "Yes",
       "naf_type" => "Copayment",
       "naf_value" => "22",
       "risk_share_id" => product_risk_share.id,
       "step" => 6,
       "updated_by_id" => user.id
     }

     assert {:ok, %ProductCoverageRiskShare{} = product_risk_share} = ProductContext.update_product_risk_share(product_risk_share, params)
     assert product_risk_share.af_covered_percentage == 22
     assert product_risk_share.af_type == "N/A"
     assert product_risk_share.af_value == nil
     assert product_risk_share.naf_reimbursable == "Yes"
     assert product_risk_share.naf_type == "Copayment"
     assert product_risk_share.naf_value == nil
   end

   test "get_product_risk_share/1, returns product risk shares with a given id" do
     product1 = insert(:product)
     coverage1 = insert(:coverage, name: "OPL")
     product_coverage1 = insert(:product_coverage, product: product1, coverage: coverage1)
     seed_product_risk_share = insert(:product_coverage_risk_share, product_coverage: product_coverage1)

     product_risk_share = ProductContext.get_product_risk_share(seed_product_risk_share.id)
     assert product_risk_share.id == seed_product_risk_share.id
   end

   test "get_product_riskshare_facility/2, returns product risk share facility with a given id" do
     facility = insert(:facility, name: "Makati Med")
     product1 = insert(:product)
     coverage1 = insert(:coverage, name: "OPL")
     product_coverage1 = insert(:product_coverage, product: product1, coverage: coverage1)
     seed_product_risk_share = insert(:product_coverage_risk_share, product_coverage: product_coverage1)
     product_risk_share_facility = insert(:product_coverage_risk_share_facility, product_coverage_risk_share: seed_product_risk_share, facility: facility)

     get_product_risk_share_facility = ProductContext.get_product_riskshare_facility(seed_product_risk_share.id, facility.id)
     assert product_risk_share_facility.id == get_product_risk_share_facility.id
   end

  test " validate_facility/1" do
    params =  %{
      "product_risk_share_facility_id" => "",
    }
    result  = ProductContext.validate_facility(params)
    assert result == nil
  end

  test " validate_procedure/1" do
    params =  %{
      "pcrsfpp" => "",
    }
    result  = ProductContext. validate_procedure(params)
    assert result == nil
  end

  test "delete_product_exclusion!/2, creating logs if general tab has been updated" do
    product = insert(:product)
    exclusion = insert(:exclusion)
    product_exclusion = insert(:product_exclusion, product: product, exclusion: exclusion)
    ProductContext.delete_product_exclusion!(product, product_exclusion.id)
    product = ProductContext.get_product!(product.id)
    assert Enum.empty?(product.product_exclusions)
  end

  test "loop_facilities/1, loop for all facilities" do
    insert(:facility, name: "Makati Medical Center")
    insert(:facility, name: "Manila Medical Center")
    insert(:facility, name: "Taguig Medical Center")
    facilities = FacilityContext.get_all_facility()
    loop_result = [] ++ for facility <- facilities do
     facility.name
    end
    assert Enum.sort(loop_result) == Enum.sort(["Makati Medical Center", "Manila Medical Center", "Taguig Medical Center"])
  end

  test "loop_procedures/1, loop for all procedures" do
    insert(:procedure, description: "Citrate")
    insert(:procedure, description: "MIR Scan")
    insert(:procedure, description: "Citi Scan")
    procedures = ProcedureContext.get_all_procedures()
    loop_result = [] ++ for procedure <- procedures do
     procedure.description
    end
    assert Enum.sort(loop_result) == Enum.sort(["Citrate", "MIR Scan", "Citi Scan"])
  end

  #for product_download
  test "csv download product" do
    params = %{"product_code" => ["PRD-40112"]}
    insert(:product, code: "PRD-40112", name: "Maxicare Product 1", description: "health card for regualr employee", standard_product: "yes")
    insert(:user, username: "masteradmin")
    query = (
      from p in Product,
      join: u in User, on: u.id == p.created_by_id,
      join: uu in User, on: uu.id == p.updated_by_id,
      where: p.code in ^params["product_code"], order_by: p.code,
      select: ([
        p.code,
        p.name,
        p.description,
        p.standard_product,
        u.username,
        p.inserted_at,
        uu.username,
        p.updated_at
      ])
    )
    _query = Repo.all(query)
    assert _query = ProductContext.csv_product_downloads(params)
  end

  # Product Condition Hierarchy of Eligible Dependents
  test "clear_product_condition_hierarchy/1, clears all record in the table ProductConditionHierarchyOfEligibleDependents" do
    product = insert(:product)
    ProductContext.clear_product_condition_hierarchy(product.id)
  end

  test "insert_product_condition_hierarchy/4, inserts a new record to the table ProductConditionHierarchyOfEligibleDependents" do
    product = insert(:product)
    ProductContext.insert_product_condition_hierarchy(product.id, "Married Employee", "Spouse", 1)
  end

  test "insert_facility_by_location_group/2 got :ok" do
    insert(:location_group, name: "Northern")
    insert(:product, name: "Produkto")
    insert(:coverage)
    product_coverage = insert(:product_coverage)
    facility = ProductContext.add_facility_by_location_group(["Northern"], product_coverage.id)

    assert :ok == facility
  end

  test "insert_facility_by_location_group/2 got nil with nil parameter" do
    insert(:product, name: "Produkto")
    insert(:coverage)
    product_coverage = insert(:product_coverage)
    facility = ProductContext.add_facility_by_location_group(nil, product_coverage.id)

    assert is_nil(facility)
  end

  test "insert_facility_by_location_group/2 got nil with [] parameter" do
    insert(:product, name: "Produkto")
    insert(:coverage)
    product_coverage = insert(:product_coverage)
    facility = ProductContext.add_facility_by_location_group([], product_coverage.id)

    assert is_nil(facility)
  end

  test"check_facility_if_existing/2 got :ok" do
    facility = insert(:facility)
    insert(:product, name: "Produkto")
    insert(:coverage)
    product_coverage = insert(:product_coverage)
    pcf = ProductContext.check_facility_if_existing([facility.id], product_coverage.id)

    assert :ok == pcf
  end

  test"check_facility_if_existing/2 got nil with [] parameter" do
    insert(:product, name: "Produkto")
    insert(:coverage)
    product_coverage = insert(:product_coverage)
    pcf = ProductContext.check_facility_if_existing([], product_coverage.id)

    assert is_nil(pcf)
  end

  test "get_acu_affiliated_facilities/1, get all affiliated facility" do
    facility = insert(:facility)
    product = insert(:product, name: "Sample")
    coverage = insert(:coverage, name: "ACU")
    pc = insert(:product_coverage, product: product, coverage: coverage)
    insert(:product_coverage_facility, product_coverage: pc, facility: facility)

    {:ok, result} = ProductContext.get_acu_affiliated_facilities(product.id)
    assert List.first(result).id == facility.id
  end


  test "set_product_coverages/, with valid parameter" do
    product = insert(:product, product_category: "Dental Plan")
    facility = insert(:facility)
    coverage = insert(:coverage, code: "DENTL", name: "Dental")
    pc = insert(:product_coverage, product: product, coverage: coverage)
    insert(:product_coverage_facility, product_coverage: pc, facility: facility)
    insert(:product_coverage_limit_threshold, product_coverage: pc)
    params = %{"facility_ids" => [facility.id], "type" => "Specific Facilities"}

    result = ProductContext.set_product_coverages(product, params, coverage.code)
    assert result == {:ok}
  end
  describe "get dental facilities by location group" do
    test "when params is valid" do
      ftype = insert(:dropdown, type: "Facility Type22", value: "DP", text: "DENTAL PROVIDER")
      facility = insert(:facility, code: "test", name: "test", type: ftype)
      location_group = insert(:location_group, name: "LOCATIONGROUP", code: "LOCGROUP")
      insert(:facility_location_group, facility: facility, location_group: location_group)

      result = ProductContext.get_dental_facilities_by_lg_name("LOCATIONGROUP")
      assert result.name == location_group.name
    end

    test "when params is valid and no data fetch" do
      ftype = insert(:dropdown, type: "Facility Type22", value: "DP", text: "DENTAL PROVIDER")
      facility = insert(:facility, code: "test", name: "test", type: ftype)
      location_group = insert(:location_group, name: "LOCATIONGROUP", code: "LOCGROUP")
      insert(:facility_location_group, facility: facility, location_group: location_group)

      result = ProductContext.get_dental_facilities_by_lg_name("LOCATIONGROUP22")
      assert result == nil
    end

    # test "when params is valid and have multiple result" do
    #   ftype = insert(:dropdown, type: "Facility Type22", value: "DP", text: "DENTAL PROVIDER")
    #   facility = insert(:facility, code: "test", name: "test", type: ftype)
    #   location_group = insert(:location_group, name: "LOCATIONGROUP", code: "LOCGROUP")
    #   insert(:facility_location_group, facility: facility, location_group: location_group)

    #   insert(:facility_location_group, facility: facility, location_group: location_group)

    #   result = ProductContext.get_dental_facilities_by_lg_name("LOCATIONGROUP")
    #   assert result == nil
    # end
  end
end

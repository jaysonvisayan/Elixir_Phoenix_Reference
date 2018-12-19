defmodule Innerpeace.PayorLink.Web.ProductControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper
  alias Innerpeace.Db.Schemas.Product

  alias Ecto.UUID


  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_products", module: "Products"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "lists all entries on index", %{conn: conn, user: user} do
    product =
      insert(:product,
        code: Product.random_pcode(),
        created_by_id: user.id,
        updated_by_id: user.id)
    conn = get conn, product_path(conn, :index)
    assert html_response(conn, 200) =~ "Plan"
    # assert html_response(conn, 200) =~ "Search"
    assert html_response(conn, 200) =~ "Plan Name"
    assert html_response(conn, 200) =~ "Description"
  end

  test "renders form for creating new product", %{conn: conn} do
    conn = get conn, product_path(conn, :new_reg)
    assert html_response(conn, 200) =~ "Plan"
    assert html_response(conn, 200) =~ "Add Plan"
    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ "Benefit"
    assert html_response(conn, 200) =~ "Exclusion"
    assert html_response(conn, 200) =~ "Facility Access"
    assert html_response(conn, 200) =~ "Conditions"
    assert html_response(conn, 200) =~ "Summary"
    assert html_response(conn, 200) =~ "Plan Name"
    assert html_response(conn, 200) =~ "Plan Description"
    assert html_response(conn, 200) =~ "Limit Amount"
    assert html_response(conn, 200) =~ "Plan Type"
  end

  test "creates general step1 with valid attributes", %{conn: conn, user: user} do
    insert(:payor)
    params = %{
      "name" => "produkto el dorado",
      "description" => "test desc",
      "limit_applicability" => "limit_app_test",
      "type" => "123",
      "limit_type" => "test",
      "limit_amount" => "2000",
      "phic_status" => "test_phic_status",
      "standard_product" => "Yes",
      "created_by_id" => user.id,
      # "created_by_id" => user.id,
      "step" => "3",
      "member_type" => ["Principal"],
      "product_base" => "Exclusion-based"
    }
    conn = post conn, product_path(conn, :create), product: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == product_path(conn, :setup, id, step: "2")
  end

  #  test "doesn't create general step1 with invalid attributes", %{conn: conn} do
  #    insert(:payor)
  #    params = %{
  #      "name" => "",
  #      "description" => "",
  #      "limit_applicability" => "",
  #      "type" => "123",
  #      "limit_type" => "test",
  #      "limit_amount" => "2000",
  #      "phic_status" => "test_phic_status",
  #      "standard_product" => "Yes"
  #    }
  #    conn = post conn, product_path(conn, :create), product: params
  #    assert html_response(conn, 200) =~ "Product Name"
  #  end

  test "renders form for editing step 1 of the given product", %{conn: conn} do
    product = insert(:product, step: "1")
    conn = get conn, product_path(conn, :setup, product, step: "1")
    assert html_response(conn, 200) =~ product.name
  end

  test "updates step 1 of the given product with valid attrs", %{conn: conn, user: user} do
    product = insert(:product, product_category: "Regular Plan")
    params = %{
      "name" => "produkto el dorado updated",
      "description" => "test desc",
      "limit_applicability" => "Indwividual",
      "type" => "123",
      "limit_type" => "Platinum",
      "limit_amount" => "20001",
      "phic_status" => "Required to File",
      "standard_product" => "No",
      "member_type" => ["Principal", "Dependent"],
      "product_base" => "Exclusion-based",
      "created_by_id" => user.id
    }
    conn = put conn, product_path(conn, :update_setup, product, step: "1", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  end

  test "updates step 1 of the given product with invalid attrs", %{conn: conn} do
    product = insert(:product)
    params = %{
      "name" => "produkto el dorado updated",
      "description" => "",
      "limit_applicability" => "Indwividual",
      "type" => "123",
      "limit_type" => "Platinum",
      "limit_amount" => "20001",
      "phic_status" => "Required to File",
      "standard_product" => "No"
    }
    conn = put conn, product_path(conn, :update_setup, product, step: "1", product: params)
    assert html_response(conn, 200) =~ product.name
  end

  test "renders form for step-3 of the given product", %{conn: conn} do
    product = insert(:product, step: "3")
    conn = get conn, product_path(conn, :setup, product, step: "3")
    assert html_response(conn, 200) =~ "Benefit"
    assert html_response(conn, 200) =~ "Benefit Code"
  end

  test "renders form for step-2 of the given product", %{conn: conn} do
    product = insert(:product, step: "2")
    conn = get conn, product_path(conn, :setup, product, step: "2")
    assert html_response(conn, 200) =~ "Exclusion"
    assert html_response(conn, 200) =~ "General Exclusion"
    assert html_response(conn, 200) =~ "Pre-Existing Condition"
    #from modal
    assert html_response(conn, 200) =~ "Add Exclusions"
    assert html_response(conn, 200) =~ "Exclusion Code"
    assert html_response(conn, 200) =~ "Exclusion Name"
    assert html_response(conn, 200) =~ "No. of Procedures"
    assert html_response(conn, 200) =~ "No. of Diseases"
  end

  test "step-2 adds general exclusion within the product with valid attrs", %{conn: conn} do
    product = insert(:product)
    exclusion1 = insert(:exclusion, coverage: "Exclusion")
    exclusion2 = insert(:exclusion, coverage: "Exclusion")
    exclusions = "#{exclusion1.id},#{exclusion2.id}"

    params = %{
      "gen_exclusion_ids_main" => exclusions
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "2.1", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  end

  test "step-2 adds general exclusion within the product with invalid attrs", %{conn: conn} do
    product = insert(:product)
    params = %{
      "gen_exclusion_ids_main" => ""
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "2.1", product: params)
    assert html_response(conn, 200) =~ "Exclusion"
    assert html_response(conn, 200) =~ "General Exclusion"
    assert html_response(conn, 200) =~ "Pre-Existing Condition"
  end

  test "step-2 adds pre existing condition within the product with valid attrs", %{conn: conn} do
    product = insert(:product)
    exclusion1 = insert(:exclusion, coverage: "Pre-existing condition", limit_type: "Peso", limit_amount: "1000")
    exclusion2 = insert(:exclusion, coverage: "Pre-existing condition", limit_type: "Peso", limit_amount: "1000")
    exclusions = "#{exclusion1.id},#{exclusion2.id}"

    params = %{
      "pre_existing_ids_main" => exclusions
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "2.2", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  end

  test "step-2 adds pre existing condition within the product with invalid attrs", %{conn: conn} do
    product = insert(:product)
    params = %{
      "pre_existing_ids_main" => ""
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "2.2", product: params)
    assert html_response(conn, 200) =~ "Exclusion"
    assert html_response(conn, 200) =~ "General Exclusion"
    assert html_response(conn, 200) =~ "Pre-Existing Condition"
  end

  test "step-2 edits pre existing condition within the product with valid attrs", %{conn: conn} do
    product = insert(:product)
    exclusion = insert(:exclusion)
    product_exclusion = insert(:product_exclusion, product: product, exclusion: exclusion)
    params = %{
      "product_exclusion" => product_exclusion.id,
      "exclusion_id" => exclusion.id,
      "limit_type" => "Peso",
      "limit_peso" => 100
    }
    conn = post conn, product_path(conn, :edit_pec_limit, product, product_exclusion: params)
    assert conn.private[:phoenix_flash]["info"] =~ "Successfully updated PEC Limit"
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  end

  test "step-2 edits pre existing condition within the product with invalid attrs", %{conn: conn} do
    product = insert(:product)
    exclusion = insert(:exclusion)
    product_exclusion = insert(:product_exclusion, product: product, exclusion: exclusion)
    params = %{
      "product_exclusion" => product_exclusion.id,
      "exclusion_id" => exclusion.id,
      "limit_type" => "Pesoa",
      "limit_peso" => 100
    }
    conn = post conn, product_path(conn, :edit_pec_limit, product, product_exclusion: params)
    assert conn.private[:phoenix_flash]["error"] =~ "Error updating PEC Limit"
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  end

  #  test "step-3 adds benefit within the product", %{conn: conn} do
  #    product = insert(:product)
  #    benefit1 = insert(:benefit, name: "Benefit1")
  #    benefit2 = insert(:benefit, name: "Benefit2")
  #    benefits = benefit1.id <>","<> benefit2.id || "#{benefit1.id},#{benefit2.id}"
  #    params = %{
  #      "benefit_ids_main" => benefits,
  #    }
  #    conn = post conn, product_path(conn, :update_setup, product, step: "2", product: params)
  #    assert redirected_to(conn) == product_path(conn, :setup, product, step: "2")
  #  end

  test "step-3 adds benefit within the product without selecting any of benefits", %{conn: conn} do
    product = insert(:product)
    benefit1 = insert(:benefit, name: "Benefit1")
    benefit2 = insert(:benefit, name: "Benefit2")
    _benefits = benefit1.id <> "," <> benefit2.id || "#{benefit1.id},#{benefit2.id}"
    params = %{
      "benefit_ids_main" => "",
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "3", product: params)
    assert html_response(conn, 200) =~ "Benefit Code"
  end

  test "step-3 after adding benefit within the product, onclick for benefit_code on a given row, renders product_benefit_limit_clone_table, For Product Percentage", %{conn: conn} do
    product = insert(:product)
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
    product_benefit_limit =
      insert(:product_benefit_limit,
        benefit_limit: benefit_limit,
        product_benefit: product_benefit,
        coverages: "OPC, OPL",
        limit_type: "Plan Limit Percentage",
        limit_percentage: 90)
    conn = get conn, product_path(conn, :setup, product, product_benefit, step: "3.1")
    assert html_response(conn, 200) =~ "Benefit:"
    assert html_response(conn, 200) =~ benefit.code
    assert html_response(conn, 200) =~ benefit.name
    assert html_response(conn, 200) =~ "Coverage"
    assert html_response(conn, 200) =~ "Type"
    assert html_response(conn, 200) =~ "Value"
    assert html_response(conn, 200) =~ product_benefit_limit.limit_type
    assert html_response(conn, 200) =~ product_benefit_limit.coverages
    assert html_response(conn, 200) =~ Integer.to_string(product_benefit_limit.limit_percentage)
  end

  test "step-3 after adding benefit within the product, onclick for benefit_code on a given row, renders product_benefit_limit_clone_table, For Peso", %{conn: conn} do
    product = insert(:product)
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
    product_benefit_limit =
      insert(:product_benefit_limit,
        benefit_limit: benefit_limit,
        product_benefit: product_benefit,
        coverages: "OPC, OPL",
        limit_type: "Peso",
        limit_amount: 10_000)
    conn = get conn, product_path(conn, :setup, product, product_benefit, step: "3.1")
    assert html_response(conn, 200) =~ "Benefit:"
    assert html_response(conn, 200) =~ benefit.code
    assert html_response(conn, 200) =~ benefit.name
    assert html_response(conn, 200) =~ "Coverage"
    assert html_response(conn, 200) =~ "Type"
    assert html_response(conn, 200) =~ "Value"
    assert html_response(conn, 200) =~ product_benefit_limit.limit_type
    assert html_response(conn, 200) =~ product_benefit_limit.coverages
    assert html_response(conn, 200) =~ Decimal.to_string(product_benefit_limit.limit_amount)
  end

  test "step-3 after adding benefit within the product, onclick for benefit_code on a given row, renders product_benefit_limit_clone_table, For Session", %{conn: conn} do
    product = insert(:product)
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
    product_benefit_limit =
      insert(:product_benefit_limit,
        benefit_limit: benefit_limit,
        product_benefit: product_benefit,
        coverages: "OPC, OPL",
        limit_type: "Sessions",
        limit_session: 25)
    conn = get conn, product_path(conn, :setup, product, product_benefit, step: "3.1")
    assert html_response(conn, 200) =~ "Benefit:"
    assert html_response(conn, 200) =~ benefit.code
    assert html_response(conn, 200) =~ benefit.name
    assert html_response(conn, 200) =~ "Coverage"
    assert html_response(conn, 200) =~ "Type"
    assert html_response(conn, 200) =~ "Value"
    assert html_response(conn, 200) =~ product_benefit_limit.limit_type
    assert html_response(conn, 200) =~ product_benefit_limit.coverages
    assert html_response(conn, 200) =~ Integer.to_string(product_benefit_limit.limit_session)
  end

  test "updating product_benefit_limit with valid attrs from modal-form", %{conn: conn} do
    product = insert(:product)
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
    product_benefit_limit =
      insert(:product_benefit_limit,
        benefit_limit: benefit_limit,
        product_benefit: product_benefit,
        coverages: "OPC, OPL",
        limit_type: "Percentage",
        limit_amount: 200)
    params = %{
      product_benefit_limit_id: product_benefit_limit.id,
      product_benefit_id: product_benefit.id,
      coverages: "OPC, EMRGNCY",
      limit_type: "Peso",
      amount: 200
    }
    conn = put conn, product_path(conn, :update_setup, product, step: "3.1", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, product_benefit, step: "3.1")
  end

  test "renders table for step 4", %{conn: conn} do
    product = insert(:product, step: "4")
    conn = get conn, product_path(conn, :setup, product, step: "4")
    assert html_response(conn, 200) =~ "Facility Code"
    assert html_response(conn, 200) =~ "Facility Name"
    assert html_response(conn, 200) =~ "Facility Type"
    assert html_response(conn, 200) =~ "Region"
    assert html_response(conn, 200) =~ "Category"
  end

  test "step4 updating product_facility list in products with valid attrs", %{conn: conn} do
    product = insert(:product, name: "test name")
    product_coverage = insert(:product_coverage)
    facility1 = insert(:facility, name: "Facility1")
    facility2 = insert(:facility, name: "Facility2")

    params = %{
      "product_coverage_id" => product_coverage.id,
      "facility_ids_main" => facility1.id <> "," <> facility2.id,
    }
    conn = post conn, product_path(conn, :update_setup, product, step: "4", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "4")
  end

  test "get_product_facilities, get list of product facilities", %{conn: conn} do
    product = insert(:product, step: "4")
    conn = get conn, product_path(conn, :setup, product, step: "4")
    assert html_response(conn, 200) =~ "Category"
  end

  test "deleting_product_facilities, deleting product facility records", %{conn: conn} do
    product_coverage = insert(:product_coverage)
    _product_params = %{
      product_coverage_id: product_coverage.id
    }

    conn = delete conn, product_path(conn, :deleting_product_facilities, product_coverage.id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

  test "deleting_product_facility, deleting a product facility record", %{conn: conn} do
    product_facilities = insert(:product_facility)

    conn = delete conn, product_path(conn, :deleting_product_facility, product_facilities.id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

  test "update_product_coverage, update coverage in product record", %{conn: conn} do
    product = insert(:product)
    coverage = insert(:coverage)
    product_params = %{
      product_id: product.id,
      coverage_id: coverage.id
    }

    conn = put conn, product_path(conn, :update_product_coverage, product_params.product_id, product_params.coverage_id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

    test "renders table for edit facility access", %{conn: conn} do
      product = insert(:product, standard_product: "No")
      conn = get conn, product_path(conn, :edit_setup, product, tab: "facility_access")
      assert html_response(conn, 200) =~ "Facility Code"
      assert html_response(conn, 200) =~ "Facility Name"
      assert html_response(conn, 200) =~ "Facility Type"
      assert html_response(conn, 200) =~ "Region"
      assert html_response(conn, 200) =~ "Category"
    end

    test "edit_facility, updating product_facility list in products with valid attrs", %{conn: conn} do
      product = insert(:product)
      product_coverage = insert(:product_coverage, product: product)
      facility1 = insert(:facility, name: "Facility1")
      facility2 = insert(:facility, name: "Facility2")

      params = %{
        "product_coverage_id" => product_coverage.id,
        "facility_ids_main" => facility1.id <> "," <> facility2.id,
      }
      conn = post conn, product_path(conn, :save, product, tab: "facility_access", product: params)
      assert redirected_to(conn) == product_path(conn, :edit_setup, product, tab: "facility_access")
    end

  test "renders table for step 6", %{conn: conn} do
    product = insert(:product, step: "6")
    conn = get conn, product_path(conn, :setup, product, step: "6")
    assert html_response(conn, 200) =~ "Risk Share"
    assert html_response(conn, 200) =~ "Value"
    assert html_response(conn, 200) =~ "Covered after Risk Share"
    assert html_response(conn, 200) =~ "Facility"
    assert html_response(conn, 200) =~ "Procedure"
  end

  #  test "update for step 6, only for af_covered, naf_covered and naf_reimbursable", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    params =
  #      %{
  #        "af_covered" => "22",
  #        "af_type" => "N/A",
  #        "af_value" => "",
  #        "naf_covered" => "22",
  #        "naf_reimbursable" => "No",
  #        "naf_type" => "N/A",
  #        "naf_value" => "",
  #        "risk_share_id" => product_risk_share.id
  #      }
  #    conn = put conn, product_path(conn, :update_setup, product, step: "6", product: params)
  #    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
  #  end

  #  test "update for step 6, with complete params", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    params =
  #      %{
  #        "af_covered" => "22",
  #        "af_type" => "Copayment",
  #        "af_value" => "2255",
  #        "naf_covered" => "22",
  #        "naf_reimbursable" => "Yes",
  #        "naf_type" => "Copayment",
  #        "naf_value" => "2255",
  #        "risk_share_id" => product_risk_share.id
  #      }
  #    conn = put conn, product_path(conn, :update_setup, product, step: "6", product: params)
  #    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
  #  end

  #  test "update for step 6, with incomplete params", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    params =
  #      %{
  #        "af_covered" => "",
  #        "af_type" => "Copayment",
  #        "af_value" => "2255",
  #        "naf_covered" => "",
  #        "naf_reimbursable" => "",
  #        "naf_type" => "Copayment",
  #        "naf_value" => "2255",
  #        "risk_share_id" => product_risk_share.id
  #      }
  #    conn = put conn, product_path(conn, :update_setup, product, step: "6", product: params)
  #    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
  #  end

  # There will be no negative test scenario in this ProductRiskShareFacility
  #  due to the modal complexity only, javascript validation has been suggested
  #  test "update for step 6, inserting product risk share facility
  #   if product_risk_share_facility_id is null", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    facility = insert(:facility)
  #    params =
  #      %{
  #        "covered" => "100",
  #        "facility_id" => facility.id,
  #        "product_risk_share_facility_id" => "",
  #        "product_risk_share_id" => product_risk_share.id,
  #        "type" => "Alternative",
  #        "value" => "22"
  #      }
  #    conn = post conn, product_path(conn, :update_setup, product, step: "6.1", product: params)
  #    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
  #  end

# There will be no negative test scenario in this ProductRiskShareFacilityProcedure
#   due to the modal complexity, only javascript validation has been suggested
#  test "update for step 6, inserting product risk share facility procedure
#   if product_risk_share_facility_procedure_id is null", %{conn: conn} do
#    product = insert(:product)
#    coverage = insert(:coverage, description: "OPLAB")
#    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
#    facility = insert(:facility)
#    product_risk_share_facility =
#     insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
#    procedure = insert(:procedure)
#    params =
#      %{
#        "procedure_id" => procedure.id,
#        "product_risk_share_facility_id" => product_risk_share_facility.id,
#        "product_risk_share_facility_procedure_id" => "",
#        "rs_covered" => "22",
#        "rs_type" => "Alternative",
#        "rs_value" => "22"
#      }
#
#    conn = post conn, product_path(conn, :update_setup, product, step: "6.2", product: params)
#    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
#  end

# There will be no negative test scenario in this ProductRiskShareFacility
#   due to the modal complexity only, javascript validation has been suggested
#  test "update for step 6, updating product risk share facility
#   if product_risk_share_facility_id is not-null", %{conn: conn} do
#    product = insert(:product)
#    coverage = insert(:coverage, description: "OPLAB")
#    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
#    facility = insert(:facility, code: "FC101", name: "MakatiMed")
#    product_risk_share_facility =\
#     insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
#    params =
#      %{
#        "covered" => "100",
#        "facility_id" => facility.id,
#        "product_risk_share_facility_id" => product_risk_share_facility.id,
#        "product_risk_share_id" => product_risk_share.id,
#        "type" => "Alternative",
#        "value" => "22"
#      }
#    conn = put conn, product_path(conn, :update_setup, product, step: "6.1", product: params)
#    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
#    assert product_risk_share_facility.facility.code
#    assert product_risk_share_facility.facility.name
#  end

# There will be no negative test scenario in this ProductRiskShareFacilityProcedure
#   due to the modal complexity, only javascript validation has been suggested
#  test "update for step 6,updating product risk share facility procedure
#   if product_risk_share_facility_procedure_id is not-null", %{conn: conn} do
#    product = insert(:product)
#    coverage = insert(:coverage, description: "OPLAB")
#    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
#    facility = insert(:facility)
#    product_risk_share_facility =
#     insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
#    procedure = insert(:procedure)
#    product_risk_share_facility_procedure =
#     insert(:product_risk_share_facility_procedure,
#     product_risk_share_facility: product_risk_share_facility, procedure: procedure)
#    params =
#      %{
#        "procedure_id" => procedure.id,
#        "product_risk_share_facility_id" => product_risk_share_facility.id,
#        "product_risk_share_facility_procedure_id" => product_risk_share_facility_procedure.id,
#        "rs_covered" => "22",
#        "rs_type" => "Alternative",
#        "rs_value" => "22"
#      }
#    conn = put conn, product_path(conn, :update_setup, product, step: "6.2", product: params)
#    assert redirected_to(conn) == product_path(conn, :setup, product, step: "6")
#  end

  ##### AJAX get_product_benefit_limit
  # test "get_product_benefit_limit, request and response", %{conn: conn} do
  #   product_benefit_limit =
  #     insert(:product_benefit_limit, limit_type: "Peso", limit_amount: 20.10, coverages: "OPC, OPL", limit_classification: "Per Coverage")
  #   conn = get conn, product_path(conn, :get_product_benefit_limit, product_benefit_limit.id)
  #   assert json_response(conn, 200) == Poison.encode!(%{
  #     "limit_type": "Peso",
  #     "limit_session": nil,
  #     "limit_percentage": nil,
  #     "limit_amount": "20.1",
  #     "limit_classification": "Per Coverage",
  #     "id": product_benefit_limit.id,
  #     "coverages": "OPC, OPL"
  #   })
  # end

  ##### AJAX get_product_risk_share
  #  test "get_product_risk_share, request and response", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #
  #    conn = get conn, product_path(conn, :get_product_risk_share, product_risk_share.id)
  #    response = json_response(conn, 200)
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed.id == product_risk_share.id
  #
  #    parsed = Poison.Parser.parse!(response)
  #    assert parsed["id"] == product_risk_share.id
  #  end

  ##### AJAX get_product_risk_share_facility
  # test "get_product_rs_facility, request and response", %{conn: conn} do
  #   product = insert(:product)
  #   coverage = insert(:coverage, description: "OPLAB")
  #   product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #   facility = insert(:facility)
  #   product_risk_share_facility =
  #   insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)

  #   conn = get conn, product_path(conn, :get_product_rs_facility, product_risk_share.id, facility.id)
  #   response = json_response(conn, 200)

  #   parsed = Poison.Parser.parse!(response, keys: :atoms)
  #   assert parsed.id == product_risk_share_facility.id

  #   parsed = Poison.Parser.parse!(response)
  #   assert parsed["id"] == product_risk_share_facility.id
  # end

  # test "get_product_risk_share_facility, request and response", %{conn: conn} do
  #   product = insert(:product)
  #   coverage = insert(:coverage, description: "OPLAB")
  #   product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #   facility = insert(:facility)
  #   product_risk_share_facility =
  #   insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)

  #   conn = get conn, product_path(conn, :get_product_risk_share_facility, product_risk_share_facility.id)
  #   response = json_response(conn, 200)

  #   parsed = Poison.Parser.parse!(response, keys: :atoms)
  #   assert parsed.id == product_risk_share_facility.id

  #   parsed = Poison.Parser.parse!(response)
  #   assert parsed["id"] == product_risk_share_facility.id
  # end

  ##### AJAX get_product_risk_share_facility_procedure
  #  test "get_prsf_procedure, request and response", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    facility = insert(:facility)
  #    product_risk_share_facility =
  #     insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #    procedure = insert(:procedure)
  #    product_risk_share_facility_procedure =
  #     insert(:product_risk_share_facility_procedure,
  #     product_risk_share_facility: product_risk_share_facility, procedure: procedure)
  #
  #    conn = get conn, product_path(conn, :get_prsf_procedure, product_risk_share_facility.id, procedure.id)
  #    response = json_response(conn, 200)
  #
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed.id == product_risk_share_facility_procedure.id
  #
  #    parsed = Poison.Parser.parse!(response)
  #    assert parsed["id"] == product_risk_share_facility_procedure.id
  #  end

  ##### AJAX deleting product_risk_share_facility
  #  test "delete_prs_facility, deleting product_risk_share_facility", %{conn: conn} do
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage)
  #    facility = insert(:facility)
  #    product_risk_share_facility =
  #    insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #    conn = delete conn, product_path(conn, :delete_prs_facility, product_risk_share_facility.id)
  #    response = json_response(conn, 200)
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed == %{valid: true}
  #  end

  # my branch is not yet updated in sir bryan's latest branch we skip for a while
  #test "insert_empty_facility, if they selected radiobutton aaf or sf", %{conn: conn} do
  #  product = insert(:product)
  #  coverage = insert(:coverage, description: "OPLAB")
  #
  #end

  test "update_prsf_coverage, update coverage_accordion in product_risk_share_facility", %{conn: conn} do
    product = insert(:product)
    coverage = insert(:coverage)

    conn = put conn, product_path(conn, :update_prsf_coverage, product.id, coverage.id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

  ### We skipped edit/update methods due to same logic with Step

  #  test "renders step7", %{conn: conn} do
  #    product = insert(:product, name: "Maxi product", code: "MAXI-101")
  #
  #    benefit = insert(:benefit, name: "B101")
  #    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
  #
  #    exclusion = insert(:exclusion, name: "Exclusion101")
  #    product_exclusion = insert(:product_exclusion, product: product, exclusion: exclusion)
  #
  #    coverage = insert(:coverage, description: "OPLAB")
  #
  #
  #    coverage2 = insert(:coverage, description: "OPCON")
  #
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage, af_value: 20)
  #    facility = insert(:facility, name: "Manila Med")
  #    product_risk_share_facility =
  #    insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #    procedure = insert(:procedure, description: "MIR Scan")
  #    product_risk_share_facility_procedure = insert(
  #      :product_risk_share_facility_procedure,
  #      product_risk_share_facility: product_risk_share_facility,
  #      procedure: procedure
  #    )
  #
  #    conn = get conn, product_path(conn, :setup, product, step: "7")
  #    assert html_response(conn, 200) =~ "General"
  #    assert html_response(conn, 200) =~ "Benefit"
  #    assert html_response(conn, 200) =~ "Exclusion"
  #    assert html_response(conn, 200) =~ "Facility Access"
  #    assert html_response(conn, 200) =~ "Condition"
  #    assert html_response(conn, 200) =~ "Risk Share"
  #    assert html_response(conn, 200) =~ "Summary"
  #    assert html_response(conn, 200) =~ product.id
  #    assert html_response(conn, 200) =~ product.name
  #    assert html_response(conn, 200) =~ product.code
  #    assert html_response(conn, 200) =~ product_benefit.benefit.name
  #    assert html_response(conn, 200) =~ product_exclusion.exclusion.name
  #    # Temporarily removed this
  #    # assert html_response(conn, 200) =~ product_coverage.product_coverage_facilities.facility.name
  #    assert html_response(conn, 200) =~ Integer.to_string(product_risk_share.af_value)
  #    assert html_response(conn, 200) =~ product_risk_share_facility.facility.name
  #    assert html_response(conn, 200) =~ product_risk_share_facility_procedure.procedure.description
  #  end

  ## skip this test due to no json encode valid true
  # test "delete_product_exclusion, deletes selected product exclusion", %{conn: conn} do
  #   product = insert(:product)
  #   exclusion = insert(:exclusion, name: "Exclusion101")
  #   product_exclusion = insert(:product_exclusion, product: product, exclusion: exclusion)
  #   conn = delete conn, product_path(conn, :delete_product_exclusion, product.id, product_exclusion.id)
  # end

  #  test "filter_prs_facilities, facilities -- selected_facilities", %{conn: conn} do
  #    facility = insert(:facility, name: "MakatiMed", code: "MMC")
  #    facility2 = insert(:facility, name: "MakatiMedssss", code: "MMssC")
  #
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage, af_value: 20)
  #    product_risk_share_facility =
  #    insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #
  #
  #    conn = get conn, product_path(conn, :filter_prs_facilities, product.id, coverage.id)
  #    response = json_response(conn, 200)
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed == [%{display: "MMssC - MakatiMedssss", id: facility2.id}]
  #
  #  end

  #  test "filter_prs_facility_procedures, procedures -- selected_procedures", %{conn: conn} do
  #    facility = insert(:facility, name: "MakatiMed", code: "MMC")
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage, af_value: 20)
  #    product_risk_share_facility =
  #    insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #
  #    procedure = insert(:procedure, description: "MIR Scan", code: "MIR101")
  #    procedure2 = insert(:procedure, description: "Tele Scan", code: "TScan102")
  #    product_risk_share_facility_procedure = insert(
  #      :product_risk_share_facility_procedure,
  #      product_risk_share_facility: product_risk_share_facility,
  #      procedure: procedure
  #    )
  #
  #    conn = get conn, product_path(conn, :filter_prs_facility_procedures, product.id, product_risk_share_facility.id)
  #    response = json_response(conn, 200)
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed == [%{display: "TScan102 - Tele Scan", id: procedure2.id}]
  #  end

  # test "filter_included_prs_facilities, selected_facilities", %{conn: conn} do
  #   facility = insert(:facility, name: "MakatiMed", code: "MMC")

  #   product = insert(:product)
  #   coverage = insert(:coverage, description: "OPLAB")
  #   product_risk_share = insert(:product_risk_share, product: product, coverage: coverage, af_value: 20)
  #   product_risk_share_facility =
  #   insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)

  #   conn = get conn, product_path(conn, :filter_included_prs_facilities, product.id, coverage.id)
  #   response = json_response(conn, 200)
  #   parsed = Poison.Parser.parse!(response, keys: :atoms)
  #   assert parsed == [%{display: "MMC - MakatiMed", id: facility.id}]
  # end

  #  test "filter_prs_facility_procedures, selected_procedures", %{conn: conn} do
  #    facility = insert(:facility, name: "MakatiMed", code: "MMC")
  #    product = insert(:product)
  #    coverage = insert(:coverage, description: "OPLAB")
  #    product_risk_share = insert(:product_risk_share, product: product, coverage: coverage, af_value: 20)
  #    product_risk_share_facility =
  #    insert(:product_risk_share_facility, facility: facility, product_risk_share: product_risk_share)
  #
  #    procedure = insert(:procedure, description: "MIR Scan", code: "MIR101")
  #    product_risk_share_facility_procedure = insert(
  #      :product_risk_share_facility_procedure,
  #      product_risk_share_facility: product_risk_share_facility,
  #      procedure: procedure
  #    )
  #
  #    conn =
  #     get conn, product_path(conn,
  #     :filter_included_prs_facility_procedures, product.id, product_risk_share_facility.id)
  #    response = json_response(conn, 200)
  #    parsed = Poison.Parser.parse!(response, keys: :atoms)
  #    assert parsed == [%{display: "MIR101 - MIR Scan", id: procedure.id}]
  #  end

  ## positive test asof now, to be follow negative test
  test "step3_cov/2, rendering coverage step3", %{conn: conn, user: user} do
    product =
      insert(:product,
        code: Product.random_pcode(),
        created_by_id: user.id,
        updated_by_id: user.id,
        product_base: "Exclusion-based",
        step: "3.2")
    coverage1 = insert(:coverage, description: "OPLAB")
    coverage2 = insert(:coverage, description: "OPCON")
    conn = get conn, product_path(conn, :setup, product, step: "3.2")
    assert html_response(conn, 200) =~ "Plan"
    assert html_response(conn, 200) =~ "Coverage"
    assert html_response(conn, 200) =~ coverage1.id
    assert html_response(conn, 200) =~ coverage2.id
  end

  test "step3_cov_update/3, insert or updating product_coverage step3", %{conn: conn, user: user} do
    product =
      insert(:product,
        code: Product.random_pcode(),
        created_by_id: user.id,
        updated_by_id: user.id,
        product_base: "Exclusion-based")
    coverage1 = insert(:coverage, description: "OPLAB")
    coverage2 = insert(:coverage, description: "OPCON")
    params = %{
      "coverages" => [coverage1.id, coverage2.id]
    }
    conn = put conn, product_path(conn, :update_setup, product, step: "3.2", product: params)
    assert redirected_to(conn) == product_path(conn, :setup, product, step: "4")
  end

  test "delete_product_all/1, discard draft plans", %{conn: conn} do
    product = insert(:product)
    conn = delete conn, main_product_path(conn, :delete_product_all, product.id)
    assert json_response(conn, 200) == Poison.encode!(%{
      valid: true
    })
  end

  # test "update_general", %{conn: conn, user: user} do
  #   product = insert(:product, product_category: "Regular Plan")
  #   product_params = %{
  #     "name" => "produkto el dorado updated",
  #     "description" => "test desc",
  #     "limit_applicability" => "Individual",
  #     "type" => "123",
  #     "limit_type" => "Platinum",
  #     "limit_amount" => "20001",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "member_type" => ["Principal", "Dependent"],
  #     "product_base" => "Exclusion-based",
  #     "created_by_id" => user.id,
  #     "step" => "2"
  #   }

  #   conn = put conn, main_product_path(conn, :update_general, product, product: product_params)
  #   assert conn.private[:phoenix_flash]["info"] =~ "Plan Updated Successfully."
  #   assert redirected_to(conn) == "/web/products/#{product.id}/edit?tab=general"
  # end

  test "update_general_peme", %{conn: conn, user: user} do
    product = insert(:product, product_category: "PEME Plan", member_type: ["Dependent"])
    product_params = %{
      "name" => "produkto el dorado peme updated",
      "description" => "test desc",
      "in_lieu_of_acu" => "true",
      "type" => "Gold",
      "standard_product" => "No",
      "member_type" => ["Principal", "Dependent"],
      "created_by_id" => user.id,
      "updated_by_id" => user.id,
      "step" => "2"
     }

    conn = put conn, main_product_path(conn, :update_general_peme, product, product: product_params)
    assert conn.private[:phoenix_flash]["info"] =~ "Plan Updated Successfully."
    # conn = post conn, main_product_path(conn, :save, product, tab: "general")
    assert redirected_to(conn) == "/web/products/#{product.id}/edit?tab=general"
  end

  test "update_general_reg_plan", %{conn: conn, user: user} do
    product = insert(:product, product_category: "Regular Plan")
    product_params = %{
      "name" => "produkto el dorado updated",
      "description" => "test desc",
      "limit_applicability" => "Principal",
      "type" => "Platinum",
      "limit_type" => "MBL",
      "limit_amount" => "110000",
      "phic_status" => "Required to File",
      "standard_product" => "No",
      "member_type" => ["Principal", "Dependent"],
      "product_base" => "Benefit-based",
      "created_by_id" => user.id,
      "updated_by_id" => user.id,
      "step" => "2"
    }

    conn = put conn, main_product_path(conn, :update_general_reg_plan, product, product: product_params)
    assert conn.private[:phoenix_flash]["info"] =~ "Plan Updated Successfully."
    assert redirected_to(conn) == "/web/products/#{product.id}/edit?tab=general"
  end

  test "update_product_benefit", %{conn: conn, user: user} do
    product = insert(:product, product_category: "Regular Plan")
    benefit = insert(:benefit)
    benefit_limit = insert(:benefit_limit, benefit: benefit)
    product_benefit = insert(:product_benefit, benefit: benefit, product: product)
    product_benefit_limit =
      insert(:product_benefit_limit,
        benefit_limit: benefit_limit,
        product_benefit: product_benefit)

    product_params = %{
      "amount" => "5000.00",
      "coverages" => "IP",
      "limit_classification" => "Per Transaction",
      "limit_type" => "Peso",
      "original_amount" => "2000.00",
      "product_benefit_id" => product_benefit.id,
      "product_benefit_limit_id" => product_benefit_limit.id,
      "product_limit_amount" => "60000.00"
    }

    conn = post conn, main_product_path(conn, :update_product_benefit, product, product: product_params)
    assert conn.private[:phoenix_flash]["info"] =~ "Benefit Limit updated successfully."
    assert redirected_to(conn) == "/web/products/#{product.id}/edit?tab=product_benefit&pb=#{product_benefit_limit.product_benefit_id}"
  end

end

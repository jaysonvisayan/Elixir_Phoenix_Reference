defmodule Innerpeace.PayorLink.Web.Main.ProductControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  alias Innerpeace.Db.{
    Repo,
    Schemas.Product
  }

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_products", module: "Products"})
    user =
      user
      |> Repo.preload([
        user_roles:
        [role:
         [
           [role_permissions: :permission],
           [role_applications: :application]
         ]
        ]
      ])
    conn = authenticated(conn, user)

    payor = insert(:payor, name: "Maxicare")

    product =
      insert(:product,
             name: "DENTAL PLAN 1",
             code: "DENTAL PLAN 1",
             type: "Platinum",
             description: "DENTAL PLAN 1",
             standard_product: "No",
             limit_amount: Decimal.new(100000),
             product_category: "Dental Plan",
             product_base: "Benefit-based",
             step: "8",
             created_by_id: user.id,
             updated_by_id: user.id,
             payor: payor,
             nem_principal: 10,
             nem_dependent: 10,
             mded_principal: "None",
             mded_dependent: "None",
             principal_min_age: 0,
             principal_min_type: "Years",
             principal_max_age: 100,
             principal_max_type: "Years",
             adult_dependent_min_age: 0,
             adult_dependent_min_type: "Years",
             adult_dependent_max_age: 0,
             adult_dependent_max_type: "Years",
             minor_dependent_min_age: 0,
             minor_dependent_min_type: "Years",
             minor_dependent_max_age: 0,
             minor_dependent_max_type: "Years",
             overage_dependent_min_age: 0,
             overage_dependent_min_type: "Years",
             overage_dependent_max_age: 0,
             overage_dependent_max_type: "Years",
             adnb: Decimal.new(10),
             adnnb: Decimal.new(10),
             opmnb: Decimal.new(10),
             opmnnb: Decimal.new(10),
             hierarchy_waiver: "Skip Allowed",
             sop_principal: "Monthly",
             sop_dependent: "Monthly",
             no_outright_denial: false,
             no_days_valid: 10,
             is_medina: false,
             smp_limit: Decimal.new(0),
             loa_facilitated: true,
             reimbursement: false,
             peme_fee_for_service: false ,
             dental_funding_arrangement: "ASO",
             loa_validity: "12",
             loa_validity_type: "Days",
             special_handling_type: "ASO Override",
             type_of_payment_type: "Separate Fee"
      )
    benefit1 = insert(:benefit, name: "Dental Benefit 1")
    benefit2 = insert(:benefit, name: "Dental Benefit 2")

    coverage = insert(:coverage, name: "Dental", code: "DENTL", description: "Dental", plan_type: "riders")

    insert(:benefit_coverage, benefit: benefit1, coverage: coverage)
    insert(:benefit_coverage, benefit: benefit2, coverage: coverage)
    insert(:benefit_limit, benefit: benefit1,
           limit_type: "Peso",
           limit_amount: Decimal.new(1000),
           coverages: "DENTL"
    )
    insert(:benefit_limit, benefit: benefit2,
           limit_type: "Peso",
           limit_amount: Decimal.new(2000),
           coverages: "DENTL"
    )
    insert(:product_benefit, product: product, benefit: benefit1)
    insert(:product_benefit, product: product, benefit: benefit2)
    pc = insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    f = insert(:facility, name: "HAHAHAA")
    insert(:product_coverage_facility, product_coverage: pc, facility: f)

    {:ok, %{conn: conn, product: product, coverage: coverage}}
  end

  # describe "Copy Dental Plan /web/products/:new_product_id/copy" do
  #   test "copy_dental_plan copies plan", %{conn: conn, product: product} do
  #     conn = post conn, main_product_path(conn, :copy_product, product)

  #     {_, url} = Enum.find(conn.resp_headers, fn(rp) ->
  #       match?({"location", _}, rp)
  #     end)

  #     copied_product_id =
  #       url
  #       |> String.split("/")
  #       |> Enum.at(3)

  #     assert redirected_to(conn) == main_product_path(
  #       conn,
  #       :update_setup,
  #       copied_product_id,
  #       step: "1"
  #     )
  #   end

  #   test "copy_dental_plan does not copy when id does not exist", %{conn: conn} do
  #     conn = post conn, main_product_path(conn, :copy_product, Ecto.UUID.generate())

  #     assert redirected_to(conn) == main_product_path(conn, :index)
  #   end
  # end

  test "render condition form of dental plan", %{conn: conn} do
    product = insert(
      :product,
      step: "3",
      product_category: "Dental Plan"
    )
    conn = get conn, main_product_path(
      conn,
      :setup,
      product,
      step: "3"
    )
    assert html_response(conn, 200) =~ "Dental"
  end

  test "create condition for dental plan", %{conn: conn} do
    product = insert(
      :product,
      step: "3.1",
      product_category: "Dental Plan"
    )
    product_params = %{
      product_id: product.id,
      nem_principal: "2",
      nem_dependent: "4",
      mded_principal: "Date Hire",
      mded_dependent: "Date Hire",
      principal_min_age: "1",
      principal_min_type: "Years",
      principal_max_age: "65",
      principal_max_type: "Years",
      adult_dependent_min_age: "40",
      adult_dependent_min_type: "Years",
      adult_dependent_max_age: "65",
      adult_dependent_max_type: "Years",
      minor_dependent_min_age: "18",
      minor_dependent_min_type: "Years",
      minor_dependent_max_age: "30",
      minor_dependent_max_type: "Years",
      overage_dependent_min_age: "45",
      overage_dependent_min_type: "Years",
      overage_dependent_max_age: "75",
      overage_dependent_max_type: "Years",
      loa_facilitated: "true",
      reimbursement: "true",
      loa_validity: "60",
      loa_validity_type: "Days",
      special_handling_type: "Fee for Service",
      dental_funding_arrangement: "Full Risk",
      type_of_payment_type: "Built In"
    }
    conn = post conn, main_product_path(
      conn, :update_setup,
      product,
      step: "3",
    ),
    product: product_params
    assert redirected_to(conn) == main_product_path(
      conn,
      :update_setup,
      product,
      step: "4"
    )
  end

  test "render summary form of dental plan", %{conn: conn} do
    product = insert(
      :product,
      step: "4",
      product_category: "Dental Plan",
      mode_of_payment: "capitation",
      capitation_type: "test",
      capitation_fee: Decimal.new(1000)
    )
    conn = get conn, main_product_path(conn, :setup, product, step: "4")
    assert html_response(conn, 200) =~ "Summary"
  end

  test "summary form completion of creating dental plan", %{conn: conn} do
    product = insert(
      :product,
      product_category: "Dental Plan",
      mode_of_payment: "capitation",
      capitation_type: "test",
      capitation_fee: Decimal.new(1000)
    )
    product_params = %{
      product_id: product.id
    }
    conn = get conn, main_product_path(
      conn,
      :save_dental_plan,
      product_params.product_id
    )
    assert html_response(conn, 200) =~ "Summary"
  end

  describe "update facility dental" do
    test "renders facility step", %{conn: conn, coverage: coverage} do
      product = insert(
        :product,
        step: "2",
        product_category: "Dental Plan"
      )

      d = insert(:dropdown, value: "DP", text: "DENTAL PROVIDER")
      lg = insert(:location_group, name: "LG 1", code: "LG 123")
      f = insert(:facility, name: "dental fac 1", code: "123123123", type: d)
      f2 = insert(:facility, name: "dental fac 2", code: "234234234", type: d)
      insert(:facility_location_group, facility: f, location_group: lg)
      insert(:facility_location_group, facility: f2, location_group: lg)
      pc = insert(:product_coverage, product: product, coverage: coverage, type: "exception")
      pcdrs = insert(:product_coverage_dental_risk_shares, asdf_type: "copay", asdf_percentage: "100", asdf_special_handling: "corporate guarantee", product_coverage: pc)
      insert(:product_coverage_facility, product_coverage: pc, facility: f2)
      insert(:product_coverage_location_group, location_group: lg, product_coverage: pc)

     conn = get conn, main_product_path(conn, :setup, product, step: "2")
     assert html_response(conn, 200) =~ "Facility"
    end

    test "with valid parameter", %{conn: conn, coverage: coverage} do
      facility = insert(:facility)
      product = insert(
        :product,
        step: "2",
        product_category: "Dental Plan"
      )
      lg = insert(:location_group, name: "LG 1", code: "LG 123")
      pc = insert(:product_coverage, product: product, coverage: coverage, type: "exception")
      pcdrs = insert(:product_coverage_dental_risk_shares, asdf_type: "copay", asdf_percentage: "100", asdf_special_handling: "corporate guarantee", product_coverage: pc)
      params = %{
        "coverages" => ["dentl"],
        "location_group_id" => lg.id,
        "product_coverage_id" => pc.id,
        "pcdrs_id" => pcdrs.id,
        "dentl" => %{
          "facility_ids" => [facility.id],
          "type" => "Specific Facilities"
        },
        "id" => product.id,
        "is_draft" => "false",
        "backButtonFacility" => "false",
        "copay" => "",
        "coinsurance" => ""
      }
      conn = post conn, main_product_path(conn, :update_facility_dental, product, product: params)
   assert redirected_to(conn) == "/web/products/#{product.id}/setup?step=3"

    end
  end

  describe "general step dental" do
    test "Dental general step valid params", %{conn: conn, coverage: coverage} do
      benefit1 = insert(:benefit, name: "Dental Benefit 1")
      benefit2 = insert(:benefit, name: "Dental Benefit 2")
      bc1 = insert(:benefit_coverage, coverage: coverage, benefit: benefit1)
      bc2 = insert(:benefit_coverage, coverage: coverage, benefit: benefit2)
      benefit_limit_data = [
         benefit1.id,
         "Sessions",
         "1",
         benefit2.id,
         "Sessions",
         "1"] |> Enum.join(",")
      product_params = %{
        code: "PRD-Dental0099",
        name: "Dental001",
        description: "Dental Plan Coverage",
        standard_product: "Yes",
        limit_applicability: ["Principal"],
        type: "Platinum",
        limit_amount: "100",
        product_category: "Dental Plan",
        is_draft: "false",
        benefit_ids: [
          benefit1.id,
          benefit2.id
        ],
        benefit_limit_datas: [
          benefit_limit_data
        ]
      }
    conn = post conn, main_product_path(conn, :create_dental, product: product_params)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == "/web/products/#{id}/setup?step=2"
    end
  end

end

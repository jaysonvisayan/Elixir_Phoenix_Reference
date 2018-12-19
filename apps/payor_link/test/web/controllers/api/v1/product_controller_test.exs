defmodule Innerpeace.PayorLink.Web.Api.V1.ProductControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias Innerpeace.Db.Base.Api.ProductContext
  alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    # payor =
    #   :payor
    #   |> insert(code: "MAXI101", name: "Maxicare")

    # procedure =
    #   :procedure
    #   |> insert(code: "15534", description: "Dengue vaccine")

    # payor_procedure =
    #   :payor_procedure
    #   |> insert(procedure_id: procedure.id, payor_id: payor.id, code: "MMC101", description: "D-Vaccine")

    # facility_mmc =
    #   :facility
    #   |> insert(code: "880000000006035", name: "Makati Med")

    # facility_calamba =
    #   :facility
    #   |> insert(code: "880000000000359", name: "Calamba Med")

    # :facility_payor_procedure
    # |> insert(facility: facility_mmc, payor_procedure: payor_procedure, code: "MMC-Dvaccine")

    # :facility_payor_procedure
    # |> insert(facility: facility_calamba, payor_procedure: payor_procedure, code: "CMC-Dvaccine")

    # :room
    # |> insert(code: "REGROOM101", type: "Regular Room")

    # :exclusion
    # |> insert(name: "pre-existing exclusion", code: "Pre-existing-102", coverage: "Pre-existing Condition")

    # acu_benefit =
    #   :benefit
    #   |> insert(name: "ACU101", code: "ACU101", acu_type: "Executive", acu_coverage: "Inpatient")

    # ip_benefit =
    #   :benefit
    #   |> insert(name: "Inpatient101", code: "Inpatient")

    # inpatient =
    #   :coverage
    #   |> insert(name: "Inpatient", description: "Inpatient")

    # acu_cov =
    #   :coverage
    #   |> insert(name: "ACU", description: "ACU")

    #   :benefit_coverage
    #   |> insert(benefit: ip_benefit, coverage: inpatient)

    #   :benefit_coverage
    #   |> insert(benefit: acu_benefit, coverage: acu_cov)

    {:ok, %{jwt: jwt}}
  end

  test "/products, loads all records of product", %{conn: conn, jwt: jwt} do
    products = ProductContext.get_all_products()
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_product_path(conn, :load_products))
    assert %{"product" => json_response(conn, 200)["product"]} == render_json("load_all_products.json", products: products)
  end

  test "/products, loads all records of product without authorization", %{conn: conn} do
    ProductContext.get_all_products()

    conn =
      conn
      |> get(api_product_path(conn, :load_products))
    assert json_response(conn, 401) == %{"error" => %{"message" => "Unauthorized"}}
  end

  # test "post api/v1/products, creating one whole product using product_base: 'Benefit-based' and product_category: 'Regular Product'", %{conn: conn, jwt: jwt} do

  #   params = %{
  #     "code" => "PRD-103550",
  #     "name" => "Ultima Product",
  #     "product_base" => "Benefit-based",
  #     "description" => "Super Product for Elders",
  #     "limit_applicability" => "Individual",
  #     "type" => "Platinum",
  #     "limit_type" => "MBL",
  #     "limit_amount" => "200000.00",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "product_category" => "Regular product",
  #     "member_type" => ["Principal", "Dependent"],

  #     "exclusion" => %{
  #       code: ["Pre-existing-102"]
  #     },

  #     "benefit" => %{
  #       code: ["ACU101"]
  #     },

  #     "facility" => [

  #       %{
  #         "coverage": "acu",
  #         "type": "inclusion",
  #         "code": [
  #           "880000000006035"
  #         ]
  #       }


  #     ],

  #     "nem_principal" => "100",
  #     "nem_dependent" => "0",
  #     "principal_min_age" => "18",
  #     "principal_min_type" => "Years",
  #     "principal_max_age" => "65",
  #     "principal_max_type" => "Years",
  #     "adult_dependent_min_age" => "18",
  #     "adult_dependent_min_type" => "Years",
  #     "adult_dependent_max_age" => "65",
  #     "adult_dependent_max_type" => "Years",
  #     "minor_dependent_min_age" => "15",
  #     "minor_dependent_min_type" => "Days",
  #     "minor_dependent_max_age" => "17",
  #     "minor_dependent_max_type" => "Years",
  #     "overage_dependent_min_age" => "66",
  #     "overage_dependent_min_type" => "Years",
  #     "overage_dependent_max_age" => "100",
  #     "overage_dependent_max_type" => "Years",
  #     "adnb" => "0",
  #     "opmnnb" => "0",
  #     "opmnb" => "0",
  #     "adnnb" => "0",

  #     "funding_arrangement" => [
  #       %{
  #         coverage: "acu",
  #         type: "Full Risk"
  #       }
  #     ],

  #     "rnb" => [

  #       %{
  #         "coverage": "ACU",
  #         "room_and_board": "Nomenclature",
  #         "room_type": "Regular Room",
  #         "room_upgrade": "4",
  #         "room_upgrade_time": "Hours"
  #       }


  #     ]
  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end

  # test "post api/v1/products, creating one whole product using product_base: 'Exclusion-based' and product_category: 'Regular Product'", %{conn: conn, jwt: jwt} do


  #   params = %{
  #     "code" => "PRD-103550",
  #     "name" => "Ultima Product",
  #     "product_base" => "Exclusion-based",
  #     "description" => "Super Product for Elders",
  #     "limit_applicability" => "Individual",
  #     "type" => "Platinum",
  #     "limit_type" => "MBL",
  #     "limit_amount" => "200000.00",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "product_category" => "Regular product",
  #     "member_type" => ["Principal", "Dependent"],

  #     "exclusion" => %{
  #       code: ["Pre-existing-102"]
  #     },

  #     "coverage" => ["Inpatient"],

  #     "facility" => [

  #       %{
  #         "coverage": "inpatient",
  #         "type": "inclusion",
  #         "code": [
  #           "880000000006035"
  #         ]
  #       }


  #     ],

  #     "nem_principal" => "100",
  #     "nem_dependent" => "0",
  #     "principal_min_age" => "18",
  #     "principal_min_type" => "Years",
  #     "principal_max_age" => "65",
  #     "principal_max_type" => "Years",
  #     "adult_dependent_min_age" => "18",
  #     "adult_dependent_min_type" => "Years",
  #     "adult_dependent_max_age" => "65",
  #     "adult_dependent_max_type" => "Years",
  #     "minor_dependent_min_age" => "15",
  #     "minor_dependent_min_type" => "Days",
  #     "minor_dependent_max_age" => "17",
  #     "minor_dependent_max_type" => "Years",
  #     "overage_dependent_min_age" => "66",
  #     "overage_dependent_min_type" => "Years",
  #     "overage_dependent_max_age" => "100",
  #     "overage_dependent_max_type" => "Years",
  #     "adnb" => "0",
  #     "opmnnb" => "0",
  #     "opmnb" => "0",
  #     "adnnb" => "0",

  #     "funding_arrangement" => [
  #       %{
  #         coverage: "inpatient",
  #         type: "Full Risk"
  #       }
  #     ],

  #     "rnb" => [

  #       %{
  #         "coverage": "Inpatient",
  #         "room_and_board": "Nomenclature",
  #         "room_type": "Regular Room",
  #         "room_upgrade": "4",
  #         "room_upgrade_time": "Hours"
  #       }
  #     ],
  #     "risk_share" => [
  #       %{
  #         "coverage": "Inpatient",
  #         "af_type": "Coinsurance",
  #         "af_value": "99",
  #         "af_covered": "100",
  #         "naf_type": "Copayment",
  #         "naf_value": "3000",
  #         "naf_reimbursable": "No",
  #         "naf_covered": "100",

  #         "exempted_facilities": [
  #           %{
  #             "facility_code": "880000000006035",
  #             "covered": "33",
  #             "type": "CoInsurance",
  #             "value": "80",
  #             "exempted_procedures": [
  #               %{
  #                 "facility_cpt_code": "MMC-Dvaccine",
  #                 "covered": "100",
  #                 "type": "Copayment",
  #                 "value": "1200"
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     ]


  #   }

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end

  # test "post api/v1/products, post /products -- Add Exclusion: Positive Test (One Exclusion)", %{conn: conn, jwt: jwt} do
  #   params = initialize_bb_rp()

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end

  # test "post api/v1/products, post /products -- Add Exclusion: Positive Test (Multiple Exclusion)", %{conn: conn, jwt: jwt} do
  #   codes = %{
  #     code: [
  #       "Pre-existing-102"
  #     ]
  #   }

  #   params =
  #     initialize_bb_rp()
  #     |> Map.put("exclusion", codes)

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end

  # test "post api/v1/products, post /products -- Add Exclusion: No Exclusion/s (Empty list)", %{conn: conn, jwt: jwt} do
  #   params =
  #     initialize_bb_rp()
  #     |> Map.put("exclusion", %{code: []})

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end

  # test "post api/v1/products, post /products -- Add Exclusion: No Exclusion/s (No exclusion in params)", %{conn: conn, jwt: jwt} do
  #   params =
  #     initialize_bb_rp()
  #     |> Map.delete("exclusion")

  #   conn =
  #     conn
  #     |> put_req_header("authorization", "Bearer #{jwt}")
  #     |> post(api_product_path(conn, :create_product_api), params: params)
  #   assert json_response(conn, 200)
  # end


  # defp initialize_bb_rp() do
  #   # Benefit based -- Regular Product

  #   %{
  #     "code" => "PRD-103550",
  #     "name" => "Ultima Product",
  #     "product_base" => "Benefit-based",
  #     "description" => "Super Product for Elders",
  #     "limit_applicability" => "Individual",
  #     "type" => "Platinum",
  #     "limit_type" => "MBL",
  #     "limit_amount" => "200000.00",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "product_category" => "Regular product",
  #     "member_type" => ["Principal", "Dependent"],
  #     "exclusion" => %{
  #       code: ["Pre-existing-102"]
  #     },
  #     "benefit" => %{
  #       code: ["ACU101"]
  #     },
  #     "facility" => [
  #       %{
  #         "coverage": "acu",
  #         "type": "inclusion",
  #         "code": [
  #           "880000000006035"
  #         ]
  #       }
  #     ],
  #     "nem_principal" => "100",
  #     "nem_dependent" => "0",
  #     "principal_min_age" => "18",
  #     "principal_min_type" => "Years",
  #     "principal_max_age" => "65",
  #     "principal_max_type" => "Years",
  #     "adult_dependent_min_age" => "18",
  #     "adult_dependent_min_type" => "Years",
  #     "adult_dependent_max_age" => "65",
  #     "adult_dependent_max_type" => "Years",
  #     "minor_dependent_min_age" => "15",
  #     "minor_dependent_min_type" => "Days",
  #     "minor_dependent_max_age" => "17",
  #     "minor_dependent_max_type" => "Years",
  #     "overage_dependent_min_age" => "66",
  #     "overage_dependent_min_type" => "Years",
  #     "overage_dependent_max_age" => "100",
  #     "overage_dependent_max_type" => "Years",
  #     "adnb" => "0",
  #     "opmnnb" => "0",
  #     "opmnb" => "0",
  #     "adnnb" => "0",
  #     "funding_arrangement" => [
  #       %{
  #         coverage: "acu",
  #         type: "Full Risk"
  #       }
  #     ],
  #     "rnb" => [
  #       %{
  #         "coverage": "ACU",
  #         "room_and_board": "Nomenclature",
  #         "room_type": "Regular Room",
  #         "room_upgrade": "4",
  #         "room_upgrade_time": "Hours"
  #       }
  #     ],
  #     "risk_share": [
  #       %{
  #         "coverage": "ACU",
  #         "af_type": "Coinsurance",
  #         "af_value": "99",
  #         "af_covered": "100",
  #         "naf_type": "Copayment",
  #         "naf_value": "3000",
  #         "naf_reimbursable": "No",
  #         "naf_covered": "100",
  #         "exempted_facilities": [
  #           %{
  #             "facility_code": "880000000006035",
  #             "covered": "33",
  #             "type": "CoInsurance",
  #             "value": "80",
  #             "exempted_procedures": [
  #               %{
  #                 "facility_cpt_code": "MMC-Dvaccine",
  #                 "covered": "100",
  #                 "type": "Copayment",
  #                 "value": "1200"
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     ]
  #   }
  # end

  # defp initialize_bb_pp() do
  #   # Benefit based -- PEME Product

  #   %{
  #     "code" => "PRD-103550",
  #     "name" => "Ultima Product",
  #     "product_base" => "Benefit-based",
  #     "description" => "Super Product for Elders",
  #     "limit_applicability" => "Individual",
  #     "type" => "Platinum",
  #     "limit_type" => "MBL",
  #     "limit_amount" => "200000.00",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "product_category" => "PEME product",
  #     "member_type" => ["Principal", "Dependent"],
  #     "exclusion" => %{
  #       code: ["Pre-existing-102"]
  #     },
  #     "benefit" => %{
  #       code: ["ACU101"]
  #     },
  #     "facility" => [
  #       %{
  #         "coverage": "acu",
  #         "type": "inclusion",
  #         "code": [
  #           "880000000006035"
  #         ]
  #       }
  #     ],
  #     "nem_principal" => "100",
  #     "nem_dependent" => "0",
  #     "principal_min_age" => "18",
  #     "principal_min_type" => "Years",
  #     "principal_max_age" => "65",
  #     "principal_max_type" => "Years",
  #     "adult_dependent_min_age" => "18",
  #     "adult_dependent_min_type" => "Years",
  #     "adult_dependent_max_age" => "65",
  #     "adult_dependent_max_type" => "Years",
  #     "minor_dependent_min_age" => "15",
  #     "minor_dependent_min_type" => "Days",
  #     "minor_dependent_max_age" => "17",
  #     "minor_dependent_max_type" => "Years",
  #     "overage_dependent_min_age" => "66",
  #     "overage_dependent_min_type" => "Years",
  #     "overage_dependent_max_age" => "100",
  #     "overage_dependent_max_type" => "Years",
  #     "adnb" => "0",
  #     "opmnnb" => "0",
  #     "opmnb" => "0",
  #     "adnnb" => "0",
  #     "funding_arrangement" => [
  #       %{
  #         coverage: "acu",
  #         type: "Full Risk"
  #       }
  #     ],
  #     "rnb" => [
  #       %{
  #         "coverage": "ACU",
  #         "room_and_board": "Nomenclature",
  #         "room_type": "Regular Room",
  #         "room_upgrade": "4",
  #         "room_upgrade_time": "Hours"
  #       }
  #     ],
  #     "risk_share": [
  #       %{
  #         "coverage": "ACU",
  #         "af_type": "Coinsurance",
  #         "af_value": "99",
  #         "af_covered": "100",
  #         "naf_type": "Copayment",
  #         "naf_value": "3000",
  #         "naf_reimbursable": "No",
  #         "naf_covered": "100",
  #         "exempted_facilities": [
  #           %{
  #             "facility_code": "880000000006035",
  #             "covered": "33",
  #             "type": "CoInsurance",
  #             "value": "80",
  #             "exempted_procedures": [
  #               %{
  #                 "facility_cpt_code": "MMC-Dvaccine",
  #                 "covered": "100",
  #                 "type": "Copayment",
  #                 "value": "1200"
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     ]
  #   }
  # end

  # defp initialize_eb_rp() do
  #   # Exclusion based -- Regular Product

  #   %{
  #     "code" => "PRD-103550",
  #     "name" => "Ultima Product",
  #     "product_base" => "Exclusion-based",
  #     "description" => "Super Product for Elders",
  #     "limit_applicability" => "Individual",
  #     "type" => "Platinum",
  #     "limit_type" => "MBL",
  #     "limit_amount" => "200000.00",
  #     "phic_status" => "Required to File",
  #     "standard_product" => "No",
  #     "product_category" => "Regular product",
  #     "member_type" => ["Principal", "Dependent"],
  #     "exclusion" => %{
  #       code: []
  #     },
  #     "coverage" => ["Inpatient"],
  #     "facility" => [
  #       %{
  #         "coverage": "inpatient",
  #         "type": "inclusion",
  #         "code": [
  #           "880000000006035"
  #         ]
  #       }
  #     ],
  #     "nem_principal" => "100",
  #     "nem_dependent" => "0",
  #     "principal_min_age" => "18",
  #     "principal_min_type" => "Years",
  #     "principal_max_age" => "65",
  #     "principal_max_type" => "Years",
  #     "adult_dependent_min_age" => "18",
  #     "adult_dependent_min_type" => "Years",
  #     "adult_dependent_max_age" => "65",
  #     "adult_dependent_max_type" => "Years",
  #     "minor_dependent_min_age" => "15",
  #     "minor_dependent_min_type" => "Days",
  #     "minor_dependent_max_age" => "17",
  #     "minor_dependent_max_type" => "Years",
  #     "overage_dependent_min_age" => "66",
  #     "overage_dependent_min_type" => "Years",
  #     "overage_dependent_max_age" => "100",
  #     "overage_dependent_max_type" => "Years",
  #     "adnb" => "0",
  #     "opmnnb" => "0",
  #     "opmnb" => "0",
  #     "adnnb" => "0",
  #     "funding_arrangement" => [
  #       %{
  #         coverage: "inpatient",
  #         type: "Full Risk"
  #       }
  #     ],
  #     "rnb" => [

  #       %{
  #         "coverage": "Inpatient",
  #         "room_and_board": "Nomenclature",
  #         "room_type": "Regular Room",
  #         "room_upgrade": "4",
  #         "room_upgrade_time": "Hours"
  #       }
  #     ],
  #     "risk_share" => [
  #       %{
  #         "coverage": "Inpatient",
  #         "af_type": "Coinsurance",
  #         "af_value": "99",
  #         "af_covered": "100",
  #         "naf_type": "Copayment",
  #         "naf_value": "3000",
  #         "naf_reimbursable": "No",
  #         "naf_covered": "100",
  #         "exempted_facilities": [
  #           %{
  #             "facility_code": "880000000006035",
  #             "covered": "33",
  #             "type": "CoInsurance",
  #             "value": "80",
  #             "exempted_procedures": [
  #               %{
  #                 "facility_cpt_code": "MMC-Dvaccine",
  #                 "covered": "100",
  #                 "type": "Copayment",
  #                 "value": "1200"
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     ]
  #   }
  # end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.ProductView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

end

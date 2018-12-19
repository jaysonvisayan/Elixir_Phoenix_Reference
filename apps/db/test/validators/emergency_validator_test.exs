defmodule Innerpeace.Db.Validator.EmergencyValidatorTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.{
    # Schemas.Embedded.Emergency,
    # Validators.EmergencyValidator
  }

  # alias Innerpeace.Db.Base.{
  #   ProductContext
  # }

  setup do
    user = insert(:user)
    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    member = insert(:member, %{
      first_name: "Junnie",
      last_name: "Boy",
      card_no: "123456789012",
      account_group: account_group,
      effectivity_date: Ecto.Date.cast!("2011-11-10")
    })
    coverage = insert(:coverage,
                      name: "Emergency",
                      description: "Emergency",
                      code: "EMRGNCY",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis, code: "A00.0",
                        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication",
                        type: "Non-Dreaded")

    diagnosis_2 = insert(:diagnosis, code: "A18.4",
                        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication2",
                        type: "Non-Dreaded")

    diagnosis_3 = insert(:diagnosis, code: "A01.0",
                        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication3",
                        type: "Non-Dreaded")

    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Health")

    benefit_limit = insert(:benefit_limit, benefit: benefit,
                          limit_type: "Peso",
                          limit_amount: 10_000,
                          coverages: "Emergency")

    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)

    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)

    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis_2)

    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis_3)
    product = insert(:product,
                     limit_amount: 50_000,
                     name: "Maxicare Product 5",
                     standard_product: "Yes", step: "7"
                     )
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage)

    product_benefit = insert(:product_benefit,
                              product: product,
                              benefit: benefit)

    insert(:product_benefit_limit,
            product_benefit: product_benefit,
            benefit_limit: benefit_limit,
            limit_type: "Peso",
            limit_amount: 10_000)
    account = insert(:account,
                     account_group: account_group)

    account_product = insert(:account_product,
                             account: account,
                             product: product)

    insert(:member_product,
            member: member,
            account_product: account_product,
            tier: 1)
    facility = insert(:facility, name: "MAKATI MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")
    practitioner = insert(:practitioner,
                          first_name: "Junnie",
                          middle_name: "",
                          last_name: "Boy",
                          effectivity_from: "2017-11-13",
                          effectivity_to: "2019-11-13")

    practitioner_facility = insert(:practitioner_facility,
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
                          practitioner_id: practitioner.id)

    insert(:product_coverage_facility,
           product_coverage: product_coverage,
           facility: facility)

    payor_procedure = insert(:payor_procedure,
                             code: "95065",
                             description: "sample_procedure",
                             is_active: true,
                             deactivation_date: Ecto.Date.cast!("2050-12-12"),
                             exclusion_type: "No")

    payor_procedure_2 = insert(:payor_procedure,
                             code: "86580",
                             description: "sample_procedure2",
                             is_active: true,
                             deactivation_date: Ecto.Date.cast!("2050-12-12"),
                             exclusion_type: "No")

    payor_procedure_3 = insert(:payor_procedure,
                             code: "85027",
                             description: "sample_procedure3",
                             is_active: true,
                             deactivation_date: Ecto.Date.cast!("2050-12-12"),
                             exclusion_type: "No")

    insert(:benefit_procedure,
           benefit: benefit,
           procedure: payor_procedure)

    insert(:benefit_procedure,
           benefit: benefit,
           procedure: payor_procedure_2)

    insert(:benefit_procedure,
           benefit: benefit,
           procedure: payor_procedure_3)

    facility_payor_procedure = insert(:facility_payor_procedure,
                                      facility: facility,
                                      payor_procedure: payor_procedure)

    facility_payor_procedure_2 =
      insert(:facility_payor_procedure,
              facility: facility,
              payor_procedure: payor_procedure_2)

    facility_payor_procedure_3 =
      insert(:facility_payor_procedure,
              facility: facility,
              payor_procedure: payor_procedure_3)

    room =
      insert(:room,
              code: "16",
              type: "EMRGNCY",
              hierarchy: 1,
              ruv_rate: "15")

    facility_room_rate =
      insert(:facility_room_rate,
              room: room,
              facility_room_type: "test",
              facility_room_rate: "1000")

    insert(:facility_payor_procedure_room,
           facility_payor_procedure: facility_payor_procedure,
           facility_room_rate: facility_room_rate,
           amount: 1000.0,
           discount: 0,
           start_date: Ecto.Date.utc())

    insert(:facility_payor_procedure_room,
           facility_payor_procedure: facility_payor_procedure_2,
           facility_room_rate: facility_room_rate,
           amount: 1000.0,
           discount: 0,
           start_date: Ecto.Date.utc())

    insert(:facility_payor_procedure_room,
           facility_payor_procedure: facility_payor_procedure_3,
           facility_room_rate: facility_room_rate,
           amount: 1000.0,
           discount: 0,
           start_date: Ecto.Date.utc())

    insert(:case_rate,
           type: "ICD",
           description: "test case rate 1",
           hierarchy: 1,
           discount_percentage: 100,
           diagnosis: diagnosis)

    insert(:case_rate,
           type: "ICD",
           description: "test case rate 2",
           hierarchy: 2,
           discount_percentage: 50,
           diagnosis: diagnosis_3)

    authorization =
      insert(:authorization,
               coverage: coverage,
               member: member,
               facility: facility)

    product_coverage_risk_share =
      insert(:product_coverage_risk_share,
               product_coverage: product_coverage,
               af_type: "Copayment",
               af_covered_amount: 100,
               naf_reimbursable: "No",
               naf_type: "Copayment",
               naf_covered_amount: 100,
               af_value_amount: 100,
               naf_value_amount: 100)
    pcrsf =
      insert(:product_coverage_risk_share_facility,
              product_coverage_risk_share: product_coverage_risk_share ,
              facility: facility,
              type: "Copayment",
              value_amount: 150,
              covered: 100)
    
    insert(:product_coverage_risk_share_facility_procedure,
            product_coverage_risk_share_facility: pcrsf,
            facility_payor_procedure: facility_payor_procedure_2,
            type: "Copayment",
            value_amount: 50,
            covered: 100)

    {:ok, %{user: user,
            coverage: coverage,
            member: member,
            facility: facility,
            authorization: authorization,
            product: product,
            diagnosis1: diagnosis,
            diagnosis2: diagnosis_2,
            diagnosis3: diagnosis_3,
            practitioner: practitioner,
            practitioner_facility: practitioner_facility,
            payor_procedure: payor_procedure,
            payor_procedure2: payor_procedure_2,
            payor_procedure3: payor_procedure_3,
            # product: product,
            product_coverage: product_coverage
            }}
  end

  # test "request emergency with invalid params" do
  #   p = insert(:practitioner)
  #   d = insert(:diagnosis)
  #   m = insert(:member)
  #   f = insert(:facility)

  #   params = %{
  #     chief_complaint: "headache",
  #     practitioner_id: p.id,
  #     diagnosis_id: d.id,
  #     member_id: m.id,
  #     facility_id: f.id
  #   }

  #   changeset = Emergency.changeset(%Emergency{}, params)
  #   refute changeset.valid? == true
  # end

  # test "request emergency with positive result", %{
  #   practitioner: practitioner,
  #   diagnosis1: diagnosis1,
  #   diagnosis2: diagnosis2,
  #   diagnosis3: diagnosis3,
  #   member: member,
  #   facility: facility,
  #   user: user,
  #   payor_procedure: payor_procedure,
  #   payor_procedure2: payor_procedure_2,
  #   payor_procedure3: payor_procedure_3,
  #   product: product,
  #   product_coverage: product_coverage,
  #   authorization: authorization
  # } do

  #   insert(:product_coverage_risk_share,
  #          product_coverage: product_coverage,
  #          af_type: "Copayment",
  #          af_covered_amount: 100,
  #          naf_reimbursable: "No",
  #          naf_type: "Copayment",
  #          naf_covered_amount: 80,
  #          af_value_amount: 100,
  #          naf_value_amount: 100)
  #   exclusion = insert(:exclusion, coverage: "Pre-existing Condition", code: "test", name: "test")
  #   insert(:exclusion_duration, exclusion: exclusion, disease_type: "Non-Dreaded",
  #          duration: 6, percentage: 50)
  #   insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis1)
  #   insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis2)
  #   pe = insert(:product_exclusion, product: product, exclusion: exclusion)
  #   params = %{
  #     user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     practitioner_id: practitioner.id,
  #     diagnosis_id: [diagnosis1.id, diagnosis2.id, diagnosis3.id],
  #     member_id: member.id,
  #     diagnosis_procedure: [
  #       %{
  #         diagnosis_id: diagnosis1.id,
  #         procedure_id: payor_procedure.id
  #       },
  #       %{
  #         diagnosis_id: diagnosis2.id,
  #         procedure_id: payor_procedure_2.id
  #       },
  #       %{
  #         diagnosis_id: diagnosis3.id,
  #         procedure_id: payor_procedure_3.id
  #       }
  #     ],
  #     facility_id: facility.id,
  #     procedure_id: [
  #       payor_procedure.id,
  #       payor_procedure_2.id,
  #       payor_procedure_3.id
  #     ],
  #     admission_datetime: "2011-12-12"
  #   }

  #   {:ok, changeset} = EmergencyValidator.request(params)

  #   assert changeset.valid? == true
  # end
end

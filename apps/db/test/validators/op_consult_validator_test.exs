defmodule Innerpeace.Db.Validator.OPConsultValidatorTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.{
    Schemas.Embedded.OPConsult
  }

  setup do
    user = insert(:user)
    role = insert(:role)

    _user_role = insert(:user_role, user: user, role: role)

    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    member = insert(:member, %{
      first_name: "Daniel Eduard",
      last_name: "Andal",
      card_no: "123456789012",
      account_group: account_group
    })
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    diagnosis = insert(:diagnosis, code: "A05.0",
                        description: "OTHER BACTERIAL FOODBORNE INTOXICATIONS: Foodborne staphylococcal intoxication",
                        type: "Dreaded")
    benefit = insert(:benefit, code: "B102", name: "Medilink Benefit", category: "Health")

    benefit_limit = insert(:benefit_limit, benefit: benefit,
                          limit_type: "Peso",
                          limit_amount: 1000,
                          coverages: "OPC",
                          limit_classification: "Per Coverage Period")

    insert(:benefit_coverage,
           benefit: benefit,
           coverage: coverage)
    insert(:benefit_diagnosis,
           benefit: benefit,
           diagnosis: diagnosis)
    product = insert(:product,
                     limit_amount: 10_000,
                     name: "Maxicare Product 5",
                     standard_product: "Yes",
                     step: "7",
                     product_base: "Benefit-based",
                     limit_type: "ABL"
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
            limit_amount: 1000)

    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("1990-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                      status: "Active")

    account_product = insert(:account_product,
                             account: account,
                             product: product)

    insert(:member_product,
            member: member,
            account_product: account_product, tier: 1)

    dropdown = insert(:dropdown, type: "VAT Status", text: "Vatable", value: "Vatable")
    facility = insert(:facility, name: "CALAMBA MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23")

    practitioner = insert(:practitioner,
                          first_name: "Daniel",
                          middle_name: "Murao",
                          last_name: "Andal",
                          effectivity_from: "2017-11-13",
                          effectivity_to: "2019-11-13",
                          vat_status_id: dropdown.id)

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

    specialization = insert(:specialization, name: "Radiology")

    practitioner_specialization = insert(:practitioner_specialization,
                                          practitioner: practitioner,
                                          specialization: specialization)

    _practitioner_facility_consultation_fee = insert(:practitioner_facility_consultation_fee,
                                              practitioner_facility: practitioner_facility,
                                              practitioner_specialization: practitioner_specialization,
                                              fee: 1000)

    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)


    {:ok, %{user: user,
      coverage: coverage,
      member: member,
      facility: facility,
      authorization: authorization,
      product: product,
      diagnosis: diagnosis,
      practitioner: practitioner,
      practitioner_facility: practitioner_facility,
      product_coverage: product_coverage,
      practitioner_specialization: practitioner_specialization
    }}
  end

  test "request opconsult with valid params" do
    p = insert(:practitioner_specialization)
    d = insert(:diagnosis)
    m = insert(:member)
    f = insert(:facility)

    params = %{
      consultation_type: "initial",
      chief_complaint: "headache",
      practitioner_specialization_id: p.id,
      diagnosis_id: d.id,
      member_id: m.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.valid? == true
  end

  test "request opconsult with missing consultation_type" do
    p = insert(:practitioner_specialization)
    d = insert(:diagnosis)
    m = insert(:member)
    f = insert(:facility)

    params = %{
      chief_complaint: "headache",
      practitioner_specialization_id: p.id,
      diagnosis_id: d.id,
      member_id: m.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    ce = changeset.errors
    assert ce == [consultation_type: {"can't be blank", [validation: :required]}]
  end

  test "request opconsult with missing chief_complaint" do
    p = insert(:practitioner_specialization)
    d = insert(:diagnosis)
    m = insert(:member)
    f = insert(:facility)

    params = %{
      consultation_type: "initial",
      practitioner_specialization_id: p.id,
      diagnosis_id: d.id,
      member_id: m.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.errors == [chief_complaint: {"can't be blank", [validation: :required]}]
  end

  test "request opconsult with missing practitioner_specialization_id" do
    d = insert(:diagnosis)
    m = insert(:member)
    f = insert(:facility)

    params = %{
      consultation_type: "initial",
      chief_complaint: "headache",
      diagnosis_id: d.id,
      member_id: m.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.errors == [practitioner_specialization_id: {"can't be blank", [validation: :required]}]
  end

  test "request opconsult with missing diagnosis_id" do
    p = insert(:practitioner_specialization)
    m = insert(:member)
    f = insert(:facility)

    params = %{
      consultation_type: "initial",
      chief_complaint: "headache",
      practitioner_specialization_id: p.id,
      member_id: m.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.errors == [diagnosis_id: {"can't be blank", [validation: :required]}]
  end

  test "request opconsult with missing member_id" do
    p = insert(:practitioner_specialization)
    d = insert(:diagnosis)
    f = insert(:facility)

    params = %{
      consultation_type: "initial",
      chief_complaint: "headache",
      practitioner_specialization_id: p.id,
      diagnosis_id: d.id,
      facility_id: f.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.errors == [member_id: {"can't be blank", [validation: :required]}]
  end

  test "request opconsult with missing facility_id" do
    p = insert(:practitioner_specialization)
    d = insert(:diagnosis)
    m = insert(:member)

    params = %{
      consultation_type: "initial",
      chief_complaint: "headache",
      practitioner_specialization_id: p.id,
      diagnosis_id: d.id,
      member_id: m.id
    }

    changeset = OPConsult.changeset(%OPConsult{}, params)
    assert changeset.errors == [facility_id: {"can't be blank", [validation: :required]}]
  end

  # test "request opconsult with positive result copayment",
  # %{diagnosis: diagnosis, member: member,
  #  facility: facility, user: user, product_coverage: product_coverage,
  #  authorization: authorization, practitioner_specialization: practitioner_specialization} do

  #   insert(:product_coverage_risk_share,
  #          product_coverage: product_coverage,
  #          af_type: "Copayment",
  #          af_covered_amount: 80,
  #          naf_reimbursable: "No",
  #          naf_type: "Copayment",
  #          naf_covered_amount: 80,
  #          af_value_amount: 100,
  #          naf_value_amount: 100)

  #   params = %{user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     diagnosis_id: diagnosis.id,
  #     member_id: member.id,
  #     facility_id: facility.id,
  #     authorization_id: authorization.id,
  #     origin: "payorlink",
  #     practitioner_specialization_id: practitioner_specialization.id
  #   }

  #   {:ok, changeset} = OPConsultValidator.request_consult_web(params)

  #   cap = changeset.changes.selected_product.covered_after_percentage
  #   assert changeset.changes.risk_share_type == "Copayment"
  #   assert changeset.changes.copayment == Decimal.new(100)
  #   assert cap == Decimal.new(0)
  #   assert changeset.valid? == true
  # end

  # test "request opconsult without product risk share",
  # %{diagnosis: diagnosis, member: member,
  # facility: facility, user: user, product_coverage: product_coverage,
  # authorization: authorization, practitioner_specialization: practitioner_specialization} do
  # insert(:product_coverage_risk_share,
  #         product_coverage: product_coverage)

  #   params = %{user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     practitioner_specialization_id: practitioner_specialization.id,
  #     diagnosis_id: diagnosis.id,
  #     member_id: member.id,
  #     facility_id: facility.id,
  #     authorization_id: authorization.id,
  #     origin: "payorlink"
  #   }

  #   {:ok, changeset} = OPConsultValidator.request_consult_web(params)

  #   assert changeset.valid? == true
  # end

  #TODO

  # test "request opconsult with positive result with pre-existing condition percentage",
  # %{diagnosis: diagnosis, member: member,
  #   facility: facility, user: user, diagnosis: diagnosis, product: product,
  #   product_coverage: product_coverage, authorization: authorization, practitioner_specialization: practitioner_specialization} do

  #   exclusion = insert(:exclusion, coverage: "Pre-existing Condition", code: "test", name: "test")
  #     insert(:exclusion_duration, exclusion: exclusion, disease_type: "Dreaded",
  #            duration: 12, percentage: 50, cad_percentage: 60)
  #   insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis)
  #   insert(:product_exclusion, product: product, exclusion: exclusion)

  #   insert(:product_coverage_risk_share,
  #          product_coverage: product_coverage,
  #          af_type: nil,
  #          af_covered_percentage: nil,
  #          af_value_percentage: nil)

  #   params = %{user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     diagnosis_id: diagnosis.id,
  #     member_id: member.id,
  #     facility_id: facility.id,
  #     authorization_id: authorization.id,
  #     origin: "payorlink",
  #     practitioner_specialization_id: practitioner_specialization.id
  #   }

  #   {:ok, changeset} = OPConsultValidator.request_consult_web(params)
  #   _cap = changeset.changes.selected_product.covered_after_percentage
  #   assert changeset.valid? == true
  # end

  # test "request opconsult with positive result coinsurance",
  # %{diagnosis: diagnosis, member: member,
  #   facility: facility, user: user, diagnosis: diagnosis,
  #   product_coverage: product_coverage, authorization: authorization,
  #   practitioner_specialization: practitioner_specialization} do
  #   insert(:product_coverage_risk_share,
  #          product_coverage: product_coverage,
  #          af_type: "CoInsurance",
  #          af_covered_percentage: 50,
  #          af_value_percentage: 50)

  #   params = %{user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     practitioner_specialization_id: practitioner_specialization.id,
  #     diagnosis_id: diagnosis.id,
  #     member_id: member.id,
  #     facility_id: facility.id,
  #     authorization_id: authorization.id,
  #     origin: "payorlink"
  #   }

  #   {:ok, changeset} = OPConsultValidator.request_consult_web(params)

  #   assert changeset.changes.risk_share_type == "CoInsurance"
  #   assert changeset.changes.coinsurance == 50
  #   assert changeset.changes.coinsurance_percentage == 50
  #   assert changeset.valid? == true
  # end

  # test "request opconsult with positive result with pre-existing condition coinsurance",
  # %{diagnosis: diagnosis, member: member,
  #   facility: facility, user: user, diagnosis: diagnosis,
  #   product: product, product_coverage: product_coverage,
  #   authorization: authorization,
  #   practitioner_specialization: practitioner_specialization} do
  #   insert(:product_coverage_risk_share,
  #          product_coverage: product_coverage,
  #          af_type: "CoInsurance",
  #          af_covered_percentage: 50,
  #          af_value_percentage: 50)
  #   exclusion = insert(:exclusion, coverage: "Pre-existing Condition", code: "test", name: "test")
  #   insert(:exclusion_duration, exclusion: exclusion,
  #          disease_type: "Dreaded", duration: 12, cad_percentage: 50)
  #   insert(:exclusion_disease, exclusion: exclusion, disease: diagnosis)
  #   insert(:product_exclusion, product: product, exclusion: exclusion)

  #   params = %{user_id: user.id,
  #     consultation_type: "initial",
  #     chief_complaint: "headache",
  #     practitioner_specialization_id: practitioner_specialization.id,
  #     diagnosis_id: diagnosis.id,
  #     member_id: member.id,
  #     facility_id: facility.id,
  #     origin: "payorlink",
  #     authorization_id: authorization.id
  #   }

  #   {:ok, changeset} = OPConsultValidator.request_consult_web(params)
  #   assert changeset.changes.risk_share_type == "CoInsurance"
  #   assert changeset.changes.coinsurance == 50
  #   assert changeset.changes.coinsurance_percentage == 50
  #   assert changeset.valid? == true
  # end
end

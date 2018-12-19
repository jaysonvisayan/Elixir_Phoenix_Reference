defmodule Innerpeace.Db.Validators.EmergencyValidator do

  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Decimal

  alias Innerpeace.Db.{
    Repo,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.Facility,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityPayorProcedureRoom,
    Schemas.Benefit,
    Schemas.BenefitProcedure,
    Schemas.PayorProcedure,
    Schemas.CaseRate,
    Schemas.Diagnosis,
    Schemas.Embedded.Emergency,
    Schemas.Procedure,
    Schemas.MemberProduct,
    Schemas.Member,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageRiskShare,
    Schemas.ProductCoverageRiskShareFacility,
    Schemas.ProductCoverageRiskShareFacilityPayorProcedure,
    Schemas.Coverage,
    Schemas.FacilityRoomRate,
    Schemas.Room,
    Schemas.FacilityRUV,
    Schemas.ProductExclusion,
    Schemas.ExclusionProcedure,
    Schemas.ExclusionDisease,
    Schemas.ExclusionDuration,
    Schemas.Exclusion,
    Schemas.BenefitRUV,
    Schemas.AuthorizationProcedureDiagnosis,
    Schemas.Authorization
  }

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    PractitionerContext,
    MemberContext,
    ProductContext,
    BenefitContext,
    CoverageContext,
    FacilityContext,
    DiagnosisContext
  }

  def validate_authorization(authorization) do
    coverage = CoverageContext.get_coverage_by_code("EMRGNCY")
    member = MemberContext.get_a_member!(authorization.member_id)
    {products_of_member, apds} = setup_products_of_member(member, coverage, authorization)
    if Enum.empty?(products_of_member) do
      update_amounts_without_product(authorization)
    else

      if Enum.empty?(apds) do
          update_amounts(authorization)
      else
        products_of_member
        |> check_icd()
        |> check_benefit_covered_icd()
        |> check_cpt_exclusion()
        |> check_exclusion_covered_icd()
        |> check_outer_limit(member.id, authorization.id)
        |> check_inner_limit(member)
        |> get_highest_product()
        |> update_amounts(authorization)
      end
    end
  end

  defp update_amounts_without_product(authorization) do
    zero = Decimal.new(0)
    AuthorizationProcedureDiagnosis
    |> where([apd], apd.authorization_id == ^authorization.id)
    |> update([apd], set: [member_pay: fragment("? * ?", apd.unit, apd.amount), payor_pay: ^zero])
    |> Repo.update_all([])
    apds = authorization.authorization_procedure_diagnoses
    total_member_pays = Enum.map(apds, &(Decimal.mult(&1.unit, &1.amount)))
    total_member_pays = total_member_pays |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    params = %{
      "payor_covered" => Decimal.new(0),
      "member_covered" => total_member_pays,
      "total_amount" => total_member_pays,
      "authorization_id" => authorization.id
    }
    AuthorizationContext.create_authorization_amount(params, authorization.created_by_id)
  end

  #Jayson Setup Product Of Member
  def setup_products_of_member(member, coverage, authorization) do
    member_products =
      AuthorizationContext.get_member_product_with_coverage(member.products, coverage.id)
    apds = Enum.group_by(authorization.authorization_procedure_diagnoses, & (&1.diagnosis.id))
    apds = Enum.map(apds, fn({diagnosis_id, procedures}) ->
      %{
        icd: diagnosis_id,
        excluded: nil,
        pec: nil,
        covered: nil,
        procedures:
        Enum.map(procedures, fn(procedure) ->
          %{
            cpt: procedure,
            covered: nil,
            excluded: nil,
            amount: procedure.amount,
            unit: procedure.unit,
            payor_pays: Decimal.new(0),
            member_pays: Decimal.new(0),
            philhealth_pays: Decimal.new(0),
            member_product: nil,
            product_benefit: nil
          }
        end)
      }
    end)
    apds = Enum.filter(apds, fn(apd) ->
      checker = Enum.filter(apd.procedures, &(is_nil(&1.cpt.payor_procedure_id)))
      Enum.empty?(checker)
    end)
    product_apds =
      Enum.map(member_products, fn(member_product) ->
        %{
          member_product: member_product,
          member: member,
          coverage: coverage,
          product: member_product.account_product.product,
          diagnosis_procedures: apds
        }
      end)
    {product_apds, apds}
  end

  #Jayson End

  defp get_highest_product(params) do
    Enum.max_by(params, fn(product_procedure) ->
      payor_pays = Enum.map(product_procedure.computed_procedures, &(&1.payor_pays))
      payor_pays = Enum.reduce(payor_pays, Decimal.new(0), &Decimal.add/2)
      Decimal.to_float(payor_pays)
    end)
  end

  defp update_amounts(product_procedures, authorization) do
    apds =
      Enum.map(product_procedures.computed_procedures, fn(diagnosis_procedure) ->
        {member_product_id, product_benefit_id} = check_product_benefit(diagnosis_procedure, product_procedures)
        params = %{
          payor_pay: diagnosis_procedure.payor_pays,
          member_pay: diagnosis_procedure.member_pays,
          member_product_id: member_product_id,
          product_benefit_id: product_benefit_id
        }
        apd = AuthorizationContext.get_authorization_procedure_diagnosis(diagnosis_procedure.cpt.id)
        apd
        |> AuthorizationProcedureDiagnosis.update_changeset(params)
        |> Repo.update!()
      end)
    total_member_pays = Enum.map(apds, &(&1.member_pay))
    total_member_pays = total_member_pays |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    total_payor_pays = Enum.map(apds, &(&1.payor_pay))
    total_payor_pays = total_payor_pays |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    params = %{
      "payor_covered" => total_payor_pays,
      "member_covered" => total_member_pays,
      "total_amount" => total_payor_pays |> Decimal.add(total_member_pays),
      "authorization_id" => authorization.id
    }
    AuthorizationContext.create_authorization_amount(params, authorization.created_by_id)
  end

  defp update_amounts(authorization) do
    params = %{
      "payor_covered" => Decimal.new(0),
      "member_covered" => Decimal.new(0),
      "total_amount" => Decimal.new(0),
      "authorization_id" => authorization.id
    }
    AuthorizationContext.create_authorization_amount(params, authorization.created_by_id)
  end

  defp check_product_benefit(diagnosis_procedure, product_procedures) do
    if product_procedures.product.product_base == "Exclusion-based" do
      {product_procedures.member_product.id, nil}
    else
      if is_nil(diagnosis_procedure.product_benefit) do
        {nil, nil}
      else
        {product_procedures.member_product.id, diagnosis_procedure.product_benefit.id}
      end
    end
  end

  # Raymond and Shane

  def check_icd(product_setup) do
    Enum.map(product_setup, fn(ps) ->
      dp = Enum.map(ps.diagnosis_procedures, fn(dp) ->
        coverage_id = ps.coverage.id
        check_product_benefit_procedure(ps.product, dp, coverage_id, ps.member)
      end)
      Map.put(ps, :diagnosis_procedures, dp)
    end)
  end

  def check_product_benefit_procedure(product, diagnosis_procedure, coverage_id, member) do
    if product.product_base == "Benefit-based" do
      check_benefit_based(product, diagnosis_procedure, coverage_id, member)
    else
      check_exclusion_based(product, diagnosis_procedure, member)
    end
  end

  def check_benefit_based(product, diagnosis_procedure, coverage_id, member) do
    pbs =
      product.product_benefits
      |> Enum.filter(fn(product_benefit) ->
        product_benefit.benefit.benefit_coverages
        |> Enum.map(&(&1.coverage.id))
        |> Enum.member?(coverage_id)
      end)
    product_benefits = for product_benefit <- pbs do
      with {:ok} <- check_product_exclusions(product, diagnosis_procedure),
           {:ok} <- check_product_pec(product, diagnosis_procedure, member)
      do
        product_benefit
      else
        _ ->
          nil
      end
    end
    product_benefit =
      product_benefits
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
    icd_exclusion = get_icd_exclusion(diagnosis_procedure.icd, product.id, "Pre-existing Condition")
    if is_nil(product_benefit) do
      if Enum.empty?(icd_exclusion) do
        diagnosis_procedure
        |> Map.put(:excluded, false)
        |> Map.put(:pec, false)
      else
        diagnosis_procedure
        |> Map.put(:excluded, false)
        |> Map.put(:pec, true)
      end
    else
      if Enum.empty?(icd_exclusion) do
        diagnosis_procedure
        |> Map.put(:excluded, false)
        |> Map.put(:pec, false)
      else
        diagnosis_procedure
        |> Map.put(:excluded, true)
      end
    end
  end

  def procedure_ids(procedures) do
    Enum.into(procedures, [], &(&1.cpt.payor_procedure_id))
  end

  def check_product_exclusions(product, diagnosis_procedure) do
    exclusion_diseases =
      for product_exclusion <- Enum.filter(product.product_exclusions, &(&1.exclusion.coverage == "General Exclusion")) do
        Enum.map(product_exclusion.exclusion.exclusion_diseases, &(&1.disease.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    exclusion_procedures =
      for product_exclusion <- Enum.filter(product.product_exclusions, &(&1.exclusion.coverage == "General Exclusion")) do
        Enum.map(product_exclusion.exclusion.exclusion_procedures, &(&1.procedure.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    if Enum.member?(exclusion_diseases, diagnosis_procedure.icd) or not is_nil(find_procedures(exclusion_procedures, diagnosis_procedure.procedures)) do
      {:excluded}
    else
      {:ok}
    end
  end

  defp find_procedures(exclusion_procedures, procedures) do
    Enum.find(exclusion_procedures, fn(ep) ->
      Enum.member?(procedure_ids(procedures), ep)
    end)
  end

  def check_product_pec(product, diagnosis_procedure, member) do
    enrollment_date = member.enrollment_date
    exclusion_diseases =
      for product_exclusion <- Enum.filter(product.product_exclusions, &(&1.exclusion.coverage == "Pre-existing Condition")) do
        Enum.map(product_exclusion.exclusion.exclusion_diseases, &(&1.disease.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    pec = ProductContext.get_pec_op_lab(product.id, diagnosis_procedure.icd, member.id)
    if Enum.member?(exclusion_diseases, diagnosis_procedure.icd) and not is_nil(pec) do
      {:excluded}
    else
      {:ok}
    end
  end

  def check_exclusion_based(product, diagnosis_procedure, member) do
    pec = ProductContext.get_pec_op_lab(product.id, diagnosis_procedure.icd, member.id)
    pec_diseases =
      product.product_exclusions
      |> Enum.filter(&(&1.exclusion.coverage == "Pre-existing Condition"))
      |> Enum.map(&(&1.exclusion.exclusion_diseases))
      |> List.flatten()
      |> Enum.map(&(&1.disease_id))
    procedure_ids = procedure_ids(diagnosis_procedure.procedures)
    product_exclusions =
      Enum.into(product.product_exclusions, [], fn(product_exclusion) ->
        with %ExclusionProcedure{} <- Enum.find(product_exclusion.exclusion.exclusion_procedures, &(Enum.member?(procedure_ids, &1.procedure_id))) do
          true
        else
          _ ->
            false
        end
      end)

    icd_exclusion = get_icd_exclusion(diagnosis_procedure.icd, product.id, "General Exclusion")
    cond do
      Enum.member?(product_exclusions, true) ->
        diagnosis_procedure
        |> Map.put(:pec, true)
        |> Map.put(:excluded, false)

      not Enum.empty?(icd_exclusion) and is_nil(pec) ->
        diagnosis_procedure
        |> Map.put(:pec, false)
        |> Map.put(:excluded, true)

      is_nil(pec) and Enum.member?(pec_diseases, diagnosis_procedure.icd) ->
        diagnosis_procedure
        |> Map.put(:pec, false)
        |> Map.put(:excluded, true)

      is_nil(pec) and not Enum.member?(pec_diseases, diagnosis_procedure.icd) ->
        diagnosis_procedure
        |> Map.put(:pec, false)
        |> Map.put(:excluded, false)

      true ->
        diagnosis_procedure
        |> Map.put(:pec, true)
        |> Map.put(:excluded, false)
    end
  end

  def get_icd_exclusion(diagnosis_id, product_id, type) do
    ProductExclusion
    |> join(:inner, [pe], e in Exclusion, pe.exclusion_id == e.id)
    |> join(:inner, [pe, e], ed in ExclusionDisease, e.id == ed.exclusion_id)
    |> join(:inner, [pe, e, ed], d in Diagnosis, ed.disease_id == d.id)
    |> where([pe, e, ed, d], ed.disease_id == ^diagnosis_id and pe.product_id == ^product_id)
    |> where([pe, e, ed, d], e.coverage == ^type)
    |> Repo.all()
  end

  # RS end

  #Brian Check Benefit Covered ICD

  def check_benefit_covered_icd(result) do
    cbci_check_records(result, [])
  end

  defp cbci_check_records([head | tails], data) do
    product =
      head.product
      |> Repo.preload([
        [
          product_benefits:
          [
            benefit: [
              [
                :benefit_limits,
                benefit_diagnoses: :diagnosis,
                benefit_coverages: :coverage,
                benefit_procedures: [
                  procedure: [
                    procedure: :procedure_category
                  ]
                ],
                benefit_packages: [
                  package: [
                    package_payor_procedure: [
                      payor_procedure: :procedure]
                  ]
                ]
              ]
            ]
          ]
        ]
      ])

    benefits =
      product.product_benefits
      |> Enum.map(&(check_if_op_lab(&1.benefit, head.coverage)))
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    diagnosis_ids =
      benefits
      |> load_benefit_diagnosis([])
      |> List.flatten
      |> Enum.uniq

    procedure_ids =
      benefits
      |> load_benefit_procedures([])
      |> List.flatten
      |> Enum.uniq

    diagnosis_procedures =
      head.diagnosis_procedures
      |> Enum.map(&(cbci_check_icd(&1, diagnosis_ids, procedure_ids, product)))

    data =
      data ++ [%{
        member_product: head.member_product,
        member: head.member,
        coverage: head.coverage,
        product: head.product,
        diagnosis_procedures: diagnosis_procedures
      }]

    cbci_check_records(tails, data)
  end

  defp cbci_check_records([], data), do: data

  defp check_if_op_lab(benefit, coverage) do
    coverages =
      benefit.benefit_coverages
      |> Enum.map(&(&1.coverage.id))

    if Enum.member?(coverages, coverage.id) do
      benefit
    else
      nil
    end
  end

  defp cbci_check_icd(icd, diagnosis_ids, procedure_ids, product) do
    result = if icd.excluded do
      false
    else
      Enum.member?(diagnosis_ids, icd.icd)
    end
    icd
    |> Map.put(:covered, result)
    |> check_benefit_covered_cpt(procedure_ids, product, result)
  end

  defp load_benefit_diagnosis([head | tails], result) do
    diagnoses =
      head.benefit_diagnoses
      |> Enum.map(&(&1.diagnosis.id))

    result = result ++ diagnoses
    load_benefit_diagnosis(tails, result)
  end

  defp load_benefit_diagnosis([], result), do: result

  #Brian End

  #Gilbert Check Cpt Exclusion

  def check_cpt_exclusion(result) do
  check_cpt_records(result, [])
  end

  defp check_cpt_records([head | tails], data) do
    product =
      head.product
      |> Repo.preload([
        [
          product_exclusions:
          [
            exclusion: [
              [
                exclusion_procedures:
                  [procedure: :procedure]
              ]
            ]
          ]
        ]
      ])

    exclusions =
      product.product_exclusions
      |> Enum.map(&(&1.exclusion))

    procedure_ids =
      exclusions
      |> load_exclusion_procedures([])
      |> List.flatten
      |> Enum.uniq

    exclusion_procedures =
      head.diagnosis_procedures
      |> Enum.map(&(check_product_exclusion_cpt(&1, procedure_ids)))

    data =
      data ++ [%{
        member_product: head.member_product,
        member: head.member,
        coverage: head.coverage,
        product: head.product,
        diagnosis_procedures: exclusion_procedures
      }]

    check_cpt_records(tails, data)
  end

  defp check_cpt_records([], data), do: data

  defp check_product_exclusion_cpt(apd, procedure_ids) do
    procedures =
      apd.procedures
      |> Enum.map(fn(procedure) ->
        procedure
        |> Map.put(:excluded, Enum.member?(procedure_ids, procedure.cpt.payor_procedure.procedure.id))
      end)
    apd
    |> Map.put(:procedures, procedures)
  end

  defp load_exclusion_procedures([head | tails], result) do
    exclusion =
      head.exclusion_procedures
      |> Enum.map(&(&1.procedure.procedure.id))

    result = result ++ exclusion
    load_exclusion_procedures(tails, result)
  end

  defp load_exclusion_procedures([], result), do: result

  #Gilbert End

  #Glen Check Benefit Covered CPT

  defp load_benefit_procedures([head | tails], result) do
    benefit_procedures =
      head.benefit_procedures
      |> Enum.map(&(&1.procedure.procedure.id))

    # benefit_packages =
    #   head.benefit_packages
    #   |> load_benefit_packages([])
    #   |> List.flatten

    procedures =
      benefit_procedures #++ benefit_packages
      |> Enum.uniq()

    result = result ++ procedures
    load_benefit_procedures(tails, result)
  end

  defp load_benefit_procedures([], result), do: result

  # defp load_benefit_packages([head | tails], result) do
  #   head.package.package_payor_procedure
  #   |> Enum.map(&(&1.payor_procedure.procedure.id))
  # end

  # defp load_benefit_packages([head | tails], result), do: result

  def check_benefit_covered_cpt(icd, cpt_ids, product, icd_covered) do
    procedures =
      icd.procedures
      |> check_bc_cpt([], cpt_ids, product, icd_covered)

    icd
    |> Map.put(:procedures, procedures)
  end

  defp check_bc_cpt([head | tails], result, cpt_ids, product, icd_covered) do
    procedure_id = head.cpt.payor_procedure.procedure.id
    procedure_amount = head.amount
    procedure_unit = head.unit

    covered =
      with true <- Enum.member?(cpt_ids, procedure_id)
      do
        true
      else
        _ ->
          false
      end

    payor_pays =
      if covered and icd_covered do
        Decimal.mult(procedure_amount, procedure_unit)
      else
        Decimal.new(0)
      end

    member_pays =
      if covered and icd_covered do
        Decimal.new(0)
      else
        Decimal.mult(procedure_amount, procedure_unit)
      end

    pb =
      if covered and icd_covered do
        find_pb(product.product_benefits, result, procedure_id)
      else
        nil
      end

    cpt_covered =
      head
      |> Map.put(:covered, covered)
      |> Map.put(:product_benefit, pb)
      |> Map.put(:payor_pays, payor_pays)
      |> Map.put(:member_pays, member_pays)

    result = result ++ [cpt_covered]
    check_bc_cpt(tails, result, cpt_ids, product, icd_covered)
  end

  defp check_bc_cpt([], result, cpt_ids, product, icd_covered), do: result

  defp find_pb([head | tails], result, procedure_id) do
    coverage = CoverageContext.get_coverage_by_name("OP Laboratory")
    benefits =
      [head]
      |> Enum.map(&(check_if_op_lab(&1.benefit, coverage)))
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

    procedure_ids =
      benefits
      |> load_benefit_procedures([])
      |> List.flatten
      |> Enum.uniq

    if Enum.member?(procedure_ids, procedure_id) do
      find_pb([], head, procedure_id)
    else
      find_pb(tails, nil, procedure_id)
    end
  end

  defp find_pb([], result, procedure_id), do: result

  #Glen End

  # Daniel Compute Outer Limit

  def check_outer_limit(product_setup, member_id, authorization_id) do
    Enum.map(product_setup, fn(ps) ->
      dp = Enum.map(ps.diagnosis_procedures, fn(dp) ->
        dp
      end)
      dp  =
        dp
        |> List.first()

      ## PRODUCT LIMIT
      remaining_limit_amount = get_total_remaining_product_limit(ps, dp.icd, member_id, authorization_id)
      ps =
        ps
        |> Map.put(:remaining_product_limit, remaining_limit_amount)
      compute_outer_limit(ps)
    end)
  end

  ## GET TOTAL REMAINING PRODUCT LIMIT
  defp get_total_remaining_product_limit(product_setup, diagnosis_id, member_id, authorization_id) do
    member = MemberContext.get_member(member_id)
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)
    active_account = List.first(member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    product = ProductContext.get_product!(product_setup.member_product.account_product.product.id)

    case product.limit_type do
      "ABL" ->
        used_limit = remaining_limit_abl(product_setup.member_product.id, start_date, end_date, authorization, diagnosis_id)
        Decimal.sub(product.limit_amount, used_limit)
      "MBL" ->
        used_limit = remaining_limit_mbl(product_setup.member_product.id, start_date, end_date, authorization, diagnosis_id)
        Decimal.sub(product.limit_amount, used_limit)
      _ ->
        Decimal.new(0)
    end
  end

  ## ABL LIMIT
  defp remaining_limit_abl(member_product_id, start_date, end_date, authorization, diagnosis_id) do
    used_per_product = get_used_limit_per_product(member_product_id, start_date, end_date, authorization)
  end

  defp check_inner_limit(product_procedures, member) do
    Enum.map(product_procedures, fn(product_procedure) ->
      if product_procedure.product.product_base == "Benefit-based" do
        Map.put(
          product_procedure,
          :computed_procedures,
        filter_covered_icds(product_procedure.product, product_procedure.computed_procedures, member)
        )
      else
        product_procedure
      end
    end)
  end

  defp filter_covered_icds(product, diagnosis_procedures, member) do
    grouped_apds = Enum.group_by(diagnosis_procedures, &(&1.product_benefit))
    grouped_apds = Enum.map(grouped_apds, fn({product_benefit, diagnosis_procedures}) ->
      if is_nil(product_benefit) do
        diagnosis_procedures
      else
        {diagnosis_procedures, remaining} = compute_inner_limit(product_benefit, diagnosis_procedures, member, product)
        diagnosis_procedures
      end
    end)
    grouped_apds |> List.flatten()
  end

  defp compute_inner_limit(product_benefit, diagnosis_procedure, member, product) do
    benefit_limit = Enum.find(product_benefit.product_benefit_limits, &(String.contains?(&1.coverages, "EMRGNCY")))
    remaining = get_remaining_benefit_limit(product_benefit, diagnosis_procedure, member, product)
    case benefit_limit.limit_type do
      "Peso" ->
        reduce_peso(diagnosis_procedure, remaining)
      "Plan Limit Percentage" ->
        reduce_peso(diagnosis_procedure, remaining)
      "Sessions" ->
        reduce_sessions(diagnosis_procedure, remaining)
    end
  end

  defp reduce_sessions(diagnosis_procedure, remaining) do
    Enum.map_reduce(diagnosis_procedure, remaining, fn(dp, acc) ->
      if dp.payor_pays == Decimal.new(0) do
        {dp, acc}
      else
        if acc > 0 do
          payor_pays = Decimal.mult(Decimal.new(acc), dp.amount)
          if compare_decimal(payor_pays, dp.payor_pays) == :gt do
            payor_pays = dp.payor_pays
          end
          if Decimal.to_integer(dp.unit) < acc do
            acc = acc - Decimal.to_integer(dp.unit)
          else
            acc = 0
          end
          {payor_pays, member_pays} = {payor_pays, Decimal.sub(Decimal.mult(dp.amount, dp.unit), payor_pays)}
        else
          {payor_pays, member_pays} = {Decimal.new(0), dp.amount}
        end
        dp =
          dp
          |> Map.put(:payor_pays, payor_pays)
          |> Map.put(:member_pays, member_pays)
        {dp, acc}
      end
    end)
  end

  defp compare_decimal(d1, d2) do
    gt = Decimal.new(1)
    lt = Decimal.new(-1)
    eq = Decimal.new(0)
    compare = Decimal.compare(d1, d2)
    cond do
      compare == gt ->
        :gt
      compare == eq ->
        :eq
      compare == lt ->
        :lt
    end
  end

  defp reduce_peso(diagnosis_procedure, remaining) do
    Enum.map_reduce(diagnosis_procedure, remaining, fn(dp, acc) ->
      if dp.payor_pays == Decimal.new(0) do
        {dp, acc}
      else
        {payor_pays, member_pays} = compute_peso(acc, dp)
        dp =
          dp
          |> Map.put(:payor_pays, payor_pays)
          |> Map.put(:member_pays, member_pays)
        {dp, Decimal.sub(acc, dp.payor_pays)}
      end
    end)
  end

  defp compute_peso(bl, diagnosis_procedure) do
    gt = Decimal.new(1)
    lt = Decimal.new(-1)
    eq = Decimal.new(0)
    compare = Decimal.compare(bl, diagnosis_procedure.payor_pays)
    cond do
      compare == gt ->
        payor_pays = diagnosis_procedure.payor_pays
        member_pays = Decimal.new(0)
      compare == eq ->
        payor_pays = diagnosis_procedure.payor_pays
      compare == lt ->
        payor_pays = bl
    end
    if compare_decimal(bl, diagnosis_procedure.payor_pays) == :gt do
      payor_pays = diagnosis_procedure.payor_pays
    end
    member_pays = Decimal.sub(Decimal.mult(diagnosis_procedure.amount, diagnosis_procedure.unit), payor_pays)
    {payor_pays, member_pays}
  end

  defp get_remaining_benefit_limit(product_benefit, diagnosis_procedure, member, product) do
    benefit_limit = Enum.find(product_benefit.product_benefit_limits, &(String.contains?(&1.coverages, "EMRGNCY")))
    if benefit_limit.limit_classification == "Per Coverage Period" do
      used = compute_used_benefit_per_coverage(product_benefit, diagnosis_procedure, member, benefit_limit)
    else
      used = Decimal.new(0)
    end
    case benefit_limit.limit_type do
      "Peso" ->
        benefit_limit.limit_amount |> Decimal.sub(used)
      "Plan Limit Percentage" ->
        percent = benefit_limit.limit_percentage / 100
        percent_decimal = Decimal.new(percent)
        limit = Decimal.mult(product.limit_amount, percent_decimal)
        Decimal.sub(limit, used)
      "Sessions" ->
        benefit_limit.limit_session - Decimal.to_integer(used)
    end
  end

  defp compute_used_benefit_per_coverage(product_benefit, diagnosis_procedure, member, benefit_limit) do
    auth = List.first(diagnosis_procedure).cpt.authorization
    active_account = List.first(member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    adps =
      AuthorizationContext.get_used_limit_per_product_benefit(
        member.id,
        product_benefit.id,
        start_date,
        end_date,
        auth
      )
    if benefit_limit.limit_type == "Sessions" do
      adps
      |> Enum.map(&(&1.unit))
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    else
      adps
      |> Enum.map(&(&1.payor_pay))
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    end
  end

  defp compute_per_transaction_limit(diagnosis_procedure, member) do
    raise 123
  end

  defp compute_inner_limit(diagnosis_procedure, member) do
    benefit_limit = Enum.find(diagnosis_procedure.product_benefit.benefit.benefit_limits, &(String.contains?(&1.coverages, "EMRGNCY")))
    if benefit_limit.limit_classification == "Per Transaction" do
      compute_per_transaction_limit(diagnosis_procedure, member)
    else
      raise "haha"
    end
    raise diagnosis_procedure.product_benefit
  end


  defp filter_covered_procedures(product, procedures, member) do
    raise 123
    raise procedures.product_benefit
    active_account = List.first(member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    #raise benefit_limit
    #raise Enum.count(procedures)
    #Enum.group_by(procedures, &(&1.product_benefit.id)) procedures |> Enum.count() |> raise()
    Enum.map(procedures, fn(procedure) ->
      # raise procedure.product_benefit
      #raise procedure.amount
      # raise member.id
      raise AuthorizationContext.get_used_limit_per_product_benefit(
        procedure.cpt.authorization.member_id,
        procedure.product_benefit.id,
        start_date,
        end_date,
        procedure.cpt.authorization
      )
      benefit_limit = Enum.find(procedure.product_benefit.benefit_limits, &(String.contains?(&1.coverages, "EMRGNCY")))
      raise procedure.authorization_id
      raise benefit_limit
      if procedure.covered do
        raise procedure.product_benefit
        raise procedure.member_pays
        raise procedure.cpt.payor_procedure.id
      else
        procedure
      end
    end)
  end

  ## MBL LIMIT
  defp remaining_limit_mbl(member_product_id, start_date, end_date, authorization, diagnosis_id) do
    diagnosis = DiagnosisContext.get_diagnosis(diagnosis_id)
    diagnosis_group = String.slice(diagnosis.code, 0..2)
    used_limit = get_used_limit_per_diagnosis_group(member_product_id, diagnosis_group, start_date, end_date, authorization)
  end

  ## USED LIMIT IN AUTHORIZATION PER PRODUCT
  def get_used_limit_per_product(member_product_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationProcedureDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      apd.member_product_id == ^member_product_id and
      a.id != ^authorization.id and
      a.status == "Approved"
    )
    |> select([apd, a], apd.payor_pay)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  ## USED LIMIT IN AUTHORIZATION PER DIAGNOSIS GROUP
  def get_used_limit_per_diagnosis_group(member_product_id, diagnosis_group, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationProcedureDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> join(:inner, [apd, a], d in Diagnosis, apd.diagnosis_id == d.id)
    |> where(
      [apd, a, d],
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      like(d.code, ^"#{diagnosis_group}%") and
      a.id != ^authorization.id and
      apd.member_product_id == ^member_product_id and
      a.status == "Approved"
    )
    |> select([apd, a], apd.payor_pay)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  ## REMAINING BALANCE OF PRODUCT LIMIT
  defp get_remaining_balance(balance, payor_pays) do
    remaining = Decimal.sub(balance, payor_pays)
    if Decimal.to_float(remaining) < Decimal.to_float(Decimal.new(0)) do
      remaining = Decimal.new(0)
    else
      remaining = remaining
    end
  end

  defp get_payor_and_member_outer_limit(balance, payor_pays, amount) do
    gt = Decimal.new(1)
    lt = Decimal.new(-1)
    eq = Decimal.new(0)

    cond do
      Decimal.to_float(payor_pays) == Decimal.to_float(Decimal.new(0)) ->
        payor_pays = Decimal.new(0)
        member_pays = amount
      Decimal.compare(balance, payor_pays) == gt ->
        payor_pays = payor_pays
        member_pays = Decimal.new(0)
      Decimal.compare(balance, payor_pays) == eq ->
        payor_pays = amount
        member_pays = Decimal.new(0)
      Decimal.compare(balance, payor_pays) == lt ->
        member_pays = Decimal.sub(balance, payor_pays)
        member_pays =
          member_pays
          |> Decimal.abs()
        payor_pays = Decimal.new(balance)
    end

    %{payor_pays: payor_pays, member_pays: member_pays}
  end

  ## COMPUTE FOR REMAINING PRODUCT LIMIT
  def compute_outer_limit(ps) do
    procedures = Enum.map(ps.diagnosis_procedures, fn(diagnosis_procedure) ->
      Enum.map(diagnosis_procedure.procedures, fn(procedure) ->
        procedure
      end)
    end)
    procedures = procedures |> List.flatten()
    limit_amount_balance = ps.remaining_product_limit

    computed_procedures = Enum.map_reduce(procedures, limit_amount_balance, fn(p, bal) ->
      payor_pays = get_payor_and_member_outer_limit(bal, p.payor_pays, p.amount).payor_pays
      member_pays = get_payor_and_member_outer_limit(bal, p.payor_pays, p.amount).member_pays
      procedures =
        p
        |> Map.put(:payor_pays, payor_pays)
        |> Map.put(:member_pays, member_pays)

      remaining = get_remaining_balance(bal, p.payor_pays)

      {procedures, remaining}
    end)
    {procedures, limit} = computed_procedures
    ps =
      ps
      |> Map.put(:computed_procedures, procedures)
  end

  #Daniel End

  #Anton Compute Inner Limit



  #Anton End

  #GET PEC VALUE

  def get_pec(product_id, diagnosis_id, member_id) do
    pec =
      from(
        p in Product,
        join: pe in ProductExclusion,
        on: pe.product_id == p.id,
        join: e in Exclusion,
        on: e.id == pe.exclusion_id,
        join: ed in ExclusionDisease,
        on: ed.exclusion_id == e.id,
        join: d in Diagnosis,
        on: d.id == ed.disease_id,
        join: edu in ExclusionDuration,
        on: edu.exclusion_id == e.id and edu.disease_type == d.type,
        where:
          p.id == ^product_id and e.coverage == "Pre-existing Condition" and
            ed.disease_id == ^diagnosis_id,
        order_by: edu.duration,
        select: %{
          duration: edu.duration,
          percentage: edu.cad_percentage,
          amount: edu.cad_amount,
          d_id: d.id,
          product_exclusion_id: pe.id
        }
      )

    pec = Repo.all(pec)

    percentage = get_pec_value(pec, "percentage", member_id)
    amount = get_pec_value(pec, "amount", member_id)

    discount =
      if is_nil(percentage) do
        Decimal.new(0)
      else
        percentage.discount || 0
      end

    amount_val =
      if is_nil(amount) do
        Decimal.new(0)
      else
        amount.amount_val || 0
      end

    %{percentage: discount, amount: amount_val}
  end

  def get_pec_value(pec, type, member_id) do
    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    for p <- pec do
      if not is_nil(pec) do
        eff_date =
          Member
          |> select([m], date_add(m.enrollment_date, ^p.duration, "month"))
          |> Repo.get(member_id)

        if eff_date < date_now do
          get_pec_value_by_type(p, type)
        end
      end
    end
    |> Enum.filter(&(!is_nil(&1)))
    |> List.last()
  end

  def get_pec_value_by_type(pec, type) do
    if type == "amount" do
      %{amount_val: pec.amount, d_id: pec.d_id}
    else
      %{discount: pec.percentage, d_id: pec.d_id}
    end
  end
  #Ian End

  ##Adrian Deduct Special Approval Amount to Member Pays(will be available if there is an member pays, maximum wll be member pays)

  # def compute_saa(a_id, saa) do
  #   auth = AuthorizationContext.get_authorization(a_id)

  #   amount = auth.authorization_amounts.total_amount
  #   saa = Decimal.new(saa)

  #   difference = Decimal.sub(member_pays, saa)
  # end

  ##Adrian End

  # Check Exclusion Covered ICD

  def check_exclusion_covered_icd(result) do
    ceci_check_records(result, [])
  end

  defp ceci_check_records([head | tails], data) do
    product =
      head.product
      |> Repo.preload([
        [
          product_exclusions:
          [
            exclusion: [
              [
                exclusion_diseases: :disease,
                exclusion_procedures: [
                  procedure: :procedure
                ]
              ]
            ]
          ]
        ],
        [
          product_coverages: :coverage
        ]
      ])

    coverages =
      head.product.product_coverages
      |> Enum.map(&(&1.coverage.id))

    emergency = CoverageContext.get_coverage_by_name("Emergency")

    with true <- head.product.product_base == "Exclusion-based",
         true <- Enum.member?(coverages, emergency.id)
    do
      gen_exclusions =
        product.product_exclusions
        |> Enum.map(&(&1.exclusion))
        |> Enum.filter(&(&1.coverage == "General Exclusion"))

      exclusions =
        product.product_exclusions
        |> Enum.map(&(&1.exclusion))

      diagnosis_ids =
        exclusions
        |> load_exclusion_diagnosis([])
        |> List.flatten
        |> Enum.uniq

      all_diagnosis_id =
        Diagnosis
        |> Repo.all
        |> Enum.map(&(&1.id))

      diagnosis_ids = all_diagnosis_id -- diagnosis_ids

      procedure_ids =
        gen_exclusions
        |> load_exclusion_procedures([])
        |> List.flatten
        |> Enum.uniq

      diagnosis_procedures =
        head.diagnosis_procedures
        |> Enum.map(&(check_exclusion_icd(&1, diagnosis_ids, procedure_ids, product)))

      data =
        data ++ [%{
          member_product: head.member_product,
          member: head.member,
          coverage: head.coverage,
          product: head.product,
          diagnosis_procedures: diagnosis_procedures
        }]

      ceci_check_records(tails, data)
    else
      _ ->
        data =
          data ++ [%{
            member_product: head.member_product,
            member: head.member,
            coverage: head.coverage,
            product: head.product,
            diagnosis_procedures: head.diagnosis_procedures
          }]

      ceci_check_records(tails, data)
    end
  end

  defp check_exclusion_icd(icd, diagnosis_ids, procedure_ids, product) do
    pec = icd.pec
    result =
      with true <- pec do
        true
      else
        _ ->
          Enum.member?(diagnosis_ids, icd.icd)
      end
    icd
    |> Map.put(:covered, result)
    |> check_exclusion_covered_cpt(procedure_ids, product, result)
  end

  defp check_exclusion_covered_cpt(icd, cpt_ids, product, icd_covered) do
    procedures =
      icd.procedures
      |> check_ec_cpt([], cpt_ids, product, icd_covered)
    icd
    |> Map.put(:procedures, procedures)
  end

  defp check_ec_cpt([head | tails], result, cpt_ids, product, icd_covered) do
    procedure_id = head.cpt.payor_procedure.procedure.id
    procedure_amount = head.amount
    procedure_unit = head.unit

    covered =
      with true <- Enum.member?(cpt_ids, procedure_id)
      do
        false
      else
        _ ->
          true
      end

    payor_pays =
      if covered and icd_covered do
        Decimal.mult(procedure_amount, procedure_unit)
      else
        Decimal.new(0)
      end

    member_pays =
      if covered and icd_covered do
        Decimal.new(0)
      else
        Decimal.mult(procedure_amount, procedure_unit)
      end

    pb =
      if covered and icd_covered do
        find_pb(product.product_benefits, result, procedure_id)
      else
        nil
      end

    cpt_covered =
      head
      |> Map.put(:covered, covered)
      |> Map.put(:product_benefit, pb)
      |> Map.put(:payor_pays, payor_pays)
      |> Map.put(:member_pays, member_pays)

    result = result ++ [cpt_covered]
    check_ec_cpt(tails, result, cpt_ids, product, icd_covered)
  end

  defp check_ec_cpt([], result, cpt_ids, product, icd_covered), do: result

  defp ceci_check_records([], data), do: data

  defp load_exclusion_diagnosis([head | tails], result) do
    exclusion =
      head.exclusion_diseases
      |> Enum.map(&(&1.disease.id))

    result = result ++ exclusion
    load_exclusion_diagnosis(tails, result)
  end

  defp load_exclusion_diagnosis([], data), do: data

  defp load_product_exclusion_procedures([head | tails], result) do
    exclusion =
      head.exclusion_procedures
      |> Enum.map(&(&1.procedure.procedure.id))

    procedure =
      Procedure
      |> Repo.all
      |> Enum.map(&(&1.id))

    valid_ids = procedure -- exclusion

    result = result ++ valid_ids
    load_product_exclusion_procedures(tails, result)
  end

  defp load_product_exclusion_procedures([], result), do: result

  # End of Check Exclusion Covered ICD

  # END OF GET PEC VALUE
end

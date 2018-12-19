defmodule Innerpeace.Db.Validators.OPLabValidatorOld do

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
    Schemas.Embedded.OPLab,
    Schemas.Procedure,
    Schemas.MemberProduct,
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
    Schemas.BenefitRUV
  }

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    PractitionerContext,
    MemberContext,
    ProductContext,
    BenefitContext,
    CoverageContext,
    FacilityContext
  }

  # WEB
  def request_web_op_lab(params) do
    changeset =
      %OPLab{}
      |> OPLab.changeset(params)

    changeset =
      changeset
      |> Ecto.Changeset.put_change(:authorization_id, params["authorization_id"])
      |> Ecto.Changeset.put_change(:user_id, params["user_id"])

    chief_complaint = if Map.has_key?(changeset.changes, :chief_complaint) do
      changeset.changes.chief_complaint
    else
      nil
    end

    if changeset.errors == [] do
      member = MemberContext.get_a_member!(changeset.changes.member_id)
      coverage_id = AuthorizationContext.get_coverage_id_by_code("OPL")
      ruv_coverage_id = AuthorizationContext.get_coverage_id_by_code("RUV")
      authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
      AuthorizationContext.modify_authorization_laboratory_step4(authorization, params, changeset.changes.user_id)
      AuthorizationContext.create_authorization_practitioner(params, changeset.changes.user_id)
      params = %{
        "chief_complaint" => chief_complaint,
        "practitioner_id" => changeset.changes.practitioner_id,
        "member_id" => changeset.changes.member_id,
        "facility_id" => changeset.changes.facility_id,
        "coverage_id" => coverage_id,
        "authorization_id" => authorization.id,
        "admission_datetime" => Ecto.DateTime.cast!("#{changeset.changes.admission_datetime} 00:00:00")
      }
      changeset
      |> Ecto.Changeset.put_change(:member, member)
      |> Ecto.Changeset.put_change(:coverage_id, coverage_id)
      |> Ecto.Changeset.put_change(:ruv_coverage_id, ruv_coverage_id)
      |> compute_fees()
      |> compute_deductions_web2()
      |> compute_ruv_deductions()
      |> insert_authorization_amounts()
    else
      {:error, changeset}
    end
  end

  # END OF WEB

  defp insert_authorization_amounts(changeset) do
    payor_pays_ruvs = Enum.map(changeset.changes.final_ruv_fees, &(&1.payor_pays))
    payor_pays_procedures = Enum.map(changeset.changes.final_procedure_fees, &(&1.payor_pays))
    payor_pays = Enum.reduce(payor_pays_ruvs ++ payor_pays_procedures, Decimal.new(0), &Decimal.add/2)

    member_pays_ruvs = Enum.map(changeset.changes.final_ruv_fees, &(&1.member_pays))
    member_pays_procedures = Enum.map(changeset.changes.final_procedure_fees, &(&1.member_pays))
    member_pays = Enum.reduce(member_pays_ruvs ++ member_pays_procedures, Decimal.new(0), &Decimal.add/2)

    philhealth_pays_ruvs = Enum.map(changeset.changes.final_ruv_fees, &(&1.philhealth_pays))
    philhealth_pays_procedures = Enum.map(changeset.changes.final_procedure_fees, &(&1.philhealth_pays))
    philhealth_pays = Enum.reduce(philhealth_pays_ruvs ++ philhealth_pays_procedures, Decimal.new(0), &Decimal.add/2)

    params = %{
      "payor_covered" => payor_pays,
      "member_covered" => member_pays,
      "company_covered" => philhealth_pays,
      "total_amount" => payor_pays |> Decimal.add(member_pays) |> Decimal.add(philhealth_pays),
      "authorization_id" => changeset.changes.authorization_id
    }
    AuthorizationContext.create_authorization_amount(params, changeset.changes.user_id)
  end

  defp compute_ruv_deductions(changeset) do
    member_products = Enum.filter(changeset.changes.member.products, fn(member_product) ->
      Enum.member?(Enum.map(member_product.account_product.product.product_coverages, &(&1.coverage.id)), changeset.changes.ruv_coverage_id)
    end)
    ruv_fees =
      Enum.map(filter_fees(changeset.changes.procedure_fees, :ruv_fee), fn(ruv) ->
        cond do
          ruv.ruv_fee == ruv.philhealth_pays ->
            params = %{
              procedure_id: ruv.ruv.id,
              authorization_id: changeset.changes.authorization_id,
              facility_ruv_id: ruv.id,
              philhealth_pay: ruv.philhealth_pays,
              member_pay: Decimal.new(0),
              payor_pay: Decimal.new(0)
            }

            params.authorization_id
            |> AuthorizationContext.get_authorization_ruv(params.facility_ruv_id)
            |> AuthorizationContext.update_authorization_ruv(params)
            Map.put(ruv, :product_id, nil)
          true ->
            if Enum.empty?(check_product_benefit_ruv(member_products, ruv.ruv_id)) do
              member_pays = Decimal.sub(ruv.ruv_fee, ruv.philhealth_pays)
              params = %{
                ruv_id: ruv.ruv_id,
                authorization_id: changeset.changes.authorization_id,
                philhealth_pay: ruv.philhealth_pays,
                member_pay: member_pays,
                payor_pay: Decimal.new(0)
              }

              params.authorization_id
              |> AuthorizationContext.get_authorization_ruv(ruv.id)
              |> AuthorizationContext.update_authorization_ruv(params)
              ruv
              |> Map.put(:product_id, nil)
              |> Map.put(:member_pays, member_pays)
            else
              get_highest_product_ruv(ruv, filter_covered_products_ruv(member_products, ruv), changeset.changes.facility_id, changeset)
            end
        end
      end)
    changeset
    |> Ecto.Changeset.put_change(:final_ruv_fees, ruv_fees)
  end

  defp filter_covered_products_ruv(member_products, ruv) do
    Enum.filter(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        product_benefit_ruvs =
          Enum.map(member_product.account_product.product.product_benefits, fn(product_benefit) ->
            for product_benefit_ruv <- product_benefit.benefit.benefit_ruvs do
              product_benefit_ruv.ruv.id
            end
          end)
          product_benefit_ruvs |> List.flatten() |> Enum.uniq() |> Enum.member?(ruv.ruv_id)
      else
        true
      end
    end)
  end

  defp check_product_benefit_ruv(member_products, ruv_id) do
    Enum.reject(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Exclusion-based" do
        product_ruvs = [true]
      else
        product_ruvs = for product_benefit <- member_product.account_product.product.product_benefits do
          with %BenefitRUV{} <- Enum.find(product_benefit.benefit.benefit_ruvs, &(&1.ruv_id == ruv_id)) do
            product_benefit
          else
            _ ->
              nil
          end
        end
      end
      product_ruv =
        product_ruvs
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
      is_nil(product_ruv)
    end)
  end

  #TODO CHECK UNUSED FUNCTIONS
  def validate_without_procedure_and_diagnosis(params) do
    params = %{
      admission_datetime: params["admission_datetime"],
      member_id: params["member_id"],
      practitioner_id: params["doctor_id"],
      facility_id: params["provider_id"],
      card_number: params["card_number"],
      chief_complaint: params["complaint"],
      availment_type: params["availment_type"]
    }
    changeset =
      %OPLab{}
      |> OPLab.changeset_without_procedure_and_dignosis(params)
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  #TODO CHECK UNUSED FUNCTIONS
  def request_without_procedure_and_diagnosis(changeset, params) do
    member = MemberContext.get_a_member!(changeset.changes.member_id)
    #check if there's a product in member
    member_product = for member_product <- member.products do
      #check coverage facility
      product = member_product.account_product.product
      coverage = CoverageContext.get_coverage_by_name("OP Laboratory")
        inclusion_product = for pc <- product.product_coverages do
          if pc.type == "inclusion" and pc.coverage_id == coverage.id do
            pc.product_coverage_facilities
          end
        end
        inclusion_product =
          inclusion_product
          |> List.flatten()
          |> Enum.uniq()
          |> List.delete(nil)
        inclusion_facilities_id = for ip <- inclusion_product do
          ip.facility_id
        end
      inclusion_facilities = Enum.uniq(inclusion_facilities_id)

      if Enum.member?(inclusion_facilities, changeset.changes.facility_id) do
        member_product
      else
        exception_product = for pc <-  product.product_coverages do
          if pc.type == "exception" and pc.coverage_id == coverage.id do
            pc
          end
        end
        exception_product =
          exception_product
          |> List.flatten()
          |> Enum.uniq()
          |> List.delete(nil)
        exception_facilities = if exception_product == [] do
          []
        else
          exception_facilities_id = for ep <- exception_product do
            for pcf <- ep.product_coverage_facilities do
              pcf.facility_id
            end
          end
          exception_facilities_id =
            exception_facilities_id
            |> List.flatten()
            |> Enum.uniq()
            |> List.delete(nil)
          exception_facilities_id = Enum.uniq(exception_facilities_id)
          facilities = FacilityContext.get_all_facility
          facilities_id = for facility <- facilities do
            facility.id
          end
          exception_facilities = facilities_id -- exception_facilities_id
        end
        if Enum.member?(exception_facilities, changeset.changes.facility_id) do
          member_product
        end
      end
    end
    member_product =
      member_product
      |> Enum.uniq()
      |> List.delete(nil)

    if Enum.empty?(member_product) do
      {:error, "no_product"}
    else
      AuthorizationContext.request_op_lab(params)
    end
  end

  def get_facility_ruv(id) do
    FacilityRUV
    |> where([fruv], fruv.id == ^id)
    |> Repo.one!()
    |> Repo.preload([
      ruv: :case_rates
    ])
  end

  defp get_ruv_case_rate(ruv_id) do
    CaseRate
    |> where([cr], cr.ruv_id == ^ruv_id)
    |> Repo.one()
  end

  defp compute_ruv_fees(facility_ruv, op_room) do
    zero = Decimal.new(0)
    if facility_ruv.ruv.type == "Unit" do
      ruv_fee = Decimal.mult(facility_ruv.ruv.value, Decimal.new(op_room.facility_room_rate))
    else
      ruv_fee = facility_ruv.ruv.value
    end
    if is_nil(case_rate = get_ruv_case_rate(facility_ruv.ruv.id)) do
      philhealth_pays = zero
    else
      if case_rate.hierarchy == 2 do
        philhealth_pays = Decimal.div(ruv_fee, Decimal.new(2))
      else
        philhealth_pays = ruv_fee
      end
    end
    if is_nil(case_rate) do
      case_rate_hierarchy = 0
    else
      case_rate_hierarchy = case_rate.hierarchy
    end
    %{
      payor_pays: zero,
      member_pays: zero,
      philhealth_pays: philhealth_pays,
      ruv_fee: ruv_fee,
      case_rate_hierarchy: case_rate_hierarchy
    }
    Map.merge(%{
      payor_pays: zero,
      member_pays: zero,
      philhealth_pays: philhealth_pays,
      ruv_fee: ruv_fee,
      case_rate_hierarchy: case_rate_hierarchy
    }, facility_ruv)
  end

  # 1 - Get Doctor Fee based on Facility
  defp compute_fees(changeset) do
    op_room =
      FacilityRoomRate
      |> join(:inner, [frr], r in Room,  frr.room_id == r.id)
      |> where([frr, r], frr.facility_id == ^changeset.changes.facility_id and r.code == "16")
      |> Repo.one()
    ruv_ids = changeset.changes.ruv_ids
    #ruv_ids = []
    ruv_fees =
      Enum.map(ruv_ids, fn(facility_ruv) ->
        facility_ruv
        |> get_facility_ruv()
        |> compute_ruv_fees(op_room)
      end)
    procedure_fees =
      for diagnosis_procedure <- changeset.changes.diagnosis_procedure do
        procedure_fee = Decimal.mult(diagnosis_procedure.unit, get_fppr_amount(diagnosis_procedure.procedure_id, changeset.changes.facility_id))
        if case_rate = check_case_rate(diagnosis_procedure.diagnosis_id) do
          if case_rate.hierarchy == 2 do
            philhealth_pays = Decimal.div(procedure_fee, Decimal.new(2))
          else
            philhealth_pays = procedure_fee
          end
        else
          philhealth_pays = Decimal.new(0)
        end
        zero = Decimal.new(0)
        case_rate_hierarchy =
          if is_nil(case_rate) do
            0
          else
            case_rate.hierarchy
          end
        fees = %{payor_pays: zero, member_pays: zero, philhealth_pays: philhealth_pays, procedure_fee: procedure_fee, case_rate_hierarchy: case_rate_hierarchy}
        Map.merge(diagnosis_procedure, fees)
      end
    combined = ruv_fees ++ procedure_fees
    h1 = get_top_hierarchy(combined, 1)
    h2 = get_top_hierarchy(combined, 2)
    changeset
    |> Ecto.Changeset.put_change(:procedure_fees, filter_loa_fees(combined, h1, h2))
  end

  defp filter_loa_fees(list, h1, h2) do
    Enum.map(list, fn(x) ->
      if x == h1 or x == h2 do
        x
      else
        Map.put(x, :philhealth_pays, Decimal.new(0))
      end
    end)
  end

  defp get_top_hierarchy(list, hierarchy) do
    filtered = Enum.filter(list, &(&1.case_rate_hierarchy == hierarchy))
    top =
      if Enum.empty?(filtered) do
        nil
      else
        Enum.max_by(filtered, &(&1.philhealth_pays))
      end
  end

  defp get_fppr_amount(facility_procedure_id, facility_id) do
    FacilityPayorProcedureRoom
    |> join(:inner, [fppr], frr in FacilityRoomRate, frr.id == fppr.facility_room_rate_id)
    |> join(:inner, [fppr, frr], r in Room, r.id == frr.room_id)
    |> join(:inner, [fppr, frr, r], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
    |> join(:inner, [fppr, frr, r, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
    |> where([fppr, frr, r, fpp, pp], pp.id == ^facility_procedure_id and r.type == "OP" and frr.facility_id == ^facility_id)
    |> select([fppr, frr, r, fpp, pp], fppr.amount)
    |> Repo.one()
  end

  defp check_case_rate(diagnosis_id) do
    CaseRate
    |> where([cr], cr.diagnosis_id == ^diagnosis_id)
    |> Repo.one()
  end

  # 1 - Deduct fee based on case rates per disease of member
  # 2 - Deduct fee based on copayment/coinsurance percentage based on the product of the member
  # 3 - Deduct fee based on diagnonis exists in pre-existing condition
  # 4 - Deduct fee based on based on covered risk share

  defp filter_fees(list, key) do
    Enum.filter(list, &(Map.has_key?(&1, key)))
  end

  defp compute_deductions_web2(changeset) do
    member_products = Enum.filter(changeset.changes.member.products, fn(member_product) ->
      Enum.member?(Enum.map(member_product.account_product.product.product_coverages, &(&1.coverage.id)), changeset.changes.coverage_id)
    end)
    procedure_fees =
      Enum.map(filter_fees(changeset.changes.procedure_fees, :procedure_fee), fn(diagnosis_procedure) ->
        cond do
          diagnosis_procedure.procedure_fee == diagnosis_procedure.philhealth_pays ->
            params = %{
              procedure_id: diagnosis_procedure.procedure_id,
              authorization_id: changeset.changes.authorization_id,
              diagnosis_id: diagnosis_procedure.diagnosis_id,
              philhealth_pay: diagnosis_procedure.philhealth_pays,
              payor_pay: Decimal.new(0),
              member_pay: Decimal.new(0)
            }

            params.authorization_id
            |> AuthorizationContext.get_authorization_procedure_diagnosis_by_ids(params.procedure_id, params.diagnosis_id)
            |> AuthorizationContext.update_authorization_procedure_diagnosis(params)
            Map.put(diagnosis_procedure, :product_id, nil)
          true ->
            if Enum.empty?(check_product_benefit_procedure(member_products, diagnosis_procedure, changeset.changes.coverage_id)) do
              member_pays = Decimal.sub(diagnosis_procedure.procedure_fee, diagnosis_procedure.philhealth_pays)
              params = %{
                procedure_id: diagnosis_procedure.procedure_id,
                authorization_id: changeset.changes.authorization_id,
                diagnosis_id: diagnosis_procedure.diagnosis_id,
                philhealth_pay: diagnosis_procedure.philhealth_pays,
                payor_pay: Decimal.new(0),
                member_pay: member_pays
              }

              params.authorization_id
              |> AuthorizationContext.get_authorization_procedure_diagnosis_by_ids(params.procedure_id, params.diagnosis_id)
              |> AuthorizationContext.update_authorization_procedure_diagnosis(params)
              diagnosis_procedure
              |> Map.put(:product_id, nil)
              |> Map.put(:member_pays, member_pays)
            else
              get_highest_product(diagnosis_procedure, filter_covered_products(member_products, diagnosis_procedure), changeset.changes.facility_id, changeset)
            end
        end
      end)
    changeset
    |> Ecto.Changeset.put_change(:final_procedure_fees, procedure_fees)
  end

  defp filter_covered_products(member_products, diagnosis_procedure) do
    Enum.filter(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        product_benefit_procedures =
          Enum.map(member_product.account_product.product.product_benefits, fn(product_benefit) ->
            for product_benefit_procedure <- product_benefit.benefit.benefit_procedures do
              product_benefit_procedure.procedure.id
            end
          end)
          product_benefit_procedures |> List.flatten() |> Enum.uniq() |> Enum.member?(diagnosis_procedure.procedure_id)
      else
        true
      end
    end)
  end

  defp get_highest_product_ruv(ruv, member_products, facility_id, changeset) do
    product_fees = Enum.map(member_products, fn(member_product) ->
      check_highest_product_ruv(member_product, ruv, facility_id, changeset)
    end)
    highest_product = Enum.max_by(product_fees, &(&1.payor_pays))
    update_params = %{
      risk_share_type: highest_product.risk_share_type,
      risk_share_setup: highest_product.risk_share_setup,
      risk_share_amount: highest_product.risk_share_amount,
      percentage_covered: highest_product.percentage_covered,
      pec: highest_product.pec,
      philhealth_pay: highest_product.philhealth_pays,
      member_pay: highest_product.member_pays,
      payor_pay: highest_product.payor_pays,
      product_benefit_id: highest_product.product_benefit_id,
      member_product_id: highest_product.member_product_id
    }

    changeset.changes.authorization_id
    |> AuthorizationContext.get_authorization_ruv(ruv.id)
    |> AuthorizationContext.update_authorization_ruv(update_params)
    highest_product
  end

  defp check_highest_product_ruv(member_product, ruv, facility_id, changeset) do
    if member_product.account_product.product.product_base == "Exclusion-based" do
      product_benefit_id = nil
    else
      product_benefit_id = Enum.find(member_product.account_product.product.product_benefits, fn(product_benefit) ->
        Enum.member?(Enum.map(product_benefit.benefit.benefit_ruvs, &(&1.ruv.id)), ruv.ruv_id) and
        Enum.member?(Enum.map(product_benefit.benefit.benefit_coverages, &(&1.coverage.id)), changeset.changes.ruv_coverage_id)
      end).id
    end

    balance = Decimal.sub(ruv.ruv_fee, ruv.philhealth_pays)
    risk_share = risk_share_checker_ruv(member_product.account_product.product, facility_id, ruv.ruv_id)
    pec = Decimal.new(0)
    params =  %{
      procedure_fee: balance,
      covered_percentage: risk_share.covered,
      type: risk_share.type,
      copayment_val: risk_share.copayment,
      coinsurance_val: risk_share.coinsurance,
      value: Decimal.new(0),
      pec: pec,
      authorization_id: changeset.changes.authorization_id,
      ruv_id: ruv.id,
      setup: risk_share.setup,
      philhealth_pays: ruv.philhealth_pays,
      member_product_id: member_product.id
    }
    if is_nil(risk_share.setup) do
      computed_fees = %{
        payor: balance,
        member: Decimal.new(0)
      }
      update_params = %{
        philhealth_pay: params.philhealth_pays,
        member_product_id: params.member_product_id
      }

      params.authorization_id
      |> AuthorizationContext.get_authorization_ruv(params.ruv_id)
      |> AuthorizationContext.update_authorization_ruv(update_params)
    else
      computed_fees = compute_laboratory_ruv(params)
    end
    payor_excess = Decimal.new(0)
    payor = Decimal.sub(computed_fees.payor, payor_excess)
    member = Decimal.add(payor_excess, computed_fees.member)
    risk_share_amount = if params.type == "Copayment" do
      params.copayment_val
    else
      params.coinsurance_val
    end
    ruv |> Map.merge(%{
      member_pays: member,
      payor_pays: payor,
      product_id: member_product.id,
      risk_share_type: params.type,
      risk_share_setup: params.setup,
      risk_share_amount: risk_share_amount,
      percentage_covered: params.covered_percentage,
      pec: params.pec,
      product_benefit_id: product_benefit_id,
      member_product_id: member_product.id
    })
  end

  defp get_highest_product(diagnosis_procedure, member_products, facility_id, changeset) do
    product_fees = Enum.map(member_products, fn(member_product) ->
      compute_fees_with_product(member_product, diagnosis_procedure, facility_id, changeset)
    end)
    highest_product = Enum.max_by(product_fees, fn(x) ->
      Decimal.to_float(x.payor_pays)
    end)
    update_params = %{
      risk_share_type: highest_product.risk_share_type,
      risk_share_setup: highest_product.risk_share_setup,
      risk_share_amount: highest_product.risk_share_amount,
      percentage_covered: highest_product.percentage_covered,
      pec: highest_product.pec,
      philhealth_pay: highest_product.philhealth_pays,
      member_pay: highest_product.member_pays,
      payor_pay: highest_product.payor_pays,
      product_benefit_id: highest_product.product_benefit_id,
      member_product_id: highest_product.member_product_id
    }

    changeset.changes.authorization_id
    |> AuthorizationContext.get_authorization_procedure_diagnosis_by_ids(diagnosis_procedure.procedure_id, diagnosis_procedure.diagnosis_id)
    |> AuthorizationContext.update_authorization_procedure_diagnosis(update_params)
    highest_product
  end

  defp compute_fees_with_product(member_product, diagnosis_procedure, facility_id, changeset) do
    if member_product.account_product.product.product_base == "Exclusion-based" do
      product_benefit_id = nil
    else
      if product_benefit = Enum.find(member_product.account_product.product.product_benefits, fn(product_benefit) ->
        Enum.member?(Enum.map(product_benefit.benefit.benefit_procedures, &(&1.procedure.id)), diagnosis_procedure.procedure_id) and
        Enum.member?(Enum.map(product_benefit.benefit.benefit_coverages, &(&1.coverage.id)), changeset.changes.coverage_id)
      end) do
        product_benefit_id = product_benefit.id
      else
        product_benefit_id = nil
      end
    end

    if product_benefit_id do
      benefit_limit = AuthorizationContext.get_benefit_limit(product_benefit_id, "OPL")
      benefit_limit =
        case benefit_limit.limit_type do
          "Peso" ->
            benefit_limit.limit_amount
          "Plan Limit Percentage" ->
            percentage_amount = Decimal.new(benefit_limit.limit_percentage || 0)
            Decimal.div(percentage_amount || Decimal.new(0), Decimal.new(100)) |> Decimal.mult(benefit_limit.product_limit)
          _ ->
            raise "error"
        end
      used_benefit_limit = AuthorizationContext.get_used_benefit_limit_per_authorization(changeset.changes.authorization_id, product_benefit_id, diagnosis_procedure.procedure_id)
      remaining_bl = Decimal.sub(benefit_limit, used_benefit_limit)
    end

    balance = Decimal.sub(diagnosis_procedure.procedure_fee, diagnosis_procedure.philhealth_pays)
    risk_share = risk_share_checker(member_product.account_product.product, facility_id, diagnosis_procedure.procedure_id)
    pec = ProductContext.get_pec_op_lab(member_product.account_product.product.id, diagnosis_procedure.diagnosis_id, member_product.member.id)

    if is_nil(pec) do
      pec = Decimal.new(0)
    else
      pec = Decimal.new(pec)
    end

    params =  %{
      procedure_fee: balance,
      covered_percentage: risk_share.covered,
      type: risk_share.type,
      copayment_val: risk_share.copayment,
      coinsurance_val: risk_share.coinsurance,
      value: Decimal.new(0),
      pec: pec,
      authorization_id: changeset.changes.authorization_id,
      procedure_id: diagnosis_procedure.procedure_id,
      diagnosis_id: diagnosis_procedure.diagnosis_id,
      setup: risk_share.setup,
      philhealth_pays: diagnosis_procedure.philhealth_pays,
      member_product_id: member_product.id
    }

    # TEMPO REMOVED
    #if is_nil(risk_share.setup) do
    #  computed_fees = %{
    #    payor: balance,
    #    member: Decimal.new(0)
    #  }
    #  update_params = %{
    #    philhealth_pay: params.philhealth_pays,
    #    member_product_id: params.member_product_id
    #  }
    #else
    #  computed_fees = compute_laboratory(params)
    #end

    #raise remaining_bl
    if pec == Decimal.new(0) do
      if product_benefit_id do
        if remaining_bl |> Decimal.sub(balance) |> AuthorizationContext.less_than_zero?() do
          member_pay = remaining_bl |> Decimal.sub(balance) |> Decimal.abs()
          computed_fees = %{
            payor: Decimal.sub(balance, member_pay),
            member: member_pay
          }
        else
          computed_fees = %{
            payor: balance,
            member: Decimal.new(0)
          }
        end
      else
        computed_fees = %{
          payor: balance,
          member: Decimal.new(0)
        }
      end
    else
      if product_benefit_id do
        if remaining_bl |> Decimal.sub(balance) |> AuthorizationContext.less_than_zero?() do
          member_pay = remaining_bl |> Decimal.sub(balance) |> Decimal.abs()
          remaining_payor = Decimal.sub(balance, member_pay)
          payor = pec |> Decimal.div(Decimal.new(100)) |> Decimal.mult(remaining_payor)
          member_pay = Decimal.add(member_pay, Decimal.sub(remaining_payor, payor))
          computed_fees = %{
            payor: payor,
            member: member_pay
          }
        else
          payor = pec |> Decimal.div(Decimal.new(100)) |> Decimal.mult(balance)
          computed_fees = %{
            payor: payor,
            member: Decimal.sub(balance, payor)
          }
        end
      else
        payor = pec |> Decimal.div(Decimal.new(100)) |> Decimal.mult(balance)
        computed_fees = %{
          payor: payor,
          member: Decimal.sub(balance, payor)
        }
      end
    end

    payor_excess = Decimal.new(0)
    payor = Decimal.sub(computed_fees.payor, payor_excess)
    member = Decimal.add(payor_excess, computed_fees.member)
    risk_share_amount = if params.type == "Copayment" do
      params.copayment_val
    else
      params.coinsurance_val
    end

    # TEMPO REMOVED
    #diagnosis_procedure |> Map.merge(%{
    #  member_pays: member,
    #  payor_pays: payor,
    #  product_id: member_product.id,
    #  risk_share_type: params.type,
    #  risk_share_setup: params.setup,
    #  risk_share_amount: risk_share_amount,
    #  percentage_covered: params.covered_percentage,
    #  pec: params.pec,
    #  product_benefit_id: product_benefit_id,
    #  member_product_id: member_product.id
    #})

    diagnosis_procedure |> Map.merge(%{
      member_pays: member,
      payor_pays: payor,
      product_id: member_product.id,
      risk_share_type: nil,
      risk_share_setup: nil,
      risk_share_amount: nil,
      percentage_covered: nil,
      pec: params.pec,
      product_benefit_id: product_benefit_id,
      member_product_id: member_product.id
    })
  end

  defp risk_share_checker(product, facility_id, procedure_id) do
    product_coverage = Enum.find(product.product_coverages, &(&1.coverage.code == "OPL"))
    pcr = product_coverage.product_coverage_risk_share
    rs_facility =
      if is_nil(pcr) do
        nil
      else
        Enum.find(pcr.product_coverage_risk_share_facilities, &(&1.facility_id == facility_id))
      end
    rs_procedure =
      if is_nil(rs_facility) do
        nil
      else
        Enum.find(rs_facility.product_coverage_risk_share_facility_payor_procedures, &(&1.facility_payor_procedure.payor_procedure_id == procedure_id))
      end
    cond do
      rs_procedure ->
        %{
          type: rs_procedure.type,
          copayment: rs_procedure.value_amount,
          coinsurance: rs_procedure.value_percentage,
          covered: rs_procedure.covered,
          setup: "Procedure"
        }
      rs_facility ->
        %{
          type: rs_facility.type,
          copayment: rs_facility.value_amount,
          coinsurance: rs_facility.value_percentage,
          covered: rs_facility.covered,
          setup: "Facility"
        }
      pcr.af_type == "N/A" ->
        %{
          type: nil,
          copayment: 0,
          coinsurance: 0,
          covered: 0,
          setup: nil
        }
      pcr.af_type ->
        if pcr.af_type == "Copayment" do
        %{
          type: pcr.af_type,
          copayment: pcr.af_value_amount,
          coinsurance: 0,
          covered: pcr.af_covered_percentage,
          setup: "Coverage"
        }
        else
        %{
          type: pcr.af_type,
          copayment: 0,
          coinsurance: pcr.af_value_percentage,
          covered: pcr.af_covered_percentage,
          setup: "Coverage"
        }
        end
      true ->
        %{
          type: nil,
          copayment: 0,
          coinsurance: 0,
          covered: 0,
          setup: nil
        }
    end
  end

  defp risk_share_checker_ruv(product, facility_id, ruv_id) do
    product_coverage = Enum.find(product.product_coverages, &(&1.coverage.code == "RUV"))
    pcr = product_coverage.product_coverage_risk_share
    rs_facility =
      if is_nil(pcr) do
        nil
      else
        Enum.find(pcr.product_coverage_risk_share_facilities, &(&1.facility_id == facility_id))
      end
    cond do
      rs_facility ->
        %{
          type: rs_facility.type,
          copayment: rs_facility.value_amount,
          coinsurance: rs_facility.value_percentage,
          covered: rs_facility.covered,
          setup: "Facility"
        }
      pcr.af_type == "N/A" ->
        %{
          type: nil,
          copayment: 0,
          coinsurance: 0,
          covered: 0,
          setup: nil
        }
      pcr.af_type ->
        if pcr.af_type == "Copayment" do
        %{
          type: pcr.af_type,
          copayment: pcr.af_value_amount,
          coinsurance: 0,
          covered: pcr.af_covered_percentage,
          setup: "Coverage"
        }
        else
        %{
          type: pcr.af_type,
          copayment: 0,
          coinsurance: pcr.af_value_percentage,
          covered: pcr.af_covered_percentage,
          setup: "Coverage"
        }
        end
      true ->
        %{
          type: nil,
          copayment: 0,
          coinsurance: 0,
          covered: 0,
          setup: nil
        }
    end
  end

  defp list_benefit_procedure_ids(benefit) do
    Enum.map(benefit.benefit_procedures, fn(benefit_procedure) ->
      benefit_procedure.procedure.id
    end)
  end

  defp check_product_benefit_procedure(member_products, diagnosis_procedure, coverage_id) do
    Enum.reject(member_products, fn(member_product) ->
      if member_product.account_product.product.product_base == "Benefit-based" do
        check_benefit_based(member_product, diagnosis_procedure, coverage_id)
      else
        check_exclusion_based(member_product, diagnosis_procedure)
      end
    end)
  end

  defp check_benefit_based(member_product, diagnosis_procedure, coverage_id) do
    pbs =
      member_product.account_product.product.product_benefits
      |> Enum.filter(fn(product_benefit) ->
        product_benefit.benefit.benefit_coverages
        |> Enum.map(&(&1.coverage.id))
        |> Enum.member?(coverage_id)
      end)
    product_benefits = for product_benefit <- pbs do
      with %BenefitProcedure{} <- Enum.find(product_benefit.benefit.benefit_procedures, &(&1.procedure_id == diagnosis_procedure.procedure_id)),
           {:ok} <- check_product_exclusions(member_product, diagnosis_procedure),
           {:ok} <- check_product_pec(member_product, diagnosis_procedure)
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
    is_nil(product_benefit)
  end

  defp check_product_exclusions(member_product, diagnosis_procedure) do
    exclusion_diseases =
      for product_exclusion <- Enum.filter(member_product.account_product.product.product_exclusions, &(&1.exclusion.coverage == "General Exclusion")) do
        Enum.map(product_exclusion.exclusion.exclusion_diseases, &(&1.disease.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    exclusion_procedures =
      for product_exclusion <- Enum.filter(member_product.account_product.product.product_exclusions, &(&1.exclusion.coverage == "General Exclusion")) do
        Enum.map(product_exclusion.exclusion.exclusion_procedures, &(&1.procedure.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    if Enum.member?(exclusion_diseases, diagnosis_procedure.diagnosis_id) or Enum.member?(exclusion_procedures, diagnosis_procedure.procedure_id) do
      {:excluded}
    else
      {:ok}
    end
  end

  defp check_product_pec(member_product, diagnosis_procedure) do
    enrollment_date = member_product.member.enrollment_date
    exclusion_diseases =
      for product_exclusion <- Enum.filter(member_product.account_product.product.product_exclusions, &(&1.exclusion.coverage == "Pre-existing Condition")) do
        Enum.map(product_exclusion.exclusion.exclusion_diseases, &(&1.disease.id))
      end
      |> List.flatten()
      |> Enum.uniq()
    pec = ProductContext.get_pec_op_lab(member_product.account_product.product.id, diagnosis_procedure.diagnosis_id, member_product.member_id)
    if Enum.member?(exclusion_diseases, diagnosis_procedure.diagnosis_id) and is_nil(pec) do
      {:excluded}
    else
      {:ok}
    end
  end

  defp check_exclusion_based(member_product, diagnosis_procedure) do
    pec = ProductContext.get_pec_op_lab(member_product.account_product.product.id, diagnosis_procedure.diagnosis_id, member_product.member_id)
    pec_diseases =
      member_product.account_product.product.product_exclusions
      |> Enum.filter(&(&1.exclusion.coverage == "Pre-existing Condition"))
      |> Enum.map(&(&1.exclusion.exclusion_diseases))
      |> List.flatten()
      |> Enum.map(&(&1.disease_id))
    product_exclusions =
      for product_exclusion <- member_product.account_product.product.product_exclusions do
        with %ExclusionProcedure{} <- Enum.find(product_exclusion.exclusion.exclusion_procedures, &(&1.procedure_id == diagnosis_procedure.procedure_id)) do
          true
        else
          _ ->
            false
        end
      end
    cond do
      Enum.member?(product_exclusions, true) ->
        true
      is_nil(pec) and Enum.member?(pec_diseases, diagnosis_procedure.diagnosis_id) ->
        true
      true ->
        false
    end
  end

  #TODO CHECK UNUSED FUNCTIONS
  defp compute_deductions_web(changeset) do
    diagnosis_ids = changeset.changes.diagnosis_id
    facility_id = changeset.changes.facility_id
    member_id = changeset.changes.member_id
    practitioner_id = changeset.changes.practitioner_id
    total_procedure_fee = changeset.changes.procedure_fee
    procedure_ids = changeset.changes.procedure_id

    test = for diagnosis_procedure <- changeset.changes.diagnosis_procedure do
      diagnosis_id = diagnosis_procedure.diagnosis_id
      procedure_id = diagnosis_procedure.procedure_id
      unit = diagnosis_procedure.unit

      member = MemberContext.get_a_member!(changeset.changes.member_id)
      member_products = for member_product <- member.products do
        member_product
      end
      product_tier = get_product_tier(member_products, changeset)
      tier = Enum.min(product_tier)

      if not is_nil(tier) do
        member_product =
        for member_product <- member_products do
          if member_product.tier == tier do
            member_product
          end
        end
        member_product =
          member_product
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()
        product = member_product.account_product.product

        op_lab = CoverageContext.get_coverage_by_name("OP Laboratory")
        product_coverage =
          ProductCoverage
          |> where([pc], pc.product_id == ^product.id and pc.coverage_id == ^op_lab.id)
          |> Repo.one
          |> Repo.preload([product_coverage_facilities: [facility: [facility_payor_procedures: [:facility_payor_procedure_rooms]]]])

        facility = Facility
                 |> where([f], f.id == ^facility_id)
                 |> Repo.one

        product_benefit = get_product_benefit(member_products, changeset, tier)
        benefit = Benefit |> Repo.get!(product_benefit.benefit_id) |> Repo.preload(benefit_procedures: :procedure)
        benefit_procedures =
          BenefitProcedure
          |> join(:inner, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
          |> where([bp], bp.benefit_id == ^benefit.id)
          |> order_by([bp, pp], pp.code)
          |> select([bp, pp], pp)
          |> Repo.all
          |> Repo.preload([facility_payor_procedures: :facility_payor_procedure_rooms])

        payor_procedures =
          FacilityPayorProcedure
          |> join(:inner, [fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
          |> where([fpp, pp], fpp.facility_id == ^facility.id)
          |> order_by([fpp, pp], pp.code)
          |> select([fpp, pp], pp)
          |> Repo.all
          |> Repo.preload([facility_payor_procedures: :facility_payor_procedure_rooms])
        procedure_checker = Enum.filter(benefit_procedures, &(Enum.member?(payor_procedures, &1)))

        covered_procedures = for pp <- procedure_checker do
          for fpp <- pp.facility_payor_procedures do
            for fppr <- fpp.facility_payor_procedure_rooms do
              fppr
            end
          end
        end

        covered_procedures =
          covered_procedures
          |> List.flatten

        dp_diagnosis_id = [diagnosis_id]
        dp_procedure_id = [procedure_id]

        case_rate =
          CaseRate
          |> where([cr], cr.diagnosis_id == ^diagnosis_id)
          |> select([cr], %{diagnosis: cr.diagnosis_id, hierarchy: cr.hierarchy, discount: cr.discount_percentage})
          |> Repo.all

        requested_diagnosis_case_rate =
         Enum.filter(case_rate, fn(x) ->
           Enum.member?(dp_diagnosis_id, x.diagnosis)
        end)

        requested_covered_procedures =
          Enum.filter(procedure_checker, fn(x) ->
            Enum.member?(dp_procedure_id, x.id)
        end)

        procedure_fee = FacilityPayorProcedureRoom
        |> join(:inner, [fppr], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
        |> join(:inner, [fppr, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
        |> where([fppr, fpp, pp], pp.id == ^procedure_id)
        |> select([fppr, fpp, pp], fppr.amount)
        |> Repo.all
        |> List.first()
        |> Decimal.mult(unit)

        total_procedure_amount =
              procedure_fee

        if Enum.empty?(requested_diagnosis_case_rate) == false do
        # TODO: find procedure in parameters based on diagnosis
        case_rate_procedure =
          for y <- requested_diagnosis_case_rate do
            if y.diagnosis == diagnosis_id do
              y =
                y
                |> Map.put(:procedure_id, procedure_id)
                |> Map.put(:unit, unit)
            end
          end
        added_procedure = Enum.filter(Enum.concat(case_rate_procedure), fn(x) -> x != nil end)

        xy = for x <- added_procedure do
          procedure_fees = FacilityPayorProcedureRoom
                      |> join(:inner, [fppr], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
                      |> join(:inner, [fppr, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
                      |> where([fppr, fpp, pp], pp.id == ^procedure_id)
                      |> select([fppr, fpp, pp], %{amount: fppr.amount, procedure_id: fpp.payor_procedure_id})
                      |> Repo.all
                      |> List.first()
          procedure_fees =
              procedure_fees
              |> Map.merge(%{unit: unit})

          procedure_fee = Decimal.mult(procedure_fees.amount, procedure_fees.unit)

          %{amount: procedure_fee, procedure_id: procedure_fees.procedure_id}
        end
        y = Enum.into(added_procedure, %{})

        b =
            for m <- xy do
              cond do
                y.discount == 100 and y.procedure_id == m.procedure_id ->
                  %{amount: m.amount, procedure_id: m.procedure_id, hierarchy: 1}
                y.discount == 50 and y.procedure_id == m.procedure_id ->
                  %{amount: Decimal.div(m.amount, Decimal.new(2)), procedure_id: m.procedure_id, hierarchy: 2}
                true ->
                  nil
              end
            end
          b =
            b
            |> Enum.uniq()
        amounts = Enum.filter(Enum.concat(b), fn(x) -> x != nil end)
        amounts = Enum.into(amounts, %{})

        philhealth_pays =
          if procedure_id == amounts.procedure_id do
            amounts
            |> Map.put_new(:philhealth_pays, amounts.amount)
            |> Map.put_new(:hierarchy, amounts.hierarchy)
          end

        x = philhealth_pays

        ph = if x.hierarchy == 1 do
          amount =
            x
            |> Map.drop([:procedure_id, :diagnosis_id, :hierarchy])
            |> Map.values()
            |> List.first()
          %{hierarchy: 1, amount: amount}
        else
          amount =
            x
            |> Map.drop([:procedure_id, :diagnosis_id, :hierarchy])
            |> Map.values()
            |> List.first()
          %{hierarchy: 2, amount: amount}
        end

        total_procedure_fee_case_rate =
          total_procedure_amount
          |> Decimal.sub(ph.amount)

        changeset =
          changeset
          |> Ecto.Changeset.put_change(:philhealth_pays, total_procedure_fee_case_rate)

        else
          changeset =
          changeset
          |> Ecto.Changeset.put_change(:philhealth_pays, Decimal.new(0))
        end

        pec = ProductContext.get_pec_op_lab(product.id, diagnosis_id, member.id)
        pec2 = ProductContext.get_pec_oplab(product.id, changeset.changes.diagnosis_id, member.id)

        pec =
        if is_nil(pec) do
          Decimal.new(0)
        else
          pec
          |> Decimal.new()
          |> percentage()
        end

        fpp = fpp(changeset, dp_procedure_id)

        procedure_fee = Decimal.sub(procedure_fee, changeset.changes.philhealth_pays)

        params = %{
          philhealth_pays: changeset.changes.philhealth_pays,
          diagnosis_id: diagnosis_id,
          procedure_id: procedure_id,
          product: product,
          facility_payor_procedure: fpp,
          pre_existing_condition: pec,
          pre_existing_condition_2: pec2,
          procedure_fee: procedure_fee,
          total_procedure_fee: total_procedure_fee,
          facility_id: facility_id,
          member_id: member_id,
          practitioner_id: practitioner_id,
          authorization_id: changeset.changes.authorization_id
        }

        params =
          params
          |> risk_share_checker_web()
          |> Map.merge(%{philhealth_pays: changeset.changes.philhealth_pays})
      else
        if not is_nil(changeset.changes.validated) and
        changeset.changes.validated == true do
           member = MemberContext.get_a_member!(changeset.changes.member_id)
           member_products = for member_product <- member.products do
            if not is_nil(member_product.loa_payor_pays) do
              member_product
            end
          end
          member_products =
            member_products
            |> Enum.uniq()
            |> List.delete(nil)
          payor_pays = for member_product <- member_products do
              member_product.loa_payor_pays
          end

          payor_max = Decimal.new(Enum.max(payor_pays))

          tier = for member_product <- member_products do
            if payor_max == member_product.loa_payor_pays do
              member_product.tier
            end
          end
          tier =
           tier
            |> Enum.uniq()
            |> List.delete(nil)

          tier = if Enum.count(tier) > 1 do
            Enum.min(tier)
          else
            Enum.at(tier, 0)
          end

          member_product = for member_product <- member_products do
            if member_product.tier == tier do
              member_product
            end
          end
          member_product =
            member_product
            |> Enum.uniq()
            |> List.delete(nil)
            |> List.first()
          product = member_product.account_product.product

          op_lab = CoverageContext.get_coverage_by_name("OP Laboratory")
        product_coverage =
          ProductCoverage
          |> where([pc], pc.product_id == ^product.id and pc.coverage_id == ^op_lab.id)
          |> Repo.one
          |> Repo.preload([product_coverage_facilities: [facility: [facility_payor_procedures: [:facility_payor_procedure_rooms]]]])

        facility = Facility
                 |> where([f], f.id == ^facility_id)
                 |> Repo.one

        product_benefit = get_product_benefit(member_products, changeset, tier)
        benefit = Benefit |> Repo.get!(product_benefit.benefit_id) |> Repo.preload(benefit_procedures: :procedure)
        benefit_procedures =
          BenefitProcedure
          |> join(:inner, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
          |> where([bp], bp.benefit_id == ^benefit.id)
          |> order_by([bp, pp], pp.code)
          |> select([bp, pp], pp)
          |> Repo.all
          |> Repo.preload([facility_payor_procedures: :facility_payor_procedure_rooms])

        payor_procedures =
          FacilityPayorProcedure
          |> join(:inner, [fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
          |> where([fpp, pp], fpp.facility_id == ^facility.id)
          |> order_by([fpp, pp], pp.code)
          |> select([fpp, pp], pp)
          |> Repo.all
          |> Repo.preload([facility_payor_procedures: :facility_payor_procedure_rooms])
        procedure_checker = Enum.filter(benefit_procedures, &(Enum.member?(payor_procedures, &1)))

        covered_procedures = for pp <- procedure_checker do
          for fpp <- pp.facility_payor_procedures do
            for fppr <- fpp.facility_payor_procedure_rooms do
              fppr
            end
          end
        end

        covered_procedures =
          covered_procedures
          |> List.flatten

        dp_diagnosis_id = [diagnosis_id]
        dp_procedure_id = [procedure_id]

        case_rate =
          CaseRate
          |> where([cr], cr.diagnosis_id == ^diagnosis_id)
          |> select([cr], %{diagnosis: cr.diagnosis_id, hierarchy: cr.hierarchy, discount: cr.discount_percentage})
          |> Repo.all

        requested_diagnosis_case_rate =
         Enum.filter(case_rate, fn(x) ->
           Enum.member?(dp_diagnosis_id, x.diagnosis)
        end)

        requested_covered_procedures =
          Enum.filter(procedure_checker, fn(x) ->
            Enum.member?(dp_procedure_id, x.id)
        end)

        procedure_fee = FacilityPayorProcedureRoom
        |> join(:inner, [fppr], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
        |> join(:inner, [fppr, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
        |> where([fppr, fpp, pp], pp.id == ^procedure_id)
        |> select([fppr, fpp, pp], fppr.amount)
        |> Repo.all
        |> List.first()
        |> Decimal.mult(unit)

        total_procedure_amount =
              procedure_fee

        if Enum.empty?(requested_diagnosis_case_rate) == false do
        # TODO: find procedure in parameters based on diagnosis
        case_rate_procedure =
          for y <- requested_diagnosis_case_rate do
            if y.diagnosis == diagnosis_id do
              y =
                y
                |> Map.put(:procedure_id, procedure_id)
                |> Map.put(:unit, unit)
            end
          end
        added_procedure = Enum.filter(Enum.concat(case_rate_procedure), fn(x) -> x != nil end)

        xy = for x <- added_procedure do
          procedure_fees = FacilityPayorProcedureRoom
                      |> join(:inner, [fppr], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
                      |> join(:inner, [fppr, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
                      |> where([fppr, fpp, pp], pp.id == ^procedure_id)
                      |> select([fppr, fpp, pp], %{amount: fppr.amount, procedure_id: fpp.payor_procedure_id})
                      |> Repo.all
                      |> List.first()
          procedure_fees =
              procedure_fees
              |> Map.merge(%{unit: unit})

          procedure_fee = Decimal.mult(procedure_fees.amount, procedure_fees.unit)

          %{amount: procedure_fee, procedure_id: procedure_fees.procedure_id}
        end
        y = Enum.into(added_procedure, %{})

        b =
            for m <- xy do
              cond do
                y.discount == 100 and y.procedure_id == m.procedure_id ->
                  %{amount: m.amount, procedure_id: m.procedure_id, hierarchy: 1}
                y.discount == 50 and y.procedure_id == m.procedure_id ->
                  %{amount: Decimal.div(m.amount, Decimal.new(2)), procedure_id: m.procedure_id, hierarchy: 2}
                true ->
                  nil
              end
            end
          b =
            b
            |> Enum.uniq()
        amounts = Enum.filter(Enum.concat(b), fn(x) -> x != nil end)
        amounts = Enum.into(amounts, %{})

        philhealth_pays =
          if procedure_id == amounts.procedure_id do
            amounts
            |> Map.put_new(:philhealth_pays, amounts.amount)
            |> Map.put_new(:hierarchy, amounts.hierarchy)
          end

        x = philhealth_pays

        ph = if x.hierarchy == 1 do
          amount =
            x
            |> Map.drop([:procedure_id, :diagnosis_id, :hierarchy])
            |> Map.values()
            |> List.first()
          %{hierarchy: 1, amount: amount}
        else
          amount =
            x
            |> Map.drop([:procedure_id, :diagnosis_id, :hierarchy])
            |> Map.values()
            |> List.first()
          %{hierarchy: 2, amount: amount}
        end

        total_procedure_fee_case_rate =
          total_procedure_amount
          |> Decimal.sub(ph.amount)

        changeset =
          changeset
          |> Ecto.Changeset.put_change(:philhealth_pays, total_procedure_fee_case_rate)

        else
          changeset =
          changeset
          |> Ecto.Changeset.put_change(:philhealth_pays, Decimal.new(0))
        end

        pec = ProductContext.get_pec_op_lab(product.id, diagnosis_id, member.id)
        pec2 = ProductContext.get_pec_oplab(product.id, changeset.changes.diagnosis_id, member.id)

        pec =
        if is_nil(pec) do
          Decimal.new(0)
        else
          pec
          |> Decimal.new()
          |> percentage()
        end

        fpp = fpp(changeset, dp_procedure_id)

        procedure_fee = Decimal.sub(procedure_fee, changeset.changes.philhealth_pays)

        params = %{
          philhealth_pays: changeset.changes.philhealth_pays,
          diagnosis_id: diagnosis_id,
          procedure_id: procedure_id,
          product: product,
          facility_payor_procedure: fpp,
          pre_existing_condition: pec,
          pre_existing_condition_2: pec2,
          procedure_fee: procedure_fee,
          total_procedure_fee: total_procedure_fee,
          facility_id: facility_id,
          member_id: member_id,
          practitioner_id: practitioner_id,
          authorization_id: changeset.changes.authorization_id
        }

        params =
          params
          |> risk_share_checker_web()
          |> Map.merge(%{philhealth_pays: changeset.changes.philhealth_pays})
        end
      end
    end
    test =
      test
      |> Enum.reject(&(is_nil(&1)))
      |> List.flatten()

    member_pays = for x <- test do
      member_pays =
        x.member
    end
    member_pays =
      member_pays
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    payor_pays = for x <- test do
      payor_pays =
        x.payor
    end
    payor_pays =
      payor_pays
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    philhealth_pays = for x <- test do
      philhealth_pays =
        x.philhealth_pays
    end
    philhealth_pays =
      philhealth_pays
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    changeset =
      changeset
      |> Ecto.Changeset.put_change(:philhealth_pays, philhealth_pays)
      |> Ecto.Changeset.put_change(:payor_pays, payor_pays)
      |> Ecto.Changeset.put_change(:member_pays, member_pays)

  end

  defp risk_share_checker_web(params) do
    philhealth_pays = params.philhealth_pays
    diagnosis_id = params.diagnosis_id
    procedure_id = params.procedure_id
    product = params.product
    fpp = params.facility_payor_procedure
    pec = params.pre_existing_condition
    pec2 = params.pre_existing_condition_2
    procedure_fee = params.procedure_fee
    total_procedure_fee = params.total_procedure_fee
    facility_id = params.facility_id
    member_id = params.member_id
    practitioner_id = params.practitioner_id
    authorization_id = params.authorization_id

    dmp_coverage_id = get_dmp_coverage_id(member_id)
    dmp_coverage_id =
      dmp_coverage_id
      |> list_flattens_first()

    facility_payor_procedure_id = FacilityPayorProcedure
      |> where([fpp], fpp.payor_procedure_id == ^procedure_id and fpp.facility_id == ^facility_id)
      |> select([fpp], fpp.id)
      |> Repo.all()

    facility_payor_procedure_id =
      facility_payor_procedure_id
      |> list_flattens_first()

    dmpc_risk_share_id = if is_nil(dmp_coverage_id) do
      dmpc_risk_share_id = [nil]
    else
      dmpc_risk_share_id = ProductCoverageRiskShare
      |> where([pcr], pcr.product_coverage_id == ^dmp_coverage_id)
      |> select([pcr], pcr.id)
      |> Repo.all()
    end

    dmpc_risk_share_id =
      dmpc_risk_share_id
      |> list_flattens_first()

    dmpcrk_facility_id = if is_nil(dmpc_risk_share_id) do
      dmpcrk_facility_id = [nil]
    else
      dmpcrk_facility_id = ProductCoverageRiskShareFacility
        |> where([pcrf], pcrf.product_coverage_risk_share_id == ^dmpc_risk_share_id and pcrf.facility_id == ^facility_id)
        |> select([pcrf], pcrf.id)
        |> Repo.all()
    end

    dmpcrk_facility_id =
      dmpcrk_facility_id
      |> list_flattens_first()

    dmpcrkf_procedure_id = if is_nil(dmpcrk_facility_id) do
      dmpcrkf_procedure_id = [nil]
    else
      dmpcrkf_procedure_id = ProductCoverageRiskShareFacilityPayorProcedure
        |> where([pcrfp], pcrfp.product_coverage_risk_share_facility_id == ^dmpcrk_facility_id and pcrfp.facility_payor_procedure_id == ^facility_payor_procedure_id)
        |> select([pcrfp], pcrfp.id)
        |> Repo.all()
    end

    dmpcrkf_procedure_id =
      dmpcrkf_procedure_id
      |> list_flattens_first()

    if not is_nil(dmpcrkf_procedure_id) do

      dmpcrkf_procedure = ProductCoverageRiskShareFacilityPayorProcedure
      |> where([pcrfp], pcrfp.product_coverage_risk_share_facility_id == ^dmpcrk_facility_id and pcrfp.facility_payor_procedure_id == ^facility_payor_procedure_id)
      |> Repo.all()

      dmpcrkf_procedure =
        dmpcrkf_procedure
        |> list_flattens_first()

      params =  %{
        procedure_fee: procedure_fee,
        covered_percentage: dmpcrkf_procedure.covered,
        type: dmpcrkf_procedure.type,
        copayment_val: dmpcrkf_procedure.value_amount,
        coinsurance_val: dmpcrkf_procedure.value_percentage,
        value: dmpcrkf_procedure.value,
        total_procedure_fee: total_procedure_fee,
        pec: pec,
        authorization_id: authorization_id,
        procedure_id: procedure_id,
        diagnosis_id: diagnosis_id,
        setup: "Procedure"
      }

      compute_laboratory(params)
    else
      if not is_nil(dmpcrk_facility_id) do

        dmpcrk_facility = ProductCoverageRiskShareFacility
          |> where([pcrf], pcrf.product_coverage_risk_share_id == ^dmpc_risk_share_id and pcrf.facility_id == ^facility_id)
          |> Repo.all()

          dmpcrk_facility =
            dmpcrk_facility
            |> list_flattens_first()

          params =  %{
            procedure_fee: procedure_fee,
            covered_percentage: dmpcrk_facility.covered,
            type: dmpcrk_facility.type,
            copayment_val: dmpcrk_facility.value_amount,
            coinsurance_val: dmpcrk_facility.value_percentage,
            value: dmpcrk_facility.value,
            total_procedure_fee: total_procedure_fee,
            pec: pec,
            authorization_id: authorization_id,
            procedure_id: procedure_id,
            diagnosis_id: diagnosis_id,
            setup: "Facility"

          }

          compute_laboratory(params)
      else
        if not is_nil(dmpc_risk_share_id) do
          dmpc_risk_share = ProductCoverageRiskShare
            |> where([pcr], pcr.product_coverage_id == ^dmp_coverage_id)
            |> Repo.all()

          dmpc_risk_share =
            dmpc_risk_share
            |> list_flattens_first()

          if dmpc_risk_share.af_type == "Copayment" do
            params =  %{
                procedure_fee: procedure_fee,
                covered_percentage: dmpc_risk_share.af_covered_amount,
                type: dmpc_risk_share.af_type,
                copayment_val: dmpc_risk_share.af_value_amount,
                coinsurance_val: dmpc_risk_share.af_value_percentage,
                value: dmpc_risk_share.af_value,
                total_procedure_fee: total_procedure_fee,
                pec: pec,
                authorization_id: authorization_id,
                procedure_id: procedure_id,
                diagnosis_id: diagnosis_id,
                setup: "Coverage"
              }

            compute_laboratory(params)
          else
            params =  %{
              procedure_fee: procedure_fee,
              covered_percentage: dmpc_risk_share.af_covered_percentage,
              type: dmpc_risk_share.af_type,
              copayment_val: dmpc_risk_share.af_value_amount,
              coinsurance_val: dmpc_risk_share.af_value_percentage,
              value: dmpc_risk_share.af_value,
              total_procedure_fee: total_procedure_fee,
              pec: pec,
              authorization_id: authorization_id,
              procedure_id: procedure_id,
              diagnosis_id: diagnosis_id,
              setup: "Coverage"
            }

            compute_laboratory(params)
          end
        else
          %{payor: Decimal.new(0), member: Decimal.new(procedure_fee)}
        end
      end
    end
  end

  defp list_flattens_first(value) do
    value =
      value
      |> List.flatten()
      |> List.first()
  end

  defp compute_laboratory_ruv(params) do
    risk_share_type = params.type
    procedure_fee = risk_share_value(params.procedure_fee)
    coinsurance = risk_share_value(params.coinsurance_val)
    copayment = risk_share_value(params.copayment_val)
    value = risk_share_value(params.value)
    covered_percentage = risk_share_value(params.covered_percentage)
    pec = params.pec
    risk_share_setup = params.setup
    divider = Decimal.new(100)

    if Decimal.to_float(coinsurance) != Decimal.to_float(Decimal.new(0)) do
      risk_share_amount = coinsurance
    else
      risk_share_amount = copayment
    end

    #UPDATE AUTHORIZATION PROCEDURE DIAGNOSIS RISK SHARE

    if Decimal.to_float(pec) == Decimal.to_float(Decimal.new(0)) do
      percent = Decimal.div(covered_percentage, divider)
      percent_decimal = percent
    else
      pre_existing_percentage = Decimal.div(pec, divider)
    end

    if risk_share_type == "Copayment" do
      if Decimal.to_float(pec) > Decimal.to_float(Decimal.new(0)) do
        copayment_amount = Decimal.sub(procedure_fee, copayment)
        covered_percentage = Decimal.div(covered_percentage, divider)
        payor_copay = if Decimal.to_float(copayment) > Decimal.to_float(procedure_fee) do
          Decimal.new(0)
        else
          Decimal.sub(procedure_fee, copayment)
        end
        payor_copay_pec = Decimal.mult(payor_copay, covered_percentage)
        payor = Decimal.mult(payor_copay_pec, pre_existing_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      else
        copayment_amount = Decimal.sub(procedure_fee, copayment)
        covered_percentage = Decimal.div(covered_percentage, divider)
        payor_copay = if Decimal.to_float(copayment) > Decimal.to_float(procedure_fee) do
          Decimal.new(0)
        else
          Decimal.sub(procedure_fee, copayment)
        end
        payor = Decimal.mult(payor_copay, covered_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      end
    else
      if Decimal.to_float(pec) > Decimal.to_float(Decimal.new(0)) do
        coinsurance_percentage =
          Decimal.div(Decimal.new(coinsurance), divider)
        payor_coinsurance =
          Decimal.mult(coinsurance_percentage, procedure_fee)
        coinsurance_covered_percentage =
          Decimal.div(Decimal.new(covered_percentage), divider)
        payor_coinsurance_pec =
          Decimal.mult(payor_coinsurance, coinsurance_covered_percentage)
        payor = Decimal.mult(payor_coinsurance_pec, pre_existing_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      else
        coinsurance_percentage =
          Decimal.div(Decimal.new(coinsurance), divider)
        payor_coinsurance =
          Decimal.mult(coinsurance_percentage, procedure_fee)

        test =
          Decimal.sub(procedure_fee, payor_coinsurance)
        coinsurance_covered_percentage =
              Decimal.div(Decimal.new(covered_percentage), divider)
        payor = Decimal.mult(test,
                               coinsurance_covered_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      end
    end

    update_params = %{
      risk_share_type: risk_share_type,
      risk_share_setup: risk_share_setup,
      risk_share_amount: risk_share_amount,
      percentage_covered: covered_percentage,
      pec: pec,
      philhealth_pay: params.philhealth_pays,
      member_product_id: params.member_product_id,
      payor_pay: Decimal.new(payor),
      member_pay: Decimal.new(member)
    }

    params.authorization_id
    |> AuthorizationContext.get_authorization_ruv(params.ruv_id)
    |> AuthorizationContext.update_authorization_ruv(update_params)
    %{payor: Decimal.new(payor), member: Decimal.new(member)}
  end

  defp compute_laboratory(params) do
    risk_share_type = params.type
    procedure_fee = risk_share_value(params.procedure_fee)
    coinsurance = risk_share_value(params.coinsurance_val)
    copayment = risk_share_value(params.copayment_val)
    value = risk_share_value(params.value)
    covered_percentage = risk_share_value(params.covered_percentage)
    pec = params.pec
    risk_share_setup = params.setup
    divider = Decimal.new(100)

    if coinsurance != Decimal.new(0) do
      risk_share_amount = coinsurance
    else
      risk_share_amount = copayment
    end

    update_params = %{
      risk_share_type: risk_share_type,
      risk_share_setup: risk_share_setup,
      risk_share_amount: risk_share_amount,
      percentage_covered: covered_percentage,
      pec: pec,
      philhealth_pay: params.philhealth_pays,
      member_product_id: params.member_product_id
    }

    params.authorization_id
    |> AuthorizationContext.get_authorization_procedure_diagnosis_by_ids(params.procedure_id, params.diagnosis_id)
    |> AuthorizationContext.update_authorization_procedure_diagnosis(update_params)

    #UPDATE AUTHORIZATION PROCEDURE DIAGNOSIS RISK SHARE
    if Decimal.to_float(pec) == Decimal.to_float(Decimal.new(0)) do
      percent = Decimal.div(covered_percentage, divider)
      percent_decimal = percent
    else
      pre_existing_percentage = Decimal.div(pec, divider)
    end

    if risk_share_type == "Copayment" do
      if Decimal.to_float(pec) > Decimal.to_float(Decimal.new(0)) do
        copayment_amount = Decimal.sub(procedure_fee, copayment)
        covered_percentage = Decimal.div(covered_percentage, divider)
        payor_copay = if Decimal.to_float(copayment) > Decimal.to_float(procedure_fee) do
          Decimal.new(0)
        else
          Decimal.sub(procedure_fee, copayment)
        end
        payor_copay_pec = Decimal.mult(payor_copay, covered_percentage)
        payor = Decimal.mult(payor_copay_pec, pre_existing_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      else
        copayment_amount = Decimal.sub(procedure_fee, copayment)
        covered_percentage = Decimal.div(covered_percentage, divider)
        payor_copay = if Decimal.to_float(copayment) > Decimal.to_float(procedure_fee) do
          Decimal.new(0)
        else
          Decimal.sub(procedure_fee, copayment)
        end
        payor = Decimal.mult(payor_copay, covered_percentage)
        if payor == Decimal.new(0) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      end
    else
      if Decimal.to_float(pec) > Decimal.to_float(Decimal.new(0)) do
        coinsurance_percentage =
          Decimal.div(Decimal.new(coinsurance), divider)
        payor_coinsurance =
          Decimal.mult(coinsurance_percentage, procedure_fee)
        coinsurance_covered_percentage =
          Decimal.div(Decimal.new(covered_percentage), divider)
        payor_coinsurance_pec =
          Decimal.mult(payor_coinsurance, coinsurance_covered_percentage)
        payor = Decimal.mult(payor_coinsurance_pec, pre_existing_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      else
        coinsurance_percentage =
          Decimal.div(Decimal.new(coinsurance), divider)
        payor_coinsurance =
          Decimal.mult(coinsurance_percentage, procedure_fee)

        test =
          Decimal.sub(procedure_fee, payor_coinsurance)
        coinsurance_covered_percentage =
              Decimal.div(Decimal.new(covered_percentage), divider)
        payor = Decimal.mult(test,
                               coinsurance_covered_percentage)
        if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
          member = procedure_fee
        else
          member = Decimal.sub(procedure_fee, payor)
        end
      end
    end

    %{payor: Decimal.new(payor), member: Decimal.new(member)}

  end

  defp risk_share_value(data) do
    if is_nil(data) do
      Decimal.new(0)
    else
      Decimal.new(data)
    end
  end

  defp get_dmp_coverage_id(member_id) do
    dm_product_id =
      MemberProduct
      |> join(:inner, [mp], ac in AccountProduct, mp.account_product_id == ac.id)
      |> join(:inner, [mp, ac], p in Product, ac.product_id == p.id)
      |> where([mp, ac, p], mp.member_id == ^member_id)
      |> select([mp, ac, p], p.id)
      |> Repo.all()
    dmp_coverage_id = for id <- dm_product_id do
      ProductCoverage
      |> join(:inner, [pc], c in Coverage, pc.coverage_id == c.id)
      |> where([pc, c], pc.product_id == ^id and c.code == ^"OPL")
      |> select([pc, c], pc.id)
      |> Repo.all()
    end
  end

  defp compute_balance_web(changeset) do
    member = MemberContext.get_a_member!(changeset.changes.member_id)
    member_products = for member_product <- member.products do
      member_product
    end

    product_tier = get_product_tier(member_products, changeset)
    product_tier =
      product_tier
      |> List.delete(nil)
    tier = Enum.min(product_tier)
    if not is_nil(tier) do
      product_benefit = get_product_benefit(member_products, changeset, tier)

      member_product = for member_product <- member_products do
        if member_product.tier == tier do
          member_product
        end
      end

      member_product =
        member_product
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()

      product = member_product.account_product.product
      pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)
      payor = Decimal.new(changeset.changes.payor_pays)
      benefit_limit = Decimal.sub(pb.limit_amount, payor)
      product_limit = Decimal.sub(product.limit_amount, payor)

      MemberContext.update_member_product_payor_pays(member_product,%{loa_payor_pays: Decimal.new(Decimal.to_float(payor))})
      changeset =
        changeset
        |> put_changeset(:benefit_limit, benefit_limit)
        |> put_changeset(:product_limit, product_limit)
    else
      if not is_nil(changeset.changes.validated) and changeset.changes.validated == true do
        member = MemberContext.get_a_member!(changeset.changes.member_id)
        member_products = for member_product <- member.products do
          if not is_nil(member_product.loa_payor_pays) do
            member_product
          end
        end
        member_products =
          member_products
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.flatten()

        payor_pays = for member_product <- member_products do
          member_product.loa_payor_pays
        end

        payor_max = Decimal.new(Enum.max(payor_pays))

        tier = for member_product <- member_products do
          if payor_max == member_product.loa_payor_pays do
            member_product.tier
          end
        end
        tier =
          tier
          |> Enum.uniq()
          |> List.delete(nil)

        tier = if Enum.count(tier) > 1 do
          Enum.min(tier)
        else
          Enum.at(tier, 0)
        end

        product_benefit = get_product_benefit(member_products, changeset, tier)

        member_product = for member_product <- member_products do
          if member_product.tier == tier do
            member_product
          end
        end
        member_product =
          member_product
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()
        product = member_product.account_product.product

        pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)
        payor = Decimal.new(changeset.changes.payor_pays)
        benefit_limit = Decimal.sub(pb.limit_amount, payor)
        product_limit = Decimal.sub(product.limit_amount, payor)
        changeset =
          changeset
          |> put_changeset(:benefit_limit, benefit_limit)
          |> put_changeset(:product_limit, product_limit)
      else
        changeset
      end
    end
  end

  defp process_web(changeset) do

    benefit_balance = changeset.changes.benefit_limit
    product_balance = changeset.changes.product_limit
    payor_pays = changeset.changes.payor_pays
    member_pays = changeset.changes.member_pays
    philhealth_pays = changeset.changes.philhealth_pays

    facility_id = changeset.changes.facility_id
    member_id = changeset.changes.member_id
    coverage_id = AuthorizationContext.get_op_lab_coverage_id()

    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)

    # FOR RISK SHARE SETUP
    member = MemberContext.get_a_member!(changeset.changes.member_id)
    member_products = for member_product <- member.products do
      if not is_nil(member_product.loa_payor_pays) do
        member_product
      end
    end
    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()
    loa_payor_pays = for member_product <- member_products do
      member_product.loa_payor_pays
    end

    loa_payor_pays = for loa_payor_pay <- loa_payor_pays do
      Decimal.to_float(loa_payor_pay)
    end

    ########################----------------------------

    if loa_payor_pays == [] do
    else
      payor_max = Decimal.new(Enum.max(loa_payor_pays))
      tier = for member_product <- member_products do
      if Decimal.equal?(payor_max, member_product.loa_payor_pays) do
        member_product.tier
        end
      end
      tier =
        tier
        |> Enum.uniq()
        |> List.delete(nil)

      tier = if Enum.count(tier) > 1 do
        Enum.min(tier)
      else
        Enum.at(tier, 0)
      end

      product_benefit = get_product_benefit(member_products, changeset, tier)
      member_product = get_member_products(tier, member_products)
      product = member_product.account_product.product

      pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)

      pec = ProductContext.get_pec_op_lab(product.id,
                                   List.first(changeset.changes.diagnosis_id), member.id)
      pec = if is_nil(pec) do
        Decimal.new(0)
      else
        Decimal.new(pec)
      end
      pec = Decimal.to_integer(pec)

      params = %{
              "authorization_id" => authorization.id,
              "chief_complaint" => changeset.changes.chief_complaint,
              "total_amount" => changeset.changes.procedure_fee,
              "member_covered" => member_pays,
              "payor_covered" => payor_pays,
              "member_id" => changeset.changes.member_id,
              "facility_id" => changeset.changes.facility_id,
              "practitioner_id" => changeset.changes.practitioner_id,
              "coverage" => coverage_id,
              "product_id" => product.id,
              "limit_amount" => changeset.changes.product_limit,
              "benefit_limit" => changeset.changes.benefit_limit,
              "admission_datetime" => changeset.changes.admission_datetime,
              "request_date" => Ecto.Date.utc(),
              "company_covered" => philhealth_pays,
              "user_id" => changeset.changes.user_id
      }

      with {:ok, authorization} <-
          AuthorizationContext.modify_authorization_laboratory_step4(authorization,
                              params, changeset.changes.user_id)
        do
          params = Map.put_new(params,"authorization_id", authorization.id)
          AuthorizationContext.create_authorization_amount(params,
                                                changeset.changes.user_id)
          AuthorizationContext.create_authorization_practitioner(params,
                                                changeset.changes.user_id)

          if changeset.valid? do
            changeset =
              changeset
              |> put_changeset(:authorization_id, authorization.id)
              {:ok, changeset}
          end
        end
    end

  end

   # 1 - Get limit of the member
  defp compute_balance(changeset) do
    member = MemberContext.get_a_member!(changeset.changes.member_id)
    member_products = for member_product <- member.products do
      member_product
    end

    product_tier = get_product_tier(member_products, changeset)
    tier = Enum.min(product_tier)
    if not is_nil(tier) do
      product_benefit = get_product_benefit(member_products, changeset, tier)

      member_product = for member_product <- member_products do
        if member_product.tier == tier do
          member_product
        end
      end

      member_product =
        member_product
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()

      product = member_product.account_product.product
      pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)
      payor = Decimal.new(changeset.changes.payor_pays)
      benefit_limit = Decimal.sub(pb.limit_amount, payor)
      product_limit = Decimal.sub(product.limit_amount, payor)

      MemberContext.update_member_product_payor_pays(member_product,%{loa_payor_pays: Decimal.new(Decimal.to_float(payor))})
      changeset =
        changeset
        |> put_changeset(:benefit_limit, benefit_limit)
        |> put_changeset(:product_limit, product_limit)
    else
      if not is_nil(changeset.changes.validated) and changeset.changes.validated == true do
        member = MemberContext.get_a_member!(changeset.changes.member_id)
        member_products = for member_product <- member.products do
          if not is_nil(member_product.loa_payor_pays) do
            member_product
          end
        end
        member_products =
          member_products
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.flatten()

        payor_pays = for member_product <- member_products do
          member_product.loa_payor_pays
        end

        payor_max = Decimal.new(Enum.max(payor_pays))

        tier = for member_product <- member_products do
          if payor_max == member_product.loa_payor_pays do
            member_product.tier
          end
        end
        tier =
          tier
          |> Enum.uniq()
          |> List.delete(nil)

        tier = if Enum.count(tier) > 1 do
          Enum.min(tier)
        else
          Enum.at(tier, 0)
        end

        product_benefit = get_product_benefit(member_products, changeset, tier)

        member_product = for member_product <- member_products do
          if member_product.tier == tier do
            member_product
          end
        end
        member_product =
          member_product
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()
        product = member_product.account_product.product

        pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)
        payor = Decimal.new(changeset.changes.payor_pays)
        benefit_limit = Decimal.sub(pb.limit_amount, payor)
        product_limit = Decimal.sub(product.limit_amount, payor)
        changeset =
          changeset
          |> put_changeset(:benefit_limit, benefit_limit)
          |> put_changeset(:product_limit, product_limit)
      else
        changeset
      end
    end
  end

  defp procedure_amount(procedure_id) do
    FacilityPayorProcedureRoom
    |> join(:inner, [fppr], fpp in FacilityPayorProcedure, fppr.facility_payor_procedure_id == fpp.id)
    |> join(:inner, [fppr, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
    |> where([fppr, fpp, pp], pp.id  == ^procedure_id)
    |> select([fppr, fpp, pp], fppr.amount)
    |> Repo.one
  end

  defp put_changeset(changeset, key, value) do
    Ecto.Changeset.put_change(changeset, key, value)
  end

  defp get_product_tier(member_products, changeset) do
    for member_product <- member_products do
      product = member_product.account_product.product
      pbs = for pbs <- product.product_benefits do
        for bc <- pbs.benefit.benefit_coverages do
          if bc.coverage.code == "OPL" do
            pbs
          end
        end
      end
      pbs =
        pbs
        |> Enum.uniq()
        |> List.delete([nil])
        |> List.flatten()
      product_benefit =
        for pb <- pbs do
          pb
        end
      product_benefit =
        product_benefit
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()
        |> List.first()
      if not is_nil(product_benefit) and product.step >= "7" and
      not is_nil(product.limit_amount) and product.limit_amount > 0 and
      is_nil(member_product.loa_payor_pays) do
        member_product.tier
      end
    end
  end

  defp get_product_benefit(member_products, changeset, tier) do
    product_benefit =
      for member_product <- member_products do
        if member_product.tier == tier do
          product = member_product.account_product.product

          pbs =
            for pbs <- product.product_benefits do
              for bc <- pbs.benefit.benefit_coverages do
                if bc.coverage.code == "OPL" do
                  pbs
                end
              end
            end
          pbs =
            pbs
            |> Enum.uniq()
            |> List.delete([nil])
            |> List.flatten()
          product_benefit =
            for pb <- pbs do
              pb
            end
        end
      end
      product_benefit
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end

  defp get_tier_without_diagnosis(member_products) do
    tier = for member_product <- member_products do
        member_product.tier
    end
    tier =
      tier
      |> Enum.uniq()
      |> List.delete(nil)

    tier = if Enum.count(tier) > 1 do
      Enum.min(tier)
    else
      Enum.at(tier, 0)
    end
  end

  defp get_member_products(tier, member_products) do
    member_product = for member_product <- member_products do
        if member_product.tier == tier do
          member_product
        end
      end
    member_product =
      member_product
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end

  def sum_list([]) do
    0
  end

  def sum_list([h|t]) do
    r =
      t
      |> sum_list()
      |> Decimal.new()
    Decimal.add(h, r)
  end

  def percentage(p) do
    p
    |> Decimal.new()
    |> Decimal.div(Decimal.new(100))
  end

  def risk_share_procedure(changeset, pec, fpp, phil, pec2) do
    dmp_coverage_id = risk_share(changeset)
    dmpc_risk_share_id = for id <- dmp_coverage_id do
      ProductCoverageRiskShare
      |> where([pcr], pcr.product_coverage_id in ^id)
      |> select([pcr], pcr.id)
      |> Repo.all()
    end
    dmpcrk_facility_id = for id <- dmpc_risk_share_id do
      ProductCoverageRiskShareFacility
      |> where([pcrf], pcrf.product_coverage_risk_share_id in ^id and pcrf.facility_id == ^changeset.changes.facility_id)
      |> select([pcrf], pcrf.id)
      |> Repo.all()
    end
    dmpcrkf_procedure_id = for id <- dmpcrk_facility_id do
      ProductCoverageRiskShareFacilityPayorProcedure
      |> where([pcrfp], pcrfp.product_coverage_risk_share_facility_id in ^id)
      |> select([pcrfp], pcrfp.id)
      |> Repo.all()
    end
    dmpcrkf_procedure_id =
      dmpcrkf_procedure_id
      |> List.flatten()

    prs_amount = for fpp <- fpp do
      for p <- phil do
        if p.procedure_id == fpp.payor_procedure.id do
          total_pays =
            for d <- fpp.facility_payor_procedure_rooms do
              d.amount
            end
            |> List.first()
            |> Decimal.sub(p.philhealth_pays)
          total_pays = %{
            amount: total_pays,
            id: fpp.payor_procedure.id,
            d_id: p.diagnosis_id
          }
        end
      end
    end

    prs_amount =
      prs_amount
      |> List.flatten()
      |> Enum.reject(&(is_nil(&1) or Decimal.new(0) <= &1))

    rsp_data = for id <- dmpcrkf_procedure_id do
      data =
        ProductCoverageRiskShareFacilityPayorProcedure
        |> join(:inner, [pcrfp], fpp in FacilityPayorProcedure, pcrfp.facility_payor_procedure_id == fpp.id)
        |> join(:inner, [pcrfp, fpp], pp in PayorProcedure, fpp.payor_procedure_id == pp.id)
        |> where([pcrfp, fpp, pp], pcrfp.id == ^id and pp.id in ^changeset.changes.procedure_id and pcrfp.type == ^"Copayment")
        |> select([pcrfp,fpp, pp], %{id:  pcrfp.id, amount: pcrfp.value_amount, covered: pcrfp.covered, pp_id: pp.id})
        |> Repo.all()
    end

    payor_pays = for d <-  rsp_data |> List.flatten()  do
      for d2 <- prs_amount do
        if d2.id == d.pp_id do
          pec_d = for p <- pec2 do
            if p.d_id == d2.d_id do
             p.discount
            end
          end
          |> Enum.reject(&(is_nil(&1) or Decimal.new(0) <= &1))
          |> List.first()

          case pec_d do
            nil ->
              d2.amount
              |> Decimal.sub(d.amount)
              |> Decimal.mult(percentage(d.covered))
            _ ->
              d2.amount
              |> Decimal.sub(d.amount)
              |> Decimal.mult(pec_d)
          end
        end
      end
    end
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1) or Decimal.new(0) == &1))
    |> sum_list()
    |> Decimal.new()

    pec_count = for d <-  rsp_data |> List.flatten()  do
      for d2 <- prs_amount do
        if d2.id == d.pp_id do
          pec_d = for p <- pec2 do
            if p.d_id == d2.d_id do
             p.discount
            end
          end
          |> Enum.reject(&(is_nil(&1)))
          |> List.first()
        end
      end
    end
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1)))
    |> List.first()

    tamount = for p <- phil do
      p.philhealth_pays
    end
    |> sum_list()

    #    member_pays =
    #      changeset.changes.procedure_fee
    #      |> Decimal.sub(tamount)
    #      |> Decimal.sub(payor_pays)

    member_pays = for d <-  rsp_data |> List.flatten()  do
      for d2 <- prs_amount do
          d2.amount
      end
    end
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1) or Decimal.new(0) == &1))
    |> sum_list()
    |> Decimal.new()
    |> Decimal.sub(payor_pays)

    changeset =
      changeset
      |> Ecto.Changeset.put_change(:payor_pays, payor_pays)
      |> Ecto.Changeset.put_change(:member_pays, member_pays)
      |> Ecto.Changeset.put_change(:philhealth_pays, phil)
      |> Ecto.Changeset.put_change(:pec, pec_count)
  end

  def risk_share_facility(changeset, pec, fpp, phil) do
    dmp_coverage_id = risk_share(changeset)
    dmpc_risk_share_id = for id <- dmp_coverage_id do
      ProductCoverageRiskShare
      |> where([pcr], pcr.product_coverage_id in ^id)
      |> select([pcr], pcr.id)
      |> Repo.all()
    end
    dmpcrk_facility_id = for id <- dmpc_risk_share_id do
      ProductCoverageRiskShareFacility
      |> where([pcrf], pcrf.product_coverage_risk_share_id in ^id and pcrf.facility_id == ^changeset.changes.facility_id)
      |> select([pcrf], pcrf)
      |> Repo.all()
    end
    |> List.flatten()
    |> List.first()

    tamount = for fpp <- fpp do
      for d <- fpp.facility_payor_procedure_rooms do
        d.amount
      end
    end
    |> List.flatten()
    |> sum_list()

    damount = for p <- phil do
      p.philhealth_pays
    end
    |> sum_list()

    frs_amount =
      tamount
      |> Decimal.sub(damount)
      |> Decimal.sub(check_pays(changeset.changes))

    if Map.has_key?(changeset.changes, :pec) do
      pec = nil
    else
      changeset =
        changeset
        |> Ecto.Changeset.put_change(:pec, "1")
    end

    payor_pays = case pec do
      nil ->
        frs_amount
        |> Decimal.sub(dmpcrk_facility_id.value_amount)
        |> Decimal.mult(percentage(dmpcrk_facility_id.covered))
      _ ->
        frs_amount
        |> Decimal.sub(dmpcrk_facility_id.value_amount)
        |> Decimal.mult(pec)
    end

    member_pays =
      frs_amount
      |> Decimal.sub(payor_pays)
      |> Decimal.add(check_member_pays(changeset.changes))

    payor_pays =
      payor_pays
      |> Decimal.add(check_payor_pays(changeset.changes))

    if frs_amount > Decimal.new(0.00) do
      changeset =
        changeset
        |> Ecto.Changeset.put_change(:payor_pays, payor_pays)
        |> Ecto.Changeset.put_change(:member_pays, member_pays)
    else
      changeset
    end
  end

  def risk_share_coverage(changeset, pec, fpp, phil) do
    dmp_coverage_id = risk_share(changeset)
    dmpc_risk_share_id = for id <- dmp_coverage_id do
      ProductCoverageRiskShare
      |> where([pcr], pcr.product_coverage_id in ^id)
      |> select([pcr], pcr)
      |> Repo.all()
    end
    |> List.flatten()
    |> List.first()

    tamount = for fpp <- fpp do
      for d <- fpp.facility_payor_procedure_rooms do
        d.amount
      end
    end
    |> List.flatten()
    |> sum_list()

    damount = for p <- phil do
      p.philhealth_pays
    end
    |> sum_list()

    crs_amount =
      tamount
      |> Decimal.sub(damount)
      |> Decimal.sub(check_pays(changeset.changes))

    if Map.has_key?(changeset.changes, :pec) do
      pec = nil
    else
      changeset =
        changeset
        |> Ecto.Changeset.put_change(:pec, "1")
    end

    payor_pays =
      case pec do
        nil ->
          crs_amount
          |> Decimal.sub(dmpc_risk_share_id.af_value_amount)
          |> Decimal.mult(percentage(dmpc_risk_share_id.af_covered_amount))
        _ ->
          crs_amount
          |> Decimal.sub(dmpc_risk_share_id.af_value_amount)
          |> Decimal.mult(pec)
      end

   member_pays =
      crs_amount
      |> Decimal.sub(payor_pays)
      |> Decimal.add(check_member_pays(changeset.changes))


    payor_pays =
      payor_pays
      |> Decimal.add(check_payor_pays(changeset.changes))
    if crs_amount > Decimal.new(0.00) do
      changeset =
        changeset
        |> Ecto.Changeset.put_change(:payor_pays, payor_pays)
        |> Ecto.Changeset.put_change(:member_pays, member_pays)

    else
      changeset
    end

  end

  def risk_share(changeset) do
    dm_product_id =
      MemberProduct
      |> join(:inner, [mp], ac in AccountProduct, mp.account_product_id == ac.id)
      |> join(:inner, [mp, ac], p in Product, ac.product_id == p.id)
      |> where([mp, ac, p], mp.member_id == ^changeset.changes.member_id)
      |> select([mp, ac, p], p.id)
      |> Repo.all()
    dmp_coverage_id = for id <- dm_product_id do
      ProductCoverage
      |> join(:inner, [pc], c in Coverage, pc.coverage_id == c.id)
      |> where([pc, c], pc.product_id == ^id and c.code == ^"OPL")
      |> select([pc, c], pc.id)
      |> Repo.all()
    end
  end

  def fpp(changeset, dp_procedure_id) do
    for d <- dp_procedure_id do
      FacilityPayorProcedure
      |> where([fpp], fpp.payor_procedure_id == ^d and fpp.facility_id == ^changeset.changes.facility_id)
      |> Repo.all()
      |> Repo.preload([:facility_payor_procedure_rooms, :payor_procedure])
    end
    |> List.flatten()
  end

  def check_pays(params) do
    member_pays = if params.member_pays do
      params.member_pays
    else
      Decimal.new(0)
    end

    payor_pays = if params.payor_pays do
      params.payor_pays
    else
      Decimal.new(0)
    end

    sum_list([member_pays, payor_pays])
  end

  def check_member_pays(params) do
    if params.member_pays do
      params.member_pays
    else
      Decimal.new(0)
    end
  end

  def check_payor_pays(params) do
    if params.payor_pays do
      params.payor_pays
    else
      Decimal.new(0)
    end
  end

end

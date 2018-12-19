defmodule Innerpeace.Db.Validators.OPConsultValidator do

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Decimal
  alias Innerpeace.Db.Schemas.Embedded.OPConsult
  alias Innerpeace.Db.Schemas.{
    BenefitDiagnosis,
    Authorization,
    AuthorizationDiagnosis,
    AuthorizationProcedureDiagnosis,
    ExclusionDisease
  }
  alias Innerpeace.Db.Repo

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    PractitionerContext,
    MemberContext,
    ProductContext,
    DiagnosisContext,
    FacilityContext,
    UserContext,
    DropdownContext
    # BenefitContext,
    # CoverageContext
  }

  def put_changeset(changeset, key, value) do
    Ecto.Changeset.put_change(changeset, key, value)
  end

  def request_web_ajax(params) do
    changeset =
      %OPConsult{}
      |> OPConsult.changeset(params)
    if changeset.errors == [] do
      practitioner_specialization = PractitionerContext.get_practitioner_id_by_speciliazation(params.practitioner_specialization_id)
      practitioner =  PractitionerContext.get_a_practitioner(practitioner_specialization.practitioner.id)
      member = MemberContext.get_a_member!(changeset.changes.member_id)
      changeset =
        changeset
        |> put_changeset(:member, member)
        |> put_changeset(:practitioner, practitioner)
        |> compute_fees()
        |> compute_deductions()
        |> compute_balance()
    else
      {:error, changeset}
    end
  end

  def request(params) do
    changeset =
    %OPConsult{}
    |> OPConsult.changeset(params)
    if changeset.errors == [] do
      practitioner_specialization = PractitionerContext.get_practitioner_id_by_speciliazation(params["practitioner_specialization_id"])
      practitioner =  PractitionerContext.get_a_practitioner(practitioner_specialization.practitioner.id)
      member = MemberContext.get_a_member!(changeset.changes.member_id)
      changeset =
        changeset
        |> put_changeset(:chief_complaint, params["chief_complaint"])
        |> put_changeset(:chief_complaint_others, params["chief_complaint_others"])
        |> put_changeset(:member, member)
        |> put_changeset(:practitioner, practitioner)
        |> compute_fees()
        |> compute_deductions()
        |> compute_balance()
        |> process_web()
    else
      {:error, changeset}
    end
  end

  def request_consult_web(params) do
    changeset =
      %OPConsult{}
      |> OPConsult.changeset(params)

      if changeset.errors == [] do
        practitioner_specialization = PractitionerContext.get_practitioner_id_by_speciliazation(params.practitioner_specialization_id)
        practitioner =  PractitionerContext.get_a_practitioner(practitioner_specialization.practitioner.id)
        diagnosis = DiagnosisContext.get_diagnosis(params.diagnosis_id)
        facility = FacilityContext.get_facility(params.facility_id)
        member = MemberContext.get_a_member!(params.member_id)

        cond do
          is_nil(diagnosis) ->
            {:error, changeset}
          is_nil(practitioner) ->
            {:error, changeset}
          is_nil(facility) ->
            {:error, changeset}
          is_nil(member) ->
            {:error, changeset}
          true ->
            member = MemberContext.get_a_member!(changeset.changes.member_id)

          changeset =
            changeset
            |> put_changeset(:member, member)
            |> put_changeset(:practitioner, practitioner)
            |> compute_fees()
            |> compute_deductions()
            |> compute_balance()
            |> process_web()
        end
      else
        {:error, changeset}
      end
  end

  # 1 - Get Doctor Fee based on Facility
  defp compute_fees(changeset) do
    consultation_fee =
        PractitionerContext.get_specialization_consultation_fee(changeset.changes.facility_id,
                                                                changeset.changes.practitioner_specialization_id)
    put_changeset(changeset, :consultation_fee, consultation_fee || Decimal.new(0))
  end

  # 1 - Deduct fee based on copayment/coinsurance percentage
  # based on the product of the member
  # 2 - Deduct fee based on diagnonis exists in pre-existing condition
  # 3 - Deduct fee based on based on covered risk share

  defp compute_product_payor_pays(member_product, changeset) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
    active_account = List.first(authorization.member.account_group.account)
    product = member_product.account_product.product
    product_limit_amount_bal = get_total_remaining_product_limit(changeset, member_product, changeset.changes.diagnosis_id)
    pec = ProductContext.get_pec_consult(product.id, changeset.changes.diagnosis_id, changeset.changes.member.id)
    vat = DropdownContext.get_dropdown(changeset.changes.practitioner.vat_status_id)

    if member_product.account_product.product.product_base == "Benefit-based" do
      risk_share = risk_share_checker(product, changeset.changes.facility_id)

      params = %{
        total_remaing_product_limit: product_limit_amount_bal,
        consultation_fee: changeset.changes.consultation_fee,
        copay: risk_share.copayment,
        pec_amount: pec.amount,
        pec_percentage: pec.percentage,
        covered: risk_share.covered,
        risk_share_type: risk_share.type,
        coinsurance_covered: risk_share.covered,
        coinsurance: risk_share.coinsurance,
        vat_status: vat.value
      }

      deductions = compute_consultation(params)
      member_product
      |> Map.put(:payor_pays, deductions.payor)
      |> Map.put(:member_pays, deductions.member)
      |> Map.put(:copayment, deductions.copayment)
      |> Map.put(:coinsurance, deductions.coinsurance)
      |> Map.put(:coinsurance_percentage, deductions.coinsurance_percentage)
      |> Map.put(:pre_existing_percentage, deductions.pre_existing_percentage)
      |> Map.put(:covered_after_percentage, deductions.covered_after_percentage)
      |> Map.put(:risk_share_type, deductions.risk_share_type)
      |> Map.put(:product_limit_balance, product_limit_amount_bal)
      |> Map.put(:vat_status, vat.value)
    else

      diagnosis_list =
        product.product_exclusions
        |> Enum.filter(&(&1.exclusion.coverage == "General Exclusion"))
        |> Enum.filter(fn(x) ->
              y =  Enum.filter(x.exclusion.exclusion_diseases, &(&1.disease_id == changeset.changes.diagnosis_id))
              if Enum.empty?(y) do
                false
              else
                true
              end
           end)

      if Enum.empty?(diagnosis_list) do
        risk_share = risk_share_checker(product, changeset.changes.facility_id)

        params = %{
          total_remaing_product_limit: product_limit_amount_bal,
          consultation_fee: changeset.changes.consultation_fee,
          copay: risk_share.copayment,
          pec_amount: pec.amount,
          pec_percentage: pec.percentage,
          covered: risk_share.covered,
          risk_share_type: risk_share.type,
          coinsurance_covered: risk_share.covered,
          coinsurance: risk_share.coinsurance,
          vat_status: vat.value
        }
        deductions = compute_consultation(params)
        member_product
        |> Map.put(:payor_pays, deductions.payor)
        |> Map.put(:member_pays, deductions.member)
        |> Map.put(:copayment, deductions.copayment)
        |> Map.put(:coinsurance, deductions.coinsurance)
        |> Map.put(:coinsurance_percentage, deductions.coinsurance_percentage)
        |> Map.put(:pre_existing_percentage, deductions.pre_existing_percentage)
        |> Map.put(:covered_after_percentage, deductions.covered_after_percentage)
        |> Map.put(:risk_share_type, deductions.risk_share_type)
        |> Map.put(:total_remaing_product_limit, product_limit_amount_bal)
        |> Map.put(:product_limit_balance, product_limit_amount_bal)
        |> Map.put(:vat_status, vat.value)
      else
        member_product
        |> Map.put(:payor_pays, Decimal.new(0))
        |> Map.put(:member_pays, Decimal.new(changeset.changes.consultation_fee))
        |> Map.put(:copayment, Decimal.new(0))
        |> Map.put(:coinsurance, Decimal.new(0))
        |> Map.put(:coinsurance_percentage, Decimal.new(0))
        |> Map.put(:pre_existing_percentage, Decimal.new(0))
        |> Map.put(:covered_after_percentage, Decimal.new(0))
        |> Map.put(:risk_share_type, nil)
        |> Map.put(:vat_status, vat.value)
        |> Map.put(:product_limit_balance, product_limit_amount_bal)
        |> Map.put(:total_payor_pays, Decimal.new(0))
      end
    end
  end

  defp compute_deductions(changeset) do
    coverage_id = AuthorizationContext.get_coverage_by_code()
    consultation_fee = changeset.changes.consultation_fee
    member = changeset.changes.member
    member_products = Enum.filter(member.products, fn(member_product) ->
      Enum.member?(Enum.map(member_product.account_product.product.product_coverages, &(&1.coverage.id)), coverage_id)
    end)
    member_products = for member_product <- member_products do
      member_product
      |> compute_product_payor_pays(changeset)
    end

    changeset
    |> put_changeset(:member_products, member_products)
    |> put_changeset(:coverage_id, coverage_id)
  end

  # 1 - Get limit of the member
  defp compute_balance(changeset) do
    member_products =
      Enum.reject(changeset.changes.member_products, fn(member_product) ->
        product_benefits = for product_benefit <- member_product.account_product.product.product_benefits do
          product_benefit_coverages =
            Enum.map(product_benefit.benefit.benefit_coverages, &(&1.coverage.code))
            with true <- Enum.member?(product_benefit_coverages, "OPC"),
                 %BenefitDiagnosis{} = benefit_diagnosis <- Enum.find(product_benefit.benefit.benefit_diagnoses, &(&1.diagnosis_id == changeset.changes.diagnosis_id))
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
      end)


    member_product_exclusion =
      Enum.reject(changeset.changes.member_products, fn(member_product) ->
        product_exclusions = for product_exclusion <- member_product.account_product.product.product_exclusions do
            with %ExclusionDisease{} = exclusion_disease <- Enum.find(product_exclusion.exclusion.exclusion_diseases, &(&1.disease_id == changeset.changes.diagnosis_id))
            do
              product_exclusion
            else
              _ ->
                nil
            end
        end
        product_exclusion =
          product_exclusions
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()

        is_nil(product_exclusion)
      end)

    if Enum.empty?(member_products) do
      zero = Decimal.new(0)
      if Enum.empty?(member_product_exclusion) do
        member_prod = changeset.changes.member_products |> List.first()
        vat_status = member_prod.vat_status
        member_product = %{
            coinsurance: zero,
            copayment: zero,
            coinsurance_percentage: zero,
            pre_existing_percentage: zero,
            covered_after_percentage: zero,
            risk_share_type: "",
            vat_status: vat_status
        }

      else
        member_product_ =  Enum.max(member_product_exclusion, &(Decimal.to_float(&1.payor_pays)))
        pre_existing_ = if is_nil(member_product_.pre_existing_percentage) do
          Decimal.new(0)
        else
          member_product_.pre_existing_percentage
        end

        member_product = %{
            coinsurance: zero,
            copayment: zero,
            coinsurance_percentage: zero,
            pre_existing_percentage: pre_existing_,
            product_limit_balance: member_product_.product_limit_balance,
            covered_after_percentage: zero,
            risk_share_type: "",
            member_product_id: member_product_.id,
            vat_status: member_product_.vat_status,
            product_code: member_product_.account_product.product.code
        }

        product_exclusions = for product_exclusion <- member_product_.account_product.product.product_exclusions do
            with %ExclusionDisease{} = exclusion_disease <- Enum.find(product_exclusion.exclusion.exclusion_diseases, &(&1.disease_id == changeset.changes.diagnosis_id))
            do
              product_exclusion
            else
              _ ->
                nil
            end
        end
        product_exclusion =
          product_exclusions
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()
      end
    else
      member_product = Enum.max(member_products, &(Decimal.to_float(&1.payor_pays)))
      product_benefits = for product_benefit <- member_product.account_product.product.product_benefits do
        product_benefit_coverages =
          Enum.map(product_benefit.benefit.benefit_coverages, &(&1.coverage.code))
          with true <- Enum.member?(product_benefit_coverages, "OPC"),
               %BenefitDiagnosis{} = benefit_diagnosis <- Enum.find(product_benefit.benefit.benefit_diagnoses, &(&1.diagnosis_id == changeset.changes.diagnosis_id))
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
    end

    if is_nil(product_benefit) do
      filtered_exclusion_product = Enum.filter(changeset.changes.member_products, fn(x) -> x.account_product.product.product_base == "Exclusion-based" end)
      if Enum.empty?(filtered_exclusion_product) do
        member_product
      else
        member_product  = Enum.max(filtered_exclusion_product, &(Decimal.to_float(&1.payor_pays)))
      end
      if Enum.empty?(filtered_exclusion_product) do
        if is_nil(product_exclusion) do
          if member_product.vat_status == "Vatable" do
            payor = Decimal.new(0)
            consultation_fee = Decimal.new(changeset.changes.consultation_fee)
            vat_percentage = Decimal.div(Decimal.new(12), Decimal.new(100))
            vat_amount = Decimal.mult(consultation_fee, vat_percentage)
            member = Decimal.add(consultation_fee, vat_amount)
          else
            payor = Decimal.new(0)
            member = Decimal.new(changeset.changes.consultation_fee)
          end

          changeset =
            changeset
            |> put_changeset(:member_pays, member)
            |> put_changeset(:payor_pays, payor)
            |> put_changeset(:selected_product, member_product)
            |> put_changeset(:copayment, member_product.copayment)
            |> put_changeset(:coinsurance, member_product.coinsurance)
            |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
            |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
            |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
            |> put_changeset(:risk_share_type, member_product.risk_share_type)
        else
          authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
          active_account = List.first(authorization.member.account_group.account)
          pb = ProductContext.get_a_product_exclusion_limit(product_exclusion.id)
          if member_product.vat_status == "Vatable" do
            vat_consult = Decimal.mult(Decimal.new(changeset.changes.consultation_fee), Decimal.new(0.12))
            consultation_fee = Decimal.add(Decimal.new(changeset.changes.consultation_fee), vat_consult)
          else
            consultation_fee = changeset.changes.consultation_fee
          end
          member = Decimal.sub(consultation_fee, member_product.pre_existing_percentage)
          payor = Decimal.new(member_product.pre_existing_percentage)
          limit_amount = get_total_remaining_exclusion_limit(changeset, member_product_, changeset.changes.diagnosis_id, pb)

          cond do
            pb.limit_type == "Peso" ->

              if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                payor_excess = Decimal.sub(payor, limit_amount)
                payor = limit_amount
                member = Decimal.add(member, payor_excess)
              end

              changeset =
                changeset
                |> put_changeset(:member_pays, member)
                |> put_changeset(:payor_pays, payor)
                |> put_changeset(:product_exclusion_id, product_exclusion.id)
                |> put_changeset(:member_product_id, member_product.member_product_id)
                |> put_changeset(:selected_product, member_product)
                |> put_changeset(:copayment, member_product.copayment)
                |> put_changeset(:coinsurance, member_product.coinsurance)
                |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                |> put_changeset(:risk_share_type, member_product.risk_share_type)

            pb.limit_type == "Sessions" ->
              isSessionAvailable = check_sessions_inner_limit_consult(pb.limit_session, pb.product_exclusion.id, authorization, active_account)

              if Enum.member?([isSessionAvailable], true) do
                payor = Decimal.new(payor)
                member = Decimal.sub(Decimal.new(consultation_fee), Decimal.new(payor))
              else
                payor = payor
                member = Decimal.sub(Decimal.new(consultation_fee), Decimal.new(payor))
              end

              if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                payor_excess = Decimal.sub(payor, limit_amount)
                payor = limit_amount
                member = Decimal.add(member, payor_excess)
              end

              changeset =
                changeset
                |> put_changeset(:member_pays, member)
                |> put_changeset(:payor_pays, payor)
                |> put_changeset(:product_exclusion_id, product_exclusion.id)
                |> put_changeset(:member_product_id, member_product.member_product_id)
                |> put_changeset(:selected_product, member_product)
                |> put_changeset(:copayment, member_product.copayment)
                |> put_changeset(:coinsurance, member_product.coinsurance)
                |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                |> put_changeset(:risk_share_type, member_product.risk_share_type)

            pb.limit_type == "Percentage" ->
              payor_excess = if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                Decimal.sub(payor, limit_amount)
              else
                Decimal.new(0)
              end

              if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                payor = pb.limit_amount
                member = Decimal.add(member, payor_excess)
              end

              bl_multiplier = Decimal.div(Decimal.new(pb.limit_percentage), Decimal.new(100))
              new_benefit_limit = Decimal.mult(member_product.product_limit_balance, bl_multiplier)
              if Decimal.to_float(payor) > Decimal.to_float(new_benefit_limit) do
                payor_excess = Decimal.sub(payor, new_benefit_limit)
                payor = new_benefit_limit
                member = Decimal.add(member, payor_excess)
              end

              changeset =
                changeset
                |> put_changeset(:member_pays, member)
                |> put_changeset(:payor_pays, payor)
                |> put_changeset(:product_exclusion_id, product_exclusion.id)
                |> put_changeset(:member_product_id, member_product.member_product_id)
                |> put_changeset(:selected_product, member_product)
                |> put_changeset(:copayment, member_product.copayment)
                |> put_changeset(:coinsurance, member_product.coinsurance)
                |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                |> put_changeset(:risk_share_type, member_product.risk_share_type)
            end
        end
      else
        if not is_nil(product_exclusion) do
          authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
          active_account = List.first(authorization.member.account_group.account)
          pb = ProductContext.get_a_product_exclusion_limit(product_exclusion.id)
          if is_nil(pb) do
            payor = Decimal.new(member_product.payor_pays)
            member = Decimal.new(member_product.member_pays)
            product_limit_balance = get_total_remaining_product_limit(changeset, member_product, changeset.changes.diagnosis_id)

            if Decimal.to_float(payor) > Decimal.to_float(product_limit_balance) do
              payor_excess = Decimal.sub(payor, product_limit_balance)
              payor = product_limit_balance
              member = Decimal.add(member, payor_excess)
            end
            changeset =
              changeset
              |> put_changeset(:member_pays, member)
              |> put_changeset(:payor_pays, payor)
              |> put_changeset(:selected_product, member_product)
              |> put_changeset(:member_product_id, member_product.id)
              |> put_changeset(:copayment, member_product.copayment)
              |> put_changeset(:coinsurance, member_product.coinsurance)
              |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
              |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
              |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
              |> put_changeset(:risk_share_type, member_product.risk_share_type)
          else
            if member_product.vat_status == "Vatable" do
              vat_consult = Decimal.mult(Decimal.new(changeset.changes.consultation_fee), Decimal.new(0.12))
              consultation_fee = Decimal.add(Decimal.new(changeset.changes.consultation_fee), vat_consult)
            else
              consultation_fee = changeset.changes.consultation_fee
            end
            member = Decimal.sub(consultation_fee, member_product.pre_existing_percentage)
            payor = Decimal.new(member_product.pre_existing_percentage)
            limit_amount = get_total_remaining_exclusion_limit(changeset, member_product_, changeset.changes.diagnosis_id, pb)

            cond do
              pb.limit_type == "Peso" ->
                if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                  payor_excess = Decimal.sub(payor, limit_amount)
                  payor = limit_amount
                  member = Decimal.add(member, payor_excess)
                end

                changeset =
                  changeset
                  |> put_changeset(:member_pays, member)
                  |> put_changeset(:payor_pays, payor)
                  |> put_changeset(:product_exclusion_id, product_exclusion.id)
                  |> put_changeset(:member_product_id, member_product.id)
                  |> put_changeset(:selected_product, member_product)
                  |> put_changeset(:copayment, member_product.copayment)
                  |> put_changeset(:coinsurance, member_product.coinsurance)
                  |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                  |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                  |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                  |> put_changeset(:risk_share_type, member_product.risk_share_type)

              pb.limit_type == "Sessions" ->
                isSessionAvailable = check_sessions_inner_limit_consult(pb.limit_session, pb.product_exclusion.id, authorization, active_account)

                if Enum.member?([isSessionAvailable], true) do
                  payor = Decimal.new(payor)
                  member = Decimal.sub(Decimal.new(consultation_fee), Decimal.new(payor))
                else
                  payor = payor
                  member = Decimal.sub(Decimal.new(consultation_fee), Decimal.new(payor))
                end

                if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                  payor_excess = Decimal.sub(payor, limit_amount)
                  payor = limit_amount
                  member = Decimal.add(member, payor_excess)
                end

                changeset =
                  changeset
                  |> put_changeset(:member_pays, member)
                  |> put_changeset(:payor_pays, payor)
                  |> put_changeset(:product_exclusion_id, product_exclusion.id)
                  |> put_changeset(:member_product_id, member_product.id)
                  |> put_changeset(:selected_product, member_product)
                  |> put_changeset(:copayment, member_product.copayment)
                  |> put_changeset(:coinsurance, member_product.coinsurance)
                  |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                  |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                  |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                  |> put_changeset(:risk_share_type, member_product.risk_share_type)

              pb.limit_type == "Percentage" ->
                payor_excess = if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                  Decimal.sub(payor, limit_amount)
                else
                  Decimal.new(0)
                end

                if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                  payor = pb.limit_amount
                  member = Decimal.add(member, payor_excess)
                end

                bl_multiplier = Decimal.div(Decimal.new(pb.limit_percentage), Decimal.new(100))
                new_benefit_limit = Decimal.mult(member_product.product_limit_balance, bl_multiplier)
                if Decimal.to_float(payor) > Decimal.to_float(new_benefit_limit) do
                  payor_excess = Decimal.sub(payor, new_benefit_limit)
                  payor = new_benefit_limit
                  member = Decimal.add(member, payor_excess)
                end

                changeset =
                  changeset
                  |> put_changeset(:member_pays, member)
                  |> put_changeset(:payor_pays, payor)
                  |> put_changeset(:product_exclusion_id, product_exclusion.id)
                  |> put_changeset(:member_product_id, member_product.id)
                  |> put_changeset(:selected_product, member_product)
                  |> put_changeset(:copayment, member_product.copayment)
                  |> put_changeset(:coinsurance, member_product.coinsurance)
                  |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
                  |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
                  |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
                  |> put_changeset(:risk_share_type, member_product.risk_share_type)
            end
          end
        else
          payor = Decimal.new(member_product.payor_pays)
          member = Decimal.new(member_product.member_pays)
          product_limit_balance = get_total_remaining_product_limit(changeset, member_product, changeset.changes.diagnosis_id)

          if Decimal.to_float(payor) > Decimal.to_float(product_limit_balance) do
            payor_excess = Decimal.sub(payor, product_limit_balance)
            payor = product_limit_balance
            member = Decimal.add(member, payor_excess)
          end

          changeset =
            changeset
            |> put_changeset(:member_pays, member)
            |> put_changeset(:payor_pays, payor)
            |> put_changeset(:selected_product, member_product)
            |> put_changeset(:member_product_id, member_product.id)
            |> put_changeset(:copayment, member_product.copayment)
            |> put_changeset(:coinsurance, member_product.coinsurance)
            |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
            |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
            |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
            |> put_changeset(:risk_share_type, member_product.risk_share_type)
        end
      end
    else
      authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
      active_account = List.first(authorization.member.account_group.account)
      pb = ProductContext.get_a_product_benefit_limit(product_benefit.id)
      limit_amount = get_total_remaining_benefit_limit(changeset, member_product, changeset.changes.diagnosis_id, pb.limit_classification, pb)

      if member_product.vat_status == "Vatable" do
        vat_consult = Decimal.mult(Decimal.new(changeset.changes.consultation_fee), Decimal.new(0.12))
        consultation_fee = Decimal.add(Decimal.new(changeset.changes.consultation_fee), vat_consult)
      else
        consultation_fee = changeset.changes.consultation_fee
      end

      payor = Decimal.new(member_product.payor_pays)
      member = Decimal.new(member_product.member_pays)

      payor_excess = if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
        Decimal.sub(payor, limit_amount)
      else
        Decimal.new(0)
      end
      cond do
        pb.limit_type == "Peso" ->
          if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
            payor_excess = Decimal.sub(payor, limit_amount)
            payor = limit_amount
            member = Decimal.add(member, payor_excess)
          end

          benefit_limit = Decimal.abs(Decimal.sub(limit_amount, payor))
          product_limit = Decimal.sub(member_product.account_product.product.limit_amount, payor)

          changeset =
            changeset
            |> put_changeset(:benefit_limit, pb.limit_amount)
            |> put_changeset(:benefit_limit_type, pb.limit_type)
            |> put_changeset(:product_limit, member_product.product_limit_balance)
            |> put_changeset(:product, member_product.account_product.product)
            |> put_changeset(:member_pays, member)
            |> put_changeset(:payor_pays, payor)
            |> put_changeset(:selected_product, member_product)
            |> put_changeset(:selected_benefit, product_benefit)
            |> put_changeset(:member_product_id, member_product.id)
            |> put_changeset(:product_benefit_id, product_benefit.id)
            |> put_changeset(:copayment, member_product.copayment)
            |> put_changeset(:coinsurance, member_product.coinsurance)
            |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
            |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
            |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
            |> put_changeset(:risk_share_type, member_product.risk_share_type)
            |> put_changeset(:member_excess, payor_excess)

        pb.limit_type == "Sessions" ->

          isSessionAvailable = check_sessions_inner_limit_consult(pb.limit_session, pb.product_benefit.id, authorization, active_account)

          if Enum.member?([isSessionAvailable], true) do
            payor = Decimal.new(0)
            member = Decimal.new(consultation_fee)
          else
            payor = payor
            member = member
          end

          if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
            payor_excess = Decimal.sub(payor, limit_amount)
            payor = limit_amount
            member = Decimal.add(member, payor_excess)
          end

          benefit_limit = Decimal.abs(Decimal.sub(limit_amount, payor))
          product_limit = Decimal.sub(member_product.account_product.product.limit_amount, payor)

          changeset =
            changeset
            |> put_changeset(:benefit_limit, pb.limit_session)
            |> put_changeset(:benefit_limit_type, pb.limit_type)
            |> put_changeset(:product_limit, member_product.product_limit_balance)
            |> put_changeset(:product, member_product.account_product.product)
            |> put_changeset(:member_pays, member)
            |> put_changeset(:payor_pays, payor)
            |> put_changeset(:selected_product, member_product)
            |> put_changeset(:selected_benefit, product_benefit)
            |> put_changeset(:member_product_id, member_product.id)
            |> put_changeset(:product_benefit_id, product_benefit.id)
            |> put_changeset(:copayment, member_product.copayment)
            |> put_changeset(:coinsurance, member_product.coinsurance)
            |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
            |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
            |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
            |> put_changeset(:risk_share_type, member_product.risk_share_type)
            |> put_changeset(:member_excess, payor_excess)

        pb.limit_type == "Plan Limit Percentage" ->
          case pb.limit_classification do
            "Per Coverage Period" ->
              payor_excess = if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                Decimal.sub(payor, limit_amount)
              else
                Decimal.new(0)
              end

              if Decimal.to_float(payor) > Decimal.to_float(limit_amount) do
                payor = limit_amount
                member = Decimal.add(member, payor_excess)
              end
            "Per Transaction" ->
              limit_percentage = Decimal.div(Decimal.new(pb.limit_percentage), Decimal.new(100))
              inner_limit_percentage = Decimal.mult(Decimal.new(payor), limit_percentage)
              payor2 = Decimal.mult(payor, limit_percentage)
              payor_excess = Decimal.sub(payor, payor2)
              payor = payor2
              member = Decimal.add(member, payor_excess)
            _ ->
          end

          bl_multiplier = Decimal.div(Decimal.new(pb.limit_percentage), Decimal.new(100))
          new_benefit_limit = Decimal.mult(member_product.product_limit_balance, bl_multiplier)

          if Decimal.to_float(Decimal.new(payor)) > Decimal.to_float(Decimal.new(new_benefit_limit)) do
            payor_excess = Decimal.sub(payor, new_benefit_limit)
            payor = new_benefit_limit
            member = Decimal.add(member, payor_excess)
          end

          benefit_limit = Decimal.abs(Decimal.sub(limit_amount, payor))
          product_limit = Decimal.sub(member_product.account_product.product.limit_amount, payor)

          changeset =
            changeset
            |> put_changeset(:benefit_limit, pb.limit_percentage)
            |> put_changeset(:benefit_limit_type, pb.limit_type)
            |> put_changeset(:product_limit, member_product.product_limit_balance)
            |> put_changeset(:product, member_product.account_product.product)
            |> put_changeset(:member_pays, member)
            |> put_changeset(:payor_pays, payor)
            |> put_changeset(:selected_product, member_product)
            |> put_changeset(:selected_benefit, product_benefit)
            |> put_changeset(:member_product_id, member_product.id)
            |> put_changeset(:product_benefit_id, product_benefit.id)
            |> put_changeset(:copayment, member_product.copayment)
            |> put_changeset(:coinsurance, member_product.coinsurance)
            |> put_changeset(:pre_existing_percentage, member_product.pre_existing_percentage)
            |> put_changeset(:coinsurance_percentage, member_product.coinsurance_percentage)
            |> put_changeset(:covered_percentage, member_product.covered_after_percentage)
            |> put_changeset(:risk_share_type, member_product.risk_share_type)
            |> put_changeset(:member_excess, payor_excess)
      end
    end
  end

  defp process_web(changeset) do
    user_id = changeset.changes.user_id
    chief_complaint = if Map.has_key?(changeset.changes, :chief_complaint) do
      changeset.changes.chief_complaint
    else
      nil
    end

    chief_complaint_others = if Map.has_key?(changeset.changes, :chief_complaint_others) do
      changeset.changes.chief_complaint_others
    else
      nil
    end

    total = Decimal.add(changeset.changes.payor_pays, changeset.changes.member_pays)
    approval_limit = Enum.map(UserContext.get_user!(changeset.changes.user_id).roles, &(&1.approval_limit))
    approval_limit =
      approval_limit
      |> List.first()

    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)

    product_benefit_id = Map.get(changeset.changes, :product_benefit_id) || nil
    product_exclusion_id = Map.get(changeset.changes, :product_exclusion_id) || nil
    product_limit = Map.get(changeset.changes, :product_limit) || 0
    member_product_id = Map.get(changeset.changes, :member_product_id) || nil
    selected_prod = Map.get(changeset.changes, :selected_product)

    selected_product =
    with %Innerpeace.Db.Schemas.MemberProduct{} = member_product <-
            Map.get(changeset.changes, :selected_product) do
      %{
        product_name: member_product.account_product.product.name,
        product_limit: member_product.account_product.product.limit_amount,
        pre_existing_percentage: member_product.pre_existing_percentage,
        vat_status: member_product.vat_status
      }
    else
      _ ->
        %{
          product_name: "",
          product_limit: "",
          pre_existing_percentage: 0
        }
    end

    payor_portion = if selected_prod.vat_status == "Vatable" do
      Decimal.round(Decimal.div(changeset.changes.payor_pays, Decimal.new(1.12)), 2)
    else
      changeset.changes.payor_pays
    end

    member_portion = if selected_prod.vat_status == "Vatable" do
      Decimal.round(Decimal.div(changeset.changes.member_pays, Decimal.new(1.12)), 2)
    else
      changeset.changes.member_pays
    end

    payor_vat = if selected_prod.vat_status == "Vatable" do
      Decimal.round(Decimal.mult(payor_portion, Decimal.new(0.12)), 2)
    else
      Decimal.new(0)
    end

    member_vat = if selected_prod.vat_status == "Vatable" do
      Decimal.round(Decimal.mult(member_portion, Decimal.new(0.12)), 2)
    else
      Decimal.new(0)
    end

    valid_until =
    ((:erlang.universaltime |> :calendar.datetime_to_gregorian_seconds) + 172_800)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!

    authorization_params = %{
      "authorization_id" => authorization.id,
      "chief_complaint" => chief_complaint,
      "chief_complaint_others" => chief_complaint_others,
      "consultation_fee" => changeset.changes.consultation_fee,
      "consultation_type" => changeset.changes.consultation_type,
      "diagnosis_id" => changeset.changes.diagnosis_id,
      "isMemberPay" => ["on"],
      "member_covered" => changeset.changes.member_pays,
      "member_pay" => changeset.changes.member_pays,
      "member_pays" => changeset.changes.member_pays,
      "member_pays2" => changeset.changes.member_pays,
      "member_portion" => member_portion,
      "member_vat_amount" => member_vat,
      "member_product_id" => member_product_id,
      "payor_covered" => changeset.changes.payor_pays,
      "payor_pay" => changeset.changes.payor_pays,
      "payor_pays" => changeset.changes.payor_pays,
      "payor_portion" => payor_portion,
      "payor_vat_amount" => payor_vat,
      "company_covered" => Decimal.new(0),
      "practitioner_specialization_id" => changeset.changes.practitioner_specialization_id,
      "pre_existing_amount" => selected_prod.pre_existing_percentage || Decimal.new(0),
      "product_benefit_id" => product_benefit_id,
      "product_exclusion_id" => product_exclusion_id,
      "special_approval_amount" => "0",
      "special_approval_amount2" => "0",
      "special_approval_id" => "",
      "special_approval_portion" => "0",
      "special_approval_vat_amount" => "0",
      "total_amount" => Decimal.new(total),
      "user_id" => user_id,
      "vat_status" =>  selected_prod.vat_status,
      "admission_datetime" => Ecto.DateTime.from_erl(:erlang.localtime),
      "valid_until" => valid_until,
      "origin" => String.downcase(changeset.changes.origin)
    }

    with {:ok, authorization2} <- AuthorizationContext.modify_loa_no_version(authorization, authorization_params, user_id) do
      authorization_params = Map.put_new(authorization_params, "authorization_id", authorization2.id)
      AuthorizationContext.create_authorization_diagnosis(authorization_params, user_id)
      AuthorizationContext.create_authorization_practitioner_specialization(authorization_params, user_id)
      AuthorizationContext.create_authorization_amount(authorization_params, user_id)

      authorizations = AuthorizationContext.get_authorization_by_id(authorization.id)
      test =  authorizations.authorization_diagnosis |> List.first()
      if is_nil(test.product_benefit_id) && not is_nil(test.product_exclusion_id) do
        pec_setup_limit_checker(user_id, authorizations, authorization_params, authorization_params)
      else
        no_pec_setup_limit_checker(user_id, authorizations, authorization_params, authorization_params)
      end

      if changeset.valid? do
        changeset =
          changeset
          |> put_changeset(:authorization_id, authorizations.id)
          {:ok, changeset}
      end
    end
  end

  defp pec_setup_limit_checker(user_id, authorizations, authorization_params, params) do
    is_medina = get_authorization_product_used(authorizations).is_medina
    product_base = get_authorization_product_used(authorizations).product_base
    nod = get_authorization_product_used(authorizations).no_outright_denial
    pf_status = DropdownContext.get_dropdown(get_practitioner_facility_status(authorizations).pstatus_id).value
    p_status = get_practitioner_status(authorizations).affiliated
    practitioner_status = if p_status == "Yes" do
      "Affiliated"
    else
      "Non-affiliated"
    end

    authorization_params =
      authorization_params
      |> Map.put("product_base", product_base)
      |> Map.put("isNOD", nod)
      |> Map.put("pf_status", pf_status)
      |> Map.put("p_status", practitioner_status)
      |> Map.put("is_medina", is_medina)

    user_roles = UserContext.get_user!(user_id).roles
    user_limit =
    if is_nil(user_roles) do
      Decimal.new(0)
    else
      user_limit = List.first(user_roles).approval_limit
      Decimal.new(user_limit || 0)
    end

    is_member_pay = authorization_params["isMemberPay"] || nil
    special_approval_amount =  params["special_approval_amount2"] || Decimal.new(0)
    with {:ok} <- AuthorizationContext.pec_check_excess_inner_limit_consult(authorizations) do
      if Decimal.compare(authorizations.authorization_amounts.total_amount, user_limit) == Decimal.new(-1) do
          validate_is_sonny_medina(user_id, special_approval_amount, authorizations, authorization_params, is_member_pay)
      else
          set_status_in_authorization(authorizations, authorization_params)
      end
    else
      _ ->
         set_status_in_authorization(authorizations, authorization_params)
    end
  end

  defp no_pec_setup_limit_checker(user_id, authorizations, authorization_params, params) do
    is_medina = get_authorization_product_used(authorizations).is_medina
    product_base = get_authorization_product_used(authorizations).product_base
    nod = get_authorization_product_used(authorizations).no_outright_denial
    pf_status = DropdownContext.get_dropdown(get_practitioner_facility_status(authorizations).pstatus_id).value
    p_status = get_practitioner_status(authorizations).affiliated
    practitioner_status = if p_status == "Yes" do
      "Affiliated"
    else
      "Non-affiliated"
    end

    authorization_params =
      authorization_params
      |> Map.put("product_base", product_base)
      |> Map.put("isNOD", nod)
      |> Map.put("pf_status", pf_status)
      |> Map.put("p_status", practitioner_status)
      |> Map.put("is_medina", is_medina)

    user_roles = UserContext.get_user!(user_id).roles
    user_limit =
    if is_nil(user_roles) do
      Decimal.new(0)
    else
      user_limit = List.first(user_roles).approval_limit
      Decimal.new(user_limit || 0)
    end

    is_member_pay = authorization_params["isMemberPay"] || nil
    special_approval_amount =  params["special_approval_amount2"] || Decimal.new(0)
    with {:ok} <- AuthorizationContext.check_excess_limits_consult(authorizations) do
      if Decimal.compare(authorizations.authorization_amounts.total_amount, user_limit) == Decimal.new(-1) do
          validate_is_sonny_medina(user_id, special_approval_amount, authorizations, authorization_params, is_member_pay)
      else
          set_status_in_authorization(authorizations, authorization_params)
      end
    else
      _ ->
         set_status_in_authorization(authorizations, authorization_params)
    end
  end

  defp validate_is_sonny_medina(user_id, special_approval_amount, authorizations, authorization_params, is_member_pay) do
    if authorization_params["is_medina"] == true do
      if Decimal.to_float(Decimal.new(special_approval_amount)) > Decimal.to_float(Decimal.new(0)) do
        set_status_in_authorization(authorizations, authorization_params)
      else
        set_status_in_authorization_without_special_approval(user_id,
          authorizations, authorization_params, is_member_pay)
      end
    else
      if Decimal.to_float(Decimal.new(special_approval_amount)) > Decimal.to_float(Decimal.new(0)) do
        update_for_approval_authorization(authorizations, authorization_params)
      else
        if is_nil(is_member_pay) do
          update_for_approval_authorization(authorizations, authorization_params)
        else
          if Decimal.to_float(Decimal.new(authorization_params["member_pays"])) > Decimal.to_float(Decimal.new(0)) do
            update_for_approval_authorization(authorizations, authorization_params)
          else
            update_for_approval_authorization(authorizations, authorization_params)
          end
        end
      end
    end
  end

  defp get_practitioner_facility_status(authorization) do
    aps = authorization.authorization_practitioner_specializations |> List.first()
    practitioner_facilities = aps.practitioner_specialization.practitioner.practitioner_facilities
    pf = for practitioner_facility <- practitioner_facilities do
      practitioner_facility
    end
    Enum.find(pf, &(&1.facility_id == authorization.facility_id))
  end

  defp get_practitioner_status(authorization) do
    aps = authorization.authorization_practitioner_specializations |> List.first()
    practitioner = aps.practitioner_specialization.practitioner
  end

  defp get_authorization_product_used(authorization) do
    ad = authorization.authorization_diagnosis |> List.first()
    if is_nil(ad.member_product) do
      %{
        product_base: nil,
        no_outright_denial: nil,
        is_medina: nil
      }
    else
      ad.member_product.account_product.product
    end
  end

  defp set_status_in_authorization_without_special_approval(user_id, authorizations, authorization_params, is_member_pay) do
    if Decimal.to_float(Decimal.new(authorization_params["payor_pays"])) == Decimal.to_float(Decimal.new(0)) do
      if authorization_params["product_base"] == "Exclusion-based" do
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      else
        update_disapproved_authorization(authorizations, authorization_params)
      end
    else
      if is_nil(is_member_pay) do
        update_for_approval_authorization(authorizations, authorization_params)
      else
        check_loa_is_nod_per_product_base(authorizations, authorization_params, user_id)
      end
    end
  end

  defp check_loa_is_nod_per_product_base(authorizations, authorization_params, user_id) do
    if authorization_params["product_base"] == "Exclusion-based" do
      # if selected ICD is generally excluded and the product has a set up of ‘No outright denial’
      # for Exclusion Based Only
      check_loa_exclusion_based(authorizations, authorization_params, user_id)
    else
      # Benefit Based
      check_loa_practitioner_status(authorizations, authorization_params, user_id)
    end
  end

  defp check_loa_exclusion_based(authorizations, authorization_params, user_id) do
    if authorization_params["isNOD"] == true do
      update_for_approval_authorization(authorizations, authorization_params)
    else
      # check practitioner and facility affiliation status
      check_loa_practitioner_status(authorizations, authorization_params, user_id)
    end
  end

  defp check_loa_practitioner_status(authorizations, authorization_params, user_id) do
    # if practitioner status is non affiliated
    if authorization_params["p_status"] == "Non-affiliated" do
      set_isNonAffiliated_practitioner_status(authorizations, authorization_params, user_id)
    else
      set_isAffiliated_practitioner_status(authorizations, authorization_params, user_id)
    end
  end

  def set_isNonAffiliated_practitioner_status(authorizations, authorization_params, user_id) do
    # If one of the conditions in For approval rules are met and product is tagged as outright denial.
    if authorization_params["isNOD"] != true do
      update_disapproved_authorization(authorizations, authorization_params)
    else
      update_for_approval_authorization(authorizations, authorization_params)
    end
  end

  def set_isAffiliated_practitioner_status(authorizations, authorization_params, user_id) do
      # if practitioner is facility non affiliated or disaffiliated
    if authorization_params["pf_status"] == "Non-affiliated" or authorization_params["pf_status"] == "Disaffiliated" do
      set_isNonAffiliated_facility_status(authorizations, authorization_params, user_id)
    else
      set_isAffiliated_facility_status(authorizations, authorization_params, user_id)
    end
  end

  defp set_isNonAffiliated_facility_status(authorizations, authorization_params, user_id) do
    # If one of the conditions in For approval rules are met and product is tagged as outright denial.
    if authorization_params["isNOD"] != true do
      update_disapproved_authorization(authorizations, authorization_params)
    else
      update_for_approval_authorization(authorizations, authorization_params)
    end
  end

  defp set_isAffiliated_facility_status(authorizations, authorization_params, user_id) do
    if Decimal.to_float(Decimal.new(authorization_params["member_pays"])) > Decimal.to_float(Decimal.new(0)) do
      if authorization_params["isNOD"] != true do
        update_disapproved_authorization(authorizations, authorization_params)
      else
        update_for_approval_authorization(authorizations, authorization_params)
      end
    else
      # set loa status to approve
      set_authorizations_approved_status(authorizations, authorization_params, user_id)
    end
  end

  defp set_authorizations_approved_status(authorizations, authorization_params, user_id) do
    update_approved_authorization(authorizations, authorization_params, user_id)
  end

  defp set_status_in_authorization(authorizations, authorization_params) do
    if Decimal.to_float(Decimal.new(authorization_params["payor_pays"])) == Decimal.to_float(Decimal.new(0)) do
      if authorization_params["is_medina"] == true do
        update_disapproved_authorization(authorizations, authorization_params)
      else
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      end
    else
      # If one of the conditions in For approval rules are met and product is tagged as outright denial.
      if authorization_params["is_medina"] == true do
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      else
        update_for_approval_authorization(authorizations, authorization_params)
      end
    end
  end

  defp update_for_approval_authorization(authorizations, authorization_params) do
    AuthorizationContext.update_authorization(authorizations.id, %{
        "origin" => "payorlink",
        "status" => "For Approval",
        "step" => 5
    } |> Map.merge(authorization_params))
  end

  defp update_disapproved_authorization(authorizations, authorization_params) do
    AuthorizationContext.update_authorization(authorizations.id, %{
        "origin" => "payorlink",
        "status" => "Disapproved",
        "step" => 5
    } |> Map.merge(authorization_params))
  end

  defp update_approved_authorization(authorizations, authorization_params, user_id) do
    AuthorizationContext.update_approve_authorization(authorizations.id, %{
      "origin" => "payorlink",
      "status" => "Approved",
      "step" => 5,
      "approved_by_id" => user_id,
      "approved_datetime" => Ecto.DateTime.from_erl(:erlang.localtime)
    } |> Map.merge(authorization_params))
  end

  defp update_approver_authorization_amount(authorizations, user_id) do
    AuthorizationContext.update_authorization_amount(authorizations.id, %{
      "origin" => "payorlink",
      "approved_by_id" => user_id,
      "approved_datetime" => Ecto.DateTime.from_erl(:erlang.localtime)
    })
  end

  defp risk_share_checker(product, facility_id) do
    product_coverage = Enum.find(product.product_coverages, &(&1.coverage.code == "OPC"))
    pcr = product_coverage.product_coverage_risk_share
    rs_facility = if is_nil(pcr) do
      nil
    else
      rs_facility = Enum.find(pcr.product_coverage_risk_share_facilities, &(&1.facility_id == facility_id))
    end
    cond do
      rs_facility ->
        %{
          type: rs_facility.type,
          copayment: rs_facility.value_amount,
          coinsurance: rs_facility.value_percentage,
          covered: rs_facility.covered
        }
      pcr.af_type ->
        if pcr.af_type == "Copayment" do
        %{
          type: pcr.af_type,
          copayment: pcr.af_value_amount,
          coinsurance: 0,
          covered: pcr.af_covered_percentage,
        }
        else
        %{
          type: pcr.af_type,
          copayment: 0,
          coinsurance: pcr.af_value_percentage,
          covered: pcr.af_covered_percentage,
        }
        end
      true ->
        %{
          type: nil,
          copayment: 0,
          coinsurance: 0,
          covered: 0
        }
    end
  end

  def get_member_products(tier, member_products) do
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

  def get_product_tier(member_products, changeset) do
   for member_product <- member_products do
      product = member_product.account_product.product
      pbs = for pbs <- product.product_benefits do
        for bc <- pbs.benefit.benefit_coverages do
          if bc.coverage.code == "OPC" do
            pbs
          end
        end
      end
      pbs =
        pbs
        |> List.flatten()
        |> Enum.uniq()
        |> List.delete(nil)
      product_benefit = for pb <- pbs do
        for bd <- pb.benefit.benefit_diagnoses do
          if bd.diagnosis_id == changeset.changes.diagnosis_id do
            pb
          end
        end
      end
      product_benefit =
        product_benefit
        |> List.flatten()
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
      if not is_nil(product_benefit) and product.step >= "7" and
      not is_nil(product.limit_amount) and product.limit_amount > 0 and
      is_nil(member_product.loa_payor_pays) do
        member_product.tier
      end
    end
  end

  def get_product_benefit(member_products, changeset, tier) do
    product_benefit = for member_product <- member_products do
      if member_product.tier == tier do
        product = member_product.account_product.product
        pbs = for pbs <- product.product_benefits do
          for bc <- pbs.benefit.benefit_coverages do
            if bc.coverage.code == "OPC" do
              pbs
            end
          end
        end
        pbs =
          pbs
          |> List.flatten()
          |> Enum.uniq()
          |> List.delete(nil)
        product_benefit = for pb <- pbs do
          for bd <- pb.benefit.benefit_diagnoses do
            if bd.diagnosis_id == changeset.changes.diagnosis_id do
              pb
            end
          end
        end
      end
    end
    product_benefit =
      product_benefit
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end

  def get_product_benefit_without_diagnosis(member_products, changeset, tier) do
    product_benefit = for member_product <- member_products do
      if member_product.tier == tier do
        product = member_product.account_product.product
        pbs = for pbs <- product.product_benefits do
          for bc <- pbs.benefit.benefit_coverages do
            if bc.coverage.code == "OPC" do
              pbs
            end
          end
        end
        pbs =
          pbs
          |> List.flatten()
          |> Enum.uniq()
          |> List.delete(nil)
        product_benefit = for pb <- pbs do
          for bd <- pb.benefit.benefit_diagnoses do
              pb
          end
        end
      end
    end
      product_benefit =
        product_benefit
        |> List.flatten()
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
  end

  def get_tier(member_products, payor_max) do
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
  end

  def get_tier_without_diagnosis(member_products) do
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

  defp compute_consultation(params) do
    zero = Decimal.new(0)
    total_remaing_product_limit = Decimal.new(params.total_remaing_product_limit) || zero
    consultation_fee = Decimal.new(params.consultation_fee) || zero
    coinsurance = params.coinsurance || zero
    coinsurance_covered = params.coinsurance_covered || zero
    copay = params.copay || zero
    covered = params.covered || zero
    risk_share_type = params.risk_share_type
    pec_percentage = Decimal.new(params.pec_percentage)
    pec_amount = Decimal.new(params.pec_amount)
    divider = Decimal.new(100)

    if params.vat_status == "Vatable" do
      vat_percentage = Decimal.div(Decimal.new(12), divider)
      vat_amount = Decimal.mult(consultation_fee, vat_percentage)
      consultation_fee = Decimal.add(consultation_fee, vat_amount)
    else
      vat_amount = Decimal.new(0)
      consultation_fee = Decimal.new(consultation_fee)
    end

    if is_nil(risk_share_type) do
      if Decimal.to_float(pec_percentage) > Decimal.to_float(Decimal.new(0)) ||
         Decimal.to_float(pec_amount) > Decimal.to_float(Decimal.new(0))  do
        if Decimal.to_float(pec_amount) ==  Decimal.to_float(Decimal.new(0)) do
          pre_existing_percentage = Decimal.div(pec_percentage, divider)
          payor = Decimal.mult(consultation_fee, pre_existing_percentage)
          pec_val = payor
          member = Decimal.sub(consultation_fee, payor)
        else
          if Decimal.to_float(Decimal.new(pec_amount)) > Decimal.to_float(consultation_fee) do
            member = consultation_fee
            pec_val = member
            payor = Decimal.sub(consultation_fee, member)
          else
            pec_val = pec_amount
            member = Decimal.sub(consultation_fee, Decimal.new(pec_amount))
            payor = Decimal.sub(consultation_fee, member)
          end
        end
      else
        payor = consultation_fee
        if Decimal.to_float(payor) > Decimal.to_float(total_remaing_product_limit) do
          payor = total_remaing_product_limit
          member = Decimal.sub(consultation_fee, payor)
        else
          payor = consultation_fee
          member = Decimal.sub(consultation_fee, payor)
        end
      end
    else
      copay = Decimal.new(copay) || zero
      covered = Decimal.new(covered) || zero

      if Decimal.to_float(pec_percentage) == Decimal.to_float(Decimal.new(0)) do
        percent = Decimal.div(covered, divider)
        percent_decimal = percent
      else
        pre_existing_percentage = Decimal.div(pec_percentage, divider)
      end

      if risk_share_type == "Copayment" do
        if Decimal.to_float(pec_percentage) > Decimal.to_float(Decimal.new(0)) do
          payor_copay = Decimal.sub(consultation_fee, copay)
          payor = Decimal.mult(payor_copay, pre_existing_percentage)

          if Decimal.to_float(payor) > Decimal.to_float(total_remaing_product_limit) do
            payor = total_remaing_product_limit
            member = Decimal.sub(consultation_fee, payor)
          else
            payor = Decimal.mult(payor_copay, pre_existing_percentage)
            member = Decimal.sub(consultation_fee, payor)
          end
        else
          copayment_amount = Decimal.sub(consultation_fee, copay)
          covered_percentage = Decimal.div(covered, divider)
          payor_copay = if Decimal.to_float(copay) > Decimal.to_float(consultation_fee) do
            Decimal.new(0)
          else
            Decimal.sub(consultation_fee, copay)
          end
          payor = Decimal.mult(payor_copay, covered_percentage)

          if Decimal.to_float(payor) > Decimal.to_float(total_remaing_product_limit) do
            payor = total_remaing_product_limit
            member = Decimal.sub(consultation_fee, payor)
          else
            payor = Decimal.mult(payor_copay, covered_percentage)
            if Decimal.to_float(payor) == Decimal.to_float(Decimal.new(0)) do
              member = consultation_fee
            else
              member = Decimal.sub(consultation_fee, payor)
            end
          end
        end
      else
        if Decimal.to_float(pec_percentage) > Decimal.to_float(Decimal.new(0)) do
          coinsurance_percentage =
            Decimal.div(Decimal.new(coinsurance), divider)
          payor_coinusurance =
            Decimal.mult(coinsurance_percentage, consultation_fee)
          payor =
            Decimal.mult(payor_coinusurance, pre_existing_percentage)

          if Decimal.to_float(payor) > Decimal.to_float(total_remaing_product_limit) do
            payor = total_remaing_product_limit
            member = Decimal.sub(consultation_fee, payor)
          else
            payor =
            Decimal.mult(payor_coinusurance, pre_existing_percentage)
            member = Decimal.sub(consultation_fee, payor)
          end
        else
          coinsurance_percentage =
            Decimal.div(Decimal.new(coinsurance), divider)
          payor_coinusurance = Decimal.mult(coinsurance_percentage,
                                            consultation_fee)
          coinsurance_covered_percentage =
                Decimal.div(Decimal.new(coinsurance_covered), divider)
          payor = Decimal.mult(payor_coinusurance,
                               coinsurance_covered_percentage)

          if Decimal.to_float(payor) > Decimal.to_float(total_remaing_product_limit) do
            payor = total_remaing_product_limit
            member = Decimal.sub(consultation_fee, payor)
          else
            payor = Decimal.mult(payor_coinusurance,
                               coinsurance_covered_percentage)
            member = Decimal.sub(consultation_fee, payor)
          end
        end
      end
    end

    %{
      payor: Decimal.new(payor),
      member: Decimal.new(member),
      copayment: copay,
      coinsurance: coinsurance,
      coinsurance_percentage: coinsurance_covered,
      pre_existing_percentage: pec_val,
      covered_after_percentage: Decimal.new(covered),
      risk_share_type: risk_share_type
    }
  end


  # PRIVATE FUNCTIONS

  # PRODUCT LIMIT BALANCE

  defp get_total_remaining_product_limit(changeset, member_product, diagnosis_id) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
    active_account = List.first(changeset.changes.member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    product = ProductContext.get_product!(member_product.account_product.product.id)
    case member_product.account_product.product.limit_type do
      "ABL" ->
        used_limit = remaining_limit_abl(member_product.id, start_date, end_date, authorization, diagnosis_id)
        Decimal.sub(product.limit_amount, used_limit)
      "MBL" ->
        used_limit = remaining_limit_mbl(member_product.id, start_date, end_date, authorization, diagnosis_id)
        Decimal.sub(product.limit_amount, used_limit)
      _ ->
        Decimal.new(0)
    end
  end

  defp remaining_limit_abl(member_product_id, start_date, end_date, authorization, diagnosis_id) do
    used_per_product = AuthorizationContext.get_used_limit_per_product_op_consult(member_product_id, start_date, end_date, authorization)
  end

  defp remaining_limit_mbl(member_product_id, start_date, end_date, authorization, diagnosis_id) do
    diagnosis = DiagnosisContext.get_diagnosis(diagnosis_id)
    diagnosis_group = String.slice(diagnosis.code, 0..2)
    used_limit = AuthorizationContext.get_used_limit_per_diagnosis_group_ad(member_product_id, diagnosis_group, start_date, end_date, authorization)
  end

  # BENEFIT BALANCE

  defp get_total_remaining_benefit_limit(changeset, member_product, diagnosis_id, limit_classification, product_benefit) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
    active_account = List.first(changeset.changes.member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    product = ProductContext.get_product!(member_product.account_product.product.id)

    case limit_classification do
      "Per Coverage Period" ->
        used_limit = remaining_limit_mbl(member_product.id, start_date, end_date, authorization, diagnosis_id)
        cond do
          product_benefit.limit_type == "Peso" ->
            Decimal.sub(product_benefit.limit_amount, used_limit)
          product_benefit.limit_type == "Sessions" ->
            Decimal.sub(product.limit_amount, used_limit)
          product_benefit.limit_type == "Plan Limit Percentage" ->
            multiplier = Decimal.div(Decimal.new(product_benefit.limit_percentage), Decimal.new(100))
            Decimal.mult(multiplier, Decimal.sub(product.limit_amount, used_limit))
        end
      "Per Transaction" ->
        cond do
          product_benefit.limit_type == "Peso" ->
            Decimal.new(product_benefit.limit_amount)
          product_benefit.limit_type == "Sessions" ->
            Decimal.new(product.limit_amount)
          product_benefit.limit_type == "Plan Limit Percentage" ->
            multiplier = Decimal.div(Decimal.new(product_benefit.limit_percentage), Decimal.new(100))
            Decimal.mult(multiplier, Decimal.new(product.limit_amount))
        end
      _ ->
        Decimal.new(0)
    end
  end

  # PEC LIMIT BALANCE

  defp get_total_remaining_exclusion_limit(changeset, member_product, diagnosis_id, product_exclusion) do
    authorization = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
    active_account = List.first(changeset.changes.member.account_group.account)
    start_date = active_account.start_date
    end_date = active_account.end_date
    used_limit = remaining_limit_mbl(member_product.id, start_date, end_date, authorization, diagnosis_id)
    product = ProductContext.get_product!(member_product.account_product.product.id)

    cond do
      product_exclusion.limit_type == "Peso" ->
        peso_limit = Decimal.sub(product_exclusion.limit_peso, used_limit)
        if Decimal.to_float(peso_limit) < Decimal.to_float(Decimal.new(0)) do
          Decimal.new(0)
        else
          peso_limit
        end
      product_exclusion.limit_type == "Sessions" ->
        Decimal.sub(product.limit_amount, used_limit)
      product_exclusion.limit_type == "Percentage" ->
        multiplier = Decimal.div(Decimal.new(product_exclusion.limit_percentage), Decimal.new(100))
        Decimal.mult(multiplier, Decimal.sub(product.limit_amount, used_limit))
    end
  end

  # CHECK SESSION BENEFIT

  defp check_sessions_inner_limit_consult(limit_sessions, product_benefit_id, authorization, active_account) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    current_session_count = Decimal.new(1)

    used_benefit_session =
      authorization.member_id
      |> get_used_limit_per_product_benefit_consult(
        product_benefit_id,
        start_date,
        end_date,
        authorization
      )
      |> Decimal.new()

    total_used = Decimal.add(current_session_count, used_benefit_session)
    limit_sessions |> Decimal.new() |> Decimal.sub(total_used) |> less_than_zero_consult?()
  end

  defp get_used_limit_per_product_benefit_consult(_member_id, product_benefit_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
      a.member_id == ^_member_id and
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      apd.product_benefit_id == ^product_benefit_id and
      a.id != ^authorization.id and
      a.status == "Approved"
    )
    |> select([apd, a], apd)
    |> Repo.all()
    |> Enum.count()
  end

  defp less_than_zero_consult?(decimal) do
    one = Decimal.new(1)
    none = Decimal.new(-1)
    zero = Decimal.new(0)
    cond do
      Decimal.compare(zero, decimal) == one ->
        true
      Decimal.compare(zero, decimal) == none ->
        false
      Decimal.compare(zero, decimal) == zero ->
        false
      true ->
        false
    end
  end

  # CHECK SESSION BENEFIT

  defp pec_check_sessions_inner_limit_consult(limit_sessions, product_exclusion_id, authorization, active_account) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    current_session_count = Decimal.new(1)

    used_benefit_session =
      authorization.member_id
      |> pec_get_used_limit_per_product_exclusion_consult(
        product_exclusion_id,
        start_date,
        end_date,
        authorization
      )
      |> Decimal.new()

    total_used = Decimal.add(current_session_count, used_benefit_session)
    limit_sessions |> Decimal.new() |> Decimal.sub(total_used) |> less_than_zero_consult?()
  end

  defp pec_get_used_limit_per_product_exclusion_consult(_member_id, product_exclusion_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
      a.member_id == ^_member_id and
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      apd.product_exclusion_id == ^product_exclusion_id and
      a.id != ^authorization.id and
      a.status == "Approved"
    )
    |> select([apd, a], apd)
    |> Repo.all()
    |> Enum.count()
  end

  defp less_than_zero_consult?(decimal) do
    one = Decimal.new(1)
    none = Decimal.new(-1)
    zero = Decimal.new(0)
    cond do
      Decimal.compare(zero, decimal) == one ->
        true
      Decimal.compare(zero, decimal) == none ->
        false
      Decimal.compare(zero, decimal) == zero ->
        false
      true ->
        false
    end
  end
end

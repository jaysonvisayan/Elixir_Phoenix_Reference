defmodule Innerpeace.Db.Base.Api.AuthorizationContext do
  @moduledoc """
  This module provides a api authorization context.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.AccountGroup,
    Schemas.Account,
    Schemas.Coverage,
    Schemas.Member,
    Schemas.Authorization,
    Schemas.AuthorizationAmount,
    Schemas.AuthorizationDiagnosis,
    Schemas.MemberProduct,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.Peme,
    Schemas.Claim,
    Schemas.AcuSchedule,
    Schemas.AcuScheduleMember,
    Schemas.ClaimSession,
    Schemas.AuthorizationBenefitPackage,
    Schemas.BenefitPackage,
    Schemas.Benefit,
    Schemas.Batch,
    Schemas.AcuScheduleLog,
    Schemas.ProductBenefit,
    Schemas.PackageFacility
  }

  alias Innerpeace.Db.Base.MemberContext, as: MC
  alias Innerpeace.Db.Base.{
    DiagnosisContext,
    AuthorizationContext,
    CoverageContext,
    AcuScheduleContext,
    FacilityContext,
    ApiAddressContext,
    PackageContext
  }
  alias Innerpeace.Db.Base.Api.{
    UtilityContext,
    MemberContext
  }
  alias Innerpeace.PayorLink.Web.AuthorizationView
  alias Ecto.Changeset
  alias Innerpeace.PayorLink.Web.LayoutView
  # alias Ecto.Date

  def validate_coverage_params(params) do

    with {:ok, changeset} <- validate_coverage_changeset(params),
         {:ok, changeset} <- validate_member_product_coverage(changeset)
    do
      {:ok}
    else
      {:error, changeset} ->
        {:error, changeset}

      {:not_covered} ->
        {:not_covered, "facility is not covered by the given coverage"}
    end
  end

  ################################## Changeset Checker #####################################

  def validate_member_id(changeset) do
    with true <- Map.has_key?(changeset.changes, :member_id)
    do
      if MC.get_a_member!(changeset.changes.member_id) do
        changeset
      else
        Changeset.add_error(changeset, :member_id, "Member is not existing")
      end
    else
      _ ->
        changeset
    end
  end

  def validate_coverage_changeset(params) do
    if is_nil(params["card_no"]) do
      data = %{}
      validate_coverage_types = %{
        facility_code: :string,
        coverage_name: :string,
        member_id: :string
      }
      changeset =
        {data, validate_coverage_types}
        |> Changeset.cast(params, Map.keys(validate_coverage_types))
        |> Changeset.validate_required([
          :facility_code,
          :coverage_name
        ])
        |> validate_member_id()
        |> validate_facility_code()
        |> validate_coverage_name()
    else
      data = %{}
      validate_coverage_types = %{
        card_no: :string,
        facility_code: :string,
        coverage_name: :string
      }
      changeset =
        {data, validate_coverage_types}
        |> Changeset.cast(params, Map.keys(validate_coverage_types))
        |> Changeset.validate_required([
          :card_no,
          :facility_code,
          :coverage_name
        ])
        |> validate_card_no()
        |> validate_facility_code()
        |> validate_coverage_name()
    end

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def validate_card_no(changeset) do
    with true <- Map.has_key?(changeset.changes, :card_no)
    do
      member = MemberContext.get_member_by_card_number(changeset.changes.card_no)
      cond do
        is_nil(member) ->
          Changeset.add_error(changeset, :card_no, "card number is not existing")
        downcase(member.status) != "active" ->
          if downcase(changeset.changes.coverage_name) == "acu" do
            Changeset.add_error(changeset, :card_no, "Member status must be Active to avail ACU.")
          else
            Changeset.add_error(changeset, :card_no, "Member status must be Active to avail LOA.")
          end
        true ->
          changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp downcase(string) do
    String.downcase("#{string}")
  end

  def validate_facility_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :facility_code),
         %Facility{} = facility <- get_facility_by_code(changeset.changes.facility_code)

    do
      case String.downcase(facility.status) do
        "affiliated" ->
          changeset

        _ ->
        changeset = Map.put(changeset, :error, "facility is not affiliated")
        Changeset.add_error(changeset, :facility_code, "facility is not affiliated")
      end
    else
      nil ->
        changeset = Map.put(changeset, :error, "facility code is not existing")
        Changeset.add_error(changeset, :facility_code, "facility code is not existing")

      _ ->
        changeset
    end
  end

  def validate_coverage_name(changeset) do
    with true <- Map.has_key?(changeset.changes, :coverage_name)

    do
      if get_coverage_by_name(changeset.changes.coverage_name) do
        changeset
      else
        Changeset.add_error(changeset, :coverage_name, "coverage name is not existing")
      end

    else
      _ ->
        changeset
    end
  end

  defp validate_acu_status(status, ai) do
    if Enum.member?(status, "Approved") or Enum.member?(status, "For Approval") or Enum.member?(status, "Availed") do
      if not is_nil(ai.approved_datetime) do
        date =
        ai.approved_datetime
        |> Ecto.DateTime.to_date()
        |> Ecto.Date.to_string()
        |> AuthorizationView.format_birthdate()

        if ai.is_peme? == true do
          {:invalid_coverage, "Member is no longer valid to request ACU. Reason: Already availed PEME last #{date}"}
        else
          {:invalid_coverage, "Member's ACU package has been availed last #{date}"}
        end
      else
        {:invalid_coverage, "Invalid ACU. Reason: Availed ACU has no approved date time"}
      end
    else
      true
    end
  end

  def validate_acu(member, coverage) do
    acu_authorization =
      Authorization
      |> where([a],
               a.coverage_id == ^coverage.id and
               a.member_id == ^member.id
      )
      |> Repo.all

    acu_authorization_ids = for a <- acu_authorization, do: a.id
    acu_authorization_status = for a <- acu_authorization, do: a.status

    ai =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id and
                a.member_id == ^member.id and (a.status == "Approved" or a.status == "For Approval" or a.status == "Availed"))
      |> limit(1)
      |> order_by([a], desc: a.approved_datetime)
      |> Repo.one()

    if is_nil(acu_authorization) || Enum.empty?(acu_authorization) || is_nil(ai) do
      true
    else
      validate_acu_status(acu_authorization_status, ai)
    end
  end

  def validate_acu_existing(member, coverage, facility_id) do
    ai =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id and
                a.member_id == ^member.id and
                (a.status == "Approved" or a.status == "For Approval" or a.status == "Availed"))
      |> limit(1)
      |> order_by([a], desc: a.approved_datetime)
      |> Repo.one()

    ai_forfeited =
      Authorization
      |> join(:inner, [a], abp in AuthorizationBenefitPackage, abp.authorization_id == a.id)
      |> join(:inner, [a, abp], bp in BenefitPackage, bp.id == abp.benefit_package_id)
      |> join(:inner, [a, abp, bp], b in Benefit, b.id == bp.benefit_id)
      |> where([a, abp, bp, b], a.coverage_id == ^coverage.id)
      |> where([a, abp, bp, b], a.member_id == ^member.id)
      |> where([a, abp, bp, b], a.status == "Forfeited")
      |> where([a, abp, bp, b],
               ilike(b.provider_access, "%Mobile"))
      |> where([a, abp, bp, b],
               ilike(b.provider_access, "Hospital%"))
      |> Repo.one()

    cond do
      # is_nil(ai_forfeited) && not is_nil(ai)->
      #   {:invalid_coverage, "Availment Process must have Hospital/Clinic"}
      not is_nil(ai_forfeited) && not is_nil(ai) ->
        true
      is_nil(ai) ->
        true
      ai.facility_id != facility_id ->
        {:invalid_coverage, "Member is no longer valid to request ACU. Reason: Member already requested in another Hospital/Clinic."}
      true ->
        {:invalid_coverage, "Member is no longer valid to request ACU. Reason: ACU request draft already existed."}
        true
    end
  end

  def validate_acu_pf(facility_id, member_id, coverage) do
    pfs = AuthorizationContext.get_package_facility_by_facility_id(facility_id)
    pf_ids = for pf <- pfs, do: pf.package_id

    member = MC.get_a_member!(member_id)
    # packages = for mp <- member.products do
    #   for pb <- mp.account_product.product.product_benefits do
    #     for bp <- pb.benefit.benefit_packages do
    #       bp.package.id
    #     end
    #   end
    # end
    # |> List.flatten
    # |> List.first

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member.products,
        coverage.id
      )

    benefit_package =
      MC.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()

    packages = benefit_package.package.id

    if Enum.member?(pf_ids, packages) do
      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member.products,
          coverage.id
        )
        pb =
          MC.get_acu_package_based_on_member(
            member,
            member_product
          )

          benefit_package =
            MC.get_acu_package_based_on_member_for_schedule(
              member,
              member_product
            )

            benefit_package = benefit_package
                              |> List.first()

          if not is_nil(benefit_package) do
            packages =
              male = false
              female = false
              if member.gender == "Male" do
                male = true
              else
                female = true
              end

              cond do
                benefit_package.male == male ->
                  validate_age(member, benefit_package)
                benefit_package.female == female ->
                  validate_age(member, benefit_package)
                true ->
                  {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."}
              end
          else
            {:invalid_coverage, "Product Benefit not found1"}
          end
        # if not is_nil(pb) do
        #   packages = for bp <- pb.benefit.benefit_packages do
        #     for bppp <- bp.package.package_payor_procedure do
        #       male = false
        #       female = false
        #       if member.gender == "Male" do
        #         male = true
        #       else
        #         female = true
        #       end

        #       cond do
        #         bppp.male == male ->
        #           validate_age(member, bppp)
        #         bppp.female == female ->
        #           validate_age(member, bppp)
        #         true ->
        #           {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."}
        #       end
        #     end
        #   end
        #   |> List.flatten
        #   |> List.first
        # else
        #   {:invalid_coverage, "Product Benefit not found1"}
        # end
          else
          {:invalid_coverage, "Member's ACU package is not available in this facility."}
    end
  end

  defp validate_age(member, bppp) do
    age = UtilityContext.age(member.birthdate)
    if bppp.age_from <= age and age <= bppp.age_to do
      true
    else
      {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."}
    end
  end
  # defp validate_acu_frr(member, facility_id) do
  #   acu_benefit = for mp <- member.products do
  #     for pb <- mp.account_product.product.product_benefits do
  #       for bc <- pb.benefit.benefit_coverages do
  #         if bc.coverage.code == "ACU" do
  #           pb.benefit
  #         end
  #       end
  #     end
  #   end
  #   |> List.flatten
  #   |> Enum.uniq
  #   |> List.delete(nil)
  #   |> List.first

  #   acu_type = acu_benefit.acu_type
  #   acu_coverage = acu_benefit.acu_coverage

  #   if acu_type == "Executive" and acu_coverage == "Inpatient" do
  #     frr = AuthorizationContext.get_frr_by_facility_id(facility_id)
  #     if Enum.count(frr) > 0 do
  #       true
  #     else
  #       {:invalid_coverage, "No facility room rate setup."}
  #     end
  #   else
  #     true
  #   end
  # end

  ### validate if coverage is included in member product/s
  def validate_member_product_coverage(changeset) do
    cond do
      changeset.changes.coverage_name == "PEME" ->
        validate_member_product_peme(changeset)
      changeset.changes.coverage_name == "ACU" ->
        validate_member_product_acu(changeset)
      changeset.changes.coverage_name == "OP Consult" ->
        validate_member_product(changeset)
      true ->
        validate_member_product(changeset)
    end
  end

  def validate_member_product_acu(changeset) do
    required_keys = [:facility_code, :coverage_name, :card_no]
    changeset = with {:ok, params} <- validate_parameters(changeset.changes, required_keys) do

      member =
        changeset.changes.card_no
        |> MemberContext.get_member_by_card_number()
        |> Repo.preload(
          [products:
           [account_product:
            [product:
             [product_benefits:
              [benefit: [benefit_coverages: :coverage]], product_coverages:
              [:coverage, [product_coverage_facilities: :facility]
              ]]]]]
        )

      member_products = for member_product <- Enum.sort_by(member.products, &(&1.tier)) do
        coverage_and_type = for product_coverage <- member_product.account_product.product.product_coverages do
          %{
            product: member_product.account_product.product.name,
            tiering: member_product.tier,
            product_coverage: product_coverage.coverage.name,
            type: product_coverage.type,
            pcf: all_pcf(product_coverage.product_coverage_facilities)
          }
        end
      end

      product_coverages = for member_product <- member_products do
        for details <- member_product do
          details.product_coverage
        end
      end

      coverage_name = changeset.changes.coverage_name
      coverage = CoverageContext.get_coverage_by_name(coverage_name)

      facility = FacilityContext.get_facility_by_code(changeset.changes.facility_code)
      is_member? =
        product_coverages
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.member?(coverage_name)

      if is_member? do
        changeset = if coverage.code == "ACU" do

          benefit_package =
            get_member_product(member)
            |> Enum.map(&(MC.get_acu_package_based_on_member_for_schedule(member, &1)))

            with true <- validate_multiple_package_acu(member, facility, benefit_package, coverage)
            do
              changeset
            else
              {:invalid_coverage, message} ->
                changeset = Changeset.add_error(changeset, :coverage_name, message)
              {:old_data} ->
                changeset = Changeset.add_error(changeset, :coverage_name, "Product is old data, try to create new product.")
            end
      else
        end
        else
        changeset = Changeset.add_error(changeset, :coverage_name, "coverage name is not included in member product/s")
      end
    else
      {:error_params, message} ->
        changeset = Changeset.add_error(changeset, :coverage_name, message)
    end
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_parameters(params, required_keys) do
    results = Enum.map(required_keys, fn k -> Map.has_key?(params, k) and params[k] != ""  and params[k] != [] and not is_nil(params[k]) end)

    if Enum.member?(results, false)  do
      keys_not_found =
        Enum.map(Enum.with_index(results), fn({result, i}) ->
          if result == false, do: "#{Enum.at(required_keys, i)} is required"
        end)
        |> Enum.uniq()
        |> List.delete(nil)

      {:error_params, Enum.join(keys_not_found, ", ")}
    else
      {:ok, params}
    end
  end

  defp validate_acu_benefit(member) do
    benefit_provider_access =
      Enum.map(member.products, fn(mp) ->
        Enum.map(mp.account_product.product.product_benefits, fn(pb) ->
          pb.benefit.provider_access
        end)
      end)
      |> List.flatten()

    cond do
      Enum.member?(benefit_provider_access, "") ->
        {:invalid_coverage, "Member's ACU package is not available in this facility."}
      Enum.member?(benefit_provider_access, "Mobile") ->
        {:invalid_coverage, "Member's ACU package is not available in this facility."}
      true ->
        {:valid}
    end
  end

  defp check_benefit_package(benefit_package) do
    benefit_package = List.first(benefit_package)
    if is_nil(benefit_package) do
      {:old_data}
    else
      {:valid, benefit_package}
    end
  end

  def get_member_product(member) do
    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    AuthorizationContext.get_member_product_with_coverage_and_tier2(
      member_products,
      CoverageContext.get_coverage_by_code("ACU").id
    )
  end

  ### boolean checker if it is eligible or not
  def validate_member_product(changeset) do
    member =
      changeset.changes.card_no
      |> MemberContext.get_member_by_card_number()
      |> Repo.preload([products: [account_product: [
        product: [product_coverages: [:coverage, [product_coverage_facilities: :facility]]]]]])

    member_products = for member_product <- Enum.sort_by(member.products, &(&1.tier)) do
      coverage_and_type = for product_coverage <- member_product.account_product.product.product_coverages do
        %{
          product: member_product.account_product.product.name,
          tiering: member_product.tier,
          product_coverage: product_coverage.coverage.name,
          type: product_coverage.type,
          pcf: all_pcf(product_coverage.product_coverage_facilities)
        }
      end
    end

    boolean_results = for member_product <- member_products do
      for details <- member_product do
        facility_code = changeset.changes.facility_code
        coverage_name = changeset.changes.coverage_name

        cond do
          ### if product_coverage.type == inclusion
          details.type == "inclusion" ->
            if Enum.member?(details.pcf, facility_code) and details.product_coverage == coverage_name do
              %{tier: details.tiering, result: true, coverage: details.product_coverage}
            else
              %{tier: details.tiering, result: false, coverage: details.product_coverage}
            end

          ### if product_coverage.type == exception
          details.product_coverage == coverage_name and details.type == "exception" ->
            if Enum.count(details.pcf) > 0 and details.product_coverage == coverage_name do
              cond do
                Enum.member?(details.pcf, facility_code) and details.product_coverage == coverage_name ->

                  %{tier: details.tiering, result: false, coverage: details.product_coverage}

                details.product_coverage != coverage_name ->

                  %{tier: details.tiering, result: false, coverage: "no coverage"}

                true ->
                  %{tier: details.tiering, result: true, coverage: details.product_coverage}
              end
              else

                %{tier: details.tiering, result: true, coverage: details.product_coverage}
            end

          true ->
            %{tier: details.tiering, result: false, coverage: details.product_coverage}
        end
      end
    end

    ### checker for tier, not yet done no need to check for its tier because this is not yet related in loa computations

    #   tier_checker = for boolean_result <- boolean_results do
    #     coverages = for details <- boolean_result do
    #       details.coverage
    #     end
    #   end

    #   flatten = List.flatten(tier_checker)
    #             |> Enum.filter(&(&1 == changeset.changes.coverage_name))
    #             |> Enum.count

    #   if flatten > 1 do
    #     var = for boolean_result <- boolean_results do
    #       results = for details <- boolean_result do
    #         details.result
    #       end
    #       results
    #     end
    #   end

    check = for boolean_result <- boolean_results do
      results = for details <- boolean_result do
        details.result
      end

      if Enum.member?(results, true) do
        true
      else
        false
      end
    end

    # final checker per product coverage and its hospital
    # if it is matched to true regards on SpecificFacility/Inclusion
    if Enum.member?(check, true) do
      {:ok, changeset}
    else
      {:not_covered}
    end

  end

  ################################## Utilities #####################################

  def all_pcf(product_coverage_facilities) do
    for pcf <- product_coverage_facilities do
      pcf.facility.code
    end
  end

  def get_facility_by_code(facility_code) do
    Facility
    |> where([f], f.code == ^facility_code and f.status != "Pending")
    |> Repo.one
  end

  def get_coverage_by_name(coverage_name) do
    Coverage
    |> where([c], c.name == ^coverage_name)
    |> Repo.one
  end

  #for insert_utilization
  def utilization_validate_fields(params) do
    types = %{
      coverage_code: :string,
      member_card_no: :string,
      facility_code: :string,
      consultation_type: :string,
      chief_complaint: :string,
      chief_complaint_others: :string,
      internal_remarks: :string,
      assessed_amount: :decimal,
      total_amount: :decimal,
      status: :string,
      version: :integer,
      step: :integer,
      admission_datetime: :string,
      discharge_datetime: :string,
      availment_type: :string,
      number: :string,
      reason: :string,
      valid_until: Ecto.Date,
      pre_existing_percentage: :integer,
      payor_covered: :decimal,
      member_covered: :decimal,
      company_covered: :decimal,
      total_amount: :decimal,
      vat_amount: :decimal,
      special_approval_amount: :decimal
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :consultation_type,
        :admission_datetime,
        :coverage_code,
        :facility_code,
        :member_card_no,
        :payor_covered,
        :member_covered,
        :company_covered,
        :total_amount,
        :vat_amount
      ], message: "is required")
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  # def get_member_by_id(id) do
  #   case UtilityContext.valid_uuid?(id) do
  #     {true, id} ->
  #       case MC.get_member(id) do
  #         %Member{} ->
  #           %Member{}
  #         nil ->
  #           {:nil, "member"}
  #       end
  #     {:invalid_id} ->
  #       {:invalid_id, "member"}
  #   end
  # end

  def get_member_by_card_no(card_no) do
    member = MC.get_member_by_card_no(card_no)
    if member == nil or member == [] do
      {:nil, "member"}
    else
      member
    end
  end

  def utilization_get_facility_by_code(code) do
    facility = get_facility_by_code(code)
    if facility == nil or facility == [] do
      {:nil, "provider"}
    else
      facility
    end
  end

  def get_coverage_by_code!(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> Repo.one()
  end

  def insert_authorization(params) do
    %Authorization{}
    |> Authorization.utilization_changeset(params)
    |> Repo.insert()
  end

  def insert_authorization_amount(params) do
    %AuthorizationAmount{}
    |> AuthorizationAmount.utilization_changeset(params)
    |> Repo.insert()
  end

  def insert_authorization_diagnosis(params, authorization_id, member_id, user_id) do
    if params == nil or params == [] do
    else
      for param <- params do
        diagnosis = DiagnosisContext.get_diagnosis_by_code(param["icd_code"])
        if diagnosis != nil do
          member_product = get_account_product_by_code_and_member_id(member_id, param["product_code"])
          ad_param = if member_product != nil do
            %{
              authorization_id: authorization_id,
              diagnosis_id: diagnosis.id,
              created_by_id: user_id,
              updated_by_id: user_id,
              member_product_id: member_product.id
            }
          else
            %{
              authorization_id: authorization_id,
              diagnosis_id: diagnosis.id,
              created_by_id: user_id,
              updated_by_id: user_id
            }
          end

          %AuthorizationDiagnosis{}
          |> AuthorizationDiagnosis.changeset(ad_param)
          |> Repo.insert()
        end
      end
    end
  end

  defp get_account_product_by_code_and_member_id(id, code) do
    MemberProduct
    |> join(:inner, [mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [mp, ap], p in Product, ap.product_id == p.id)
    |> where([mp, ap, p], p.code == ^code and mp.member_id == ^id)
    |> Repo.one()
  end

  def update_loa_number(params) do
    auth = Repo.get(Authorization, params["authorization_id"])
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, number: params["loa_no"])
    end
  end

  def update_otp_status(authorization_id) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, otp: "true", status: "Availed")
    end
  end

  def update_peme_status(authorization_id, params) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, otp: "true", status: "Availed",
      availment_date: params["availment_date"])
      create_peme_claim(params["authorization_id"])
    end
  end

  def update_verified(params) do
    auth = Repo.get(Authorization, params["authorization_id"])
    {:ok, admission_datetime} = Ecto.DateTime.cast(DateTime.utc_now())
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, otp: "true", status: "Availed", admission_datetime: admission_datetime)
      AcuScheduleContext.update_verified(params["authorization_id"])
      create_claim(params["authorization_id"], params["batch_no"])
    end
  end

  def load_auth_details(id) do
    Authorization
    |> Repo.get!(id)
    |> Repo.preload([
      authorization_benefit_packages: [
        benefit_package: [
          package: [
            package_payor_procedure: [
              payor_procedure: :procedure
            ]
          ]
        ]
      ],
      authorization_diagnosis: [
        :diagnosis
      ],
    ])
  end

  def create_peme_claim(authorization_id) do
    auth = Repo.get(Authorization, authorization_id)
           |> drop_keys()
    keys = Map.keys(auth)

    record = load_auth_details(authorization_id)
    acu_p = get_auth_packages(record)
    auth_d = get_auth_diagnosis(record)
    auth_procedure = get_auth_procedure(record)
    params = Map.take(auth, keys)
             |> Map.put(:authorization_id, authorization_id)

    abp =
      record.authorization_benefit_packages
      |> List.first()

    bp_id = abp.benefit_package.id

    claim =
      %Claim{}
      |> Claim.changeset(params)
      |> Repo.insert!()
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_change(:package, acu_p)
      |> Ecto.Changeset.put_change(:diagnosis, auth_d)
      |> Ecto.Changeset.put_change(:procedure, auth_d)
      |> Repo.update!()

    create_claim_sessions_params = %{
      member_id: claim.member_id,
      coverage_id: claim.coverage_id,
      facility_id: claim.facility_id,
      claim_id: claim.id,
      benefit_package_id: bp_id
    }

    insert_claim_session(create_claim_sessions_params)
    {:ok, claim}
  end

  def create_claim(authorization_id, batch_no) do
    auth = Repo.get(Authorization, authorization_id)
          |> drop_keys()
    keys = Map.keys(auth)

    record = load_auth_details(authorization_id)
    acu_p = get_auth_packages(record)
    auth_d = get_auth_diagnosis(record)
    auth_procedure = get_auth_procedure(record)

    package_codes = get_multiple_package_code(record)
    package_names = get_multiple_package_name(record)

    params = Map.take(auth, keys)
             |> Map.put(:authorization_id, authorization_id)
             |> Map.put(:batch_no, batch_no)

    abp =
      record.authorization_benefit_packages
      |> List.first()

    bp_id = abp.benefit_package.id

    claim =
      %Claim{}
      |> Claim.changeset(params)
      |> Repo.insert!()
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_change(:package_code, package_codes)
      |> Ecto.Changeset.put_change(:package_name, package_names)
      |> Ecto.Changeset.put_change(:package, acu_p)
      |> Ecto.Changeset.put_change(:diagnosis, auth_d)
      |> Ecto.Changeset.put_change(:procedure, auth_d)
      |> Repo.update!()

    create_claim_sessions_params = %{
      member_id: claim.member_id,
      coverage_id: claim.coverage_id,
      facility_id: claim.facility_id,
      claim_id: claim.id,
      benefit_package_id: bp_id
    }
    # session_params = get_claim_session_by_id(claim.id)
    # create_claim_sessions_params = %{
    #   member_id: session_params.member_id,
    #   coverage_id: session_params.coverage_id,
    #   facility_id: session_params.facility_id,
    #   claims_id: session_params.id
    # }
    insert_claim_session(create_claim_sessions_params)
  end

  defp get_claim_session_by_id(claim_id) do
    Claim
    |> Repo.get(claim_id)
    |> Repo.one()
  end

  def insert_claim_session(params) do
    %ClaimSession{}
    |> ClaimSession.changeset(params)
    |> Repo.insert()
  end


  def drop_keys(map) do
    Map.drop(map, [
      :__struct__,
      :id,
      :coverage,
      :batch_authorization,
      :authorization_amounts,
      :logs,
      :authorization_files,
      :authorization_benefit_packages
    ])
  end

  defp get_auth_diagnosis(diagnosis) do
    diagnoses = diagnosis.authorization_diagnosis
                |> Enum.map(&(&1.diagnosis))
                |> List.flatten()

    diagnoses
    |> Enum.map(fn(d) ->
      %{
        code: d.code,
        name: d.name,
        diagnosis_id: d.id,
        type: d.type,
        group_description: d.group_description,
        description: d.description,
        congenital: d.congenital,
        group_code: d.group_code,
      }
    end)
  end

  defp get_auth_procedure(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.map(&(&1.package_payor_procedure))
    |> List.flatten()
    |> Enum.map(&(&1.payor_procedure))
    |> List.flatten()
    |> Enum.map(&(&1.procedure))
    |> Enum.uniq_by(&(&1.code))
    |> auth_procedure
  end

  defp auth_procedure(procedures) do
    procedures
    |> Enum.map(fn(p) ->
      %{
        code: p.code,
        type: p.type,
        description: p.description,
        procedure_id: p.id
      }
    end)
  end

  defp get_auth_packages(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.uniq_by(&(&1.id))
    |> auth_packages
  end

  defp auth_packages(packages) do
    packages
    |> Enum.map(fn(package) ->
       %{
        code:  package.code,
        name: package.name,
        package_id: package.id
       }
    end)
  end

  # GET MULTIPLE PACKAGE NAME

  defp get_multiple_package_name(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.uniq_by(&(&1.id))
    |> auth_package_names
  end

  defp auth_package_names(packages) do
    packages
    |> Enum.map(fn(package) ->
       package.name
    end)
  end

  # GET MULTIPLE PACKAGE CODE

  defp get_multiple_package_code(package) do
    package.authorization_benefit_packages
    |> Enum.map(&(&1.benefit_package))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.uniq_by(&(&1.id))
    |> auth_package_codes
  end

  defp auth_package_codes(packages) do
    packages
    |> Enum.map(fn(package) ->
       package.code
    end)
  end

  def update_forfeited(authorization_id) do
      auth = Repo.get(Authorization, authorization_id)
      if not is_nil(auth) do
        Repo.update(Changeset.change auth, status: "Forfeited")
        AcuScheduleContext.update_forfeited(authorization_id)
      end
    rescue
       e in DBConnection.ConnectionError ->
        return = AcuScheduleContext.log_params(nil, nil, "#{authorization_id} : Connection timeout while updating forfeited loa status")
        return
        |> AcuScheduleContext.insert_acu_log()
  end

  def update_status_to_pending(authorization_id) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, otp: "false", status: "Pending")
    end
  end

  def update_status_to_approved(authorization_id) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, otp: "false", status: "Approved")
    end
  end

  def update_loa_peme_status(authorization_id, status) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      Repo.update(Changeset.change auth, status: "Cancelled")
    end
  end

  def create_loa_for_pos_terminal(params) do
    %Authorization{}
    |> Authorization.changeset_pos_terminal(params)
    |> Repo.insert()
  end

  def validate_acu_pf_schedule(facility_id, member_id, coverage, product_benefit) do
    pfs = AuthorizationContext.get_package_facility_by_facility_id(facility_id)
    pf_ids = for pf <- pfs, do: pf.package_id

    member = MC.get_a_member!(member_id)
    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member.products,
        coverage.id
      )

    benefit_package =
      MC.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()

    packages = benefit_package.package.id

    if Enum.member?(pf_ids, packages) do
      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member.products,
          coverage.id
        )
        pb =
          MC.get_acu_package_based_on_member(
            member,
            member_product
          )

          benefit_package =
            MC.get_acu_package_based_on_member_for_schedule(
              member,
              member_product
            )

            benefit_package = benefit_package
                              |> List.first()

          if not is_nil(benefit_package) do
            packages =
              male = false
              female = false
              if member.gender == "Male" do
                male = true
              else
                female = true
              end

              cond do
                benefit_package.male == male ->
                  validate_age(member, benefit_package)
                benefit_package.female == female ->
                  validate_age(member, benefit_package)
                true ->
                  {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."}
              end
          else
            {:invalid_coverage, "Product Benefit not found1"}
          end
        else
        {:invalid_coverage, "Member's ACU package is not available in this facility."}
    end
  end

  def validate_print_required(params) do
    data = %{}
    general_types = %{
      loa_number: :string,
      copy: :string
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :loa_number
      ])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp copy(copy) do
    cond do
      String.downcase(copy) == "duplicate" ->
        {:valid}
      String.downcase(copy) == "original" ->
        {:valid}
      true ->
        {:invalid}
    end
  end

  def op_consult?(changeset) do
    with true <- Map.has_key?(changeset.changes, :copy),
         true <- not is_nil(changeset.changes[:copy]) or changeset.changes[:copy] != "",
         {:valid} <- copy(changeset.changes[:copy])
    do
      {:ok, changeset}
    else
      {:invalid} ->
        changeset =
          Changeset.add_error(changeset, :copy, "Invalid Copy. Please choose either original or duplicate")
        {:error, changeset}
      _ ->
        changeset =
          Changeset.add_error(changeset, :copy, "Copy is required for OP Consult")
        {:error, changeset}
    end
  end

  def update_availed_job(verified_ids) do
    {_, {year, month, day}} =
      Ecto.Date.utc()
      |> Ecto.Date.dump()

    schedule = %DateTime{
      year: year,
      month: month,
      day: day,
      zone_abbr: "SGT",
      hour: 0,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      utc_offset: 28800,
      std_offset: 0,
      time_zone: "Singapore"
    }

    Exq.Enqueuer.start_link

    Enum.into(verified_ids, [], &(
      Exq.Enqueuer.enqueue(
        Exq.Enqueuer,
        "availed_loa_job",
        # schedule,
        "Innerpeace.Worker.Job.AvailedLoaJob",
        [&1]))
    )
  end

  def update_forfeited_job(forfeited_ids) do
    {_, {year, month, day}} =
      Ecto.Date.utc()
      |> Ecto.Date.dump()

    schedule = %DateTime{
      year: year,
      month: month,
      day: day,
      zone_abbr: "SGT",
      hour: 0,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      utc_offset: 28800,
      std_offset: 0,
      time_zone: "Singapore"
    }

    Exq.Enqueuer.start_link

    Enum.into(forfeited_ids, [], &(
      Exq.Enqueuer.enqueue(
        Exq.Enqueuer,
        "forfeited_loa_status_job",
        # schedule,
        "Innerpeace.Worker.Job.ForfeitedLoaStatusJob",
        [&1]))
    )
  end

  # PEME

  def validate_member_product_peme(changeset) do
    member =
    changeset.changes.member_id
    |> MemberContext.get_member_by_id()
    |> Repo.preload(
      [products:
        [account_product:
          [product:
            [product_benefits:
            [benefit: [benefit_coverages: :coverage]], product_coverages:
              [:coverage, [product_coverage_facilities: :facility]]]]]])

    member_products = for member_product <- Enum.sort_by(member.products, &(&1.tier)) do
      coverage_and_type = for product_coverage <- member_product.account_product.product.product_coverages do
        %{
          product: member_product.account_product.product.name,
          tiering: member_product.tier,
          product_coverage: product_coverage.coverage.name,
          type: product_coverage.type,
          pcf: all_pcf(product_coverage.product_coverage_facilities)
        }
      end
    end

    product_coverages = for member_product <- member_products do
      for details <- member_product do
        details.product_coverage
      end
    end

    coverage_name = changeset.changes.coverage_name
    coverage = CoverageContext.get_coverage_by_name(coverage_name)

    facility = FacilityContext.get_facility_by_code(changeset.changes.facility_code)
    is_member? =
      product_coverages
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.member?(coverage_name)


    if is_member? do
      changeset = if coverage.code == "PEME" do
        with true <- validate_peme_member(member, coverage, facility.id),
             true <- validate_peme(member, coverage),
             true <- validate_peme_existing(member, coverage, facility.id),
             true <- validate_peme_pf(facility.id, member.id, coverage)
            # true <- validate_acu_frr(member, facility.id)
        do
          changeset
        else
          {:invalid_coverage, message} ->
            changeset = Changeset.add_error(changeset, :coverage_name, message)
        end
      else
        changeset
      end
    else
      changeset = Changeset.add_error(changeset, :coverage_name, "coverage name is not included in member product/s")
    end

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp get_peme_member_product(member) do
    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    AuthorizationContext.get_member_product_with_coverage_and_tier(
      member_products,
      CoverageContext.get_coverage_by_code("PEME").id
    )
  end

  def validate_peme_member(member, coverage, facility_id) do
    peme_member = MC.get_peme_by_member_id(member.id)
    if String.downcase(peme_member.status) != "registered" do
      {:invalid_coverage, "Member is not allow to avail PEME Reason: Member needs to encode personal information in https://memberlink-ip-ist.medilink.com.ph/en/evoucher"}
    else
      true
    end
  end

  defp validate_peme_status(status, ai) do
    if Enum.member?(status, "Approved") or Enum.member?(status, "For Approval") or Enum.member?(status, "Availed") do
      if not is_nil(ai.approved_datetime) do
        date =
        ai.approved_datetime
        |> Ecto.DateTime.to_date()
        |> Ecto.Date.to_string()
        |> format_bdate()

        if ai.is_peme? == true do
          {:invalid_coverage, "Member is no longer valid to request PEME. Reason: Already availed PEME last #{date}"}
        else
          {:invalid_coverage, "Member is no longer valid to request PEME. Reason: Already availed PEME last #{date}"}
        end
      else
        {:invalid_coverage, "Invalid PEME. Reason: Availed PEME has no approved date time"}
      end
    else
      true
    end
  end

  defp format_bdate(date) do
    date = to_string(date)
    date =
      date
      |> String.split("-")
    year = Enum.at(date, 0)
    month = Enum.at(date, 1)
    day = Enum.at(date, 2)

    month = case month do
      "01" ->
        "January"
      "02" ->
        "February"
      "03" ->
        "March"
      "04" ->
        "April"
      "05" ->
        "May"
      "06" ->
        "June"
      "07" ->
        "July"
      "08" ->
        "August"
      "09" ->
        "September"
      "10" ->
        "October"
      "11" ->
        "November"
      "12" ->
        "December"
    end

    "#{month} #{day}, #{year}"
  end

  def validate_peme(member, coverage) do
    peme_authorization =
      Authorization
      |> where([a],
               a.coverage_id == ^coverage.id and
               a.member_id == ^member.id
      )
      |> Repo.all

    peme_authorization_ids = for a <- peme_authorization, do: a.id
    peme_authorization_status = for a <- peme_authorization, do: a.status

    ai =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id and
                a.member_id == ^member.id and (a.status == "Approved" or a.status == "For Approval" or a.status == "Availed"))
      |> limit(1)
      |> order_by([a], desc: a.approved_datetime)
      |> Repo.one()

    if is_nil(peme_authorization) || Enum.empty?(peme_authorization) || is_nil(ai) do
      true
    else
      validate_peme_status(peme_authorization_status, ai)
    end
  end

  def validate_peme_existing(member, coverage, facility_id) do
    ai =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id and
                a.member_id == ^member.id and
                (a.status != "Approved" or a.status != "For Approval" or a.status != "Cancelled" or a.status != "Availed"))
      |> limit(1)
      |> order_by([a], desc: a.approved_datetime)
      |> Repo.one()

    cond do
      is_nil(ai) ->
        true
      ai.facility_id != facility_id ->
        {:invalid_coverage, "Member is no longer valid to request PEME. Reason: Member already requested in another Hospital/Clinic."}
      true ->
        {:invalid_coverage, "Member is no longer valid to request PEME. Reason: PEME request draft already existed."}
    end
  end

  def validate_peme_pf(facility_id, member_id, coverage) do
    pfs = AuthorizationContext.get_package_facility_by_facility_id(facility_id)
    pf_ids = for pf <- pfs, do: pf.package_id

    member = MC.get_a_member!(member_id)
    member_products =
      AuthorizationContext.get_member_product_with_coverage_and_tier2(
        member.products,
        coverage.id
      )

    peme = MC.get_peme_by_member_id(member.id)

    benefit_packages =
      MC.get_peme_package_based_on_member_for_schedule2(
        member,
        member_products
    )

    benefit_packages2 =
      MC.get_peme_package_based_on_member_for_schedule2(
        member,
        member_products
    )
    |> Enum.uniq()
    |> List.delete(nil)

    if not Enum.empty?(benefit_packages2) do
      benefit_package_ids = Enum.map(benefit_packages, fn(benefit_package) ->
        Enum.map(benefit_package, fn(x) ->
          if is_nil(x) do
            nil
          else
            x.package.id
          end
        end)
      end)

      benefit_package_ids =
        benefit_package_ids
        |> List.flatten()

      if Enum.member?(benefit_package_ids, peme.package_id) do
       if(Enum.member?(pf_ids, peme.package_id)) do

          member_product =
            AuthorizationContext.get_member_product_with_coverage_and_tier(
              member.products,
              coverage.id
            )

          member_products =
            AuthorizationContext.get_member_product_with_coverage_and_tier2(
              member.products,
              coverage.id
            )

          peme = MC.get_peme_by_member_id(member.id)

          benefit_packages =
            MC.get_peme_package_based_on_member_for_schedule2(
              member,
              member_products
          )

          benefit_package = Enum.map(benefit_packages, fn(benefit_package) ->
            Enum.map(benefit_package, fn(x) ->
                x
            end)
          end)
          |> Enum.uniq()
          |> List.delete([nil])

          test = Enum.map(benefit_package, fn(test) ->
            test =
              test
              |> Enum.find(&(&1.package.id == peme.package.id))
          end)
          benefit_package =
            test
            |> Enum.reject(&(is_nil(&1)))
            |> List.first()

          if not is_nil(benefit_package) or benefit_package != [] do
            bpp = benefit_package.package.package_payor_procedure

            bpp =
             bpp
             |> List.first

            packages =
              male = false
              female = false
              if member.gender == "Male" do
                male = true
              else
                female = true
              end
              cond do
                bpp.male == male ->
                  validate_age_peme(member, bpp)
                  bpp.female == female ->
                  validate_age_peme(member, bpp)
                true ->
                  {:invalid_coverage, "Member is not eligible to avail PEME in this Hospital / Clinic."}
              end
          else
            {:invalid_coverage, "Product Benefit not found"}
          end
       else
        {:invalid_coverage, "Member is not eligible to avail PEME. Reason: Package is not available in this facility."}
       end
      else
        {:invalid_coverage, "Member is not eligible to avail PEME. Reason: Package is not available in this facility."}
      end
    else
      {:invalid_coverage, "Member is not eligible to avail PEME. Reason: Packages are invalid."}
    end

  end

  defp validate_age_peme(member, bppp) do
    age = UtilityContext.age(member.birthdate)
    if bppp.age_from <= age and age <= bppp.age_to do
      true
    else
      {:invalid_coverage, "Member is not eligible to avail PEME in this Hospital / Clinic."}
    end
  end

  def approve_loa_status(authorization_id, user_id) do
    auth = Repo.get(Authorization, authorization_id)
    if not is_nil(auth) do
      auth
      |> AuthorizationContext.approve_authorization_step4_peme(user_id)
    end
  end

  def get_claims do
    Claim
    |> join(:inner, [c], m in Member, c.member_id == m.id)
    |> where([c, m], is_nil(c.migrated))
    |> where([c, m], fragment("? LIKE ?", m.card_no, "1168%"))
    |> Repo.all()
    |> Repo.preload([
      :member,
      :coverage,
      :facility,
      :created_by,
      :updated_by,
      authorization: [
        :authorization_amounts,
        authorization_benefit_packages: [
          benefit_package: [
            :benefit,
            package: [
              package_payor_procedure: [
                payor_procedure: :procedure
              ]
            ]
          ]
        ],
        batch_authorizations: [
          batch: [
            batch_files: :file
          ]
        ],
        authorization_diagnosis: :diagnosis
      ]
    ])
  end

  def get_claims2 do
    Claim
    |> join(:inner, [c], m in Member, c.member_id == m.id)
    |> join(:inner, [c, m], b in Batch, b.batch_no == c.batch_no)
    |> where([c, m, b], is_nil(c.migrated))
    |> where([c, m, b], fragment("? LIKE ?", m.card_no, "1168%"))
    |> where([c, m, b], fragment("? = CAST((SELECT COUNT(ID) FROM claims WHERE batch_no = ?) AS TEXT)", b.estimate_no_of_claims, b.batch_no))
    |> order_by([c, m, b], [asc: c.inserted_at])
    |> limit(1)
    |> Repo.one()
    #   :coverage,
    #   :facility,
    #   :created_by,
    #   :updated_by,
    #   authorization: [
    #     :authorization_amounts,
    #     authorization_benefit_packages: [
    #       benefit_package: [
    #         :benefit,
    #         package: [
    #           package_payor_procedure: [
    #             payor_procedure: :procedure
    #           ]
    #         ]
    #       ]
    #     ],
    #     authorization_diagnosis: :diagnosis
    #   ]
    # ])
  end

  def get_claims2(batch_no) do
    Claim
    |> join(:inner, [c], m in Member, c.member_id == m.id)
    |> where([c, m], is_nil(c.migrated) and c.batch_no == ^batch_no)
    |> where([c, m], fragment("? LIKE ?", m.card_no, "1168%"))
    |> Repo.all()
    |> Repo.preload([
      :member,
      :coverage,
      :facility,
      :created_by,
      :updated_by,
      authorization: [
        :authorization_amounts,
        authorization_benefit_packages: [
          benefit_package: [
            :benefit,
            package: [
              package_payor_procedure: [
                payor_procedure: :procedure
              ]
            ]
          ]
        ],
        authorization_diagnosis: :diagnosis
      ]
    ])
  end

  def get_batch_by_no(batch_no) do
    Batch
    |> where([b], b.batch_no == ^batch_no)
    |> Repo.one()
    |> Repo.preload([
      batch_files: :file
    ])
  end

  # END OF PEME VALIDATIONS
  # Claim
  def update_migrated_claim(params) do
    for param <- params do
      claim =
        get_claim_by_id_and_batch_no(param)
      claim
      |> Claim.changeset_migrated(%{migrated: "migrated"})
      |> Repo.update()

      auth =
        get_loa_by_id_and_batch_no(param)
      auth
      |> Authorization.changeset_loe_no(%{loe_number: param["loe_no"]})
      |> Repo.update()
    end
  end

  def update_claim_migrated_by_batch(batch_no) do
    Claim
    |> where([c], c.batch_no == ^batch_no)
    |> Repo.update_all(set: [migrated: "migrated"])
  end

  defp get_claim_by_id_and_batch_no(param) do
    Claim
    |> where([c], c.number == ^param["id"] and c.batch_no == ^param["batch_no"])
    |> Repo.one()
  end

  def get_claim_count_batch_no(batch_no) do
    Claim
    |> where([c], c.batch_no == ^batch_no)
    |> Repo.all()
    |> Enum.count()
  end

  def get_claim_by_batch_no(batch_no) do
    Claim
    |> where([c], c.batch_no == ^batch_no)
    |> Repo.all()
  end

  defp get_loa_by_id_and_batch_no(param) do
    Authorization
    |> where([a], a.number == ^param["id"])
    |> Repo.one()
  end

  def setup_claims_batch do
    claims = get_claims2()
    if is_nil(claims) do
      nil
    else
      claims = get_claims2(claims.batch_no)
      claim = List.first(claims)
      batch = get_batch_by_no(claim.batch_no)
      batch_file = List.first(batch.batch_files)
      file_url = get_file_url(batch_file)
      base64_file = download_convert_file_to_base64(file_url, batch_file)
      estimated_bill  =
        claims
        |> Enum.map(&(&1.authorization.authorization_amounts.total_amount))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        %{
          batch_no: claim.batch_no,
          payor_code: "MAXICAR",
          provider_code: claim.facility.code,
          estimatedclaims: Enum.count(claims),
          estimatedbills: estimated_bill,
          remarks: "",
          created_by: claim.created_by.username,
          ref_no: claim.transaction_no,
          coverage: claim.coverage.name,
          received_date: batch.date_received,
          due_date: batch.date_due,
          physician_code: "",
          provider_instruction: "",
          "ASODOC": "",
          "AttachedDoc": base64_file,
          loes: claims,
          soa_ref_no: batch.soa_ref_no,
          soa_amount: batch.soa_amount,
          edited_soa_amount: batch.edited_soa_amount
        }
    end
  end

  defp get_first_batch_no(claims) do
    claims
    |> Enum.map(&(&1.batch_no))
    |> Enum.uniq()
    |> List.delete(nil)
    |> List.first()
  end

  defp get_file_url(batch_file) do
    with {:ok, type, file} <- validate_batch_file(batch_file)
    do
      path =
        Innerpeace.FileUploader
        |> LayoutView.file_url_for(type, file)
        |> String.replace("/apps/payor_link/assets/static", "")
        |> String.slice(0..-15)
      case Application.get_env(:db, :env) do
        :test ->
          pathsample = Path.expand('./')
          "#{pathsample}#{path}"
        :dev ->
          pathsample = Path.expand('./')
          "#{pathsample}#{path}"
        :prod ->
          File.mkdir_p!(Path.expand('./uploads/files'))
          pathsample = Path.expand('./uploads/files/')
          Download.from(path, [path: "#{pathsample}/#{batch_file.file.name}"])
          "#{pathsample}/#{batch_file.file.name}"
        _ ->
          nil
      end
    else
      _ ->
        ""
    end
  end

  defp validate_batch_file(nil), do: ""
  defp validate_batch_file(bf), do: validate_batch_file2(bf.file)

  defp validate_batch_file2(nil), do: ""
  defp validate_batch_file2(file), do: validate_batch_file3(file.type, file)

  defp validate_batch_file3(nil, _), do: ""
  defp validate_batch_file3(type, file), do: {:ok, type, file}

  defp download_convert_file_to_base64(pathsample, batch_file) do
    case File.read(pathsample) do
      {:ok, file} ->
        pathsample = Path.expand('./uploads/files/')
        File.rm_rf("#{pathsample}/#{batch_file.file.name}")
        listname = String.split(batch_file.file.name, ".")
        i = listname |> Enum.count()
        ext = listname |> Enum.at(i - 1)
        "#{ext}-#{Base.encode64(file)}"
      {:error, _reason} ->
        ""
    end
  end

  def create_claim_in_providerlink(batch_no, loa_number) do
    claims =  if is_nil(batch_no) or batch_no == "" do
      get_claim_by_authorization_number(loa_number)
    else
      get_claim_by_batch_no(batch_no)
    end

    claims = Enum.map(claims, fn(claim) ->
      record = load_auth_details(claim.authorization_id)
      acu_p = get_auth_packages(record)
      auth_d = get_auth_diagnosis(record)
      auth_procedure = get_auth_procedure(record)
      package_codes = get_multiple_package_code(record)
      package_names = get_multiple_package_name(record)

      %{
        "consultation_type" => claim.consultation_type,
        "chief_complaint" => claim.chief_complaint,
        "chief_complaint_others" => claim.chief_complaint_others,
        "internal_remarks" => claim.internal_remarks,
        "assessed_amount" => claim.assessed_amount,
        "total_amount" => claim.total_amount,
        "status" => claim.status,
        "version" => claim.version,
        "step" => claim.step,
        "admission_datetime" => claim.admission_datetime,
        "discharge_datetime" => claim.admission_datetime,
        "availment_type" => claim.availment_type,
        "number" => claim.number,
        "reason" => claim.reason,
        "valid_until" => claim.valid_until,
        "otp" => claim.otp,
        "otp_expiry" => claim.otp_expiry,
        "origin" => claim.origin,
        "control_number" => claim.control_number,
        "approved_datetime" => claim.approved_datetime,
        "requested_datetime" => "",
        "transaction_no" => claim.transaction_no,
        "is_peme?" => "",
        "swipe_datetime" => "",
        "batch_no" => claim.batch_no,
        "loe_number" => "",
        "availment_date" => "",
        "is_claimed?" => claim.is_claimed?,
        "migrated" => "",
        "nature_of_admission" => "",
        "point_of_admission" => "",
        "senior_discount" => "",
        "pwd_discount" => "",
        "date_issued" => "",
        "place_issued" => "",
        "or_and_dr_fee" => "",
        "payorlink_claim_id" => claim.id,
        "loa_id" => claim.authorization_id,
        "package" => acu_p,
        "diagnosis" => auth_d,
        "procedure" => auth_procedure,
        "package_code" => package_codes,
        "package_name" => package_names
      }
    end)

    claim_params = %{
      "claims" => claims
    }

    with {:ok, response} <- connect_to_api_post(claim_params) do
      case response.status_code do
        200 ->
          {:ok, response}
        _ ->
          {:error, "Error"}
      end
    else
      {:error_connecting_api} ->
        {:error, "Error"}
      {:unable_to_login} ->
        {:error, "Error"}
    end
  end

  def log_params(as_id, member_id, remarks) do
    %{
      acu_schedule_id: as_id,
      member_id: member_id,
      remarks: remarks
     }
  end

  def insert_acu_log(params) do
    %AcuScheduleLog{}
    |> AcuScheduleLog.changeset(params)
    |> Repo.insert()
  end

  def connect_to_api_post(params) do
    with {:ok, token} <- AcuScheduleContext.provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/claims/insert"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(params)

      with {:ok, response} <- HTTPoison.post(api_method, body, headers, [])
      do
        {:ok, response}
      else
        {:error, response} ->
          {:error_connecting_api}
        401 ->
          with {:ok, token} <- AcuScheduleContext.provider_link_sign_in(true) do
            api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
            api_method = Enum.join([api_address.address, "/api/v1/claims/insert"], "")
            headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
            body = Poison.encode!(params)

            with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
                 200 <- response.status_code
            do
              {:ok, response}
            else
              {:error, response} ->
                {:error_connecting_api}
              401 ->
                {:error_connecting_api}
            end
          else
            {:unable_to_login} ->
              {:unable_to_login}
          end
      end
    else
      {:unable_to_login} ->
        {:unable_to_login}
    end
  end

  def request_peme_loa_providerlink(params, evoucher) do
    peme = params.peme
    with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      providerlink_url = "#{api_address.address}/api/v1/peme/insert_loa"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      param =
          params
          |> Map.put(:evoucher, evoucher)

      body = create_json_params(param)
      with {:ok, response} <- HTTPoison.post(providerlink_url, body, headers) do
        resp = Poison.decode!(response.body)
        if resp["message"] == "Succesfully Created Peme Loa" do
          {:ok, response}
        else
          AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
          MC.update_peme_status_pending(peme)
          {:error, "Error creating loa in providerlink."}
        end
      else
        _ ->
          AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
          MC.update_peme_status_pending(peme)
          {:error}
      end
    else
      _ ->
        AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
          MC.update_peme_status_pending(peme)
          {:unable_to_login, "Unable to login to ProviderLink API"}
     end
  end

  defp create_json_params(params) do
    {_, package_name} = Enum.at(params.package, 2)
    {_, package_code} = Enum.at(params.package, 1)
    loa_number = AuthorizationContext.get_loa_number_by_loa_id(params.authorization_id)
    account_name = MC.get_member_account_name_by_code(params.member.account_code)
    male = if params.member.gender == "Male", do: true, else: false
    female = if params.member.gender == "Female", do: true, else: false

    params = %{
      "facility_id" => params.facility_id,
      "first_name" => params.member.first_name,
      "middle_name" => params.member.middle_name,
      "last_name" => params.member.last_name,
      "suffix" => params.member.suffix,
      "birthdate" => params.member.birthdate,
      "card_no" => params.member.card_no,
      "id" => params.member.id,
      "male" => male,
      "female" => female,
      "member_status" => "Active",
      "email" => params.member.email,
      "mobile" => params.member.mobile,
      "evoucher_number" => params.evoucher,
      "type" => params.member.type,
      "account_code" => params.member.account_code,
      "package_facility_rate" => params.package_facility_rate,
      "authorization_id" => params.authorization_id,
      "number" => loa_number,
      "evoucher" => params.evoucher,
      "account_name" => account_name,
      "gender" => params.member.gender,
      # loa_packages
      "benefit_package_id" => params.benefit_package_id,
      "package_name" => package_name,
      "package_code" => package_code,
      "benefit_code" => params.benefit_code,
      "payor_procedure" => params.payor_procedure,
      "package_facility_rate" => params.package_facility_rate,
      "admission_date" => params.admission_date,
      "discharge_date" => params.discharge_date

    }|> Poison.encode!()
  end

  def get_authorization_by_list_ids(ids) do
    Authorization
    |> where([a], a.id in ^ids)
    |> Repo.all()
    |> Repo.preload([
      authorization_benefit_packages: [
        benefit_package: [
          package: [
            package_payor_procedure: [
              payor_procedure: :procedure
            ]
          ]
        ]
      ],
      authorization_diagnosis: [
        :diagnosis
      ],
    ])
  end

  def insert_all_claim(params) do
    Claim
    |> Repo.insert_all(params)
  end

  def update_all_authorization_to_availed(auth_ids) do
    {:ok, admission_datetime} = Ecto.DateTime.cast(DateTime.utc_now())
    Authorization
    |> where([a], a.id in ^auth_ids)
    |> Repo.update_all(set: [otp: "true", status: "Availed", admission_datetime: admission_datetime])
  end

  def update_all_authorization_to_forfeited(auth_ids) do
    Authorization
    |> where([a], a.id in ^auth_ids)
    |> Repo.update_all(set: [status: "Forfeited"])
  end

  def paylink_peme_params(loa, pm_param, member, response) do
    name = UtilityContext.get_username_by_user_id(member.created_by_id)
    %{
      "AssessedAmnt" => assessed_amount(pm_param.package_facility_rate),
      "AuthorizationCode" => authorization_code(loa.loe_number),
      "AvailmentDate" => admission_date_val(loa.admission_datetime),
      "CPTList" => [
        %{
          "BenefitID" => pm_param.benefit_code,
          "CptCode" => pm_param.package_code, #Package code
          "CptDesc" => pm_param.package_name, #Package desc
          "EstimatePrice" => "#{pm_param.package_facility_rate}",
          "IcdCode" => "Z00.0",
          "LimitCode" => "C"
        }
      ],
      "CardNo" => member.card_no,
      # "CardNo" => "1168011039985356",
      "ClaimType" => "P",
      "Coverage" => "A",
      "CreatedBy" => "#{name}-#{String.upcase("#{pm_param.origin}")}2",
      "DischargeDate" => discharge_date_val(loa.discharge_datetime),
      "Email" => member.email,
      "GeneratedFrom" => "#{String.upcase("#{pm_param.origin}")}2",
      "ICDCode" => [
        %{
          "EstimatePrice" => "#{pm_param.package_facility_rate}",
          "ICDCode" => "Z00.0",
          "ICDDesc" => "GENERAL EXAMINATION AND INVESTIGATION OF PERSONS WITHOUT COMPLAINT AND REPORTED DIAGNOSIS: General medical examination"
        }
      ],
      "IpAddress" => "#{pm_param.ip}",
      "Mobile" => member.mobile,
      "OtherPhy" => "",
      "OtherPhyType" => "",
      "PatientName" => Enum.join([member.first_name, member.middle_name, member.last_name], " "),
      "ProviderCode" => pm_param.facility_code,
      "ProviderInstruction" => "",
      "RefType" => "",
      "RejectCode" => "",
      "Remarks" => "",
      "RequestedBy" => "#{name}-#{String.upcase("#{pm_param.origin}")}2",
      "SpecialApproval" => "",
      "LOANo" => loa.number,
      "LOAStatus" => "A"
    }
  end

  defp assessed_amount(amount) do
    "#{amount}"
    |> String.split(".")
    |> List.first()
    |> String.to_integer()
  end

  defp admission_date_val(nil), do: Ecto.DateTime.to_iso8601(Ecto.DateTime.utc())
  defp admission_date_val(admission_datetime), do: Ecto.DateTime.to_iso8601(admission_datetime)

  defp authorization_code(nil), do: ""
  defp authorization_code(loe_number), do: loe_number

  defp discharge_date_val(nil), do: Ecto.DateTime.to_iso8601(Ecto.DateTime.utc())
  defp discharge_date_val(discharge_datetime), do: Ecto.DateTime.to_iso8601(discharge_datetime)

  def request_peme_in_paylink(scheme, member, pm_param, authorization) do
    with {:ok, authorization} <- Repo.update(Changeset.change authorization, status: "Draft"),
         {:ok, token} <- UtilityContext.payorlink_one_sign_in_v4(scheme),
         {:ok, response} <- UtilityContext.save_peme_members_in_payorlink_one(token, member, pm_param),
         {:ok, member} <- MC.update_card_no_and_policy_and_integration_id(response, member),
         {:ok, _auth} <- Repo.update(Changeset.change authorization, number: response["LOANo"], status: "Approved")
         # authorization_params <- paylink_peme_params(authorization, pm_param, member, response),
         # {:ok, response} <- UtilityContext.create_peme_loa_payorlink_one(scheme, authorization_params)
    do
      Repo.update(Changeset.change authorization, number: response["LOANo"])
      {:ok, response}
    end
  end

  def get_peme_authorization(authorization_id) do
    Repo.get(Authorization, authorization_id)
  end

  def validate_multiple_package_acu(member, facility, benefit_packages, coverage) do
    member_products =
      member.products
      |> Enum.map (&(&1))

    auth_benefit_packages =
      Authorization
      |> where([a],
        a.coverage_id == ^coverage.id and
        a.member_id == ^member.id and
        (a.status == "Approved" or
         a.status == "For Approval" or
         a.status == "Availed"))
      |> preload([authorization_benefit_packages: :benefit_package])
      |> Repo.all()
      |> Enum.map(&(get_bp_id(List.first(&1.authorization_benefit_packages))))

    benefit_packages
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.map(&(validate_acu_product_benefit(&1, member_products, auth_benefit_packages, facility, coverage)))
    |> Enum.uniq()
    |> List.delete(nil)
    |> Enum.map(&(validate_bp(&1, auth_benefit_packages)))
    |> List.flatten()
    |> Enum.empty?()
    |> validate_multiple_package_acu_v2(auth_benefit_packages)
  end

  defp get_bp_id(nil), do: nil
  defp get_bp_id(abp), do: abp.benefit_package_id

  defp validate_bp(id, []), do: id
  defp validate_bp(id, abp) do
    Enum.filter(abp, &(if &1 != id, do: id))
  end

  defp validate_acu_product_benefit(bp, mp, abp, facility, coverage) do
    with {:valid} <- validate_pf(bp, facility.id, abp),
         {:ok, member_product} <- validate_acu_member_product(
            mp,
            facility,
            bp,
            coverage),
         {:ok, bp_id} <-
            validate_acu_product_benefits(member_product)
            |> Enum.map(&(validate_apb(&1, bp)))
            |> Enum.uniq()
            |> Enum.filter(&(not is_nil(&1)))
            |> validate_acu_product_benefit_v2()
    do
      bp_id
    end
  end

  defp validate_apb(nil, _), do: nil
  defp validate_apb(_, nil), do: nil
  defp validate_apb(pb, bp), do: validate_apb(pb.benefit_id, bp.benefit_id, pb, bp)
  defp validate_apb(nil, _, _, _), do: nil
  defp validate_apb(_, nil, _, _), do: nil
  defp validate_apb(x, y, pb, bp) when x == y, do: validate_apb_v2(pb.benefit, bp)
  defp validate_apb_v2(nil, _), do: nil
  defp validate_apb_v2(pbb, bp), do: validate_apb_v3(pbb.provider_access, bp)
  defp validate_apb_v3(nil, _), do: nil
  defp validate_apb_v3(pbbp, bp), do: validate_apb_v4(String.contains?(pbbp, "Hospital"), pbbp, bp)
  defp validate_apb_v4(true, _, bp), do: bp
  defp validate_apb_v4(_, pbbp, bp), do: validate_apb_v5(String.contains?(pbbp, "Clinic"), bp)
  defp validate_apb_v5(true, bp), do: bp.id
  defp validate_apb_v5(_, _), do: nil

  defp validate_acu_product_benefits(nil), do: []
  defp validate_acu_product_benefits(mp), do: validate_apbs(mp.account_product)
  defp validate_apbs(nil), do: []
  defp validate_apbs(ap), do: validate_apbs_v2(ap.product)
  defp validate_apbs_v2(nil), do: []
  defp validate_apbs_v2(p), do: validate_apbs_v3(p.product_benefits)
  defp validate_apbs_v3([]), do: []
  defp validate_apbs_v3(pb), do: pb

  defp validate_pf(nil, _, _), do: nil
  defp validate_pf(bp, f_id, abp), do: validate_pf_v2(bp.package_id, f_id, abp)
  defp validate_pf_v2(nil, _, _), do: nil
  defp validate_pf_v2(id, f_id, abp), do: validate_pf_v3(PackageContext.get_package_facility(id), f_id, abp, id)
  defp validate_pf_v3([], _, _, _), do: nil
  defp validate_pf_v3(pf, f_id, abp, id), do: validate_pf_v4(Enum.map(pf, &(&1.facility_id)), f_id, abp, id)
  defp validate_pf_v4([], _, _, _), do: nil
  defp validate_pf_v4(pf, f_id, abp, id), do: validate_pf_v5(Enum.member?(pf, f_id), !Enum.member?(abp, id))
  defp validate_pf_v4(_, _, _, _), do: nil
  defp validate_pf_v5(true, true), do: {:valid}
  defp validate_pf_v5(_, _), do: nil

  defp validate_acu_member_product([], _, _, _), do: nil
  defp validate_acu_member_product(_, nil, _, _), do: nil
  defp validate_acu_member_product(_, _, nil, _), do: nil
  defp validate_acu_member_product(_, _, _, nil), do: nil
  defp validate_acu_member_product(a, b, c, d), do: validate_amp_v2(get_member_product_with_coverage_and_tier_with_package(a, b, c, d))
  defp validate_amp_v2(nil), do: nil
  defp validate_amp_v2(mp), do: {:ok, mp}

  defp validate_acu_product_benefit_v2([]), do: nil
  defp validate_acu_product_benefit_v2([pb | _]), do: {:ok, pb}

  defp validate_multiple_package_acu_v2(true, []), do: {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."}
  defp validate_multiple_package_acu_v2(true, _), do: {:invalid_coverage, "Member's ACU packages has been approved or availed"}
  defp validate_multiple_package_acu_v2(_, _), do: true

  def get_multiple_package_acu(member, facility, benefit_packages, coverage) do

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    benefit_packages =
      benefit_packages
      |> List.flatten
      |> Enum.uniq()
      |> List.delete(nil)

    authorizations =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id and
               a.member_id == ^member.id and
              (a.status == "Approved" or a.status == "For Approval" or a.status == "Availed"))
      |> Repo.all()
      |> Repo.preload([
        authorization_benefit_packages: [
          :benefit_package
        ]])

    auth_benefit_packages = Enum.map(authorizations, &(List.first(&1.authorization_benefit_packages).benefit_package_id))

    benefit_packages = for benefit_package <- benefit_packages do
      package_facility = PackageContext.get_package_facility(benefit_package.package_id)
      facility_ids = Enum.map(package_facility, &(&1.facility.id))

      if Enum.member?(facility_ids, facility.id) and not Enum.member?(auth_benefit_packages, benefit_package.id) do
        member_product = get_member_product_with_coverage_and_tier_with_package(member_products, facility, benefit_package, coverage)
        product_benefits = if not is_nil(member_product) do
          for pb <- member_product.account_product.product.product_benefits do
            if pb.benefit_id == benefit_package.benefit_id and
            (String.contains?(pb.benefit.provider_access, "Hospital") or
            String.contains?(pb.benefit.provider_access, "Clinic")) do
              pb
            end
          end
        else
          []
        end

        product_benefit =
          product_benefits
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()

        if not is_nil(member_product) and not is_nil(product_benefit) do
          %{
            benefit_package: benefit_package |> Repo.preload([:benefit]),
            product_benefit: product_benefit
          }
        end
      end
    end

    benefit_packages =
      benefit_packages
      |> List.flatten
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def get_member_product_with_coverage_and_tier_with_package(member_products, facility, bp, coverage) do

    member_products = for member_product <- member_products do
      product_benefits = member_product.account_product.product.product_benefits

      for product_benefit <- product_benefits do
        benefit_packages = product_benefit.benefit.benefit_packages
        Enum.map(benefit_packages, fn(benefit_package) ->
          if benefit_package.id == bp.id and filter_facility_access_of_product(member_product.account_product.product, facility, coverage) do
            member_product
          end
        end)
      end
    end

    member_products =
      member_products
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

    # tiering
    tier = for member_product <- member_products do
      member_product.tier
    end

    tier =
      tier
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

    tier = if Enum.count(tier) > 1 do
      Enum.min(tier)
    else
      Enum.at(tier, 0)
    end

    # member_product
    member_product = for member_product <- member_products do
      if member_product.tier == tier do
        member_product
      end
    end

    _member_product =
      member_product
      |> List.flatten()
      |> Enum.uniq()
      |> List.first()
  end

  defp filter_facility_access_of_product(product, facility, coverage) do
    product_coverage = Enum.map(product.product_coverages, fn(pc) ->
      if pc.coverage.id == coverage.id, do: pc
    end)

    product_coverage =
      product_coverage
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()

    cond do
      product_coverage.type == "inclusion" ->
        facility_ids = Enum.map(product_coverage.product_coverage_facilities, fn(pcf) ->
          pcf.facility_id
        end)
        if Enum.member?(facility_ids, facility.id) do
          true
        else
          false
        end

      product_coverage.type == "exception" ->
        facility_ids = Enum.map(product_coverage.product_coverage_facilities, fn(pcf) ->
          pcf.facility_id
        end)
        if not Enum.member?(facility_ids, facility.id) do
          true
        else
          false
        end

      true ->
        false
    end
  end

  def get_product_benefit_by_member_product_and_benefit_package(member_product, facility, bp, coverage) do
    product_benefits = member_product.account_product.product.product_benefits

    product_benefits = for product_benefit <- product_benefits do
      benefit_packages = product_benefit.benefit.benefit_packages
      Enum.map(benefit_packages, fn(benefit_package) ->
        if benefit_package.id == bp.id and filter_facility_access_of_product(member_product.account_product.product, facility, coverage) do
          product_benefit
        end
      end)
    end

    product_benefits =
      product_benefits
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end


  def get_claim_by_authorization_number(number) do
    Claim
    |> where([c], c.number == ^number)
    |> Repo.all()
  end

  def insert_facial_image(params) do
    with auth = %Authorization{} <- AuthorizationContext.get_authorization_by_id(params["authorization_id"]) do
      auth
        |> Authorization.changeset_facial_image(%{facial_image: params["link"]})
        |> Repo.update()
    end
  end
end

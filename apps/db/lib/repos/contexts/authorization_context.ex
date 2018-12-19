defmodule Innerpeace.Db.Base.AuthorizationContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Decimal

  alias Innerpeace.Db. {
    Repo,
    Schemas.Member,
    Schemas.Product,
    Schemas.Facility,
    Schemas.Practitioner,
    Schemas.ProductBenefit,
    Schemas.Benefit,
    Schemas.BenefitCoverage,
    Schemas.Authorization,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.AccountProduct,
    Schemas.AccountProductBenefit,
    Schemas.AuthorizationDiagnosis,
    Schemas.AuthorizationPractitioner,
    Schemas.AuthorizationAmount,
    # Schemas.AuthorizationProcedure,
    Schemas.AuthorizationProcedureDiagnosis,
    Schemas.AuthorizationRUV,
    Schemas.Coverage,
    Schemas.PayorProcedure,
    Schemas.AuthorizationBenefitPackage,
    Schemas.ApiAddress,
    Schemas.AuthorizationRUV,
    Base.ProductContext,
    Base.Api.PractitionerContext,
    Base.PractitionerContext,
    Base.BenefitContext,
    Base.Api.UtilityContext,
    Base.MemberContext,
    Base.SchedulerContext,
    Base.AcuScheduleContext,
    Schemas.AuthorizationRUV,
    Schemas.MemberProduct,
    Schemas.ProductBenefitLimit,
    Schemas.BenefitLimit,
    Schemas.Diagnosis,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityRoomRate,
    Schemas.Room,
    Schemas.PackageFacility,
    Schemas.ProductCoverage,
    Schemas.ProductExclusion,
    Base.AccountContext,
    Base.ApiAddressContext,
    Schemas.AuthorizationPractitionerSpecialization,
    Schemas.AuthorizationFile,
    Schemas.AuthorizationLog,
    Schemas.AuthorizationRoom,
    Schemas.Claim,
    Schemas.SchedulerLog,
    Schemas.AcuSchedule,
    Schemas.AcuScheduleMember
  }
  alias Innerpeace.Db.Schemas.Embedded.OPConsult
  alias Innerpeace.Db.Base.ProductContext
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView

  def list_authorizations do
    Authorization
    |> order_by([a], desc: a.updated_at)
    |> Repo.all()
    |> Repo.preload([:member, :coverage, :updated_by, :created_by, :authorization_amounts])
  end

  def list_approved_authorizations do
    Authorization
    |> where([a], a.status == "Approved" and a.number != "")
    |> order_by([a], asc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([:member, :coverage])
  end

  def get_all_loa_by_member_id(member_id) do
    Authorization
    |> join(:inner, [a], m in Member, a.member_id == m.id)
    |> where([a, m], (m.id == ^member_id or m.principal_id == ^member_id) and a.status != ^"Draft")
    |> Repo.all()
    |> Repo.preload([
        :member, :coverage, :facility,
        :authorization_amounts, authorization_practitioners: :practitioner
      ])
  end

  def get_all_loa_by_member_id(member_id, :selected) do
    Authorization
    |> join(:inner, [a], m in Member, a.member_id == m.id)
    |> join(:inner, [a, m], f in Facility, a.facility_id == f.id)
    |> join(:inner, [a, m, f], c in Coverage, a.coverage_id == c.id)
    |> join(:inner, [a, m, f, c], aa in AuthorizationAmount, a.id == aa.authorization_id)
    |> join(:inner, [a, m, f, c, aa], ap in AuthorizationPractitioner, a.id == ap.authorization_id)
    |> join(:inner, [a, m, f, c, aa, ap], p in Practitioner, ap.practitioner_id == p.id)
    |> where([a, m, f, c, aa, ap, p], (m.id == ^member_id or m.principal_id == ^member_id) and a.status != ^"Draft")
    |> select([a, m, f, c, aa, ap, p], [
        m.relationship,
        fragment("concat(?,' / ', ?, ' ', ?)", f.name, p.last_name, p.first_name),
        fragment("to_char(?::date, 'MM/DD/YYYY')", a.admission_datetime),
        c.name,
        a.status,
        aa.total_amount
       ])
    |> Repo.all()
  end

  def create_authorization(user_id, authorization_params) do
    authorization_params =
      authorization_params
      |> Map.put("step", 2)
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)
      |> Map.put("status", "Draft")
      |> Map.put("transaction_no", generate_transaction_no())

    %Authorization{}
    |> Authorization.changeset(authorization_params)
    |> Repo.insert()
  end

  def generate_transaction_no do
    random = String.upcase(generate_random_transaction_no())
    checker =
      Authorization
      |> where([a], a.transaction_no == ^random)
      |> Repo.all()
    if Enum.empty?(checker) do
      random
    else
      generate_transaction_no()
    end
  end

  def generate_random_transaction_no do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"
    rand = UtilityContext.do_randomizer(8, String.split("#{alphabets}#{numbers}", "", trim: true))
    with true <- String.contains?(rand, String.split(alphabets, "", trim: true)),
         true <- String.contains?(rand, String.split(numbers, "", trim: true))
    do
      rand
    else
      _ ->
      generate_random_transaction_no()
    end
  end

  def create_authorization_api(user_id, authorization_params) do
    authorization_params =
      authorization_params
      |> Map.put("step", 5)
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)
      |> Map.put("version", 1)
      |> Map.put("status", "Draft")
    unless Map.has_key?(authorization_params, "transaction_no") do
      authorization_params =
        Map.put(authorization_params, "transaction_no", generate_random_transaction_no())
    end

    %Authorization{}
    |> Authorization.changeset(authorization_params)
    |> Repo.insert()
  end

  def create_authorization_approved_api(user_id, authorization_params) do
    authorization_params =
      authorization_params
      |> Map.put("step", 5)
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)
      |> Map.put("version", 1)
      |> Map.put("status", "Approved")
    unless Map.has_key?(authorization_params, "transaction_no") do
      authorization_params =
        Map.put(authorization_params, "transaction_no", generate_random_transaction_no())
    end

    %Authorization{}
    |> Authorization.changeset(authorization_params)
    |> Repo.insert()
  end

  def get_member_benefit_coverage(id) do
    query = (
      from m in Member,
      join: ag in AccountGroup, on: m.account_code == ag.code,
      join: a in Account, on: a.account_group_id == ag.id,
      join: ap in AccountProduct, on: ap.account_id == a.id,
      join: apb in AccountProductBenefit, on: apb.account_product_id == ap.id,
      join: pb in ProductBenefit, on: pb.id == apb.product_benefit_id,
      join: b in Benefit, on: b.id == pb.benefit_id,
      join: bc in BenefitCoverage, on: bc.benefit_id == b.id,
      join: c in Coverage, on: c.id == bc.coverage_id,
      where: m.id == ^id and a.status == ^"Active",
      distinct: c.id,
      select: c
    )
    _query = Repo.all query
  end

  def get_authorization_by_id(nil), do: nil
  def get_authorization_by_id(authorization_id) do
    Authorization
    |> Repo.get(authorization_id)
    |> Repo.preload([
      [
        logs: {from(al in AuthorizationLog, order_by: [desc: al.inserted_at]), [:user]}
      ],
      [
        member: [
          :peme,
          :member_contacts,
          [peme_members: :peme],
          account_group: [:payment_account,
            account: from(a in Account, where: a.status == "Active")
          ]
        ]
      ],
      [
        authorization_facility_ruvs: [
          facility_ruv: :ruv,
          member_product: [
            account_product: :product
          ]
        ]
      ],
      [
        facility: [
          :category,
          :type,
          [facility_ruvs: :ruv],
          [facility_location_groups: :location_group]
        ]
      ],
      [authorization_practitioners:
       [practitioner:
        [practitioner_specializations: :specialization]]],
      [authorization_practitioner_specializations:
        [practitioner_specialization: [:specialization, practitioner: [practitioner_facilities: :practitioner_facility_consultation_fees]]]],
      :coverage,
      [authorization_diagnosis: [:diagnosis, member_product: [
            account_product: :product
          ]]],
      :authorization_amounts,
      [
        authorization_procedure_diagnoses: [
          :authorization,
          :payor_procedure,
          :diagnosis,
          [payor_procedure: :procedure],
          member_product: [
            account_product: :product
          ]
        ]
      ],
      [authorization_benefit_packages: :benefit_package]
    ])
  end

  def get_auth_amount_by_authorization_id(a_id) do
    AuthorizationAmount
    |> Repo.get_by(authorization_id: a_id)
  end

  def update_authorization(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.changeset(params)
    |> Repo.update()
  end

  def claims_file_update_authorization(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.claims_file_changeset(params)
    |> Repo.update()
  end

  def update_authorization_amount(authorization_id, params) do
    authorization_id
    |> get_auth_amount_by_authorization_id()
    |> AuthorizationAmount.approver_changeset(params)
    |> Repo.update()
  end

  def update_approve_authorization(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.consult_approve_changeset(params)
    |> Repo.update()
  end

  def update_emergency_approve_authorization(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.step4_emergency_changeset(params)
    |> Repo.update()
  end

  def validate_member_info(params) do
    birthdate =
      params["birthdate"]
      |> Ecto.Date.cast!()

    members =
      Member
      |> join(:inner, [m], ag in AccountGroup, m.account_code == ag.code)
      |> where([m, ag, a],
               fragment("to_tsvector(concat(?, ' ', ?, ' ', ?)) @@ plainto_tsquery(?)", m.first_name, m.middle_name, m.last_name, ^"#{params["full_name"]}")
               and fragment("? = coalesce(?, ?)", m.birthdate, ^birthdate, m.birthdate))
      |> select([m, ag, a],
                %{
                  id: m.id,
                  first_name: m.first_name,
                  middle_name: m.middle_name,
                  last_name: m.last_name,
                  suffix: m.suffix,
                  birthdate: m.birthdate,
                  email: m.email,
                  mobile: m.mobile,
                  code: ag.code,
                  name: ag.name,
                  status: m.status,
                  ag_id: ag.id,
                  expiry_date: m.expiry_date
                })
      |> Repo.all()

  case Enum.count(members) do
    0 ->
      {:not_exists}
    1 ->
      active_members =
        members
        |> Enum.filter(fn(member) -> member.status == "Active" end)

      if Enum.empty?(active_members) do
        {:not_active}
      else
        if Enum.empty?(validate_member_account_active(active_members)) do
          {:not_active}
        else
          members
          |> active_member_info()
        end
      end
    _ ->
      members
      |> active_member_info()
    end
  end

  defp validate_member_account_active(active_members) do
    _active_members =
      active_members
      |> Enum.filter(fn(member) ->
        active_account = AccountContext.get_active_account(member.ag_id)
        (if is_nil(active_account), do: "Inactive", else: active_account.status) == "Active"
      end)
  end

  defp active_member_info(members) do
    _members =
      members
      |> Enum.into([], fn(member) -> [
        member.id, member.first_name,
        member.middle_name, member.last_name,
        member.suffix, member.birthdate,
        member.email, member.mobile,
        member.code, member.name, member.status,
        member.ag_id, member.expiry_date]
      end)
  end

  def validate_card(params, scheme) do
    with %Member{} = member <- MemberContext.get_member_by_card_no(params["card_number"]),
         {:active} <-
           (if member.status == "Active", do: {:active}, else: {:not_active}),
         {:active} <-
           (if is_nil(AccountContext.get_active_account(member.account_group.id)), do: {:not_active}, else: {:active}),
         {:true} <- validate_cvv(member, params, scheme)
    do
      {:true, member}
    else
      nil ->
        {:invalid_details}
      {:not_active} ->
        {:not_active}
      {:false} ->
        {:invalid_details}
      {:api_address_not_exists} ->
        {:api_address_not_exists}
      {:error_connecting_api, response} ->
        {:error_connecting_api, response}
      {:unable_to_login, message} ->
        {:unable_to_login, message}
    end
  end

  def validate_cvv(member, params, scheme) do

    {year, month, _day} =
      Timex.to_erl(member.card_expiry_date)

    month =
      if String.length(Integer.to_string(month)) == 2 do
        month
      else
        "0#{month}"
      end

    expiry_date =
      "#{String.slice(Integer.to_string(year), 2,2)}#{month}"

    params = %{
      "CardNumber" => params["card_number"],
      "ExpiryDate" => expiry_date,
      "CVV" =>  params["cvv_number"],
      "ServiceCode": "000"
    }

    with {:ok, token} <- UtilityContext.payorlink_one_sign_in(scheme),
         %ApiAddress{} = api_address <- ApiAddressContext.get_api_address_by_name("PAYORLINK 1.0")
    do
      method = "#{api_address.address}/paylinkapi/api/PayLinkLOA/CVVVerifier"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body =
        params
        |> Poison.encode!()

    option =
      if Atom.to_string(scheme) == "http" do
        [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
      else
        [recv_timeout: 60_000]
      end

      with {:ok, response} <- HTTPoison.post(method, body, headers, option)
      do
        if Poison.decode!(response.body)["Result"] == "Yes" do
          {:true}
        else
          {:false}
        end
      else
        {:error, %HTTPoison.Error{reason: {reason, _description}}} ->
          {:error_connecting_api, reason}
      end

    else
      {:api_address_not_exists} ->
        {:api_address_not_exists}
      {:unable_to_login, message} ->
        {:unable_to_login, message}
      nil ->
        {:api_address_not_exists}
    end
  end

  def update_authorization_step2(user_id, authorization_params, authorization) do
    authorization_params =
      authorization_params
      |> Map.put("step", 3)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step2_changeset(authorization_params)
    |> Repo.update()
  end

  def load_valid_coverages(member_id) do
    member =
      Member
      |> where([m], m.id == ^member_id)
      |> Repo.one
      |> Repo.preload(
        [products:
         [account_product:
          [product:
           [product_coverages:
            [:coverage,
             [product_coverage_facilities: :facility]
            ]
           ]
          ]
         ]
        ]
      )

    mps = Enum.sort_by(
      member.products,
      &(&1.tier)
    )

    member_products = for member_product <- mps do
      pcs = member_product.account_product.product.product_coverages
      _coverage_and_type = for product_coverage <- pcs do
        %{
          product_coverage: product_coverage.coverage,
        }
      end
    end

    coverages = for member_product <- member_products do
      for details <- member_product do
        details.product_coverage
      end
    end

    valid_coverages = List.flatten(coverages)
  end

  def update_authorization_step3(%Authorization{} = authorization, authorization_params, user_id) do
    member =
      Member
      |> where([m], m.id == ^authorization.member_id)
      |> Repo.one
      |> Repo.preload([
        products: [
          account_product: [
            product: [
              product_coverages: [
                :coverage,
                [product_coverage_facilities: :facility]
              ]
            ]
          ]
        ]
      ])

    # member_products = for member_product <- Enum.sort_by(member.products, &(&1.tier)) do
    #   _coverage_and_type = for product_coverage <- member_product.account_product.product.product_coverages do
    #     %{
    #       product_coverage: product_coverage.coverage,
    #     }
    #   end
    # end

    member_products =
      member.products
      |> Enum.sort_by(&(&1.tier))
      |> Enum.map(fn(member_product) ->
        member_product.account_product.product.product_coverages
        |> Enum.map(&(%{product_coverage: &1.coverage}))
      end)

    # coverages = for member_product <- member_products do
    #   for details <- member_product do
    #     details.product_coverage
    #   end
    # end

    coverages =
      member_products
      |> Enum.map(fn(member_product) ->
        Enum.map(member_product, &(&1.product_coverage))
      end)

    valid_coverages = List.flatten(coverages)
    valid_coverage_ids = [] ++ for vc <- valid_coverages, do: vc.id
    coverage_id =  authorization_params["coverage_id"]

    with true <- validate_empty_authorization_params(authorization_params, coverage_id) do
      if Enum.member?(valid_coverage_ids, coverage_id) do
        coverage =
          Coverage
          |> where([c], c.id == ^coverage_id)
          |> Repo.one

        case coverage.code do
          "ACU" ->
            with true <- validate_acu(member, coverage, authorization),
                 true <- validate_acu_pf(authorization),
                 true <- validate_acu_frr(authorization)
            do
              update_step3_result(
                user_id,
                authorization,
                authorization_params
              )
            end
          _ ->
            update_step3_result(
              user_id,
              authorization,
              authorization_params
            )
        end
      else
        {:invalid_coverage, "Coverage is not covered by the selected facility."}
      end
    else
      {:invalid_coverage, "Please select a coverage."} ->
        {:invalid_coverage, "Please select a coverage."}
      _ ->
        {:invalid_coverage, "Please select a coverage."}
    end
  end

  defp validate_empty_authorization_params(authorization_params, coverage_id), do: validate_coverage_id_step3(coverage_id)
  defp validate_empty_authorization_params(authorization_params, coverage_id) when map_size(authorization_params) == 0, do:
    {:invalid_coverage, "Please select a coverage."}

  defp validate_coverage_id_step3(coverage_id), do: true
  defp validate_coverage_id_step3(coverage_id) when coverage_id == "", do: {:invalid_coverage, "Please select a coverage."}


  # def update_authorization_step3(%Authorization{} = authorization, authorization_params, user_id) do
  #   member =
  #     Member
  #     |> where([m], m.id == ^authorization.member_id)
  #     |> Repo.one
  #     |> Repo.preload([
  #       products: [
  #         account_product: [
  #           product: [
  #             product_coverages: [
  #               :coverage,
  #               [product_coverage_facilities: :facility]
  #             ]
  #           ]
  #         ]
  #       ]
  #     ])

  #   member_products = for member_product <- Enum.sort_by(member.products, &(&1.tier)) do
  #     _coverage_and_type = for product_coverage <- member_product.account_product.product.product_coverages do
  #       %{
  #         product_coverage: product_coverage.coverage,
  #       }
  #     end
  #   end

  #   coverages = for member_product <- member_products do
  #     for details <- member_product do
  #       details.product_coverage
  #     end
  #   end

  #   valid_coverages = List.flatten(coverages)
  #   valid_coverage_ids = [] ++ for vc <- valid_coverages, do: vc.id
  #   coverage_id =  authorization_params["coverage_id"]
  #   if authorization_params != %{} do
  #     if coverage_id == "" do
  #       {:invalid_coverage, "Please select a coverage."}
  #     else
  #       if Enum.member?(valid_coverage_ids, coverage_id) do
  #         coverage =
  #           Coverage
  #           |> where([c], c.id == ^coverage_id)
  #           |> Repo.one

  #         case coverage.code do
  #           "ACU" ->
  #             with true <- validate_acu(member, coverage, authorization),
  #                  true <- validate_acu_pf(authorization),
  #                  true <- validate_acu_frr(authorization)
  #             do
  #               update_step3_result(
  #                 user_id,
  #                 authorization,
  #                 authorization_params
  #               )
  #             end
  #           _ ->
  #             update_step3_result(
  #               user_id,
  #               authorization,
  #               authorization_params
  #             )
  #         end
  #       else
  #         {:invalid_coverage, "Coverage is not covered by the selected facility."}
  #       end
  #     end
  #   else
  #     {:invalid_coverage, "Please select a coverage."}
  #   end
  # end

  defp validate_acu_status(status) do
    if Enum.member?(status, "Approved") or Enum.member?(status, "For Approval") do
      {:invalid_coverage, "Member has already availed ACU LOA."}
    else
      true
    end
  end

  def validate_acu(member, coverage, authorization) do
    acu_authorization =
      Authorization
      |> where([a],
               a.coverage_id == ^coverage.id and
               a.member_id == ^member.id
      )
      |> Repo.all

    acu_authorization_ids = for a <- acu_authorization, do: a.id
    acu_authorization_status = for a <- acu_authorization, do: a.status

    if is_nil(acu_authorization) do
      validate_acu_status(acu_authorization_status)
    else
      if Enum.member?(acu_authorization_ids, authorization.id) do
        effectivity_date = member.effectivity_date
        expiry_date = member.expiry_date
        created_date = Ecto.Date.cast!(authorization.inserted_at)

        with true <- is_peme_effectivity(authorization, created_date, effectivity_date),
             true <- is_peme_expiry(authorization, created_date, expiry_date)
        do
          validate_acu_status(acu_authorization_status)
        else
          _ ->
            validate_acu_status(acu_authorization_status)
        end
      else
        validate_acu_status(acu_authorization_status)
      end
    end
  end

  defp is_peme_effectivity(authorization, created_date, effectivity_date) do
    if authorization.is_peme? do
      check_effectivity_date(created_date, effectivity_date)
    else
      true
    end
  end

  defp is_peme_expiry(authorization, created_date, effectivity_date) do
    if authorization.is_peme? do
      check_expiry_date(created_date, effectivity_date)
    else
      true
    end
  end

  def validate_acu_pf(authorization) do
    pfs = get_package_facility_by_facility_id(authorization.facility_id)
    pf_ids = for pf <- pfs, do: pf.package_id

    member = get_member_by_member_id(authorization.member_id)
    packages = for mp <- member.products do
      for pb <- mp.account_product.product.product_benefits do
        for bp <- pb.benefit.benefit_packages do
          bp.package.id
        end
      end
    end
    |> List.flatten
    |> List.first

    if Enum.member?(pf_ids, packages) do
      true
    else
      {:invalid_coverage, "ACU Package is not available on the selected facility."}
    end
  end

  def get_member_by_member_id(m_id) do
    Member
    |> where([m], m.id == ^m_id)
    |> Repo.one
    |> Repo.preload(
      [products:
       [account_product: [
         product: [
           product_benefits: [
             benefit: [
               [
                 benefit_packages: [package: :package_payor_procedure],
                 benefit_coverages: :coverage
               ]
             ]
           ]
         ]
       ]
       ]
      ]
    )
  end

  def validate_acu_frr(authorization) do
    member = get_member_by_member_id(authorization.member_id)

    acu_benefit = for mp <- member.products do
      for pb <- mp.account_product.product.product_benefits do
        for bc <- pb.benefit.benefit_coverages do
          if bc.coverage.code == "ACU" do
            pb.benefit
          end
        end
      end
    end
    |> List.flatten
    |> Enum.uniq
    |> List.delete(nil)
    |> List.first

    acu_type = acu_benefit.acu_type
    acu_coverage = acu_benefit.acu_coverage

    if acu_type == "Executive" and acu_coverage == "Inpatient" do
      frr = get_frr_by_facility_id(authorization.facility_id)
      if Enum.count(frr) > 0 do
        true
      else
        {:invalid_coverage, "ACU Package is not available on the selected facility."}
      end
    else
      true
    end
  end

  def get_frr_by_facility_id(f_id) do
    FacilityRoomRate
    |> where([frr], frr.facility_id == ^f_id)
    |> Repo.all
  end

  def get_package_facility_by_facility_id(f_id) do
    PackageFacility
    |> where([pf], pf.facility_id == ^f_id)
    |> Repo.all
  end

  defp check_effectivity_date(cd, ed) do
    if Ecto.Date.compare(cd, ed) != :lt do
      "error"
    else
      nil
    end
  end

  defp check_expiry_date(cd, ed) do
    if Ecto.Date.compare(cd, ed) != :gt do
      nil
    else
      "error"
    end
  end

  defp update_step3_result(user_id, authorization, authorization_params) do
    authorization_params =
      authorization_params
      |> Map.put("step", 4)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step3_changeset(authorization_params)
    |> Repo.update()
  end

  def update_authorization_step4_consult(authorization, params, valid, user_id) do
    if valid == true do
      status = "Approved"
    else
      status = "For Approval"
    end

    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", status)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step4_consult_changeset(params)
    |> Repo.update()
  end

  def validate_consultation(authorization, params) do
    diagnosis_id = params["diagnosis_id"]
    payor_covered = Decimal.new(params["payor_covered"])
    coverage_id = authorization.coverage_id
    product_id = params["product_id"]
    product = ProductContext.get_product!(product_id)
    _product_limit_type = product.limit_type
    product_limit_amount = product.limit_amount

    benefit_id = for product_benefit <- product.product_benefits do
      for coverage <- product_benefit.benefit.benefit_coverages do
        if coverage.coverage_id == coverage_id do
          product_benefit.benefit_id
        end
      end
    end

    benefit_id =
      benefit_id
      |> Enum.uniq()
      |> List.delete([nil])
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()

    benefit_diagnoses =
      BenefitContext.get_benefit_diagnoses_by_benefit_id(benefit_id)
    benefit_limits = BenefitContext.get_benefit_limits_by_benefit_id(benefit_id)

    diagnoses = for benefit_diagnosis <- benefit_diagnoses do
      benefit_diagnosis.diagnosis_id
    end

    diagnoses =
      diagnoses
      |> List.flatten()
      |> Enum.uniq()

    # Check Diagnosis
    diagnosis_valid = Enum.member?(diagnoses, diagnosis_id)
    if diagnosis_valid == true do
      # Check Product Limit
      product_valid = product_limit_amount > Decimal.new(payor_covered)
      if product_valid == true do
        # Check Benefit Limit
        valid = for benefit_limit <- benefit_limits do
          if String.contains?(benefit_limit.coverages, "OPC") do
            case benefit_limit.limit_type do
              "Peso" ->
                benefit_limit.limit_amount > payor_covered
              "Plan Limit Percentage" ->
                percent = benefit_limit.limit_percentage / 100
                percent_decimal = Decimal.new(percent)
                limit = Decimal.mult(product_limit_amount, percent_decimal)
                limit > payor_covered
              "Sessions" ->
                benefit_limit.limit_session > 0
            end
          end
        end
        _valid =
          valid
          |> List.flatten()
          |> List.first()
      else
          valid = false
      end
    else
      valid = false
    end
  end

  def validate_op_laboratory(authorization, params) do
    diagnosis_id = params["diagnosis_id"]
    payor_covered = Decimal.new(params["payor_covered"])
    coverage_id = authorization.coverage_id
    product_id = params["product_id"]
    product = ProductContext.get_product!(product_id)
    _product_limit_type = product.limit_type
    product_limit_amount = product.limit_amount

    benefit_id = for product_benefit <- product.product_benefits do
      for coverage <- product_benefit.benefit.benefit_coverages do
        if coverage.coverage_id == coverage_id do
          product_benefit.benefit_id
        end
      end
    end

    benefit_id =
      benefit_id
      |> Enum.uniq()
      |> List.delete([nil])
      |> List.flatten()
      |> List.first()

    benefit_diagnoses =
      BenefitContext.get_benefit_diagnoses_by_benefit_id(benefit_id)
    benefit_limits = BenefitContext.get_benefit_limits_by_benefit_id(benefit_id)

    diagnoses = for benefit_diagnosis <- benefit_diagnoses do
      benefit_diagnosis.diagnosis_id
    end

    diagnoses =
      diagnoses
      |> List.flatten()
      |> Enum.uniq()

      # Check Diagnosis
    diagnosis_valid = Enum.any?(diagnosis_id, fn x ->  x in diagnoses end)

    if diagnosis_valid == true do
      # Check Product Limit
      product_valid = product_limit_amount > Decimal.new(payor_covered)
      if product_valid == true do
        # Check Benefit Limit
        valid = for benefit_limit <- benefit_limits do
          if String.contains?(benefit_limit.coverages, "OPL") do
            case benefit_limit.limit_type do
              "Peso" ->
                benefit_limit.limit_amount > payor_covered
              "Plan Limit Percentage" ->
                percent = benefit_limit.limit_percentage / 100
                percent_decimal = Decimal.new(percent)
                limit = Decimal.mult(product_limit_amount, percent_decimal)
                limit > payor_covered
              "Sessions" ->
                benefit_limit.limit_session > 0
            end
          end
        end
        _valid =
          valid
          |> List.flatten()
          |> List.first()
      else
        valid = false
      end
    else
      valid = false
    end
  end

  def get_diagnosis_by_authorization_id(a_id) do
    AuthorizationDiagnosis
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:diagnosis])
  end

  def get_files_by_authorization_id(a_id) do
    AuthorizationFiles
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:files])
  end

  def get_file_by_authorization_id(a_id) do
    AuthorizationFiles
    |> where([af], af.authorization_id == ^a_id)
    |> Repo.one()
    rescue
    _ ->
      nil
  end

  def get_practitioner_by_authorization_id(a_id) do
    AuthorizationPractitioner
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:practitioner])
  end

  def get_practitioner_specialization_by_authorization_id(a_id) do
    AuthorizationPractitionerSpecialization
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:practitioner_specialization])
  end

  def get_procedure_by_authorization_id(a_id) do
    AuthorizationProcedureDiagnosis
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:payor_procedure, :diagnosis])
  end

  def get_amount_by_authorization_id(a_id) do
    AuthorizationAmount
    |> Repo.get_by(authorization_id: a_id)
  end

  def create_authorization_diagnosis(params, user_id) do
    authorization_diagnosis = get_diagnosis_by_authorization_id(params["authorization_id"])

    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    if is_nil(authorization_diagnosis) == false do
      if authorization_diagnosis.diagnosis_id != params["diagnosis_id"] do
        authorization_diagnosis
        |> Repo.delete

        %AuthorizationDiagnosis{}
        |> AuthorizationDiagnosis.changeset(params)
        |> Repo.insert()
      else
        authorization_diagnosis
        |> AuthorizationDiagnosis.changeset(params)
        |> Repo.update()
      end
    else
      %AuthorizationDiagnosis{}
      |> AuthorizationDiagnosis.changeset(params)
      |> Repo.insert()
    end
  end

  def create_authorization_diagnosis_op_lab(params, user_id) do
    authorization_diagnosis = get_diagnosis_by_authorization_id(params["authorization_id"])

    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    if is_nil(authorization_diagnosis) == false do
      for diagnosis_id <- params["diagnosis_id"] do
        if authorization_diagnosis.diagnosis_id != diagnosis_id do
          authorization_diagnosis
          |> Repo.delete

          %AuthorizationDiagnosis{}
          |> AuthorizationDiagnosis.changeset(%{
            diagnosis_id: diagnosis_id,
            authorization_id: params["authorization_id"],
            created_by_id: params["created_by_id"],
            updated_by_id: params["updated_by_id"]
          })
          |> Repo.insert()
        else
          authorization_diagnosis
          |> AuthorizationDiagnosis.changeset(%{
            diagnosis_id: diagnosis_id,
            authorization_id: params["authorization_id"],
            created_by_id: params["created_by_id"],
            updated_by_id: params["updated_by_id"]
          })
          |> Repo.update()
        end
      end
    else
      for diagnosis_id <- params["diagnosis_id"] do
        %AuthorizationDiagnosis{}
        |> AuthorizationDiagnosis.changeset(%{
          diagnosis_id: diagnosis_id,
          authorization_id: params["authorization_id"],
          created_by_id: params["created_by_id"],
          updated_by_id: params["updated_by_id"]
        })
        |> Repo.insert()
      end
    end
  end

  def create_authorization_practitioner(params, user_id) do
    authorization_pracitioner = get_practitioner_by_authorization_id(params["authorization_id"])
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)
    if is_nil(authorization_pracitioner) do
      %AuthorizationPractitioner{}
      |> AuthorizationPractitioner.changeset(params)
      |> Repo.insert()
    else
      nil
      # authorization_pracitioner
      # |> AuthorizationPractitioner.changeset(params)
      # |> Repo.update()
    end
  end

  def create_authorization_practitioner_specialization(params, user_id) do
    authorization_pracitioner_specialization = get_practitioner_specialization_by_authorization_id(params["authorization_id"])

    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)
    if is_nil(authorization_pracitioner_specialization) == false do
      if authorization_pracitioner_specialization.practitioner_specialization_id != params["practitioner_specialization_id"] do
        authorization_pracitioner_specialization
        |> Repo.delete
        %AuthorizationPractitionerSpecialization{}
        |> AuthorizationPractitionerSpecialization.changeset(params)
        |> Repo.insert()
      else
        authorization_pracitioner_specialization
        |> AuthorizationPractitionerSpecialization.changeset(params)
        |> Repo.update()
      end
    else
      %AuthorizationPractitionerSpecialization{}
      |> AuthorizationPractitionerSpecialization.changeset(params)
      |> Repo.insert()
    end
  end

  def create_authorization_procedure(params, user_id) do
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    %AuthorizationProcedureDiagnosis{}
    |> AuthorizationProcedureDiagnosis.changeset(params)
    |> Repo.insert()
  end

  def create_authorization_diagnosis_only(params, user_id) do
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    %AuthorizationProcedureDiagnosis{}
    |> AuthorizationProcedureDiagnosis.diagnosis_changeset(params)
    |> Repo.insert()
  end

  def create_authorization_amount(params, user_id) do
    authorization_amount =
      get_amount_by_authorization_id(params["authorization_id"])
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    if is_nil(authorization_amount) do
      %AuthorizationAmount{}
      |> AuthorizationAmount.changeset(params)
      |> Repo.insert()
    else
      authorization_amount
      |> AuthorizationAmount.changeset(params)
      |> Repo.update()
    end
  end

  # API
  def compute_consultation(params) do
    consultation_fee = if is_nil(params["consultation_fee"]) do
      Decimal.new(0)
    else
      Decimal.new(params["consultation_fee"])
    end
    copay = if is_nil(params["copay"]) do
      Decimal.new(0)
    else
      params["copay"]
    end
    covered = if is_nil(params["covered"]) do
      Decimal.new(0)
    else
      params["covered"]
    end
    risk_share_type = params["risk_share_type"]
    pec = if params["pec"] == "" do
      Decimal.new(0)
    else
      Decimal.new(params["pec"])
    end

    divider = Decimal.new(100)

    if risk_share_type == "" do
      if pec > Decimal.new(0) do
        payor = consultation_fee
        member = Decimal.sub(consultation_fee, payor)
      else
        pre_existing_percentage = Decimal.div(pec, divider)
        payor = Decimal.mult(consultation_fee, pre_existing_percentage)
        member = Decimal.sub(consultation_fee, payor)
      end
    else
      copay = if is_nil(copay) do
        Decimal.new(0)
      else
        Decimal.new(copay)
      end

      covered = if is_nil(covered) do
        Decimal.new(0)
      else
        Decimal.new(covered)
      end

      if pec == Decimal.new(0) do
        percent = Decimal.div(covered, divider)
        percent_decimal = percent
      else
        pre_existing_percentage = Decimal.div(pec, divider)
      end

      if risk_share_type == "Copayment" do
        if pec > Decimal.new(0) do
          _copayment_amount = Decimal.sub(consultation_fee, copay)
          covered_percentage = Decimal.div(covered, divider)
          payor_copay = Decimal.sub(consultation_fee, copay)
          payor_copay_pec = Decimal.mult(payor_copay, covered_percentage)
          payor = Decimal.mult(payor_copay_pec, pre_existing_percentage)
          member = Decimal.sub(consultation_fee, payor)
        else
          copayment_amount = Decimal.sub(consultation_fee, copay)
          covered_percentage = Decimal.div(covered, divider)
          payor_copay = if copay > consultation_fee do
            Decimal.new(0)
          else
            Decimal.sub(consultation_fee, copay)
          end
          payor = Decimal.mult(payor_copay, covered_percentage)
          if payor == 0 do
            member = consultation_fee
          else
            member = Decimal.sub(consultation_fee, payor)
          end
        end
      else
        if pec > Decimal.new(0) do
          coin_percentage = Decimal.div(Decimal.new(copay), divider)
          payor_coin = Decimal.mult(coin_percentage, consultation_fee)
          coin_covered_percentage = Decimal.div(Decimal.new(covered), divider)
          payor_coin_pec = Decimal.mult(payor_coin, coin_covered_percentage)
          payor = Decimal.mult(payor_coin_pec, pre_existing_percentage)
          member = Decimal.sub(consultation_fee, payor)
        else
          coin_percentage = Decimal.div(Decimal.new(copay), divider)
          payor_coin = Decimal.mult(coin_percentage, consultation_fee)
          coin_covered_percentage = Decimal.div(Decimal.new(covered), divider)
          payor = Decimal.mult(payor_coin, coin_covered_percentage)
          member = Decimal.sub(consultation_fee, payor)
        end
      end
    end
    %{payor: Decimal.new(payor), member: Decimal.new(member)}
  end
  # End API

  #MemberLink Functions Start
  def request_op_lab(params) do
    op_lab = Repo.get_by(Coverage, name: "OP Laboratory")
    params = %{
      admission_datetime: params["datetime"],
      member_id: params["member_id"],
      facility_id: params["provider_id"],
      chief_complaint: params["complaint"],
      availment_type: params["availment_type"],
      consultation_type: "initial",
      created_by_id: params["user_id"],
      updated_by_id: params["user_id"],
      step: 3,
    }
    params = Map.put_new(params, :coverage_id, op_lab.id)
    %Authorization{}
      |> Authorization.op_lab_changeset(params)
      |> Repo.insert()
  # case op_lab do
  #   {:ok, op_lab} -> {:ok, op_lab}
  #   {:error, changeset} -> {:error, changeset, false}
  # end
  end

  def check_consultation_fee(facility_id, practitioner_id) do
    consultation_fee = PractitionerContext.get_consultation_fee(practitioner_id,
                                                                facility_id)
    if is_nil(consultation_fee) do
      {:error_fee}
    else
      {:validate_fee}
    end
  end

  def check_consultation_fee_and_affiliation_date(facility_id, practitioner_id) do
    pf = PractitionerContext.get_pf_affiliation(practitioner_id,
                                                facility_id)
    if not is_nil(pf) do
      date_today = Ecto.Date.utc
      af = Ecto.Date.compare(pf.affiliation_date, date_today)
      daf = Ecto.Date.compare(pf.disaffiliation_date, date_today)
      if not is_nil(pf.consultation_fee)
      and (af == :lt or af == :eq)
      and daf == :gt
      do
        {:validate_fee}
      else
        {:error_fee}
      end
    else
      {:error_fee}
    end
  end

  def get_provider_by_id(id) do
    case UtilityContext.valid_uuid?(id) do
      {true, id} ->
        provider = get_provider(id)
        if not is_nil(provider) do
          if provider.status == "Affiliated" do
            %Facility{}
          else
            {:invalid_provider_affiliation}
          end
        else
          {:nil, "provider"}
        end
      {:invalid_id} ->
        {:invalid_id, "provider"}
    end
  end

  def get_provider(id) do
    Facility
    |> Repo.get(id)
  end

  def get_practitioner_by_id(id) do
    case UtilityContext.valid_uuid?(id) do
      {true, id} ->
        case PractitionerContext.get_a_practitioner(id) do
          %Practitioner{} ->
            %Practitioner{}
          nil ->
            {:nil, "practitioner"}
        end
      {:invalid_id} ->
        {:invalid_id, "practitioner"}
    end
  end

  #used for member_link_web request_loa
  def check_coverage_in_product(member_id, coverage_id) do
    Coverage
    |> join(:inner, [c], pc in ProductCoverage, pc.coverage_id == c.id)
    |> join(:inner, [c, pc], p in Product, p.id == pc.product_id)
    |> join(:inner, [c, pc, p], ac in AccountProduct, ac.product_id == p.id)
    |> join(:inner, [c, pc, p, ac], mp in MemberProduct, ac.id == mp.account_product_id)
    |> join(:inner, [c, pc, p, ac, mp], m in Member, m.id == mp.member_id)
    |> where([c, pc, p, ac, mp, m], m.id == ^member_id and c.id == ^coverage_id)
    |> select([c], c.id)
    |> Repo.all
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def request_op_consult(user_id, params) do
    provider_id = params["provider_id"]
    params = Map.put_new(params, "facility_id", provider_id)
    complaint = params["complaint"]
    params = Map.put_new(params, "chief_complaint", complaint)
    params = Map.merge(params, %{"step" => 4, "created_by_id" => user_id, "status" => "Pending"})
    %Authorization{}
      |> Authorization.op_consult_changeset(params)
      |> Repo.insert()
  # case op_lab do
  #   {:ok, op_lab} -> {:ok, op_lab}
  #   {:error, changeset} -> {:error, changeset, false}
  # end
  end

  def get_loa_using_member_id(id) do
    loa =
    Authorization
    |> where([l], l.member_id == ^id)
    |> order_by([l], asc: l.admission_datetime)
    |> Repo.all
    |> Repo.preload([
      :member,
      [facility:
       [:category, :type]],
      :coverage,
      [authorization_diagnosis: :diagnosis],
      [authorization_practitioner_specializations:
        [practitioner_specialization: [:practitioner, :specialization]]],
      :authorization_amounts
    ])
    if loa != [] do
      {:ok, loa}
    else
      {:error, "loa"}
    end
  end

  #MemberLink Functions End

  # OP Consult Validator

  def get_authorization_by_facility_member_coverage(member_id, facility_id,
                                                  coverage_id) do
    Authorization
    |> where([a], a.facility_id == ^facility_id and a.member_id == ^member_id
             and a.coverage_id == ^coverage_id)
    |> Repo.one()
  end

  def get_coverage_by_code do
    Coverage
    |> where([c], c.code == "OPC")
    |> select([c], c.id)
    |> Repo.one()
  end

  def modify_authorization(authorization, params, valid, user_id) do
    if valid == true do
      status = "Approved"
    else
      status = "For Approval"
    end

    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", status)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step4_consult_changeset(params)
    |> Repo.update()
  end

  def modify_authorization(authorization, params, valid, user_id) do
    if valid == true do
      status = "Approved"
    else
      status = "For Approval"
    end

    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", status)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step4_consult_changeset(params)
    |> Repo.update()
  end

  defp put_version(authorization) do
    if is_nil(authorization.version) do
      version = 1
    else
      version = authorization.version + 1
    end
  end

  def modify_loa(authorization, params, user_id) do
    authorization = get_authorization_by_id(authorization.id)

    params =
      params
      |> Map.put("updated_by_id", user_id)
      |> Map.put("version", put_version(authorization))
      |> Map.put("edited_by_id", nil)

    authorization
    |> Authorization.step4_consult_changeset(params)
    |> Repo.update()
  end

  def modify_loa_no_version(authorization, params, user_id) do
    authorization = get_authorization_by_id(authorization.id)

    params =
      params
      |> Map.put("updated_by_id", user_id)
      |> Map.put("edited_by_id", nil)

    authorization
    |> Authorization.step4_consult_changeset(params)
    |> Repo.update()
  end

  def save_authorization(authorization, params, user_id) do
    params =
      params
      |> Map.put("step", 4)
      |> Map.put("status", "Draft")
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.step4_consult_save_changeset(params)
    |> Repo.update()
  end

  def submit_authorization(authorization, params, user_id) do
    authorization
    |> Authorization.step4_consult_save_changeset(params)
    |> Repo.update()
  end

  def modify_authorization_laboratory_step4(authorization, params, user_id) do
    params =
      params
      |> Map.put("step", 4)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.changeset(params)
    |> Repo.update()
  end

  # OP Laboratory Validator

  def get_op_lab_coverage_id do
    Coverage
    |> where([c], c.code == ^"OPL")
    |> select([c], c.id)
    |> Repo.one()
  end

  def get_coverage_id_by_code(code) do
    Coverage
    |> where([c], c.code == ^code)
    |> select([c], c.id)
    |> Repo.one()
  end

  def create_authorization_op_lab(authorization, params, valid, user_id) do
    if valid == true do
      status = "Approved"
    else
      status = "For Approval"
    end

    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", status)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.op_laboratory_changeset(params)
    |> Repo.update()
  end

  def get_product_benefit_without_diagnosis_OPL(member_products, _changeset, tier) do
    product_benefit = for member_product <- member_products do
      if member_product.tier == tier do
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
          |> List.flatten()
          |> Enum.uniq()
          |> List.delete(nil)
        _product_benefit = for pb <- pbs do
          for _bd <- pb.benefit.benefit_diagnoses do
              pb
          end
        end
      end
    end
    _product_benefit =
      product_benefit
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end

  def get_all_authorization_procedure_diagnosis(authorization_id) do
    AuthorizationProcedureDiagnosis
    |> where([apd], apd.authorization_id == ^authorization_id)
    |> Repo.all()
    |> Repo.preload([
      :payor_procedure,
      :diagnosis,
      [authorization_practitioner_specialization: [practitioner_specialization: :practitioner]]])
  end

  def get_authorization_procedure_diagnosis(id) do
    AuthorizationProcedureDiagnosis
    |> Repo.get!(id)
  end

  def delete_authorization_procedure_diagnosis(id) do
    id
    |> get_authorization_procedure_diagnosis()
    |> Repo.delete()
  end

  def delete_authorization_ruv(id) do
    id
    |> get_authorization_ruv()
    |> Repo.delete()
  end

  def delete_authorization_amount(authorization_id) do
    AuthorizationAmount
    |> where([aa], aa.authorization_id == ^authorization_id)
    |> Repo.delete_all()
  end

  defp get_room_by_code do
    Room
    |> where([b], b.code == "16" and b.type == "OP")
    |> select([b], b.id)
    |> Repo.one()
  end

  def get_payor_procedure_by_facility(payor_procedure_id) do
    PayorProcedure
    |> where([pp], pp.id == ^payor_procedure_id)
    |> Repo.all
    |> Repo.preload([facility_payor_procedures:
                     [:facility_payor_procedure_rooms]])
  end

  def get_amount_by_payor_procedure_id(payor_procedure_id, _facility_id) do
    payor_procedures = get_payor_procedure_by_facility(payor_procedure_id)
    payor_procedures =
      payor_procedures
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    list = for payor_procedure <- payor_procedures do
      for fpp <- payor_procedure.facility_payor_procedures do
        for fppr <- fpp.facility_payor_procedure_rooms do
          fppr.amount
        end
      end
    end

    _list =
      list
      |> Enum.uniq()
      |> List.flatten()
      |> List.first()
  end

  def get_op_fppr_amount(payor_procedure_id, facility_id, unit) do
    fpp = get_facility_payor_procedure_op_room(payor_procedure_id, facility_id)

    fppr_amount =
      fpp.facility_payor_procedure_rooms
      |> Enum.reject(&(is_nil(&1.facility_room_rate.room)))
      |> List.first()

    if is_nil(fppr_amount) do
      ""
    else
      Decimal.mult(Decimal.new(fppr_amount.amount), Decimal.new(unit))
    end
  end

  def get_facility_payor_procedure_op_room(payor_procedure_id, facility_id) do
    FacilityPayorProcedure
    |> where([fpp], fpp.payor_procedure_id == ^payor_procedure_id and fpp.facility_id == ^facility_id)
    |> Repo.one()
    |> Repo.preload([
        facility_payor_procedure_rooms: [
          facility_room_rate: [
            room: (from r in Room, where: r.code == "16")
          ]
        ]
      ])
  end

  # COMPUTE LABORATORY
  # def compute_laboratory(params) do

  # end

  def validate_coverage(params) do
      member = MemberContext.get_a_member!(params["member_id"])
      product_tier = for member_product <- member.products do
        product = member_product.account_product.product
        if product.product_base == "Benefit-based" do
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
          if pbs != [] and product.step >= "7" and
          not is_nil(product.limit_amount) and product.limit_amount > 0 do
            member_product.tier
          end
        else
          pbs = for pbs <- product.product_coverages do
            if pbs.coverage.code == "OPC" do
              pbs
            end
          end
          pbs =
            pbs
            |> List.flatten()
            |> Enum.uniq()
            |> List.delete(nil)
          if pbs != [] and product.step >= "7" and
          not is_nil(product.limit_amount) and product.limit_amount > 0 do
            member_product.tier
          end
        end
      end
      product_tier =
        product_tier
        |> Enum.uniq()
        |> List.delete(nil)
      if product_tier == [] do
        {:error_coverage}
      else
        {:ok_coverage}
      end
  end

  def get_authorization_procedure_diagnosis_by_ids_delete do
      AuthorizationProcedureDiagnosis
      |> Repo.delete_all()
  end

  def get_authorization_procedure_diagnosis_by_ids(aid, pid, did) do
    AuthorizationProcedureDiagnosis
    |> where([apd], apd.authorization_id == ^aid and apd.payor_procedure_id == ^pid and apd.diagnosis_id == ^did)
    |> Repo.one()
  end

  def update_authorization_procedure_diagnosis(struct, params) do
    struct
    |> AuthorizationProcedureDiagnosis.changeset(params)
    |> Repo.update()
  end

  def update_authorization_ruv(struct, params) do
    struct
    |> AuthorizationRUV.changeset(params)
    |> Repo.update()
  end

  def get_member_product_with_coverage_and_tier2(member_products, coverage_id) do
    # coverage
    member_products = for member_product <- member_products do
      product_benefits = member_product.account_product.product.product_benefits
      for product_benefit <- product_benefits do
        benefit_coverages = product_benefit.benefit.benefit_coverages
        for benefit_coverage <- benefit_coverages do
          if benefit_coverage.coverage.id == coverage_id do
            member_product
          end
        end
      end
    end

    member_products =
      member_products
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)

    test = Enum.map(member_products, fn(x) ->
      x
    end)
  end

  ##################################  start of multiple product acu  ##########################################
  # def packages_based_on_age_and_gender(member_products, member, facility) do
  #   # if new_validate_product() do
  #   #   {:member_already_availed, "Member has already availed ACU LOA"}
  #   # else
  #     member_products
  #     # |> exclude_product_approved()
  #     |> Enum.map(&(&1.account_product.product.product_benefits
  #     |> Enum.into([], fn(x) ->
  #       x.benefit.benefit_packages
  #       |> Enum.map(fn(y) ->
  #         x.benefit.benefit_coverages
  #         |> Enum.map(fn(a) -> if a.coverage.description == "ACU", do:
  #           %{
  #             benefit_code: x.benefit.code,
  #             benefit_name: x.benefit.name,
  #             benefit_provider_access: x.benefit.provider_access,
  #             product_benefit_limit_amount: get_pbl_amount(x.id),  ## pbl = product_benefit_limit
  #             benefit_acu_type: x.benefit.acu_type,
  #             benefit_acu_coverage: x.benefit.acu_coverage,
  #             benefit_package_details: %{
  #               benefit_package_id: y.id,
  #               benefit_package_age_from: y.age_from,
  #               benefit_package_age_to: y.age_to,
  #               benefit_package_female: y.female,
  #               benefit_package_male: y.male,
  #               package_facility_rate: y.package.package_facility |> AuthorizationView.package_facility_rate(facility.id),
  #               package_name: y.package.name,
  #               package_code: y.package.code,
  #               package_payor_procedures: y.package.package_payor_procedure |> Enum.map(fn(p) ->
  #                 %{payor_procedure_code: p.payor_procedure.code, payor_procedure_description: p.payor_procedure.description, payor_procedure_id: p.payor_procedure.id} end)
  #             }
  #           },
  #           else: nil end) end) end)
  #     ))
  #     |> List.flatten()
  #     |> Enum.filter(fn(l) -> l != nil end)
  #     |> validate_gender(member, member.gender)
  #     |> validate_age(member.birthdate)

  #   # end


  # end

  def packages_based_on_age_and_gender(member_products, member, facility) do
    member_products
    |> Enum.map(&(&1.account_product.product.product_benefits
    |> Enum.into([], fn(x) ->
      x.benefit.benefit_packages
      |> Enum.map(fn(y) ->
        x.benefit.benefit_coverages
        |> packages_based_on_age_and_gender_coverage_checker(x, y, facility)
      end)
    end)
    ))
    |> List.flatten()
    |> Enum.filter(fn(l) -> l != nil end)
    |> validate_gender(member, member.gender)
    |> validate_age(member.birthdate)
  end

  defp packages_based_on_age_and_gender_coverage_checker(benefit_coverages, product_benefit, benefit_package, facility) do
    Enum.map(benefit_coverages, fn(benefit_coverage) ->
      if benefit_coverage.description == "ACU", do:
      %{
        benefit_code: product_benefit.benefit.code,
        benefit_name: product_benefit.benefit.name,
        benefit_provider_access: product_benefit.benefit.provider_access,
        product_benefit_limit_amount: get_pbl_amount(product_benefit.id),  ## pbl = product_benefit_limit
        benefit_acu_type: product_benefit.benefit.acu_type,
        benefit_acu_coverage: product_benefit.benefit.acu_coverage,
        benefit_package_details: %{
          benefit_package_id: benefit_package.id,
          benefit_package_age_from: benefit_package.age_from,
          benefit_package_age_to: benefit_package.age_to,
          benefit_package_female: benefit_package.female,
          benefit_package_male: benefit_package.male,
          package_facility_rate: benefit_package.package.package_facility |> AuthorizationView.package_facility_rate(facility.id),
          package_name: benefit_package.package.name,
          package_code: benefit_package.package.code,
          package_payor_procedures: benefit_package.package.package_payor_procedure |> Enum.map(fn(p) ->
            %{payor_procedure_code: p.payor_procedure.code, payor_procedure_description: p.payor_procedure.description, payor_procedure_id: p.payor_procedure.id} end)
        }
      },
      else: nil
    end)
  end

  def validate_gender(member_acu_packages, member, "Male"), do: filter_gender(member_acu_packages, member.gender)
  def validate_gender(member_acu_packages, member, "Female"), do: filter_gender(member_acu_packages, member.gender)
  defp filter_gender(member_acu_packages, "Male") do
    member_acu_packages
    |> Enum.filter(&(&1.benefit_package_details.benefit_package_male == true))
  end
  defp filter_gender(member_acu_packages, "Female") do
    member_acu_packages
    |> Enum.filter(&(&1.benefit_package_details.benefit_package_female == true))
  end

  defp validate_age(member_acu_packages, birthdate) do
    age = UtilityContext.age(birthdate)
    member_acu_packages
    |> Enum.filter(&(age >= &1.benefit_package_details.benefit_package_age_from and age <= &1.benefit_package_details.benefit_package_age_to ))
  end

  defp get_pbl_amount(product_benefit_id) do
    product_benefit_limit = ProductContext.get_product_benefit(product_benefit_id).product_benefit_limits |> Enum.at(0)
    if is_nil(product_benefit_limit) do
      Decimal.new(0)
    else
      product_benefit_limit.limit_amount || Decimal.new(0)
    end
  end
  ##############################  end of multiple product acu  #########################################

  # Abby
  def get_member_product_with_coverage_and_tier(member_products, coverage_id) do
    # coverage
    member_products = for member_product <- member_products do
      product_benefits = member_product.account_product.product.product_benefits
      for product_benefit <- product_benefits do
        benefit_coverages = product_benefit.benefit.benefit_coverages
        for benefit_coverage <- benefit_coverages do
          if benefit_coverage.coverage.id == coverage_id do
            member_product
          end
        end
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
      |> List.delete(nil)
      |> List.first()
  end

  def get_member_product_with_coverage_and_tier_clinic(member_products, coverage_id) do
    # coverage
    member_products = for member_product <- member_products do
      product_benefits = member_product.account_product.product.product_benefits
      for product_benefit <- product_benefits do
        if product_benefit.benefit.provider_access != "Mobile" do
          benefit_coverages = product_benefit.benefit.benefit_coverages
          for benefit_coverage <- benefit_coverages do
            if benefit_coverage.coverage.id == coverage_id do
              member_product
            end
          end
        end
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
      |> List.delete(nil)
      |> List.first()
  end

  # def get_member_product_with_coverage(member_products, coverage_id) do
  #   # coverage
  #   member_products = Enum.map(member_products, fn(member_product) ->
  #     product_benefits = member_product.account_product.product.product_benefits
  #     for product_benefit <- product_benefits do
  #       benefit_coverages = product_benefit.benefit.benefit_coverages
  #       for benefit_coverage <- benefit_coverages do
  #         if benefit_coverage.coverage.id == coverage_id do
  #           member_product
  #         end
  #       end
  #     end
  #   end)

  #   member_products =
  #     member_products
  #     |> List.flatten()
  #     |> Enum.uniq()
  #     |> List.delete(nil)
  # end

  def get_member_product_with_coverage(member_products, coverage_id) do
    # coverage
    member_products = Enum.map(member_products, fn(member_product) ->
      product_coverages = member_product.account_product.product.product_coverages
      for product_coverage <- product_coverages do
        if product_coverage.coverage.id == coverage_id do
          member_product
        end
      end
    end)

    member_products =
      member_products
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def get_product_benefit_with_coverage(product, coverage_id) do
    product_benefit = for product_benefit <- product.product_benefits do
      benefit_coverages = product_benefit.benefit.benefit_coverages
      for benefit_coverage <- benefit_coverages do
        if benefit_coverage.coverage.id == coverage_id do
          product_benefit
        end
      end
    end

    product_benefit =
      product_benefit
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()

    _product_benefit =
      product_benefit
      |> Repo.preload(
        benefit: [
          benefit_packages: [
            package: [
              :package_facility,
              package_payor_procedure: [
                payor_procedure: :procedure]
            ]
          ]
        ]
      )
  end

  def get_rnb_by_coverage(product, coverage_id) do
    room_and_board = for product_coverage <- product.product_coverages do
      if product_coverage.coverage.id == coverage_id do
        product_coverage =
          product_coverage
          |> Repo.preload(
            :product_coverage_room_and_board
          )

        product_coverage.product_coverage_room_and_board
      end
    end

    _room_and_board =
      room_and_board
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.first()
  end
  # End Abby

  # ACU
  def compute_acu(params) do
    package_rate = Decimal.new(params["package_rate"])
    rnb = params["rnb"]
    rnb_amount = if is_nil(params["rnb_amount"]), do: Decimal.new(0), else: Decimal.new(params["rnb_amount"])
    rnb_id = params["rnb_id"]
    rnb_hierarchy = params["rnb_hierarchy"]
    selected_room_id = params["selected_room_id"]
    selected_room_rate = Decimal.new(params["selected_room_rate"])
    selected_room_hierarchy = params["selected_room_hierarchy"]

    case rnb do
      "Peso Based" ->
        if selected_room_rate > rnb_amount do
          member_covered = Decimal.sub(selected_room_rate, rnb_amount)
          payor_covered = Decimal.add(package_rate, rnb_amount)
        else
          member_covered = ""
          payor_covered = Decimal.add(package_rate, selected_room_rate)
        end
     "Nomenclature" ->
        if selected_room_id != rnb_id do
          if selected_room_hierarchy > rnb_hierarchy do
            member_covered = selected_room_rate
            payor_covered = package_rate
          else
            member_covered = ""
            payor_covered = Decimal.add(package_rate, selected_room_rate)
          end
        else
          member_covered = ""
          payor_covered = Decimal.add(package_rate, selected_room_rate)
        end
      "Alternative" ->
        cond do
          selected_room_id == rnb_id ->
            member_covered = ""
            payor_covered = Decimal.add(package_rate, selected_room_rate)
          selected_room_rate <= rnb_amount ->
            member_covered = ""
            payor_covered = Decimal.add(package_rate, selected_room_rate)
          true ->
            member_covered = Decimal.sub(selected_room_rate, rnb_amount)
            payor_covered = Decimal.add(package_rate, rnb_amount)
        end
    end

    payor_covered = Decimal.new(payor_covered)
    member_covered =
    if is_nil(member_covered) or member_covered == "" do
      ""
    else
      Decimal.new(member_covered)
    end

    %{payor: payor_covered, member: member_covered}
  end

  def update_authorization_step4_acu(authorization, params, user_id) do
    admission = params["admission_datetime"]
    if is_nil(admission) or admission == "" do
      nil
    else
      admission = "#{admission} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end

    discharge = params["discharge_datetime"]
    if is_nil(discharge) or discharge == "" do
      nil
    else
      discharge = "#{discharge} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end

    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", "Approved")
      |> Map.put("updated_by_id", user_id)
      |> Map.put("created_by_id", user_id)
      |> Map.put("approved_by_id", user_id)
      |> Map.put("approved_datetime", Ecto.DateTime.utc)
      |> Map.put("admission_datetime", admission)
      |> Map.put("discharge_datetime", discharge)

    {:ok, authorization} =
      authorization
      |> Authorization.acu_changeset(params)
      |> Repo.update()

    if authorization.status == "Approved"  do
      authorization
      |> Authorization.loa_number_changeset
      |> Repo.update()
    else
      {:ok, authorization}
    end
  end

  def update_authorization_step4_peme(authorization, params, user_id) do
    admission = params["admission_datetime"]
    if is_nil(admission) or admission == "" do
      nil
    else
      admission = "#{admission} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end

    discharge = params["discharge_datetime"]
    if is_nil(discharge) or discharge == "" do
      nil
    else
      discharge = "#{discharge} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end
    params =
      params
      # |> Map.put("step", 4)
      # |> Map.put("status", "Draft")
      |> Map.put("step", 5)
      |> Map.put("is_peme", true)
      |> Map.put("status", "Approved")
      |> Map.put("updated_by_id", user_id)
      |> Map.put("created_by_id", user_id)
      |> Map.put("approved_by_id", user_id)
      |> Map.put("approved_datetime", Ecto.DateTime.utc)
      |> Map.put("admission_datetime", admission)
      |> Map.put("discharge_datetime", discharge)

    {:ok, authorization} =
      authorization
      |> Authorization.acu_changeset(params)
      |> Repo.update()

    if authorization.status == "Approved"  do
      authorization
      |> Authorization.loa_number_changeset
      |> Repo.update()
    else
      {:ok, authorization}
    end
  end

  def approve_authorization_step4_peme(authorization, user_id) do
    params = %{}
    params =
      params
      |> Map.put("step", 5)
      |> Map.put("status", "Approved")
      |> Map.put("updated_by_id", user_id)
      |> Map.put("approved_by_id", user_id)
      |> Map.put("approved_datetime", Ecto.DateTime.utc)

    {:ok, authorization} =
      authorization
      |> Authorization.peme_changeset(params)
      |> Repo.update()

    if authorization.status == "Approved"  do
      authorization
      |> Authorization.loa_number_changeset
      |> Repo.update()
    else
      {:ok, authorization}
    end
  end

  def create_authorization_benefit_package(params, user_id) do
    benefit_package = get_benefit_package_by_authorization_id(params["authorization_id"])

    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    if is_nil(benefit_package) == false do
      if benefit_package.benefit_package_id != params["benefit_package_id"] do
        benefit_package
        |> Repo.delete

        %AuthorizationBenefitPackage{}
        |> AuthorizationBenefitPackage.changeset(params)
        |> Repo.insert()
      else
        benefit_package
        |> AuthorizationBenefitPackage.changeset(params)
        |> Repo.update()
      end
    else
      %AuthorizationBenefitPackage{}
      |> AuthorizationBenefitPackage.changeset(params)
      |> Repo.insert()
    end
  end

  def get_benefit_package_by_authorization_id(a_id) do
    AuthorizationBenefitPackage
    |> Repo.get_by(authorization_id: a_id)
    |> Repo.preload([:benefit_package])
  end
  # End ACU

  def delete_authorization_step_4_setup(authorization_id) do
    with {_count, nil} <- delete_all_authorization_procedure_diagnosis(authorization_id),
         {_count, nil} <- delete_all_authorization_diagnoses(authorization_id),
         {_count, nil} <- delete_all_authorization_practitioners(authorization_id),
         {_count, nil} <- delete_all_authorization_amounts(authorization_id),
         {_count, nil} <- delete_all_authorization_ruvs(authorization_id)
    do
      {:ok}
    else
      _ ->
        {:error}
    end
  end

  def delete_authorization_peme_accountlink(authorization_id) do
    with {_count, nil} <- delete_all_authorization_procedure_diagnosis(authorization_id),
         {_count, nil} <- delete_all_authorization_diagnoses(authorization_id),
         {_count, nil} <- delete_all_authorization_practitioners(authorization_id),
         {_count, nil} <- delete_all_authorization_amounts(authorization_id),
         # {_count, nil} <- delete_all_authorization_ruvs(authorization_id),
         {_count, nil} <- delete_all_authorization_benefit_packages(authorization_id),
         {_count, nil} <- delete_authorization_by_authorization_id(authorization_id)
    do
      {:ok}
    else
      _ ->
        {:error}
    end
  end

  def delete_authorization_by_authorization_id(authorization_id) do
    Authorization
      |> where([a], a.id == ^authorization_id)
      |> Repo.one()
      |> Repo.delete!()
  end

  def delete_all_authorization_benefit_packages(authorization_id) do
    AuthorizationBenefitPackage
      |> where([abp], abp.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def delete_all_authorization_procedure_diagnosis(authorization_id) do
    AuthorizationProcedureDiagnosis
      |> where([apd], apd.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def delete_all_authorization_diagnoses(authorization_id) do
    AuthorizationDiagnosis
      |> where([ad], ad.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def delete_all_authorization_practitioners(authorization_id) do
    AuthorizationPractitioner
      |> where([ap], ap.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def delete_all_authorization_amounts(authorization_id) do
    AuthorizationAmount
      |> where([aa], aa.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def delete_all_authorization_ruvs(authorization_id) do
    AuthorizationRUV
      |> where([aa], aa.authorization_id == ^authorization_id)
      |> Repo.delete_all()
  end

  def get_authorization_ruv(authorization_id, facility_ruv_id) do
    AuthorizationRUV
    |> Repo.get_by!(%{
      facility_ruv_id: facility_ruv_id,
      authorization_id: authorization_id
    })
  end

  def get_loa_number_by_loa_id(authorization_id) do
    loa_num =
      Authorization
      |> where([a], a.id == ^authorization_id)
      |> select([a], a.number)
      |> Repo.one
  end

  def get_authorization_ruv(authorization_ruv_id) do
    AuthorizationRUV
    |> Repo.get!(authorization_ruv_id)
  end

  def create_authorization_ruv(params) do
    %AuthorizationRUV{}
    |> AuthorizationRUV.changeset(params)
    |> Repo.insert!()
  end

  def check_excess_outer_limit(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    checker =
      authorization.authorization_procedure_diagnoses
      |> filter_used_products_per_procedure()
      |> Enum.group_by(&(&1.member_product_id))
      |> compute_outer_limit_excess(authorization.member_id, active_account, authorization)
    number_of_exceeded = Enum.filter(checker, &(&1.exceeded_outer_limit == true))
    if Enum.count(number_of_exceeded) > 0 do
      {:outer_limit_exceeded}
    else
      {:ok}
    end
  end

  def compute_outer_limit_excess(member_products, member_id, active_account, authorization) do
    Enum.map(member_products, fn({member_product_id, diagnosis_procedures}) ->
      {product_limit, limit_type} = get_member_product_limit(member_product_id)
      if limit_type == "ABL" do
        %{
          member_product_id: member_product_id,
          exceeded_outer_limit: diagnosis_procedures |> compute_abl_excess(
            member_product_id,
            product_limit,
            # member_id,
            active_account,
            authorization) |> less_than_zero?(),
          limit_type: "ABL"
        }
      else
        %{
          member_product_id: member_product_id,
          exceeded_outer_limit: compute_mbl_excess(
            diagnosis_procedures,
            # member_product_id,
            product_limit,
            # member_id,
            active_account,
            authorization
          ),
          limit_type: "MBL"
        }
      end
    end)
  end

  def less_than_zero?(decimal) do
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

  def compute_abl_excess(diagnosis_procedures, member_product_id, product_limit, active_account, authorization) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    get_used_limit_per_product(member_product_id, start_date, end_date, authorization)
    get_used_limit_per_product_ad(member_product_id, start_date, end_date, authorization)

    used_limit_total =
      Decimal.add(
        get_used_limit_per_product(
          member_product_id,
          start_date,
          end_date,
          authorization
        ),
        get_used_limit_per_product_ad(
          member_product_id,
          start_date,
          end_date,
          authorization
        )
      )

    remaining_product_limit = Decimal.sub(product_limit, used_limit_total)
    total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    _remaining_balance_after_deductions = Decimal.sub(remaining_product_limit, total_payor_pays)
  end

  # def compute_abl_excess(diagnosis_procedures, member_product_id, product_limit, _member_id, active_account, authorization) do
  #   start_date = active_account.start_date
  #   end_date = active_account.end_date
  #   get_used_limit_per_product(member_product_id, start_date, end_date, authorization)
  #   get_used_limit_per_product_ad(member_product_id, start_date, end_date, authorization)

  #   used_limit_total =
  #     Decimal.add(
  #       get_used_limit_per_product(
  #         member_product_id,
  #         start_date,
  #         end_date,
  #         authorization
  #       ),
  #       get_used_limit_per_product_ad(
  #         member_product_id,
  #         start_date,
  #         end_date,
  #         authorization
  #       )
  #     )

  #   remaining_product_limit = Decimal.sub(product_limit, used_limit_total)
  #   total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  #   _remaining_balance_after_deductions = Decimal.sub(remaining_product_limit, total_payor_pays)
  # end

  def compute_mbl_excess(diagnosis_procedures, product_limit, active_account, authorization) do
    start_date = active_account.start_date
    end_date = active_account.end_date

    diagnosis_procedures
    |> Enum.group_by(&(&1.diagnosis_code))
    |> hellohei(start_date, end_date, authorization, product_limit)
  end

  # def compute_mbl_excess(diagnosis_procedures, _member_product_id, product_limit, _member_id, active_account, authorization) do
  #   start_date = active_account.start_date
  #   end_date = active_account.end_date

  #   diagnosis_procedures
  #   |> Enum.group_by(&(&1.diagnosis_code))
  #   |> hellohei(start_date, end_date, authorization, product_limit)
  # end

  defp hellohei(grouped_diagnoses_procedures, start_date, end_date, authorization, product_limit) do
    checker = Enum.map(grouped_diagnoses_procedures, fn({diagnosis_code, diagnosis_procedures}) ->
      diagnosis_group = String.slice(diagnosis_code, 0..2)
      member_product_id = List.first(diagnosis_procedures).member_product_id

      used_limit_total =
        member_product_id
        |> get_used_limit_per_diagnosis_group_ad(diagnosis_group, start_date, end_date, authorization)
        |> Decimal.add(
          get_used_limit_per_diagnosis_group(
            member_product_id,
            diagnosis_group,
            start_date,
            end_date,
            authorization
          )
        )

      total_payor_pays =
        diagnosis_procedures
        |> Enum.map(&(&1.payor_pays))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      remaining_mbl_limit = Decimal.sub(product_limit, used_limit_total)
      remaining_balance_after_deductions = Decimal.sub(remaining_mbl_limit, total_payor_pays)
      if less_than_zero?(remaining_balance_after_deductions) do
        true
      else
        false
      end
    end)
    if Enum.member?(checker, true) do
      true
    else
      false
    end
  end

  def check_excess_limits(authorization) do
    with {:ok} <- check_excess_outer_limit(authorization),
         {:ok} <- check_excess_inner_limit(authorization),
         true <- authorization.authorization_procedure_diagnoses
                  |> filter_uncovered(authorization.authorization_facility_ruvs)
                  |> Enum.empty?()
    do
      {:ok}
    else
      _ ->
        {:invalid}
    end
  end

  def check_excess_limits_emergency(authorization) do
    with {:ok} <- check_excess_outer_limit(authorization),
         {:ok} <- check_excess_inner_limit_emergency(authorization),
         true <- authorization.authorization_procedure_diagnoses
                  |> filter_uncovered(authorization.authorization_facility_ruvs)
                  |> Enum.empty?()
    do
      {:ok}
    else
      _ ->
        {:invalid}
    end
  end

  def check_excess_inner_limit_emergency(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    haha =
      authorization.authorization_procedure_diagnoses
      |> filter_used_products_per_procedure()
      |> Enum.reject(&(&1.product_base == "Exclusion-based" or is_nil(&1.product_benefit_id)))
      |> Enum.group_by(&(&1.product_benefit_id))
    checker =
      Enum.map(haha, fn({product_benefit_id, diagnosis_procedures}) ->
        product_benefit_limit = get_benefit_limit(product_benefit_id, "EMRGNCY")
        case product_benefit_limit.limit_type do
          "Peso" ->
            check_peso_inner_limit(
              product_benefit_limit.limit_amount,
              diagnosis_procedures
            )
          "Plan Limit Percentage" ->
            check_percentage_inner_limit(
              product_benefit_limit.product_limit,
              diagnosis_procedures,
              product_benefit_limit.limit_percentage
            )
          "Sessions" ->
            check_sessions_inner_limit(
              product_benefit_limit.limit_session,
              diagnosis_procedures,
              authorization,
              active_account
            )
          _ ->
            raise "Inavalid product benefit limit type"
        end
      end)
    if Enum.member?(checker, true) do
      {:inner_limit_exceeded}
    else
      {:ok}
    end
  end

  def check_excess_inner_limit(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    haha =
      authorization.authorization_procedure_diagnoses
      |> filter_used_products_per_procedure()
      |> Enum.reject(&(&1.product_base == "Exclusion-based" or is_nil(&1.product_benefit_id)))
      |> Enum.group_by(&(&1.product_benefit_id))
    checker =
      Enum.map(haha, fn({product_benefit_id, diagnosis_procedures}) ->
        product_benefit_limit = get_benefit_limit(product_benefit_id, "OPL")
        case product_benefit_limit.limit_type do
          "Peso" ->
            check_peso_inner_limit(
              product_benefit_limit.limit_amount,
              diagnosis_procedures
            )
          "Plan Limit Percentage" ->
            check_percentage_inner_limit(
              product_benefit_limit.product_limit,
              diagnosis_procedures,
              product_benefit_limit.limit_percentage
            )
          "Sessions" ->
            check_sessions_inner_limit(
              product_benefit_limit.limit_session,
              diagnosis_procedures,
              authorization,
              active_account
            )
          _ ->
            raise "Inavalid product benefit limit type"
        end
      end)
    if Enum.member?(checker, true) do
      {:inner_limit_exceeded}
    else
      {:ok}
    end
  end

  defp check_peso_inner_limit(product_limit, diagnosis_procedures) do
    total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    product_limit |> Decimal.sub(total_payor_pays) |> less_than_zero?()
  end

  defp check_percentage_inner_limit(product_limit, diagnosis_procedures, percentage_amount) do
    percentage_amount =
      percentage_amount
      |> Decimal.new()
    total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    total_percentage_amount = Decimal.div(percentage_amount || Decimal.new(0), Decimal.new(100))
    total_percentage =
      total_percentage_amount
      |> Decimal.mult(product_limit)
    total_percentage |> Decimal.sub(total_payor_pays) |> less_than_zero?()
  end

  defp check_sessions_inner_limit(limit_sessions, diagnosis_procedures, authorization, active_account) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    product_benefit_id = List.first(diagnosis_procedures).product_benefit_id
    current_session_count = diagnosis_procedures |> Enum.map(&(&1.unit)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    used_benefit_session =
      authorization.member_id
      |> get_used_limit_per_product_benefit(
        product_benefit_id,
        start_date,
        end_date,
        authorization
      )
      |> Decimal.new()

    total_used = Decimal.add(current_session_count, used_benefit_session)
    limit_sessions |> Decimal.new() |> Decimal.sub(total_used) |> less_than_zero?()
  end

  defp filter_uncovered(authorization_diagnosis_procedures, authorization_ruvs) do
    Enum.filter(authorization_diagnosis_procedures, &(is_nil(&1.member_product_id))) ++
      Enum.filter(authorization_ruvs, &(is_nil(&1.member_product_id)))
  end

  defp filter_used_products_per_procedure(authorization_diagnosis_procedures) do
    Enum.map(Enum.filter(authorization_diagnosis_procedures, &(!is_nil(&1.member_product_id))), &(
      %{
        member_product_id: &1.member_product_id,
        payor_pays: &1.payor_pay,
        product_benefit_id: &1.product_benefit_id,
        diagnosis_id: &1.diagnosis_id,
        diagnosis_code: &1.diagnosis.code,
        limit_type: &1.member_product.account_product.product.limit_type,
        product_base: &1.member_product.account_product.product.product_base,
        unit: &1.unit
      }
    ))
  end

  defp filter_used_products_per_ruv(authorization_ruvs) do
    authorization_ruvs
    |> Enum.map(&(%{
      member_product_id: &1.member_product_id,
      payor_pays: &1.payor_pay,
      product_benefit_id: &1.product_benefit_id
    }))
    |> Enum.filter(&(!is_nil(&1.member_product_id)))
  end

  defp get_member_product_limit(member_product_id) do
    _mp =
      MemberProduct
      |> join(:inner, [mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [mp, ap], p in Product, ap.product_id == p.id)
      |> where([mp, ap], mp.id == ^member_product_id)
      |> select([mp, ap, p], {p.limit_amount, p.limit_type})
      |> Repo.one()
  end

  defp get_product_benefit_limit(adp, coverage_code, authorization) do
    pb =
      ProductBenefit
      |> join(:inner, [pb], pbl in ProductBenefitLimit, pb.id == pbl.product_benefit_id)
      |> where([pb, pbl], pb.id == ^adp.product_benefit_id)
      |> Repo.one()
      |> Repo.preload(:product_benefit_limits)
    Enum.find(pb.product_benefit_limits, &(String.contains?(&1.coverages, coverage_code)))
  end

  defp get_used_limit_per_product(member_product_id, effectivity_date, expiry_date, authorization) do
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

  def get_used_limit_per_product_ad(member_product_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)

    payor_pays = AuthorizationDiagnosis
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

  def get_used_limit_per_product_in_op_consult(member_product_id, effectivity_date, expiry_date) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationAmount
    |> join(:inner, [am], a in Authorization, am.authorization_id == a.id)
    |> join(:inner, [am, a], ad in AuthorizationDiagnosis, a.id == ad.authorization_id)
    |> join(:inner, [am, a, ad], mp in MemberProduct, ad.member_product_id == mp.id)
    |> where(
      [am, a, ad, mp],
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      mp.id == ^member_product_id and
      a.status == "Approved"
    )
    |> select([am, a], am.payor_covered)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp get_used_limit_per_diagnosis_group(member_product_id, diagnosis_group, effectivity_date, expiry_date, authorization) do
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

  def get_used_limit_per_diagnosis_group_ad(member_product_id, diagnosis_group, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    payor_pays = AuthorizationDiagnosis
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

  def get_used_limit_per_product_benefit(_member_id, product_benefit_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationProcedureDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      apd.product_benefit_id == ^product_benefit_id and
      a.id != ^authorization.id and
      a.member_id == ^authorization.member_id and
      a.status == "Approved" and
      is_nil(apd.payor_pay) == false
    )
    |> select([apd, a], apd)
    |> Repo.all()
    # |> Enum.count()
  end

# Emergency Validator
  def request_emergency(params) do
    emergency = Repo.get_by(Coverage, name: "Emergency")
    params = %{
      admission_datetime: params["datetime"],
      member_id: params["member_id"],
      facility_id: params["provider_id"],
      chief_complaint: params["complaint"],
      availment_type: params["availment_type"],
      consultation_type: "initial",
      created_by_id: params["user_id"],
      updated_by_id: params["user_id"],
      step: 3,
    }
    params = Map.put_new(params, :coverage_id, emergency.id)
    %Authorization{}
      |> Authorization.emergency_changeset(params)
      |> Repo.insert()
  end

  def get_emergency_coverage_id do
    Coverage
    |> where([c], c.code == ^"EMRGNCY")
    |> select([c], c.id)
    |> Repo.one()
  end

  def modify_authorization_emergency_step4(authorization, params, user_id) do
    params =
      params
      |> Map.put("step", 4)
      |> Map.put("updated_by_id", user_id)

    authorization
    |> Authorization.emergency_changeset(params)
    |> Repo.update()
  end

  def get_benefit_limit(product_benefit_id, coverage) do
    pb =
      ProductBenefit
      |> where([pb], pb.id == ^product_benefit_id)
      |> Repo.one()
      |> Repo.preload([:benefit, :product, :product_benefit_limits])
    pb.product_benefit_limits
    |> Enum.find(&(String.contains?(&1.coverages, coverage)))
    |> Map.put(:product_limit, pb.product.limit_amount)
  end

  def get_exclusion_limit(product_exclusion_id) do
    pb =
      ProductExclusion
      |> where([pe], pe.id == ^product_exclusion_id)
      |> Repo.one()
      |> Repo.preload([:exclusion, :product, :product_exclusion_limit])
    pb.product_exclusion_limit
    |> Map.put(:product_limit, pb.product.limit_amount)
  end

  def get_er_fppr_amount(payor_procedure_id, facility_id, unit) do
    fpp = get_facility_payor_procedure_er_room(payor_procedure_id, facility_id)

    fppr_amount =
      fpp.facility_payor_procedure_rooms
      |> Enum.reject(&(is_nil(&1.facility_room_rate.room)))
      |> List.first()

    if is_nil(fppr_amount) do
      ""
    else
      Decimal.mult(Decimal.new(fppr_amount.amount), Decimal.new(unit))
    end
  end

  def get_er_fppr_solo_amount(payor_procedure_id, facility_id) do
    fpp = get_facility_payor_procedure_er_room(payor_procedure_id, facility_id)

    fppr_amount =
      fpp.facility_payor_procedure_rooms
      |> Enum.reject(&(is_nil(&1.facility_room_rate.room)))
      |> List.first()

    if is_nil(fppr_amount) do
      ""
    else
      Decimal.new(fppr_amount.amount)
    end
  end

  def get_facility_payor_procedure_er_room(payor_procedure_id, facility_id) do
    FacilityPayorProcedure
    |> where([fpp], fpp.payor_procedure_id == ^payor_procedure_id and fpp.facility_id == ^facility_id)
    |> Repo.one()
    |> Repo.preload([
        facility_payor_procedure_rooms: [
          facility_room_rate: [
            room: (from r in Room, where: r.code == "31")
          ]
        ]
      ])
  end

  def check_emergency_excess_limits(authorization) do
    with {:ok} <- check_excess_outer_limit(authorization),
         {:ok} <- check_emergency_excess_inner_limit(authorization),
         true <- authorization.authorization_procedure_diagnoses
                  |> filter_uncovered(authorization.authorization_facility_ruvs)
                  |> Enum.empty?()
    do
      {:ok}
    else
      _ ->
        {:invalid}
    end
  end

  def check_emergency_excess_inner_limit(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    haha =
      authorization.authorization_procedure_diagnoses
      |> filter_used_products_per_procedure()
      |> Enum.reject(&(&1.product_base == "Exclusion-based" or is_nil(&1.product_benefit_id)))
      |> Enum.group_by(&(&1.product_benefit_id))
    checker =
      Enum.map(haha, fn({product_benefit_id, diagnosis_procedures}) ->
        product_benefit_limit = get_benefit_limit(product_benefit_id, "EMRGNCY")
        case product_benefit_limit.limit_type do
          "Peso" ->
            check_peso_inner_limit(
              product_benefit_limit.limit_amount,
              diagnosis_procedures
            )
          "Plan Limit Percentage" ->
            check_percentage_inner_limit(
              product_benefit_limit.product_limit,
              diagnosis_procedures,
              product_benefit_limit.limit_percentage
            )
          "Sessions" ->
            check_sessions_inner_limit(
              product_benefit_limit.limit_session,
              diagnosis_procedures,
              authorization,
              active_account
            )
          _ ->
            raise "Inavalid product benefit limit type"
        end
      end)
    if Enum.member?(checker, true) do
      {:inner_limit_exceeded}
    else
      {:ok}
    end
  end

  # CONSULT

  def check_excess_limits_consult(authorization) do
    with {:ok} <- check_excess_outer_limit_consult(authorization),
         {:ok} <- check_excess_inner_limit_consult(authorization),
         true <- authorization.authorization_diagnosis |> filter_uncovered_consult() |> Enum.empty?()
    do
      {:ok}
    else
      _ ->
        {:invalid}
    end
  end

  def check_excess_inner_limit_consult(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    haha =
      authorization.authorization_diagnosis
      |> filter_used_products_per_diagnosis_consult()
      |> Enum.reject(&(&1.product_base == "Exclusion-based" or is_nil(&1.product_benefit_id)))
      |> Enum.group_by(&(&1.product_benefit_id))
    checker =
      Enum.map(haha, fn({product_benefit_id, diagnosis}) ->
        product_benefit_limit = get_benefit_limit(product_benefit_id, "OPC")
        case product_benefit_limit.limit_type do
          "Peso" ->
            check_peso_inner_limit_consult(product_benefit_limit.limit_amount, diagnosis)
          "Plan Limit Percentage" ->
            check_percentage_inner_limit_consult(
              product_benefit_limit.product_limit,
              diagnosis,
              product_benefit_limit.limit_percentage
            )
          "Sessions" ->
            check_sessions_inner_limit_consult(
              product_benefit_limit.limit_session,
              diagnosis,
              authorization,
              active_account
            )
          _ ->
            raise "Inavalid product benefit limit type"
        end
      end)
    if Enum.member?(checker, true) do
      {:inner_limit_exceeded}
    else
      {:ok}
    end
  end

  defp check_peso_inner_limit_consult(product_limit, diagnosis) do
    total_payor_pays = diagnosis |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    product_limit |> Decimal.sub(total_payor_pays) |> less_than_zero_consult?()
  end

  defp check_percentage_inner_limit_consult(product_limit, diagnosis, percentage_amount) do
    percentage_amount =
      percentage_amount
      |> Decimal.new()
    total_payor_pays = diagnosis |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    total_percentage_amount = Decimal.div(percentage_amount || Decimal.new(0), Decimal.new(100))
    total_percentage =
      total_percentage_amount
      |> Decimal.mult(product_limit)
    total_percentage |> Decimal.sub(total_payor_pays) |> less_than_zero_consult?()
  end

  defp check_sessions_inner_limit_consult(limit_sessions, diagnosis, authorization, active_account) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    product_benefit_id = List.first(diagnosis).product_benefit_id
    current_session_count = diagnosis |> Enum.count() |> Decimal.new()

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

  # CHECK PEC INNER LIMIT

  def pec_check_excess_inner_limit_consult(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    haha =
      authorization.authorization_diagnosis
      |> pec_filter_used_products_per_diagnosis_consult()
      |> Enum.reject(&(&1.product_base == "Exclusion-based" or is_nil(&1.product_exclusion_id)))
      |> Enum.group_by(&(&1.product_exclusion_id))
    checker =
      Enum.map(haha, fn({product_exclusion_id, diagnosis}) ->
        product_exclusion_limit = get_exclusion_limit(product_exclusion_id)
        case product_exclusion_limit.limit_type do
          "Peso" ->
            pec_check_peso_inner_limit_consult(product_exclusion_limit.limit_peso, diagnosis)
          "Percentage" ->
            pec_check_percentage_inner_limit_consult(
              product_exclusion_limit.product_limit, diagnosis, product_exclusion_limit.limit_percentage)
          "Sessions" ->
            pec_check_sessions_inner_limit_consult(
              product_exclusion_limit.limit_session, diagnosis, authorization, active_account)
          _ ->
            raise "Inavalid product exclusion limit type"
        end
      end)

    if Enum.member?(checker, true) do
      {:inner_limit_exceeded}
    else
      {:ok}
    end
  end

  defp pec_check_peso_inner_limit_consult(product_limit, diagnosis) do
    total_payor_pays = diagnosis |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    product_limit |> Decimal.sub(total_payor_pays) |> less_than_zero_consult?()
  end

  defp pec_check_percentage_inner_limit_consult(product_limit, diagnosis, percentage_amount) do
    percentage_amount =
      percentage_amount
      |> Decimal.new()
    total_payor_pays = diagnosis |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    total_percentage_amount = Decimal.div(percentage_amount || Decimal.new(0), Decimal.new(100))
    total_percentage =
      total_percentage_amount
      |> Decimal.mult(product_limit)

    total_percentage |> Decimal.sub(total_payor_pays) |> less_than_zero_consult?()
  end

  defp pec_check_sessions_inner_limit_consult(limit_sessions, diagnosis, authorization, active_account) do
    start_date = active_account.start_date
    end_date = active_account.end_date
    product_exclusion_id = List.first(diagnosis).product_exclusion_id
    current_session_count = diagnosis |> Enum.count() |> Decimal.new()
    used_pec_session =
      authorization.member_id
      |> pec_get_used_limit_per_product_consult(product_exclusion_id, start_date, end_date, authorization)
      |> Decimal.new()
    total_used = Decimal.add(current_session_count, used_pec_session)
    limit_sessions |> Decimal.new() |> Decimal.sub(total_used) |> less_than_zero_consult?()
  end

  defp pec_get_used_limit_per_product_consult(_member_id, product_exclusion_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a],
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

  defp pec_filter_used_products_per_diagnosis_consult(authorization_diagnosis) do
    Enum.map(Enum.filter(authorization_diagnosis, &(!is_nil(&1.member_product_id))), &(
      %{
        member_product_id: &1.member_product_id,
        payor_pays: &1.payor_pay,
        product_exclusion_id: &1.product_exclusion_id,
        diagnosis_id: &1.diagnosis_id,
        diagnosis_code: &1.diagnosis.code,
        limit_type: &1.member_product.account_product.product.limit_type,
        product_base: &1.member_product.account_product.product.product_base
      }
    ))
  end

  # END OF PEC INNER LIMIT

  defp filter_uncovered_consult(authorization_diagnosis) do
    Enum.filter(authorization_diagnosis, &(is_nil(&1.member_product_id)))
  end

  defp filter_used_products_per_diagnosis_consult(authorization_diagnosis) do
    Enum.map(Enum.filter(authorization_diagnosis, &(!is_nil(&1.member_product_id))), &(
      %{
        member_product_id: &1.member_product_id,
        payor_pays: &1.payor_pay,
        product_benefit_id: &1.product_benefit_id,
        diagnosis_id: &1.diagnosis_id,
        diagnosis_code: &1.diagnosis.code,
        limit_type: &1.member_product.account_product.product.limit_type,
        product_base: &1.member_product.account_product.product.product_base
      }
    ))
  end

  defp get_benefit_limit_per_diagnosis(authorization, diagnosis_id) do
    {year, day, month} = authorization.admission_datetime |> Ecto.DateTime.to_date() |> Ecto.Date.to_erl()
    AuthorizationDiagnosis
    |> join(:inner, [apd], pb in ProductBenefit, apd.product_benefit_id == pb.id)
    |> join(:inner, [apd, pb], b in Benefit, pb.benefit_id == b.id)
    |> join(:inner, [apd, pb, b], bl in BenefitLimit, b.id == bl.benefit_id)
    |> join(:inner, [apd, pb, b, bl], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, pb, b, bl, a],
      apd.id == ""
      and like(bl.coverages, "%OPC%")
      and apd.diagnosis_id == ^diagnosis_id
      and ilike(fragment("TEXT(?)", a.admission_datetime), ^"#{year}%")
    )
      #and a.id != ^authorization.id and a.status == "Approved)
    |> select([apd, pb, b, bl, a], %{
      limit_type: bl.limit_type,
      limit_amount: bl.limit_amount,
      limit_percentage: bl.limit_percentage,
      limit_sessions: bl.limit_session
    })
    |> Repo.all()
  end

  def get_used_limit_per_product_op_consult(member_product_id, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    payor_pays = AuthorizationDiagnosis
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

  defp get_used_limit_per_diagnosis_group_consult(diagnosis_group, effectivity_date, expiry_date, authorization) do
    effectivity_date = Ecto.DateTime.from_date(effectivity_date)
    expiry_date = Ecto.DateTime.from_date(expiry_date)
    AuthorizationDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> join(:inner, [apd, a], d in Diagnosis, apd.diagnosis_id == d.id)
    |> where(
      [apd, a, d],
      a.admission_datetime >= ^effectivity_date and
      a.admission_datetime < ^expiry_date and
      like(d.code, ^"#{diagnosis_group}%") and
      a.id != ^authorization.id and
      a.status == "Approved"
    )
    |> select([apd, a], apd.payor_pay)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
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

  def check_excess_outer_limit_consult(authorization) do
    active_account = List.first(authorization.member.account_group.account)
    checker =
      authorization.authorization_procedure_diagnoses
      |> filter_used_products_per_procedure()
      |> Enum.group_by(&(&1.member_product_id))
      |> compute_outer_limit_excess_consult(authorization.member_id, active_account, authorization)
    number_of_exceeded = Enum.filter(checker, &(&1.exceeded_outer_limit == true))
    if Enum.count(number_of_exceeded) > 0 do
      {:outer_limit_exceeded}
    else
      {:ok}
    end
  end

  def compute_outer_limit_excess_consult(member_products, member_id, active_account, authorization) do
    Enum.map(member_products, fn({member_product_id, diagnosis_procedures}) ->
      {product_limit, limit_type} = get_member_product_limit(member_product_id)
      if limit_type == "ABL" do
        %{
          member_product_id: member_product_id,
          exceeded_outer_limit: diagnosis_procedures |> compute_abl_excess_consult(
            member_product_id,
            product_limit,
            # member_id,
            active_account,
            authorization) |> less_than_zero_consult?(),
          limit_type: "ABL"
        }
      else
        %{
          member_product_id: member_product_id,
          exceeded_outer_limit: compute_mbl_excess_consult(
            diagnosis_procedures,
            # member_product_id,
            product_limit,
            # member_id,
            active_account,
            authorization
          ),
          limit_type: "MBL"
        }
      end
    end)
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

  def compute_abl_excess_consult(diagnosis_procedures, member_product_id, product_limit, active_account, authorization) do
    start_date = active_account.start_date
    end_date = active_account.end_date

    remaining_product_limit =
      product_limit
      |> Decimal.sub(
        get_used_limit_per_product_op_consult(
          member_product_id,
          start_date,
          end_date,
          authorization
        )
      )

    total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    _remaining_balance_after_deductions = Decimal.sub(remaining_product_limit, total_payor_pays)
  end

  # def compute_abl_excess_consult(diagnosis_procedures, member_product_id, product_limit, _member_id, active_account, authorization) do
  #   start_date = active_account.start_date
  #   end_date = active_account.end_date

  #   remaining_product_limit =
  #     product_limit
  #     |> Decimal.sub(
  #       get_used_limit_per_product_op_consult(
  #         member_product_id,
  #         start_date,
  #         end_date,
  #         authorization
  #       )
  #     )

  #   total_payor_pays = diagnosis_procedures |> Enum.map(&(&1.payor_pays)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  #   _remaining_balance_after_deductions = Decimal.sub(remaining_product_limit, total_payor_pays)
  # end

  def compute_mbl_excess_consult(diagnosis_procedures, product_limit, active_account, authorization) do
    start_date = active_account.start_date
    end_date = active_account.end_date

    diagnosis_procedures
    |> Enum.group_by(&(&1.diagnosis_code))
    |> hellohei_consult(start_date, end_date, authorization, product_limit)
  end

  # def compute_mbl_excess_consult(diagnosis_procedures, _member_product_id, product_limit, _member_id, active_account, authorization) do
  #   start_date = active_account.start_date
  #   end_date = active_account.end_date

  #   diagnosis_procedures
  #   |> Enum.group_by(&(&1.diagnosis_code))
  #   |> hellohei_consult(start_date, end_date, authorization, product_limit)
  # end

  defp hellohei_consult(grouped_diagnoses_procedures, start_date, end_date, authorization, product_limit) do
    checker = Enum.map(grouped_diagnoses_procedures, fn({diagnosis_code, diagnosis_procedures}) ->
      diagnosis_group = String.slice(diagnosis_code, 0..2)
      remaining_mbl_limit =
        product_limit
        |> Decimal.sub(
          get_used_limit_per_diagnosis_group_consult(
            diagnosis_group,
            start_date,
            end_date,
            authorization
          )
        )

      total_payor_pays =
        diagnosis_procedures
        |> Enum.map(&(&1.payor_pays))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      remaining_balance_after_deductions = Decimal.sub(remaining_mbl_limit, total_payor_pays)
      if less_than_zero_consult?(remaining_balance_after_deductions) do
        true
      else
        false
      end
    end)
    if Enum.member?(checker, true) do
      true
    else
      false
    end
  end
  # END OF CONSULT

  def update_emergency_authorization(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.emergency_changeset(params)
    |> Repo.update()
  end

  def get_used_benefit_limit_per_authorization(authorization_id, product_benefit_id, procedure_id) do
    AuthorizationProcedureDiagnosis
    |> join(:inner, [apd], a in Authorization, apd.authorization_id == a.id)
    |> where(
      [apd, a, d],
      a.id == ^authorization_id and
      apd.product_benefit_id == ^product_benefit_id and
      apd.payor_procedure_id != ^procedure_id
    )
    |> select([apd, a], apd.payor_pay)
    |> Repo.all()
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  def insert_otp(authorization_id) do
    authorization = get_authorization_by_id(authorization_id)
    otp = "#{Enum.random(1000..9999)}"
    utc = :erlang.universaltime |> :calendar.datetime_to_gregorian_seconds
    otp_expiry = (utc + 5 * 60)
    otp_expiry =
      otp_expiry
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!

    authorization
    |> Authorization.otp_changeset(%{otp: otp, otp_expiry: otp_expiry})
    |> Repo.update()
  end

  def validate_otp(authorization_id, otp) do
    authorization = get_authorization_by_id(authorization_id)
    if is_nil(authorization.otp_expiry) or authorization.otp_expiry == "" do
      {:otp_not_requested}
    else
      auth =
        Authorization
         |> where([a], a.otp == ^otp and a.id == ^authorization.id)
         |> Repo.all()
      if auth == [] do
        {:invalid_otp}
      else
        otp_expiry =
          authorization.otp_expiry
          |> Ecto.DateTime.cast!()
          |> Ecto.DateTime.compare(Ecto.DateTime.utc)
        cond do
          otp_expiry == :gt ->
            {:ok}
          otp_expiry == :lt ->
            {:expired}
          true ->
            {:expired}
        end
      end
    end
  end

  # AUTHORIZAITON FILE
  def upload_file(authorization_id, user_id, file, file_name) do
    af_names =
      AuthorizationFile
      |> where([af], af.authorization_id == ^authorization_id)
      |> Repo.all
      |> Repo.preload(:file)
      |> Enum.map(&(&1.file.name))

    if Enum.member?(af_names, file_name) do
      {:error}
    else
      af = record_uploaded_file(authorization_id, user_id, file, file_name)
      {:ok, af.id}
    end
  end

  def record_uploaded_file(authorization_id, user_id, file, file_name) do
    content_type =
      file
      |> String.split([":", ";"])
      |> Enum.at(1)

    file_type =
      file
      |> String.split([":", ";"])
      |> Enum.at(1)
      |> String.split("/")
      |> Enum.at(1)

    {start, length} = :binary.match(file, ";base64,")
    raw_file = :binary.part(
      file,
      start + length,
      byte_size(file) - start - length
    )

    File.mkdir_p!(Path.expand('./uploads/files'))
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
      :dev ->
        Path.expand('./uploads/files/')
      :prod ->
        Path.expand('./uploads/files/')
      _ ->
        nil
    end
    File.write!(
      path <> "/#{file_name}",
      Base.decode64!(raw_file)
    )

    file_plug = %Plug.Upload{
      content_type: content_type,
      path: path <> "/#{file_name}",
      filename: file_name
    }

    file = %{name: file_name, type: file_plug}

    file_record =
      %Innerpeace.Db.Schemas.File{}
      |> Innerpeace.Db.Schemas.File.changeset(file)
      |> Repo.insert!()
      |> Innerpeace.Db.Schemas.File.changeset_file(file)
      |> Repo.update!()

    authorization_params = %{
      file_id: file_record.id,
      authorization_id: authorization_id,
      document_type: content_type,
      created_by_id: user_id,
      updated_by_id: user_id
    }

    File.rm_rf(path <> "/#{file_name}")
    %AuthorizationFile{}
      |> AuthorizationFile.changeset(authorization_params)
      |> Repo.insert!()
  end

  def delete_file(id) do
    af =
      AuthorizationFile
      |> where([af], af.id == ^id)
      |> Repo.one
      |> Repo.preload(:file)

    file_id = af.file.id
    file_name = af.file.name

    AuthorizationFile
    |> Repo.get_by(id: af.id)
    |> Repo.delete

    Innerpeace.Db.Schemas.File
    |> Repo.get_by(id: file_id)
    |> Repo.delete

    File.rm("./uploads/files/#{file_name}")
  end

  def load_authorization_files(authorization_id) do
    AuthorizationFile
    |> where([af], af.authorization_id == ^authorization_id)
    |> Repo.all
    |> Repo.preload(:file)
  end
  # AUTHORIZAITON FILE

  def random_loa_number do
    query = from a in Innerpeace.Db.Schemas.Authorization, select: a.number
    list_of_authorizations = Repo.all query
    result_generated = generate_random()
    case check_if_exists(list_of_authorizations, result_generated) do
      true  ->
        random_loa_number()
      false ->
        result_generated
    end
  end

  defp check_if_exists(list, generated) do
    Enum.member?(list, generated)
  end

  defp generate_random do
    random = 100_000..999_999 |> Enum.random() |> to_string()
  end

  def insert_authorization_to_providerlink(params, scheme) do
    with {:ok, token} <- UtilityContext.providerlink_sign_in(scheme),
         api_address = %ApiAddress{} <- ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    do
      method = "#{api_address.address}/api/v1/loa/insert"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body =
        params
        |> Poison.encode!()
      option =
        if Atom.to_string(scheme) == "http"
        do
          [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 60_000]
        else
          [recv_timeout: 60_000]
        end

      with {:ok, response} <- HTTPoison.post(method, body, headers, option)
      do
        if Poison.decode!(response.body)["status"] == "ok" do
          {:true}
        else
          {:false}
        end
      else
        {:error, %HTTPoison.Error{reason: {reason, _description}}} ->
          {:error_connecting_api, reason}
      end

    else
      {:api_address_not_exists} ->
        {:api_address_not_exists}
      {:unable_to_login, message} ->
        {:unable_to_login, message}
      nil ->
        {:api_address_not_exists}
    end
  end

  def get_authorization_by_coverage_and_member(member_id, coverage_id) do
    Authorization
      |> where([a],
               a.coverage_id == ^coverage_id and
               a.member_id == ^member_id
      )
      |> Repo.all()
  end

  def cancel_authorization(id) do
    with authorization = %Authorization{} <- get_authorization_by_id(id) do
      authorization
      |> Authorization.changeset_status(%{status: "Cancelled"})
      |> Repo.update()
    else
      _ ->
        {:missing}
    end
  end

  def approve_authorization(id, user_id) do
    with authorization = %Authorization{} <- get_authorization(id) do
      authorization
      |> Authorization.approve_changeset_status(%{status: "Approved", approved_by_id: user_id,
      approved_datetime: Ecto.DateTime.from_erl(:erlang.localtime)})
      |> Repo.update()
    else
      _ ->
        {:missing}
    end
  end

  def get_authorization(id) do
    Authorization
    |> Repo.get!(id)
  end

  def delete_authorization(id) do
    id
    |> get_authorization()
    |> Repo.delete()
  end

  def get_authorization_logs(authorization_id) do
    AuthorizationLog
    |> where([al], al.authorization_id == ^authorization_id)
    |> order_by([al], desc: al.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def insert_log(params) do
    changeset = AuthorizationLog.changeset(%AuthorizationLog{}, params)
    Repo.insert(changeset)
  end

  def disapprove_loa(loa, reason) do
    Repo.update(Ecto.Changeset.change loa, reason: reason, status: "Disapproved")
  end

  def update_authorization_reschedule_status(authorization) do
    params = %{
      status: "Cancelled"
    }
    authorization
    |> Authorization.changeset_status(params)
    |> Repo.update()
  end

  def copy_authorization(authorization) do
    changeset = Authorization.changeset(authorization)
    valid_until =
      ((:erlang.universaltime |> :calendar.datetime_to_gregorian_seconds) + 172_800)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!

    valid_until = Ecto.Date.cast!(valid_until)

    authorization_params = %{
      consultation_type: authorization.consultation_type,
      chief_complaint: authorization.chief_complaint,
      internal_remarks: authorization.internal_remarks,
      assessed_amount: authorization.assessed_amount,
      total_amount: authorization.total_amount,
      status: "Approved",
      version: authorization.version,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      special_approval_id: authorization.special_approval_id,
      created_by_id: authorization.created_by_id,
      updated_by_id: authorization.updated_by_id,
      step: authorization.step,
      admission_datetime: Ecto.DateTime.from_erl(:erlang.localtime),
      availment_type: authorization.availment_type,
      reason: authorization.reason,
      room_id: authorization.room_id,
      valid_until: valid_until,
      otp: authorization.otp,
      otp_expiry: authorization.otp_expiry,
      chief_complaint_others: authorization.chief_complaint_others,
      origin: authorization.origin,
      control_number: authorization.control_number,
      approved_by_id: authorization.approved_by_id,
      approved_datetime: authorization.approved_datetime,
      requested_datetime: authorization.requested_datetime,
      transaction_no: authorization.transaction_no
    }

    {:ok, new_authorization} =
        %Authorization{}
        |> Authorization.copy_auth_changeset(authorization_params)
        |> Repo.insert()

    authorization_diagnosis = get_diagnosis_by_authorization_id(authorization.id)
    new_ad = Repo.insert!(%AuthorizationDiagnosis{
      authorization_id: new_authorization.id,
      diagnosis_id: authorization_diagnosis.diagnosis_id,
      created_by_id: new_authorization.created_by_id,
      updated_by_id: new_authorization.updated_by_id,
      member_product_id: authorization_diagnosis.member_product_id,
      member_pay: authorization_diagnosis.member_pay,
      payor_pay: authorization_diagnosis.payor_pay,
      product_benefit_id: authorization_diagnosis.product_benefit_id,
      vat_amount: authorization_diagnosis.vat_amount,
      special_approval_amount: authorization_diagnosis.special_approval_amount,
      total_amount: authorization_diagnosis.total_amount,
      pre_existing_amount: authorization_diagnosis.pre_existing_amount,
      member_vat_amount: authorization_diagnosis.member_vat_amount,
      payor_vat_amount: authorization_diagnosis.payor_vat_amount,
      payor_portion: authorization_diagnosis.payor_portion,
      member_portion: authorization_diagnosis.member_portion,
      product_exclusion_id: authorization_diagnosis.product_exclusion_id,
      special_approval_portion: authorization_diagnosis.special_approval_portion,
      special_approval_vat_amount: authorization_diagnosis.special_approval_vat_amount
    })

    aps = get_practitioner_specialization_by_authorization_id(authorization.id)
    new_aps = Repo.insert!(%AuthorizationPractitionerSpecialization{
      authorization_id: new_authorization.id,
      practitioner_specialization_id: aps.practitioner_specialization_id,
      created_by_id: new_authorization.created_by_id,
      updated_by_id: new_authorization.updated_by_id
    })

    authorization_amount = get_amount_by_authorization_id(authorization.id)
    new_am = Repo.insert!(%AuthorizationAmount{
      authorization_id: new_authorization.id,
      coordinator_fee: authorization_amount.coordinator_fee,
      consultation_fee: authorization_amount.consultation_fee,
      copayment: authorization_amount.copayment,
      coinsurance_percentage: authorization_amount.coinsurance_percentage,
      covered_after_percentage: authorization_amount.covered_after_percentage,
      pre_existing_percentage: authorization_amount.pre_existing_percentage,
      payor_covered: authorization_amount.payor_covered,
      member_covered: authorization_amount.member_covered,
      created_by_id: new_authorization.created_by_id,
      updated_by_id: new_authorization.updated_by_id,
      company_covered: authorization_amount.company_covered,
      room_rate: authorization_amount.room_rate,
      total_amount: authorization_amount.total_amount,
      vat_amount: authorization_amount.vat_amount,
      special_approval_amount: authorization_amount.special_approval_amount
    })

    authorization_file = get_file_by_authorization_id(authorization.id)

    if is_nil(authorization_file) do
      {:ok, new_authorization}
    else
      new_af = Repo.insert!(%AuthorizationFile{
        authorization_id: new_authorization.id,
        file_id: authorization_file.file_id,
        created_by_id: new_authorization.created_by_id,
        updated_by_id: new_authorization.updated_by_id,
        document_type: authorization_file.document_type
      })
    end

    new_authorization =
      new_authorization
      |> Map.merge(%{old_authorization_id: authorization.id})

    {:ok, new_authorization}
  end

  def validate_edit_status(authorization_id) do
    Authorization
    |> where([a], a.id == ^authorization_id)
    |> select([a], a.edited_by_id)
    |> Repo.all()
    |> List.first()
  end

  def update_authorization_edit_status(authorization_id, params) do
    authorization_id
    |> get_authorization_by_id()
    |> Authorization.edit_changeset(params)
    |> Repo.update()
  end

  def create_authorization_practitioner_specialization_emergency(params, user_id) do
    params =
      params
      |> Map.put("created_by_id", user_id)
      |> Map.put("updated_by_id", user_id)

    aps_map =
      params["authorizarion_id"]
      |> get_all_authorization_practitioner_specialization()
      |> Enum.map(&(get_value(&1, params)))
      |> Enum.uniq
      |> List.delete(nil)

    if Enum.empty?(aps_map) do
      %AuthorizationPractitionerSpecialization{}
      |> AuthorizationPractitionerSpecialization.changeset(params)
      |> Repo.insert()
    else
      {:already_exist}
    end
  end

  def delete_authorization_practitioner_specialization(aps) do
    AuthorizationProcedureDiagnosis
    |> where([apd], apd.authorization_practitioner_specialization_id == ^aps.id)
    |> Repo.delete_all()

    aps
    |> Repo.delete()
  end

  def get_practitioner_specialization_by_aps_id(id) do
    AuthorizationPractitionerSpecialization
    |> Repo.get(id)
    |> Repo.preload([practitioner_specialization: :practitioner])
  end

  def update_authorization_practitioner_specialization_emergency(aps, params) do
    aps_map =
      params["authorizarion_id"]
      |> get_all_authorization_practitioner_specialization()
      |> Enum.map(&(get_value(&1, params)))
      |> Enum.uniq
      |> List.delete(nil)

    if Enum.empty?(aps_map) do
      aps
      |> AuthorizationPractitionerSpecialization.changeset(params)
      |> Repo.update()
    else
      {:already_exist}
    end
  end

  defp get_value(x, params) do
      if x.authorization_id == params["authorization_id"] do
        if x.practitioner_specialization.id == params["practitioner_specialization_id"] && x.role == params["role"] do
          true
        end
      end
  end

  def get_all_authorization_practitioner_specialization(authorization_id) do
    AuthorizationPractitionerSpecialization
    |> Repo.all()
    |> Repo.preload([practitioner_specialization: :practitioner])
  end

  def get_one_aps_by_ps_id(id) do
    AuthorizationPractitionerSpecialization
    |> where([aps], aps.practitioner_specialization_id == ^id)
    |> Repo.all()
    |> List.first()
  end

  def update_authorization_procedure_diagnosis(apd, params) do
    apd
    |> AuthorizationProcedureDiagnosis.update_changeset(params)
    |> Repo.update()
  end

  def get_all_authorization_rooms(authorization_id) do
    AuthorizationRoom
    |> where([ar], ar.authorization_id == ^authorization_id)
    |> order_by([ar], desc: ar.inserted_at)
    |> Repo.all()
    |> Repo.preload([
      :facility_room_rate
    ])
  end

  def get_authorization_room(authorization_room_id) do
    AuthorizationRoom
    |> Repo.get!(authorization_room_id)
  end

  def create_authorization_room(params) do
    %AuthorizationRoom{}
    |> AuthorizationRoom.changeset(params)
    |> Repo.insert()
  end

  def update_authorization_room(authorization_room, params) do
    authorization_room
    |> AuthorizationRoom.changeset(params)
    |> Repo.update()
  end

  def delete_authorization_room(authorization_room_id) do
    AuthorizationRoom
    |> Repo.get(authorization_room_id)
    |> Repo.delete()
  end

  def update_senior_pwd_amount(authorization_amount, discount_params) do
    authorization_amount
    |> AuthorizationAmount.senior_and_pwd_changeset(discount_params)
    |> Repo.update()
  end

  def update_special_approval_amount(authorization_amount, special_approval_params) do
    authorization_amount
    |> AuthorizationAmount.special_approval_amount_changeset(special_approval_params)
    |> Repo.update()
  end

  def apds(authorization) do
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
    apds =
      apds
      |> Enum.map(&(get_cpt_procedure_id(&1)))
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp get_cpt_procedure_id(param) do
    param.cpt.payor_procedure_id
    |>Enum.map(&(&1.cpt.payor_procedure_id))
  end

  def verify_acu(authorization, params, user_id) do
    with {:ok, authorization} <- verify_authorization_acu(authorization, params, user_id)
    do
      {:ok, authorization}
    else
      _ ->
      {:error}
    end
  end

  def verify_authorization_acu(authorization, params, user_id) do

    admission = params.admission_date
    if is_nil(admission) or admission == "" do
      nil
    else
      admission = "#{admission} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end

    discharge = params.discharge_date
    if is_nil(discharge) or discharge == "" do
      nil
    else
      discharge = "#{discharge} 00:00:00"
                  |> Ecto.DateTime.cast!()
    end

    # member_covered = params["member_covered"]
    # status = if is_nil(member_covered) or member_covered == "" do
    #   "Approved"
    # else
    #   "For Approval"
    # end

    params =
      params
      |> Map.put(:step, 5)
      |> Map.put(:status, "Availed")
      |> Map.put(:updated_by_id, user_id)
      |> Map.put(:created_by_id, user_id)
      |> Map.put(:approved_by_id, user_id)
      |> Map.put(:approved_datetime, Ecto.DateTime.utc)
      |> Map.put(:admission_datetime, admission)
      |> Map.put(:discharge_datetime, discharge)

    {:ok, authorization} =
      authorization
      |> Authorization.acu_changeset(params)
      |> Repo.update()
  end

  def get_authorization_by_loa_number(loa_number) do
    Authorization
      |> where([a],
               a.number == ^loa_number
      )
      |> Repo.one()
      |> Repo.preload([
      [
        logs: {from(al in AuthorizationLog, order_by: [desc: al.inserted_at]), [:user]}
      ],
      [
        member: [
          :member_contacts,
          account_group: [:payment_account,
            account: from(a in Account, where: a.status == "Active")
          ]
        ]
      ],
      [
        authorization_facility_ruvs: [
          facility_ruv: :ruv,
          member_product: [
            account_product: :product
          ]
        ]
      ],
      [
        facility: [
          :category,
          :type,
          [facility_ruvs: :ruv],
          [facility_location_groups: :location_group]
        ]
      ],
      [authorization_practitioners:
       [practitioner:
        [practitioner_specializations: :specialization]]],
      [authorization_practitioner_specializations:
        [practitioner_specialization: [:specialization, practitioner: [practitioner_facilities: :practitioner_facility_consultation_fees]]]],
      :coverage,
      [authorization_diagnosis: [:diagnosis, member_product: [
            account_product: :product
          ]]],
      :authorization_amounts,
      [
        authorization_procedure_diagnoses: [
          :authorization,
          :payor_procedure,
          :diagnosis,
          [payor_procedure: :procedure],
          member_product: [
            account_product: :product
          ]
        ]
      ],
      :authorization_benefit_packages
    ])
  end

  # VALIDATE PEME

  defp validate_peme_status(status) do
    if Enum.member?(status, "Approved") or Enum.member?(status, "For Approval") do
      {:invalid_coverage, "Member has already availed PEME LOA."}
    else
      true
    end
  end

  def validate_peme(member, coverage, authorization) do
    peme_authorization =
      Authorization
      |> where([a],
               a.coverage_id == ^coverage.id and
               a.member_id == ^member.id
      )
      |> Repo.all

    peme_authorization_ids = for a <- peme_authorization, do: a.id
    peme_authorization_status = for a <- peme_authorization, do: a.status

    if is_nil(peme_authorization) do
      validate_peme_status(peme_authorization_status)
    else
      if Enum.member?(peme_authorization_ids, authorization.id) do
        effectivity_date = member.effectivity_date
        expiry_date = member.expiry_date
        created_date = Ecto.Date.cast!(authorization.inserted_at)

        with true <- is_peme_effectivity(authorization, created_date, effectivity_date),
             true <- is_peme_expiry(authorization, created_date, expiry_date)
        do
          validate_peme_status(peme_authorization_status)
        else
          _ ->
            validate_peme_status(peme_authorization_status)
        end
      else
        validate_peme_status(peme_authorization_status)
      end
    end
  end

  # def get_claims() do
  #   Claim
  #   |> where([m], m.migrated == nil)
  #   |> Repo.all()
  #   |> Repo.preload([
  #     :member, :coverage, :facility,
  #     :authorization_amounts, :diagnosis, :benefit, authorization_practioners: :practitioner
  #   ])

  # end

  def get_acu_loa_for_stale do
    Authorization
    |> join(:inner, [a], f in Facility, a.facility_id == f.id)
    |> join(:inner, [a, f], c in Coverage, a.coverage_id == c.id)
    |> join(:inner, [a, f, c], m in Member, a.member_id == m.id)
    |> join(:left, [a, f, c, m],  ascm in AcuScheduleMember, m.id == ascm.member_id)
    |> where([a, f, c, m, ascm], (a.status == "Approved"
              or a.status == "Draft"
              or a.status == "Pending") and (c.name == "ACU")
              and (fragment("now()::date - ?::date >= ?", a.inserted_at, f.prescription_term))
    )
    |> select([a, f, c, m, ascm], %{authorization_id: a.id, acu_schedule_id: ascm.acu_schedule_id})
    |> Repo.all()
  end

  def update_acu_status_to_stale do
    job_name = "Innerpeace.Db.Base.AuthorizationContext, :update_acu_status_to_stale"
    params = create_json_params_for_stale(get_acu_loa_for_stale)
    count = count_loas_for_stale(params.loa_ids)

    with false <- Enum.empty?(get_acu_loa_for_stale),
         {:ok, response} <- update_provider_link_loa_stale(params),
         {:ok, response} <- check_update_provider_link_response(response)
    do
          update_loa_status_stale(params.loa_ids)
          update_acu_schedule_status_stale(params.acu_schedule_ids)
          insert_scheduler_logs(job_name, "Successfully Updated Loa Statuses To Stale", count)
    else
      true ->
        insert_scheduler_logs(job_name, "No authorizations found to stale.", 0)
      {:error} ->
        insert_scheduler_logs(job_name, "Error in Sign-in: ProviderLink", count)

      {:error, acu_loas} ->
        insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)

      {:unable_to_login, response} ->
        insert_scheduler_logs(job_name, response, count)

      {:error_update, response} ->
        insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)

      _ ->
        insert_scheduler_logs(job_name, "Update Stale To Loa Statuses Failed", count)

    end
  end

  def count_loas_for_stale(nil), do: 0
  def count_loas_for_stale(loa_ids) when not is_nil(loa_ids), do: Enum.count(loa_ids)

  def create_json_params_for_stale(acu_loa_stale) when not is_nil(acu_loa_stale) do
    acu_sched_ids = get_acu_schedule_ids_stale(get_acu_loa_for_stale)
    acu_loa_ids = get_loa_ids_stale(get_acu_loa_for_stale)
    params = %{loa_ids: acu_loa_ids, acu_schedule_ids: acu_sched_ids}
  end

  def check_update_provider_link_response(response) do
    resp = Poison.decode!(response.body)
    if resp["message"] == "Loas Successfully Updated Status as Stale" do
       {:ok, response}
    else
      {:error_update, response}
    end
  end

  def check_facility_prescription_date do
    job_name = "Innerpeace.Db.Base.AuthorizationContext, :check_facility_prescription_date"

    if Enum.empty?(get_acu_loa_for_stale) == false do
      acu_sched_ids = get_acu_schedule_ids_stale(get_acu_loa_for_stale)
      acu_loa_ids = get_loa_ids_stale(get_acu_loa_for_stale)
      count  = Enum.count(acu_loa_ids)
      params = %{loa_ids: acu_loa_ids, acu_schedule_ids: acu_sched_ids}

      with {:ok, response} <- update_provider_link_loa_stale(params) do
        resp = Poison.decode!(response.body)

        if resp["message"] == "Loas Successfully Updated Status as Stale" do
           update_loa_status_stale(acu_loa_ids)
           update_acu_schedule_status_stale(acu_sched_ids)
          insert_scheduler_logs(job_name, "Successfully Updated Loa Statuses To Stale", count)
        else
          insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)
        end

      else
        {:error} ->
          insert_scheduler_logs(job_name, "Error in Sign-in: ProviderLink", count)

        {:error, acu_loas} ->
          insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)

        {:unable_to_login, response} ->
          insert_scheduler_logs(job_name, response, count)

        _ ->
          insert_scheduler_logs(job_name, "Update Stale To Loa Statuses Failed", count)
      end

    else
      insert_scheduler_logs(job_name, "No authorizations found to stale.", 0)
    end
  end

  defp get_acu_schedule_ids_stale(map) do
    map
    |> Enum.map(fn(map) ->
      asc_id = map.acu_schedule_id
    end)
    |> Enum.uniq()
    |> Enum.filter(& !is_nil(&1))
  end

  defp get_loa_ids_stale(map) do
    map
    |> Enum.map(fn(map) ->
      asc_id = map.authorization_id
    end)
  end

  defp update_loa_status_stale(loa_ids) do
    Authorization
    |> where([a], a.id in ^loa_ids)
    |> Repo.update_all(set: [status: "Stale", updated_at: NaiveDateTime.utc_now()])
  end

  defp update_acu_schedule_status_stale(acs_ids) do
    AcuSchedule
    |> where([acs], acs.id in ^acs_ids)
    |> Repo.update_all(set: [status: "Stale", updated_at: NaiveDateTime.utc_now()])
  end

  defp insert_scheduler_logs(name, message, count) do
    log = %{
      name: name,
      message: message,
      total: count
    }
    SchedulerContext.insert_scheduler_logs(log)
  end

  def update_provider_link_loa_stale(loa_ids) do
    with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
      with {:ok, response} <- post_loa_stale_providerlink(loa_ids, token) do
        {:ok, response}
      else
        _ ->
          {:error, loa_ids}
      end
    else
      {:unable_to_login, response} ->
        {:unable_to_login, response}
      _ ->
        {:error}
    end
  end

  def post_loa_stale_providerlink(loa_ids, token) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/loas/update_status"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(loa_ids)
    with {:ok, response} <- HTTPoison.post(api_method, body, headers, [])
    do
      {:ok, response}
    else
      {:error, response} ->
         {:error}
        _ ->
         {:error}
    end
  end
end

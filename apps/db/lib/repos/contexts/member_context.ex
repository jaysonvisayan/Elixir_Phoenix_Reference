defmodule Innerpeace.Db.Base.MemberContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Member,
    Db.Schemas.MemberLog,
    Db.Schemas.MemberProduct,
    Db.Schemas.MemberUploadLog,
    Db.Schemas.MemberMaintenanceUploadLog,
    Db.Schemas.MemberUploadFile,
    Db.Schemas.Account,
    Db.Schemas.MemberSkippingHierarchy,
    Db.Schemas.AccountProduct,
    Db.Schemas.User,
    Db.Schemas.Benefit,
    Db.Schemas.BenefitPackage,
    Db.Schemas.Product,
    Db.Schemas.Package,
    Db.Parsers.MemberParser,
    Db.Parsers.MemberMaintenanceParser,
    Db.Parsers.MemberUploadParser,
    Db.Schemas.Contact,
    Db.Schemas.MemberContact,
    Db.Schemas.EmergencyHospital,
    Db.Schemas.Phone,
    Db.Schemas.Email,
    Db.Schemas.MemberComment,
    Db.Schemas.Peme,
    Db.Schemas.PemeMember,
    Db.Schemas.ApiAddress,
    Db.Base.PhoneContext,
    Db.Base.EmailContext,
    Db.Base.UserContext,
    Db.Base.ProductContext,
    Db.Base.CoverageContext,
    Db.Base.AuthorizationContext,
    Db.Base.AccountContext,
    Db.Base.PackageContext,
    Db.Schemas.AccountGroup,
    Db.Schemas.Authorization,
    Db.Schemas.AuthorizationDiagnosis,
    Db.Schemas.AuthorizationProcedureDiagnosis,
    Db.Schemas.AuthorizationBenefitPackage,
    Db.Schemas.BenefitPackage,
    Db.Schemas.EmergencyContact,
    Db.Schemas.MemberCOPUploadLog,
    Db.Utilities.SMS,
    Db.Schemas.BatchAuthorization,
    Db.Schemas.BalancingFile,
    Db.Schemas.Batch,
    Db.Schemas.ClaimFile,
    Db.Schemas.ProductBenefit,
    Db.Schemas.PackagePayorProcedure,
    Db.Schemas.Facility,
    Db.Schemas.Dropdown,
    Db.Schemas.Claim,
    Db.Schemas.PayorProcedure,
    Db.Schemas.Procedure,
    Db.Validators.PEMEValidator,
    AccountLink.EmailSmtp,
    AccountLink.Mailer,
    Db.Base.SchedulerContext
  }
  alias Ecto.Changeset
  alias Decimal
  alias Timex.Duration
  alias Ecto.Date
  alias Date, as: Dt
  alias Ecto.UUID

  alias Innerpeace.PayorLink.Web.Api.V1.MemberController
  alias Innerpeace.Db.Base.Api.MemberContext
  @uuid  Ecto.UUID.generate()

  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Innerpeace.Db.Base.UserContext
  alias Innerpeace.PayorLink.EmailSmtp, as: PayorEmailSmtp
  alias Innerpeace.PayorLink.Mailer, as: PayorMailer
  alias Innerpeace.AccountLink.EmailSmtp, as: AccountEmailSmtp
  alias Innerpeace.AccountLink.Mailer, as: AccountMailer
  alias Innerpeace.PayorLink.FileTransferProtocol, as: FTP
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController, as: AuthorizationAPI
  alias Innerpeace.Db.Parsers.FileUploadParser, as: FileUpload

  alias Plug.CSRFProtection

  def activate_members do
    Member
    |> where(
      [m],
      fragment(
        "current_date >= ?",
        fragment(
          "to_date(?, ?)",
          fragment(
            "to_char(?, 'YYYY/MM/DD')",
            m.effectivity_date
          ),
          "YYYY/MM/DD"
        )
      )
      and fragment(
        "? > current_date",
        fragment(
          "to_date(?, ?)",
          fragment(
            "to_char(?, 'YYYY/MM/DD')",
            m.expiry_date
          ),
          "YYYY/MM/DD"
        )
      )
      and (is_nil(m.status) or m.status == "Pending")
      and m.step == 5
    )
    |> Repo.update_all(set: [status: "Active"])
  end

  def activate_member(%Member{} = member, member_params) do
    member
    |> Member.changeset_status(member_params)
    |> Repo.update()
  end

  def get_verified_member(id) do
    member = Member
    |> where([m], m.id == ^id)
    |> Repo.one()
    |> utilized_preload_member

    member_details = load_member(id)
    check_member_details(member, member_details)
  end

  def get_acu_verified_member(id) do
    coverage_id = CoverageContext.get_coverage_by_code("ACU").id
    Member
    |> where([m], m.id == ^id)
    |> Repo.all()
    |> utilized_preload_member_active(coverage_id)
  end

  def get_utilized_loa_by_product(member_id, product_id) do
    # apd = AuthorizationProcedureDiagnosis
    # ad = AuthorizationDiagnosis
    # apb = AuthorizationBenefitPackage

    ad =
      Claim
      |> join(:inner, [c], a in Authorization, a.id == c.authorization_id)
      |> join(:inner, [c, a], ad in AuthorizationDiagnosis, ad.authorization_id == a.id)
      |> join(:inner, [c, a, ad], mp  in MemberProduct, ad.member_product_id == mp.id)
      |> join(:inner, [c, a, ad, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [c, a, ad, mp, ap], m in User, a.approved_by_id == m.id)
      |> where([c, a, ad, mp, ap, m], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status == "Availed")
      |> Repo.all()
      |> preload_claim()

    apd =
      Claim
      |> join(:inner, [c], a in Authorization, a.id == c.authorization_id)
      |> join(:inner, [c, a], apd in AuthorizationProcedureDiagnosis, a.id == apd.authorization_id)
      |> join(:inner, [c, a, apd], mp  in MemberProduct, apd.member_product_id == mp.id)
      |> join(:inner, [c, a, apd, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [c, a, apd, mp, ap], m in User, a.approved_by_id == m.id)
      |> where([c, a, apd, mp, ap, m], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status == "Availed")
      |> Repo.all()
      |> preload_claim()

    abp =
      Claim
      |> join(:inner, [c], a in Authorization, a.id == c.authorization_id)
      |> join(:inner, [c, a], abp in AuthorizationBenefitPackage, a.id == abp.authorization_id)
      |> join(:inner, [c, a, abp], mp  in MemberProduct, abp.member_product_id == mp.id)
      |> join(:inner, [c, a, abp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [c, a, abp, mp, ap], m in User, a.approved_by_id == m.id)
      |> where([c, a, abp, mp, ap, m], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status == "Availed")
      |> Repo.all()
      |> preload_claim()

    empty_ad? = Enum.empty?(ad) == false
    empty_apd? = Enum.empty?(apd) == false
    empty_abp? = Enum.empty?(abp) == false

    cond do
      empty_ad? && empty_apd? && empty_abp? ->
        ad ++ apd ++ abp
        |> Enum.uniq()
        |> preload_claim()
      empty_ad? && empty_apd? ->
        ad ++ apd
        |> Enum.uniq()
        |> preload_claim()
      empty_ad? && empty_abp? ->
        ad ++ abp
        |> Enum.uniq()
        |> preload_claim()
      empty_apd? && empty_abp? ->
        apd ++ abp
        |> Enum.uniq()
        |> preload_claim()
      empty_ad? ->
        ad
        |> Enum.uniq()
        |> preload_claim()
      empty_apd? ->
        apd
        |> Enum.uniq()
        |> preload_claim()
      empty_abp? ->
        abp
        |> Enum.uniq()
        |> preload_claim()
      true ->
        []
    end
  end

  def get_unutilized_member(id) do
    member =
      Member
    |> where([m], m.id == ^id)
    |> Repo.one()
    |> unutilized_preload_member()

    member_details = load_member(id)
    check_member_details(member, member_details)
  end

  def get_authorization_ibnr(member_id) do
    Authorization
    |> where([a], a.member_id == ^member_id and (a.status == ^"Pending" or a.status == ^"Approved" or a.status == ^"Forfeited" or a.status == "Cancelled"))
    |> Repo.all()
    |> preload_auth()
  end

  def get_authorization_actual(member_id) do
    Authorization
    |> where([a], a.member_id == ^member_id and a.status == ^"Availed")
    |> Repo.all()
    |> preload_auth()
  end

  def get_claim_actual(member_id) do
    Claim
    |> where([c], c.member_id == ^member_id and c.status == ^"Availed")
    |> Repo.all()
    |> preload_claim()
  end

  def get_unutilized_loa_by_product(member_id, product_id) do
    # apd = AuthorizationProcedureDiagnosis
    # ad = AuthorizationDiagnosis
    # apb = AuthorizationBenefitPackage

    ad =
      Authorization
      |> join(:inner, [a], ad in AuthorizationDiagnosis, a.id == ad.authorization_id)
      |> join(:inner, [a, ad], mp  in MemberProduct, ad.member_product_id == mp.id)
      |> join(:inner, [a, ad, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, ad, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status != "Availed")
      |> Repo.all()

    apd =
      Authorization
      |> join(:inner, [a], apd in AuthorizationProcedureDiagnosis, a.id == apd.authorization_id)
      |> join(:inner, [a, apd], mp  in MemberProduct, apd.member_product_id == mp.id)
      |> join(:inner, [a, apd, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, apd, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status != "Availed")
      |> Repo.all()

    abp =
      Authorization
      |> join(:inner, [a], abp in AuthorizationBenefitPackage, a.id == abp.authorization_id)
      |> join(:inner, [a, abp], mp  in MemberProduct, abp.member_product_id == mp.id)
      |> join(:inner, [a, abp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, abp, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number) and a.status != "Availed")
      |> Repo.all()

    empty_ad? = Enum.empty?(ad) == false
    empty_apd? = Enum.empty?(apd) == false
    empty_abp? = Enum.empty?(abp) == false

    cond do
      empty_ad? && empty_apd? && empty_abp? ->
        ad ++ apd ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? && empty_apd? ->
        ad ++ apd
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? && empty_abp? ->
        ad ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_apd? && empty_abp? ->
        apd ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? ->
        ad
        |> Enum.uniq()
        |> preload_auth()
      empty_apd? ->
        apd
        |> Enum.uniq()
        |> preload_auth()
      empty_abp? ->
        abp
        |> Enum.uniq()
        |> preload_auth()
      true ->
        []
    end
  end

  def get_member!(id) do
    Member
      |> Repo.get!(id)
      |> preload_member

    rescue
      Ecto.NoResultsError ->
        nil
      _ ->
        nil
  end

  def get_loa_by_product(member_id, product_id) do
    # apd = AuthorizationProcedureDiagnosis
    # ad = AuthorizationDiagnosis
    # apb = AuthorizationBenefitPackage

    ad =
      Authorization
      |> join(:inner, [a], ad in AuthorizationDiagnosis, a.id == ad.authorization_id)
      |> join(:inner, [a, ad], mp  in MemberProduct, ad.member_product_id == mp.id)
      |> join(:inner, [a, ad, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, ad, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number))
      |> Repo.all()

    apd =
      Authorization
      |> join(:inner, [a], apd in AuthorizationProcedureDiagnosis, a.id == apd.authorization_id)
      |> join(:inner, [a, apd], mp  in MemberProduct, apd.member_product_id == mp.id)
      |> join(:inner, [a, apd, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, apd, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number))
      |> Repo.all()

    abp =
      Authorization
      |> join(:inner, [a], abp in AuthorizationBenefitPackage, a.id == abp.authorization_id)
      |> join(:inner, [a, abp], mp  in MemberProduct, abp.member_product_id == mp.id)
      |> join(:inner, [a, abp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> where([a, abp, mp, ap], a.member_id == ^member_id and ap.product_id == ^product_id and not is_nil(a.number))
      |> Repo.all()

    empty_ad? = Enum.empty?(ad) == false
    empty_apd? = Enum.empty?(apd) == false
    empty_abp? = Enum.empty?(abp) == false

    cond do
      empty_ad? && empty_apd? && empty_abp? ->
        ad ++ apd ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? && empty_apd? ->
        ad ++ apd
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? && empty_abp? ->
        ad ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_apd? && empty_abp? ->
        apd ++ abp
        |> Enum.uniq()
        |> preload_auth()
      empty_ad? ->
        ad
        |> Enum.uniq()
        |> preload_auth()
      empty_apd? ->
        apd
        |> Enum.uniq()
        |> preload_auth()
      empty_abp? ->
        abp
        |> Enum.uniq()
        |> preload_auth()
      true ->
        []
    end
  end

  def preload_auth(auth) do
    Repo.preload(auth, [
      :facility,
      :approved_by,
      :special_approval,
      :room,
      :created_by,
      :authorization_amounts,
      #:authorization_diagnosis,
      authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
      authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
      coverage: [coverage_benefits: :benefit],
      authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
      authorization_benefit_packages: [benefit_package: [:benefit, :package]]
    ])
  end

  def preload_claim(claim) do
    Repo.preload(claim, [authorization:
                         [:facility,
                          :approved_by,
                          :special_approval,
                          :room,
                          :created_by,
                          :authorization_amounts,
                          #:authorization_diagnosis,
                          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
                          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
                          coverage: [coverage_benefits: :benefit],
                          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
                          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
                         ]
    ])
  end

  def get_active_member_by_id(id) do
    member =
      Member
      |> Repo.get_by(id: id, status: "Active")
      |> Repo.preload([
        account_group: [
          account: from(a in Account, where: a.status == "Active")
        ]
      ])

    if is_nil(member) do
      member
    else
      if Enum.empty?(member.account_group.account), do: nil, else: member
    end
  end

  def get_active_member_by_card_no(card_no) do
    member =
      Member
      |> Repo.get_by(card_no: card_no, status: "Active")
      |> Repo.preload([
        account_group: [
          account: from(a in Account, where: a.status == "Active")
        ]
      ])

    if is_nil(member) do
      member
    else
      if Enum.empty?(member.account_group.account), do: nil, else: member
    end
  end

  def get_member_by_card_no(card_no) do
    Member
    |> where([m], m.card_no == ^card_no)
    |> distinct([m], m.card_no)
    |> Repo.one()
    |> Repo.preload([
      :files,
      :user,
      :principal,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :emergency_contact,
      :peme,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: [:benefit_diagnoses, benefit_coverages: :coverage]
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share: :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])

    rescue
      Ecto.NoResultsError ->
        nil
      _ ->
        nil
  end

  def get_all_members do
    Member
    |> Repo.all()
    |> Repo.preload([
      :account_group,
      skipped_dependents: :created_by,
      products: [account_product: :product]
    ])
  end

  def get_all_dependent_members do
    Member
    |> where([m], m.type != "Principal")
    |> Repo.all()
    |> Repo.preload([
      :principal,
      :account_group,
      skipped_dependents: [:created_by, :updated_by],
      products: [account_product: :product]
    ])
  end

  def get_principal_members do
    Member
    |> where([m], m.type == "Principal")
    |> Repo.all()
    |> Repo.preload([
      :account_group,
      products: [account_product: :product]
    ])
  end

  def create_member(member_params) do
    if member_params["is_draft"] == "true" do
      %Member{}
      |> Member.changeset_general_save_as_draft(member_params)
      |> Repo.insert()
    else
      %Member{}
      |> Member.changeset_general(member_params)
      |> Repo.insert()
    end
  end

  defp create_member_save_as_draft(member_params) do
    %Member{}
    |> Member.changeset_general_save_as_draft(member_params)
    |> Repo.insert()
  end


  def update_member_step(%Member{} = member, member_params) do
    member
    |> Member.changeset_step(member_params)
    |> Repo.update()
  end

  def update_member_general(member, member_params) do
    member
    |> Member.changeset_general(member_params)
    |> Repo.update()
  end

  def update_member_contact(member, member_params) do
    member
    |> Member.changeset_contact(member_params)
    |> Repo.update()
  end

  def update_member_photo(member, member_params) do
    member
    |> Member.changeset_photo(member_params)
    |> Repo.update()
  end

  def update_member_senior_photo(member, member_params) do
    member
    |> Member.changeset_senior_photo(member_params)
    |> Repo.update()
  end

  def update_member_pwd_photo(member, member_params) do
    member
    |> Member.changeset_pwd_photo(member_params)
    |> Repo.update()
  end

  def update_member_card(member) do
    member
    |> Member.changeset_card(%{})
    |> Repo.update()
  end

  def enroll_member(member, member_params) do
    member
    |> Member.changeset_enroll(member_params)
    |> Repo.update()
  end

  def set_member_products(member_id, account_product_ids, :batch_upload) do
    member = get_member!(member_id)
    for {account_product_id, tier} <- Enum.with_index(account_product_ids, get_current_tier(member.id) + 1) do
      %MemberProduct{}
      |> MemberProduct.changeset(%{member_id: member.id, account_product_id: account_product_id, tier: tier})
      |> Repo.insert()
    end
    {:ok}
  end

  def set_member_products(member, account_product_ids) do
    for {account_product_id, tier} <- Enum.with_index(account_product_ids, get_current_tier(member.id) + 1) do
      with {:ok, _} <- insert_member_product(member.id, account_product_id, tier) do
        true
      else
        _ ->
          false
      end
    end
    |> Enum.member?(false)
    |> set_member_products_v2()
  end

  defp set_member_products_v2(true), do: {:error}
  defp set_member_products_v2(false), do: {:ok}

  defp insert_member_product(member_id, account_product_id, tier) do
    %MemberProduct{}
    |> MemberProduct.changeset(%{member_id: member_id, account_product_id: account_product_id, tier: tier})
    |> Repo.insert()
  end

  ### checker for account_products for only one ACU, if ACU has many results product should be void
  def ap_for_only_one_acu(account_product_id) do
    account_product = get_account_product(account_product_id)
    Enum.map(account_product.product.product_coverages, &(&1.coverage.name))
  end

  ### if member_product_with_acu already been set, there will be no account_product_with_acu allowed
  def mp_acu_exist?() do

  end

  def get_member_products(member_id) do
    MemberProduct
    |> where([mp], mp.member_id == ^member_id)
    |> Repo.all()
    |> Repo.preload([
      account_product: [
        product: [
          product_benefits: [
            benefit: [
              benefit_coverages: :coverage
            ]
          ]
        ]
      ]
    ])
  end

  def get_account_product(account_product_id) do
    AccountProduct
    |> Repo.get(account_product_id)
    |> Repo.preload([
      :member_products,
      product: [
        product_coverages: :coverage,
        product_benefits: [
          benefit: [
            benefit_coverages: :coverage
          ]
        ]
      ]
    ])
  end

  def update_product_tier(member_product_ids) do
    for {member_product_id, tier} <- Enum.with_index(member_product_ids, 1) do
      member_product = get_member_product(member_product_id)
      member_product =
        member_product
        |> List.first()

      member_product
      |> MemberProduct.changeset_tier(%{tier: tier})
      |> Repo.update()
    end
  end

  def show_update_product_tier(member_product_ids, member, user) do
    for {member_product_id, tier} <- Enum.with_index(member_product_ids, 1) do

      member_product = List.first(get_member_product(member_product_id))
      member_product1 =
        member_product

      member_product
      |> MemberProduct.changeset_tier(%{tier: tier})
      |> Repo.update()

      changeset = MemberProduct.changeset_tier(member_product1, %{tier: tier})
      changes = changes_to_string(changeset)
      if changes != "" do
        message = "<b> #{user.username} </b> Updated
        <b> <i>#{member_product1.account_product.product.code} </b> </i>
        where <b> <i> #{changes}</b> </i>."
        insert_log(%{
          member_id: member.id,
          user_id: user.id,
          message: message
        })
      end
    end
  end

  def get_member_product(id) do
    MemberProduct
    |> where([mp], mp.id == ^id)
    |> Repo.all()
    |> Repo.preload([account_product: [:product]])
  end

  def get_member_product_tier1(id) do
    Member
    |> where([mp], mp.id == ^id)
    |> Repo.all()
    |> Repo.preload([
      products: {from(mp in MemberProduct, where: mp.tier == 1), [
        :account_product
      ]}
    ])
  end

  def clear_member_products(member_id) do
    MemberProduct
    |> where([mp], mp.member_id == ^member_id)
    |> Repo.delete_all()
  end

  def list_member_products(member) do
    for member_product <- member.products, into: [] do
      member_product.product.code
    end
  end

  def member_card_checker(card) do
    empty =
      Member
      |> where([m], m.card_no == ^card)
      |> Repo.all()

    if Enum.empty?(empty) do
      card
    else
      card = String.to_integer(card) + 1
      member_card_checker(Integer.to_string(card))
    end
  end

  def get_member_account_product(member_id, member_product_id) do
    MemberProduct
    |> Repo.get_by!(%{member_id: member_id, id: member_product_id})
  end

  def delete_member_account_product(member_id, member_product_id) do
    with member_product = %MemberProduct{} <- get_member_account_product(member_id, member_product_id) do
      MemberProduct
      |> where([mp], mp.tier > ^member_product.tier and mp.member_id == ^member_id)
      |> Repo.update_all(inc: [tier: -1])

      member_product |> Repo.delete()
    else
      _ ->
        nil
    end
  end

  def delete_member_all(member_id) do

    MemberContact
    |> where([mc], mc.member_id == ^member_id)
    |> Repo.delete_all()

    MemberProduct
    |> where([mp], mp.member_id == ^member_id)
    |> Repo.delete_all()

    member =
      Member
      |> where([m], m.id == ^member_id)
      |> Repo.one()
      |> Repo.preload(:peme)
      |> Repo.delete()

  end

  def delete_member_all_peme(member_id) do

    MemberContact
    |> where([mc], mc.member_id == ^member_id)
    |> Repo.delete_all()

    MemberProduct
    |> where([mp], mp.member_id == ^member_id)
    |> Repo.delete_all()

    member =
      Member
      |> where([m], m.id == ^member_id)
      |> Repo.one()
      |> Repo.preload(:peme)
      |> Repo.delete()

  end

  def select_member_fields do
    Member
    |> select([:account_code, :employee_no, :email, :mobile])
    |> Repo.all()
  end

  def list_members_by_account_group(account_group_code) do
    Member
    |> where([m], m.account_code == ^account_group_code)
    |> Repo.all()
  end

  def list_members_by_account_group(member_id, account_group_code) do
    Member
    |> where([m], m.account_code == ^account_group_code and m.id != ^member_id)
    |> Repo.all()
  end

  defp get_current_tier(member_id) do
    MemberProduct
    |> where([mp], mp.member_id == ^member_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_skipping_by_id(id) do
    MemberSkippingHierarchy
    |> Repo.get(id)
  end

  def delete_skipping_for_edit(member_id) do
    member_skip = get_skipping_based_on_member(member_id)
    for skip_id <- member_skip do
      delete_skipping_based_on_member(skip_id)
    end
  end

  def insert_member_hierarchy(member_id, user_id, params) do
    skip_datas = Enum.chunk_every(String.split(Enum.at(params, 0), ","), 12)
    not_for_delete_skip = for skip_data <- skip_datas do
      if UtilityContext.valid_uuid?(Enum.at(skip_data, 11)) != {:invalid_id} do
        Enum.at(skip_data, 11)
      end
    end
    member_skip = get_skipping_based_on_member(member_id)
    skip_for_delete = member_skip -- not_for_delete_skip
    if skip_for_delete != [] do
      for skip_id <- skip_for_delete do
        delete_skipping_based_on_member(skip_id)
      end
    end
    for skip_data <- skip_datas do
      if UtilityContext.valid_uuid?(Enum.at(skip_data, 11)) != {:invalid_id} do
        if Enum.at(skip_data, 0) != "" do
          params = %{
            relationship: Enum.at(skip_data, 0),
            first_name: Enum.at(skip_data, 1),
            middle_name: Enum.at(skip_data, 2),
            last_name: Enum.at(skip_data, 3),
            suffix: Enum.at(skip_data, 4),
            gender: Enum.at(skip_data, 5),
            birthdate: UtilityContext.transform_string_dates(Enum.at(skip_data, 6) <> ", " <> Enum.at(skip_data, 7)),
            reason: Enum.at(skip_data, 8),
            updated_by_id: user_id
          }
          id = Enum.at(skip_data, 11)

          id
          |> get_skipping_by_id()
          |> MemberSkippingHierarchy.changeset(params)
          |> Repo.update()
        end
      else
        params = %{
          member_id: member_id,
          relationship: Enum.at(skip_data, 0),
          first_name: Enum.at(skip_data, 1),
          middle_name: Enum.at(skip_data, 2),
          last_name: Enum.at(skip_data, 3),
          suffix: Enum.at(skip_data, 4),
          gender: Enum.at(skip_data, 5),
          birthdate: UtilityContext.transform_string_dates(Enum.at(skip_data, 6) <> ", " <> Enum.at(skip_data, 7)),
          reason: Enum.at(skip_data, 8),
          created_by_id: user_id
        }
        {:ok, member_skip} =
          %MemberSkippingHierarchy{}
          |> MemberSkippingHierarchy.changeset(params)
          |> Repo.insert()
        upload_params =
          %{
            "base_64_encoded" => Enum.at(skip_data, 11),
            "name" => Enum.at(skip_data, 9),
            "extension" => Enum.at(skip_data, 10)
          }
        member_skip
        |> MemberUploadParser.upload_a_file(upload_params)
      end
    end
  end

  # Start of MemberLink
  def member_card_verification(card_params) do
    if card_params["birthday"] == nil do
      card_params =
        card_params
        |> Map.put("birthday", "9999/12/12")
    end
    query =
      from m in Member,
      where: m.card_no == ^card_params["cardnumber"] and
    fragment("to_char(?, ?)", m.birthdate, "MM/DD/YYYY") == ^card_params["birthday"] or
    fragment("to_char(?, ?)", m.birthdate, "YYYY/MM/DD") == ^card_params["birthday"] or
    fragment("to_char(?, ?)", m.birthdate, "YYYY-MM-DD") == ^card_params["birthday"]
    member = Repo.one(query)
    if is_nil(member) == false do
      {:ok, member}
    else
      {:member_not_found}
    end
  end

  def get_dependents_by_member_id(member_id) do
    Member
    |> where([m], m.principal_id == ^member_id)
    |> Repo.all()
  end

  def card_number_verification(card_number) do
    if card_number == "" do
      {:cardnumber_is_invalid}
    else
      number =
        Member
        |> Repo.get_by(card_no: card_number)

        if is_nil(number) do
          {:card_number_not_found}
        else
          number
        end
    end
  end

  def birthday_verification(birthday) do
    member =
      Member
      |> Repo.get_by(birthdate: Ecto.Date.cast!(birthday))

    if is_nil(member) do
      {:birthday_not_found}
    else
      member
    end

  end

  def get_member(id) do
    Member
    |> Repo.get(id)
    |> Repo.preload([
      account_group: [
        account: from(a in Account, where: a.status == "Active")
      ]
    ])
    |> Repo.preload([
      :files,
      :user,
      :created_by,
      :updated_by,
      :emergency_hospital,
      :emergency_contact,
      :principal,
      :peme,
      dependents: :skipped_dependents,
      products: [
        account_product: [
          product: [
            product_benefits: [
              benefit: :benefit_diagnoses
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share:
               :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ],
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def loa_card_checker(params) do
    case UtilityContext.valid_uuid?(params["member_id"]) do
      {true, _id} ->
        query =
          from m in Member,
          where: (is_nil(m.card_no) or m.card_no == ^params["card_number"])
          and (is_nil(m.id) or m.id == ^params["member_id"])
          member = Repo.one(query)
          cond do
            is_nil(member) == false ->
              {:ok, member}
            params["card_number"] == "" ->
              {:card_number_is_invalid}
            is_nil(member) ->
              {:not_found}
          end
      {:invalid_id} ->
        {:invalid_id, "member"}
    end
  end

  def update_member_profile(member, params) do
    member
    |> Member.changeset_memberlink_profile(params)
    |> Repo.update()
  end

  def create_member_profile(member_params) do
    %Member{}
    |> Member.changeset_memberlink_profile(member_params)
    |> Repo.insert()
  end

  def get_member_memberlink(employee_no) do
    Member
    |> Repo.get_by(employee_no: employee_no)
  end

  def insert_or_update_member(params) do
    member = get_member_memberlink(params.employee_no)
    if not is_nil(member) do
      member
      |> update_member_general(params)
    else
      create_member(params)
    end
  end

  def create_dependent(params) do
    suffix = params["extension"]
    params = Map.delete(params, "extension")
    params = Map.merge(params, %{"suffix" => suffix})
    %Member{}
    |> Member.changeset_memberlink_dependent(params)
    |> Repo.insert()
  end

  def get_emergency_contact(member_id) do
    MemberContact
    |> Repo.get_by(member_id: member_id)
  end

  def validate_emergency_contact(params) do
    changeset = Contact.member_emergency_contact_changeset(%Contact{}, params)
    if changeset.errors == [] do
      {:ok, "contact"}
    else
      {:error, changeset}
    end
  end

  def validate_member_info(member, params) do
    changeset = Member.changeset_memberlink_info(member, params)
    if changeset.errors == [] do
      {:ok, "info"}
    else
      {:error, changeset}
    end
  end

  def validate_phones(params) do
    result = for phone <- params["phones"] do
      data =
        %{
          number: phone["phone"],
          type: "mobile",
          contact_id: @uuid
        }
      p = Phone.changeset(%Phone{}, data)
      if p.errors == [] do
        if Regex.match?(~r/^[0-9]*$/, phone["phone"]) == true do
          "ok"
        else
          "error"
        end
      else
        "error"
      end
    end
    if Enum.member?(result, "error") do
      {:error, "Invalid Phones"}
    else
      {:ok, "phones"}
    end
  end

  def validate_emails(params) do
    result = for email <- params["emails"] do
      data =
        %{
          address: email["email"],
          type: "email",
          contact_id: @uuid
        }
      e = Email.changeset(%Email{}, data)
      if e.errors == [] do
        "ok"
      else
        "error"
      end
    end
    if Enum.member?(result, "error") do
      {:error, "Invalid Emails"}
    else
      {:ok, "emails"}
    end
  end

  def validate_hospital(params) do
    changeset = EmergencyHospital.changeset(%EmergencyHospital{}, params)
    if changeset.errors == [] do
      if is_nil(params["phone"]) || params["phone"] == "" do
        {:ok, "hospital"}
      else
        if Regex.match?(~r/^[0-9]*$/, params["phone"]) == true do
          {:ok, "hospital"}
        else
          {:error, "Invalid Phone"}
        end
      end
    else
      {:error, changeset}
    end
  end

  def insert_member_info(member, params) do
    member
    |> Member.changeset_memberlink_info(params)
    |> Repo.update()
  end

  def create_emergency_contact(params) do
    case insert_emergency_contact(params) do
      {:ok, contact} ->
        for cp <- params["phones"] do
          params = %{
            type: "mobile",
            contact_id: contact.id,
            number: cp
          }
          PhoneContext.create_phone(params)
        end
      for email <- params["emails"] do
        params = %{
          type: "email",
          contact_id: contact.id,
          address: email
        }
        EmailContext.create_email(params)
      end
      {:ok, contact}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def insert_emergency_contact(params) do
    %Contact{}
    |> Contact.member_emergency_contact_changeset(params)
    |> Repo.insert()
  end

  def insert_member_emergency_contact(member_id, contact_id) do
    params = %{
      member_id: member_id,
      contact_id: contact_id
    }
    %MemberContact{}
    |> MemberContact.changeset(params)
    |> Repo.insert()
  end

  def insert_member_emergency_hospital(params) do
    %EmergencyHospital{}
    |> EmergencyHospital.changeset(params)
    |> Repo.insert()
  end

  def update_emergency_contact(member_id, params) do
    mc = MemberContact
         |> where([mc], mc.member_id == ^member_id)
         |> Repo.one
    if is_nil(mc) do
    else
      Phone
      |> where([p], p.contact_id == ^mc.contact_id)
      |> Repo.delete_all()
      Email
      |> where([e], e.contact_id == ^mc.contact_id)
      |> Repo.delete_all()
      Contact
      |> where([c], c.id == ^mc.contact_id)
      |> Repo.delete_all()
      MemberContact
      |> where([mc], mc.member_id == ^member_id)
      |> Repo.delete_all()
    end
    case insert_emergency_contact(params) do
      {:ok, contact} ->
        for cp <- params["phones"] do
          params = %{
            type: "mobile",
            contact_id: contact.id,
            number: cp["phone"]
          }
          PhoneContext.create_phone(params)
        end
      for email <- params["emails"] do
        params = %{
          type: "email",
          contact_id: contact.id,
          address: email["email"]
        }
        EmailContext.create_email(params)
      end
      {:ok, contact}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_member_emergency_hospital(member_id, params) do
    eh = EmergencyHospital
         |> where([eh], eh.member_id == ^member_id)
         |> Repo.one
    if is_nil(eh) do
      insert_member_emergency_hospital(params)
    else
      changeset = EmergencyHospital.changeset(eh, params)
      Repo.update(changeset)
    end
  end

  # End of MemberLink

  def get_account_code(_data, user_id) do
    user = UserContext.get_user!(user_id)
    if not is_nil(user) and not is_nil(user.user_account) do
      {:ok, user.user_account.account_group.code}
    else
      {:error_user}
    end
  end

  def create_member_import_account_link(member_params, user_id) do
    case member_params["upload_type"] do
      "Corporate" ->
        if String.ends_with?(member_params["file"].filename, ["csv"]) do
          data =
            member_params["file"].path
            |> File.stream!()
            |> CSV.decode(headers: true)

            keys = [
              "Employee No", "Member Type",
              "Relationship", "Effective Date", "Expiry Date",
              "First Name", "Middle Name / Initial", "Last Name",
              "Suffix", "Gender", "Civil Status",
              "Birthdate", "Mobile No", "Email",
              "Date Hired", "Regularization Date", "Address",
              "City", "Plan Code", "For Card Issuance",
              "Tin No", "Philhealth", "Philhealth No", "Remarks"
            ]
            with {:ok, map} <- Enum.at(data, 1),
                 {:equal} <- column_checker(keys, map),
                 {:ok, account_code} <- get_account_code(map, user_id)
            do
              MemberParser.parse_data(
                data,
                member_params["file"].filename,
                user_id,
                member_params["upload_type"],
                account_code)
              {:ok}
            else
              nil ->
                {:not_found}
              {:error, _message} ->
                {:not_found}
              {:not_equal} ->
                {:not_equal}
              {:not_equal, columns} ->
                {:not_equal, columns}
            end
        else
        {:invalid_format}
        end
        "Cancellation" ->
          if String.ends_with?(member_params["file"].filename, ["csv"]) do
            data =
              member_params["file"].path
              |> File.stream!()
              |> CSV.decode(headers: true)

              keys = [
                "Member ID", "Cancellation Date", "Reason"
              ]

              with {:ok, map} <- Enum.at(data, 0),
                   {:equal} <- column_checker(keys, map)
              do
                MemberMaintenanceParser.cancel_parse_data(
                  data,
                  member_params["file"].filename,
                  user_id,
                  member_params["upload_type"])
                {:ok}
              else
                nil ->
                  {:not_found}
                {:not_equal} ->
                  {:not_equal}
                {:not_equal, columns} ->
                  {:not_equal, columns}
              end
          else
            {:invalid_format}
          end

          "Suspension" ->
            if String.ends_with?(member_params["file"].filename, ["csv"]) do
              data =
                member_params["file"].path
                |> File.stream!()
                |> CSV.decode(headers: true)

                keys = [
                  "Member ID", "Suspension Date", "Reason"
                ]

                with {:ok, map} <- Enum.at(data, 0),
                     {:equal} <- column_checker(keys, map)
                do
                  MemberMaintenanceParser.suspend_parse_data(
                    data,
                    member_params["file"].filename,
                    user_id,
                    member_params["upload_type"])
                  {:ok}
                else
                  nil ->
                    {:not_found}
                  {:not_equal} ->
                    {:not_equal}
                  {:not_equal, columns} ->
                    {:not_equal, columns}
                end
            else
              {:invalid_format}
            end

            "Reactivation" ->
              if String.ends_with?(member_params["file"].filename, ["csv"]) do
                data =
                  member_params["file"].path
                  |> File.stream!()
                  |> CSV.decode(headers: true)

                  keys = [
                    "Member ID", "Reactivation Date", "Reason"
                  ]

                  with {:ok, map} <- Enum.at(data, 0),
                       {:equal} <- column_checker(keys, map)
                  do
                    MemberMaintenanceParser.reactivate_parse_data(
                      data,
                      member_params["file"].filename,
                      user_id,
                      member_params["upload_type"])
                    {:ok}
                  else
                    nil ->
                      {:not_found}
                    {:not_equal} ->
                      {:not_equal}
                    {:not_equal, columns} ->
                      {:not_equal, columns}
                  end
              else
                {:invalid_format}
              end
    end
  end

  # Batch Upload
  def create_member_import(member_params, user_id) do
    case member_params["upload_type"] do
      "Corporate" ->
        if String.ends_with?(member_params["file"].filename, ["csv"]) do
          data =
            member_params["file"].path
            |> File.stream!()
            |> CSV.decode(headers: true)

            keys = [
              "Account Code", "Employee No", "Member Type",
              "Relationship", "Effective Date", "Expiry Date",
              "First Name", "Middle Name / Initial", "Last Name",
              "Suffix", "Gender", "Civil Status",
              "Birthdate", "Mobile No", "Email",
              "Date Hired", "Regularization Date", "Address",
              "City", "Plan Code", "For Card Issuance",
              "Tin No", "Philhealth", "Philhealth No", "Remarks"
            ]
            with {:ok, map} <- Enum.at(data, 1),
                 {:equal} <- column_checker(keys, map)
            do
              MemberParser.parse_data(
                data,
                member_params["file"].filename,
                user_id,
                member_params["upload_type"],
                "")
              {:ok}
            else
              nil ->
                {:not_found}
              {:error, _message} ->
                {:not_found}
              {:not_equal} ->
                {:not_equal}
              {:not_equal, columns} ->
                {:not_equal, columns}
              {:error_user} ->
                {:error_user}
            end
        else
        {:invalid_format}
        end

        "Individual, Family, Group (IFG)" ->
          if String.ends_with?(member_params["file"].filename, ["csv"]) do
            data =
              member_params["file"].path
              |> File.stream!()
              |> CSV.decode(headers: true)

              keys = [
                "Account Code", "Principal Number", "Member Type",
                "Relationship", "Effective Date", "Expiry Date",
                "First Name", "Middle Name / Initial", "Last Name",
                "Suffix", "Gender", "Civil Status",
                "Birthdate", "Mobile No", "Email",
                "Address",
                "City", "Plan Code", "For Card Issuance",
                "Tin No", "Philhealth", "Philhealth No", "Remarks"
              ]
              with {:ok, map} <- Enum.at(data, 1),
                   {:equal} <- column_checker(keys, map)
              do
                MemberParser.parse_data(
                  data,
                  member_params["file"].filename,
                  user_id,
                  member_params["upload_type"],
                  "")
                {:ok}
              else
                nil ->
                  {:not_found}
                {:error, _message} ->
                  {:not_found}
                {:not_equal} ->
                  {:not_equal}
                {:not_equal, columns} ->
                  {:not_equal, columns}
              end
          else
          {:invalid_format}
          end

          "Change of Product" ->
            if String.ends_with?(member_params["file"].filename, ["csv"]) do
              data =
                member_params["file"].path
                |> File.stream!()
                |> CSV.decode(headers: true)

                keys = [
                  "Member ID",
                  "Change of Plan Effective Date",
                  "Old Plan Code",
                  "New Plan Code",
                  "Reason"
                ]
                with {:ok, map} <- Enum.at(data, 1),
                     {:equal} <- column_checker(keys, map)
                do
                  MemberParser.parse_cop_data(
                    data,
                    member_params["file"].filename,
                    user_id,
                    member_params["upload_type"],
                    "")
                  {:ok}
                else
                  nil ->
                    {:not_found}
                  {:error, _message} ->
                    {:not_found}
                  {:not_equal} ->
                    {:not_equal}
                  {:not_equal, columns} ->
                    {:not_equal, columns}
                end
            else
            {:invalid_format}
            end
    end
  end

 ## start Batch upload (background worker)
  def create_member_import_worker(member_params, user_id) do
    case member_params["upload_type"] do
      "Corporate" ->
        if String.ends_with?(member_params["file"].filename, ["csv"]) do
          data_csv =
            member_params["file"].path
            |> File.stream!()
            |> CSV.decode(headers: true)

            keys = [
              "Account Code", "Employee No", "Member Type",
              "Relationship", "Effective Date", "Expiry Date",
              "First Name", "Middle Name / Initial", "Last Name",
              "Suffix", "Gender", "Civil Status",
              "Birthdate", "Mobile No", "Email",
              "Date Hired", "Regularization Date", "Address",
              "City", "Plan Code", "For Card Issuance",
              "Tin No", "Philhealth", "Philhealth No", "Remarks"
            ]

            data =
              data_csv
              |> Enum.map(fn({_x, y})-> y end)
              |> Enum.drop(1)

            batch_no =
              get_member_upload_logs()
              |> generate_batch_no()

            file_params = %{
              filename: member_params["file"].filename,
              created_by_id: user_id,
              batch_no: batch_no,
              upload_type: member_params["upload_type"],
              remarks: "ok",
              count: data |> Enum.count()
            }


            with {:ok, map} <- Enum.at(data_csv, 1),
                 {:equal} <- column_checker(keys, map),
                 {:ok, member_file_upload} <- create_member_upload_file(file_params)
            do

              Exq.Enqueuer.start_link
              Exq.Enqueuer
              |> Exq.Enqueuer.enqueue(
                "member_batch_upload_job",
                "Innerpeace.Db.Worker.Job.MemberBatchUploadJob",
                [
                  data,
                  member_file_upload.filename,
                  user_id,
                  member_file_upload.upload_type,
                  member_file_upload.id,
                  ""
                ])

              {:ok}

            else
              nil ->
                {:not_found}
              {:error, _message} ->
                {:not_found}
              {:not_equal} ->
                {:not_equal}
              {:not_equal, columns} ->
                {:not_equal, columns}
              {:error_user} ->
                {:error_user}
            end
        else
        {:invalid_format}
        end

        "Individual, Family, Group (IFG)" ->
          if String.ends_with?(member_params["file"].filename, ["csv"]) do
            data =
              member_params["file"].path
              |> File.stream!()
              |> CSV.decode(headers: true)

              keys = [
                "Account Code", "Principal Number", "Member Type",
                "Relationship", "Effective Date", "Expiry Date",
                "First Name", "Middle Name / Initial", "Last Name",
                "Suffix", "Gender", "Civil Status",
                "Birthdate", "Mobile No", "Email",
                "Address",
                "City", "Plan Code", "For Card Issuance",
                "Tin No", "Philhealth", "Philhealth No", "Remarks"
              ]
              with {:ok, map} <- Enum.at(data, 1),
                   {:equal} <- column_checker(keys, map)
              do
                MemberParser.parse_data(
                  data,
                  member_params["file"].filename,
                  user_id,
                  member_params["upload_type"],
                  "")
                {:ok}
              else
                nil ->
                  {:not_found}
                {:error, _message} ->
                  {:not_found}
                {:not_equal} ->
                  {:not_equal}
                {:not_equal, columns} ->
                  {:not_equal, columns}
              end
          else
          {:invalid_format}
        end

      "Change of Plan" ->
        if String.ends_with?(member_params["file"].filename, ["csv"]) do
          data =
            member_params["file"].path
            |> File.stream!()
            |> CSV.decode(headers: true)

            keys = [
              "Member ID",
              "Change of Plan Effective Date",
              "Old Plan Code",
              "New Plan Code",
              "Reason"
            ]
            with {:ok, map} <- Enum.at(data, 1),
                 {:equal} <- column_checker(keys, map)
            do
              MemberParser.parse_cop_data(
                data,
                member_params["file"].filename,
                user_id,
                member_params["upload_type"],
                "")
              {:ok}
            else
              nil ->
                {:not_found}
              {:error, _message} ->
                {:not_found}
              {:not_equal} ->
                {:not_equal}
              {:not_equal, columns} ->
                {:not_equal, columns}
            end
        else
          {:invalid_format}
        end
    end
    rescue
      e in FunctionClauseError ->
        if e = "no function clause matching in CSV.Decoding.Preprocessing.Lines.ends_sequence?/4"
        do
          {:not_readable}
        else
          user_id
          |> send_error_to_sentry(e)

          {:error, e}
        end
      _ ->
        user_id
        |> send_error_to_sentry("internal server")

        {:error, "internal server"}
  end
  ## end of Batch upload (bgw

  defp column_checker(keys, map) do
    if Enum.sort(keys) == Enum.sort(Map.keys(map)) do
      {:equal}
    else
      keys = Enum.sort(keys) -- Enum.sort(Map.keys(map))
      if Enum.count(keys) >= 6 do
        {:not_equal}
      else
        {:not_equal, Enum.join(keys, ", ")}
      end
    end
  end

  def generate_batch_no(batch_no) do
    origin = batch_no

    case Enum.count(Integer.digits(batch_no)) do
      1 ->
        batch_no = "000#{batch_no}"
      2 ->
        batch_no = "00#{batch_no}"
      3 ->
        batch_no = "0#{batch_no}"
      4 ->
        batch_no = Integer.to_string(batch_no)
      _ ->
        batch_no = Integer.to_string(batch_no)
    end

    with nil <- Repo.get_by(MemberUploadFile, batch_no: batch_no),
         false <- origin == 0
    do
      batch_no
    else
      %MemberUploadFile{} -> # UploadFile Schema
        generate_batch_no(origin + 1)
      true ->
        "0001"
    end
  end

  def create_member_upload_file(attrs) do
    %MemberUploadFile{}
    |> MemberUploadFile.changeset(attrs)
    |> Repo.insert()
  end

  def create_member_upload_log(attrs) do
    %MemberUploadLog{}
    |> MemberUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def create_member_cop_upload_log(attrs) do
    %MemberCOPUploadLog{}
    |> MemberCOPUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def create_member_maintenance_upload_log(attrs) do
    %MemberMaintenanceUploadLog{}
    |> MemberMaintenanceUploadLog.changeset(attrs)
    |> Repo.insert()
  end

  def create_member_parsed(attrs) do
    %Member{}
    |> Member.changeset_api(attrs)
    |> Repo.insert()
  end

  def get_member_upload_logs do
    Repo.one(from muf in MemberUploadFile, select: count("*"))
  end

  def get_member_upload_logs_payorlink do
    MemberUploadFile
    |> where([muf], muf.upload_type in ^["Corporate", "Individual, Family, Group (IFG)", "Change of Plan"])
    |> Repo.all()
    |> Repo.preload([:member_upload_logs, :member_cop_upload_logs])
  end

  def get_employee_no(employee_no) do
    Member
    |> where([m], m.employee_no == ^employee_no and (m.type == ^"Principal" or m.type == ^"Guardian"))
    |> Repo.all()
  end

  def get_employee_no_by_account_code(employee_no, account_code) do
    Member
    |> where([m], m.employee_no  == ^employee_no and
             m.account_code == ^account_code and (m.type == ^"Principal" or m.type == ^"Guardian"))
             |> Repo.all()
  end

  def create_member_account_product(member_id, account_product_id) do
    %MemberProduct{}
    |> MemberProduct.changeset(%{member_id: member_id,
      account_product_id: account_product_id})
      |> Repo.insert()
  end

  def get_member_upload_logs_by_type(member_upload_file_id, status) do
    MemberUploadLog
    |> where([mul], mul.member_upload_file_id ==
      ^member_upload_file_id and mul.status == ^status)
      |> Repo.all()
  end

  def get_member_batch_log(member_upload_file_id, status, type) do
    type = String.downcase(type)
    member =
      MemberUploadLog
      |> join(:inner, [mul], muf in MemberUploadFile,
              mul.member_upload_file_id == muf.id)
              |> where([mul, muf], muf.id == ^member_upload_file_id and
                       mul.status == ^status)
                       |> order_by([mul, muf], mul.inserted_at)

    if status == "success" do
      if type == "corporate" or type == "enrollment" do
        member
        |> select([mul, muf], [
          mul.upload_status, fragment("CONCAT('''', ?)", mul.card_no), mul.account_code,
          fragment("CONCAT('''', ?)", mul.employee_no), mul.type, mul.relationship,
          fragment("CONCAT('''', ?)", mul.effectivity_date),
          fragment("CONCAT('''', ?)", mul.expiry_date),
          mul.first_name, mul.middle_name, mul.last_name,
          mul.suffix, mul.gender, mul.civil_status,
          fragment("CONCAT('''', ?)", mul.birthdate),
          fragment("CONCAT('''', ?)", mul.mobile), mul.email,
          fragment("CONCAT('''', ?)", mul.date_hired),
          fragment("CONCAT('''', ?)", mul.regularization_date),
          mul.address, mul.city, mul.product_code, mul.for_card_issuance,
          mul.tin_no, mul.philhealth, mul.philhealth_no, mul.remarks
        ])
        |> Repo.all()
      else
        member
        |> select([mul, muf], [
          mul.upload_status, fragment("CONCAT('''', ?)", mul.card_no), mul.account_code,
          fragment("CONCAT('''', ?)", mul.employee_no), mul.type, mul.relationship,
          fragment("CONCAT('''', ?)", mul.effectivity_date),
          fragment("CONCAT('''', ?)", mul.expiry_date),
          mul.first_name, mul.middle_name, mul.last_name,
          mul.suffix, mul.gender, mul.civil_status,
          fragment("CONCAT('''', ?)", mul.birthdate),
          fragment("CONCAT('''', ?)", mul.mobile), mul.email, mul.address, mul.city, mul.product_code,
          mul.for_card_issuance, mul.tin_no, mul.philhealth, mul.philhealth_no, mul.remarks
        ])
        |> Repo.all()
      end
    else
      if type == "corporate" or type == "enrollment" do
        member
        |> select([mul, muf], [
          mul.upload_status, mul.account_code, fragment("CONCAT('''', ?)", mul.employee_no),
          mul.type, mul.relationship,
          fragment("CONCAT('''', ?)", mul.effectivity_date),
          fragment("CONCAT('''', ?)", mul.expiry_date),
          mul.first_name, mul.middle_name, mul.last_name,
          mul.suffix, mul.gender, mul.civil_status,
          fragment("CONCAT('''', ?)", mul.birthdate),
          fragment("CONCAT('''', ?)", mul.mobile), mul.email,
          fragment("CONCAT('''', ?)", mul.date_hired),
          fragment("CONCAT('''', ?)", mul.regularization_date),
          mul.address, mul.city, mul.product_code, mul.for_card_issuance,
          mul.tin_no, mul.philhealth, mul.philhealth_no, mul.remarks
        ])
        |> Repo.all()
      else
        member
        |> select([mul, muf], [
          mul.upload_status, mul.account_code, fragment("CONCAT('''', ?)", mul.employee_no),
          mul.type, mul.relationship,
          fragment("CONCAT('''', ?)", mul.effectivity_date),
          fragment("CONCAT('''', ?)", mul.expiry_date),
          mul.first_name, mul.middle_name, mul.last_name,
          mul.suffix, mul.gender, mul.civil_status,
          fragment("CONCAT('''', ?)", mul.birthdate),
          fragment("CONCAT('''', ?)", mul.mobile), mul.email, mul.address, mul.city, mul.product_code,
          mul.for_card_issuance, mul.tin_no, mul.philhealth, mul.philhealth_no, mul.remarks
        ])
        |> Repo.all()
      end
    end
  end

  def get_cop_member_batch_log(member_upload_file_id, status, type) do
    type = String.downcase(type)
    member =
      MemberCOPUploadLog
      |> join(:inner, [mul], muf in MemberUploadFile,
              mul.member_upload_file_id == muf.id)
              |> where([mul, muf], muf.id == ^member_upload_file_id and
                       mul.status == ^status)
                       |> order_by([mul, muf], mul.inserted_at)

    member
    |> select([mul, muf], [
      mul.upload_status,
      mul.member_id,
      mul.change_of_product_effective_date,
      mul.old_product_code,
      mul.new_product_code,
      mul.reason
    ])
    |> Repo.all()
  end

  def get_member_maintenance_batch_log(member_upload_file_id, status) do
    MemberMaintenanceUploadLog
    |> join(:inner, [mmul], muf in MemberUploadFile,
            mmul.member_upload_file_id == muf.id)
            |> where([mmul, muf], muf.id == ^member_upload_file_id and
                     mmul.status == ^status)
                     |> order_by([mmul, muf], mmul.inserted_at)
                     |> select([mmul, muf], [
                       mmul.remarks, mmul.member_id, mmul.maintenance_date, mmul.reason])
                       |> Repo.all()
  end

  def get_member_by_code_n_employee(account_code, employee_no) do
    Member
    |> where([m], m.account_code == ^account_code and
             m.employee_no == ^employee_no)
             |> Repo.all()
  end

  def get_member_by_relationship_n_code(account_code, relationship, employee_no) do
    member = Repo.get_by(Member, employee_no: employee_no, account_code: account_code)
    if is_nil(member) do
      []
    else
      Member
      |> where([m], m.type == ^"Dependent" and
               m.account_code == ^account_code and
               m.relationship == ^relationship and
               m.principal_id == ^member.id)
               |> order_by([m], asc: m.birthdate)
               |> Repo.all()
    end
  end

  def get_member_product_tier(account_code, employee_no) do
    Product
    |> join(:inner, [p], ap in AccountProduct, p.id == ap.product_id)
    |> join(:inner, [p, ap], mp in MemberProduct,
            ap.id == mp.account_product_id)
            |> join(:inner, [p, ap, mp], m in Member, mp.member_id == m.id)
            |> where([p, ap, mp, m], mp.tier == ^1 and
                     m.account_code == ^account_code and
                     m.employee_no == ^employee_no)
                     |> Repo.one
  end

  def get_number_of_dependent(account_code, employee_no) do
    member =
      Member
      |> where([m], m.employee_no == ^employee_no and
               m.account_code == ^account_code and (m.type == ^"Principal" or m.type == ^"Guardian"))
               |> Repo.one

    Member
    |> where([m], m.principal_id == ^member.id and m.type == ^"Dependent")
    |> Repo.all
  end

  def get_product(product_id) do
    Repo.get!(Product, product_id)
  end

  def get_member_file_logs(nil, params), do: []
  def get_member_file_logs(member_upload_file_id, params) do
    MemberUploadLog
    |> where([mul],
             mul.member_upload_file_id == ^member_upload_file_id and
             mul.employee_no == ^params.employee_no and
             mul.account_code == ^params.account_code and
             fragment("lower(?)", mul.relationship) == ^params.relationship and
             fragment("lower(?)", mul.type) == ^"dependent")
             |> select([mul], %{birthdate: mul.birthdate, upload_status: mul.upload_status})
             |> Repo.all()
  end

  def preload_dependents(member) do
    member
    |> Ecto.assoc(:dependents)
    |> Repo.all()
  end
  # batch upload end

  def change_member_movement(%Member{} = member) do
    Member.changeset_movement(member, %{})
  end

  def suspend_member(%Member{} = member, attrs) do
    member
    |> Member.changeset_suspend(attrs)
    |> Repo.update()
  end

  def cancel_member(%Member{} = member, attrs) do
    member
    |> Member.changeset_cancel(attrs)
    |> Repo.update()
  end

  def reactivate_member(%Member{} = member, attrs) do
    member
    |> Member.changeset_reactivate(attrs)
    |> Repo.update()
  end

  def active_member(member) do
    effectivity_date =
      member.effectivity_date
      |> Ecto.Date.cast!()
      |> Ecto.Date.compare(Ecto.Date.utc)

    if effectivity_date == :eq || effectivity_date == :lt do
      params = %{status: "Lapsed"}
      member
      |> Member.changeset_status(params)
      |> Repo.update!()
      params = %{status: "Active"}
      member
      |> Member.changeset_status(params)
      |> Repo.update!()
    end
  end

  def reactivation_member(member) do
    if is_nil(member.reactivate_date) do
      ""
    else
      reactivate_date =
        member.reactivate_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

        if reactivate_date == :eq || reactivate_date == :lt do
          params = %{status: "Active"}
          member
          |> Member.changeset_status(params)
          |> Repo.update!()
        end
    end
  end

  def suspension_member(member) do
    if not is_nil (member.suspend_date) do
      suspend_date =
        member.suspend_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

        if suspend_date == :eq || suspend_date == :lt do
          params = %{status: "Suspended"}
          member
          |> Member.changeset_status(params)
          |> Repo.update!()
        end
    end
  end

  def cancellation_member(member) do
    if not is_nil (member.cancel_date) do
      cancel_date =
        member.cancel_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

        if cancel_date == :eq || cancel_date == :lt do
          params = %{status: "Cancelled"}
          member
          |> Member.changeset_status(params)
          |> Repo.update!()
        end
    end
  end

  def expired_member(member) do

    if is_nil(member.expiry_date) do
      ""
    else
      expiry_date =
        member.expiry_date
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

        if expiry_date == :eq || expiry_date == :lt do
          params = %{status: "Lapsed"}
          member
          |> Member.changeset_status(params)
          |> Repo.update!()
        end

    end
  end

  #AccountLink Functions
  def get_all_member_based_on_account(code) do
    Member
    # |> where([m], m.account_code == ^code and not is_nil(m.card_no))
    |> Repo.all
    |> Repo.preload([
      account_group: [
        account: from(a in Account, where: a.status == "Active")
      ]
    ])
    |> Repo.preload([
      :principal,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        account_product: [
          product: [
            product_coverages: [
              product_coverage_facilities: :facility
            ],
            product_benefits: [
              benefit: [
                :benefit_procedures,
                :benefit_diagnoses,
                [
                  benefit_packages: [
                    package: :package_payor_procedure
                  ]
                ],
                [benefit_coverages: :coverage]
              ]
            ],
            product_exclusions: [
              exclusion: :exclusion_diseases
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share:
               :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ]},
    ])
  end

  def export_members(params) do
    param = params["search_value"]
    validate = params["validate"]
    if Enum.at(validate, 0) != "" and  Enum.at(validate, 1) != "" and
    Enum.at(validate, 2) != "" and Enum.at(validate, 3) != "" and
    Enum.at(validate, 4) != "" and Enum.at(validate, 5) != "" and
    Enum.at(validate, 6) != "" and Enum.at(validate, 7) != "" and param == "" do
      query = (
        from m in Member,
        where:
        ilike(fragment("text(?)", m.id), ^"%#{param}%") or
        ilike(fragment("CONCAT(?, ' ', ?)", m.first_name, m.last_name), ^("%#{param}%")) or
        ilike(m.card_no, ^("%#{param}%")) or
        ilike(m.type, ^("%#{param}%")) or
        ilike(m.status, ^("%#{param}%")),
        order_by: m.id,
        select: [m.id, fragment("CONCAT(?, ' ' , ?)", m.first_name,
m.last_name), m.card_no, m.status]
      )
      _query = Repo.all(query)
    else
      if param == "" do
        if Enum.at(validate, 5) != "" and Enum.at(validate, 6) != ""
        and Enum.at(validate, 7) != "" do
          query = (
            from m in Member,
            where:
            (m.status != ^Enum.at(validate, 0) and
                                  m.status != ^Enum.at(validate, 1) and
                                  m.status != ^Enum.at(validate, 2) and
                                  m.status != ^Enum.at(validate, 3) and
                                  m.status != ^Enum.at(validate, 4)),
                                  order_by: m.id,
                                  select: [m.id, fragment("CONCAT(?, ' ' , ?)",
m.first_name, m.last_name), m.card_no, m.status]
          )
          query = Repo.all(query)
        else
          query = (
            from m in Member,
            where:
            (m.status != ^Enum.at(validate, 0) and
                                  m.status != ^Enum.at(validate, 1) and
                                  m.status != ^Enum.at(validate, 2) and
                                  m.status != ^Enum.at(validate, 3) and
                                  m.status != ^Enum.at(validate, 4) and
                                  m.type != ^Enum.at(validate, 5) and
                                  m.type != ^Enum.at(validate, 6) and
                                  m.type != ^Enum.at(validate, 7)),
                                  order_by: m.id,
                                  select: [m.id, fragment("CONCAT(?, ' ' , ?)",
m.first_name, m.last_name), m.card_no, m.status]
          )
          query = Repo.all(query)
        end
      else
      if Enum.at(validate, 5) != "" and
      Enum.at(validate, 6) != "" and
      Enum.at(validate, 7) != "" do
        query = (
          from m in Member,
          where:
          (ilike(fragment("text(?)", m.id), ^"%#{param}%") and
(m.status != ^Enum.at(validate, 0) and
                      m.status != ^Enum.at(validate, 1) and
                      m.status != ^Enum.at(validate, 2) and
                      m.status != ^Enum.at(validate, 3) and
                      m.status != ^Enum.at(validate, 4))) or
                      (ilike(fragment("CONCAT(?, ' ', ?)", m.first_name, m.last_name), ^("%#{param}%")) and
(m.status != ^Enum.at(validate, 0) and
                      m.status != ^Enum.at(validate, 1) and
                      m.status != ^Enum.at(validate, 2) and
                      m.status != ^Enum.at(validate, 3) and
                      m.status != ^Enum.at(validate, 4))) or
                      (ilike(m.card_no, ^("%#{param}%")) and
                             (m.status != ^Enum.at(validate, 0) and
                                                   m.status != ^Enum.at(validate, 1) and
                                                   m.status != ^Enum.at(validate, 2) and
                                                   m.status != ^Enum.at(validate, 3) and
                                                   m.status != ^Enum.at(validate, 4))) or
                                                   (ilike(m.type, ^("%#{param}%")) and
                                                          (m.status != ^Enum.at(validate, 0) and
                                                                                m.status != ^Enum.at(validate, 1) and
                                                                                m.status != ^Enum.at(validate, 2) and
                                                                                m.status != ^Enum.at(validate, 3) and
                                                                                m.status != ^Enum.at(validate, 4))) or
                                                                                (ilike(m.status, ^("%#{param}%")) and
                                                                                       (m.status != ^Enum.at(validate, 0) and
                                                                                                             m.status != ^Enum.at(validate, 1) and
                                                                                                             m.status != ^Enum.at(validate, 2) and
                                                                                                             m.status != ^Enum.at(validate, 3) and
                                                                                                             m.status != ^Enum.at(validate, 4))),
                                                                                                             order_by: m.id,
                                                                                                             select: [m.id, fragment("CONCAT(?, ' ' , ?)",
m.first_name, m.last_name), m.card_no, m.status]
        )
        query = Repo.all(query)
      else
      query = (
        from m in Member,
        where:
        (ilike(fragment("text(?)", m.id), ^"%#{param}%") and
(m.status != ^Enum.at(validate, 0) and
                      m.status != ^Enum.at(validate, 1) and
                      m.status != ^Enum.at(validate, 2) and
                      m.status != ^Enum.at(validate, 3) and
                      m.status != ^Enum.at(validate, 4) and
                      m.type != ^Enum.at(validate, 5) and
                      m.type != ^Enum.at(validate, 6) and
                      m.type != ^Enum.at(validate, 7))) or
                      (ilike(fragment("CONCAT(?, ' ', ?)", m.first_name, m.last_name), ^("%#{param}%")) and
(m.status != ^Enum.at(validate, 0) and
                      m.status != ^Enum.at(validate, 1) and
                      m.status != ^Enum.at(validate, 2) and
                      m.status != ^Enum.at(validate, 3) and
                      m.status != ^Enum.at(validate, 4) and
                      m.type != ^Enum.at(validate, 5) and
                      m.type != ^Enum.at(validate, 6) and
                      m.type != ^Enum.at(validate, 7))) or
                      (ilike(m.card_no, ^("%#{param}%")) and
                             (m.status != ^Enum.at(validate, 0) and
                                                   m.status != ^Enum.at(validate, 1) and
                                                   m.status != ^Enum.at(validate, 2) and
                                                   m.status != ^Enum.at(validate, 3) and
                                                   m.status != ^Enum.at(validate, 4) and
                                                   m.type != ^Enum.at(validate, 5) and
                                                   m.type != ^Enum.at(validate, 6) and
                                                   m.type != ^Enum.at(validate, 7))) or
                                                   (ilike(m.type, ^("%#{param}%")) and
                                                          (m.status != ^Enum.at(validate, 0) and
                                                                                m.status != ^Enum.at(validate, 1) and
                                                                                m.status != ^Enum.at(validate, 2) and
                                                                                m.status != ^Enum.at(validate, 3) and
                                                                                m.status != ^Enum.at(validate, 4) and
                                                                                m.type != ^Enum.at(validate, 5) and
                                                                                m.type != ^Enum.at(validate, 6) and
                                                                                m.type != ^Enum.at(validate, 7))) or
                                                                                (ilike(m.status, ^("%#{param}%")) and
                                                                                       (m.status != ^Enum.at(validate, 0) and
                                                                                                             m.status != ^Enum.at(validate, 1) and
                                                                                                             m.status != ^Enum.at(validate, 2) and
                                                                                                             m.status != ^Enum.at(validate, 3) and
                                                                                                             m.status != ^Enum.at(validate, 4) and
                                                                                                             m.type != ^Enum.at(validate, 5) and
                                                                                                             m.type != ^Enum.at(validate, 6) and
                                                                                                             m.type != ^Enum.at(validate, 7))),
                                                                                                             order_by: m.id,
                                                                                                             select: [m.id, fragment("CONCAT(?, ' ' ,?)",
m.first_name, m.last_name), m.card_no, m.status]
      )
      query = Repo.all(query)
      end
      end
    end
  end

  def get_member_maintenance_upload_logs_by_type(member_upload_file_id, status) do
    MemberMaintenanceUploadLog
    |> where([mul], mul.member_upload_file_id == ^member_upload_file_id and
             mul.status == ^status)
             |> Repo.all()
  end

  def get_member_upload_files_by_created_by(created_by_ids) do
    MemberUploadFile
    |> where([muf], muf.created_by_id in (^created_by_ids))
    |> Repo.all()
    |> Repo.preload([:member_upload_logs, :member_maintenance_upload_logs])
  end

  # AccountLink Single Enrollment of PEME
  def single_peme_create(member) do
    # Insert a new PEME Member record
    %Member{}
    |> Member.al_peme_changeset_general(member)
    |> Repo.insert
  end

  def single_peme_update_general(id, member) do
    # Update PEME member record according to fields in general step
    record = get_member!(id)
    record
    |> Member.al_peme_changeset_general(member)
    |> Repo.update
  end

  def single_peme_update_contact(id, member) do
    # Update PEME member record according to fields in contact step
    record = get_member!(id)
    record
    |> Member.al_peme_changeset_contact(member)
    |> Repo.update
  end

  # def get_peme_loa(id) do
  #   # Gets a PEME Loa record according to its member id
  #   PemeLoa
  #   |> where([pl], pl.member_id == ^id)
  #   |> Repo.one
  #   |> Repo.preload([
  #     package: [
  #       [package_facility: :facility],
  #       [package_payor_procedure: [
  #           payor_procedure: :procedure
  #         ]
  #       ]
  #     ]
  #   ])
  # end

  # def single_peme_request_loa(peme_loa) do
  #   # Inserts a new PEME Loa record
  #   %PemeLoa{}
  #   |> PemeLoa.changeset(peme_loa)
  #   |> Repo.insert
  # end

  def load_packages(member_id) do
    # Returns list of package.
    member =
      Member
      |> where([m], m.id == ^member_id)
      |> Repo.one
      |> Repo.preload(
        [products:
         [account_product:
          [product:
           [benefits:
            [benefit_packages: :package]
           ]
          ]
         ]
        ]
      )

    member_products = member.products
    packages = [] ++ for mp <- member_products do
      if mp.account_product.product.product_category == "PEME Plan" do
        for b <- mp.account_product.product.benefits do
          for p <- b.benefit_packages do
            package = p.package
            %{display: "#{package.code} - #{package.name}", id: package.id}
          end
        end
      end
    end
    _packages =
      packages
      |> List.flatten
      |> Enum.uniq
  end

  def load_package(package_id) do
    # Returns record of package.
    Package
    |> Repo.get(package_id)
    |> Repo.preload([
      package_facility: :facility,
      package_payor_procedure: [
        payor_procedure: :procedure
      ]
    ])
  end
  #End AcountLink Functions

  def get_a_member!(id) do
    Member
    |> Repo.get!(id)
    |> Repo.preload([
      account_group: [
        account: from(a in Account, where: a.status == "Active")
      ]
    ])
    |> Repo.preload([
      :peme,
      :principal,
      :created_by,
      :updated_by,
      dependents: :skipped_dependents,
      acu_schedule_members: :acu_schedule,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        :member,
        account_product: [
          product: [
            [
              product_exclusions: [
                exclusion: [
                  :exclusion_durations,
                  exclusion_procedures: :procedure,
                  exclusion_diseases: :disease
                ]
              ]
            ],
            [
              product_benefits: [
                [product: [product_coverages: :coverage]],
                :product_benefit_limits,
                benefit: [
                  benefit_ruvs: :ruv,
                  benefit_diagnoses: :diagnosis,
                  benefit_coverages: :coverage,
                  benefit_packages: [package: [package_payor_procedure: [payor_procedure: [:procedure, :exclusion_procedures, :facility_payor_procedures, :package_payor_procedures]], package_facility: :facility]],
                  benefit_procedures: :procedure
                ]
              ]
            ],
            product_coverages: [
              :product_coverage_facilities,
              :coverage,
              [
                product_coverage_risk_share: [
                  product_coverage_risk_share_facilities: [
                    product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
                  ]
                ]
              ]
            ]
          ]
        ]
      ]},
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]]
    ])

    rescue
      Ecto.NoResultsError ->
        nil
      _ ->
        nil
  end

  def get_acu_member!(id) do
    Member
    |> Repo.get!(id)
    |> Repo.preload([
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        account_product: [
          product: [
            [
              product_benefits: [
                benefit: [
                  benefit_coverages: :coverage,
                  benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure], package_facility: :facility]],
                ]
              ]
            ],
          ]
        ]
      ]}
    ])
  end

  #Skipping Hierarchy
  def get_all_skipping_hierarchy do
    MemberSkippingHierarchy
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      member: [:principal, :account_group]
    ])
  end

  def get_skipping_based_on_member(member_id) do
    MemberSkippingHierarchy
    |> where([msh], msh.member_id == ^member_id)
    |> select([msh], msh.id)
    |> Repo.all()
  end

  def delete_skipping_based_on_member(id) do
    msh = MemberSkippingHierarchy
          |> where([msh], msh.id == ^id)
          |> Repo.one()
    File.rm_rf(Path.expand('./uploads/files/') <> "/#{msh.id}")
    msh
    |> Repo.delete()
  end

  def approve_skipping_hierarchy(id, user_id) do
    member = Member
             |> Repo.get(id)
             |> Repo.preload([:skipped_dependents])
    for skip <- member.skipped_dependents do
      skip
      |> MemberSkippingHierarchy.changeset_approve(%{updated_by_id: user_id, status: "Approved"})
      |> Repo.update()
    end
    member
    |> Member.changeset_status_cast(%{status: nil})
    |> Repo.update()
  end

  def update_status_to_nil(member) do
    member
    |> Member.changeset_status_cast(%{status: nil})
    |> Repo.update()
  end

  def disapprove_skipping_hierarchy(id, user_id, reason) do
    member = Member
             |> Repo.get(id)
             |> Repo.preload([:skipped_dependents])
    for skip <- member.skipped_dependents do
      skip
      |> MemberSkippingHierarchy.changeset_approve(%{updated_by_id: user_id, status: "Disapproved", disapproval_reason: reason})
      |> Repo.update()
    end
    member
    |> Member.changeset_status(%{status: "Disapprove"})
    |> Repo.update()
  end

  def update_for_approval_status(member) do
    member
    |> Member.changeset_status(%{status: "For Approval"})
    |> Repo.update()
  end

  def get_all_skipping_based_on_param(param, type) do
    _data = if type == "processed" do
      skip_type_processed(param, type)
    else
      skip_type_pending(param, type)
    end
  end

  def skip_type_processed(param, type) do
    param = param["search_value"]
    query = (
      from msh in MemberSkippingHierarchy,
      join: m in Member, on: msh.member_id == m.id,
      join: ag in AccountGroup, on: m.account_code == ag.code,
      join: u in User, on: msh.created_by_id == u.id,
      join: uu in User, on: msh.updated_by_id == u.id,
      where: ((ilike(fragment("lower(?)", fragment("concat(?,' ',?)", m.first_name, m.last_name)), ^"%#{param}%") or ilike(fragment("CAST(? As varchar(50))", m.id), ^"%#{param}%") or ilike(fragment("lower(?)", fragment("concat(?,' ',?)", ag.code, ag.name)), ^"%#{param}%") or ilike(fragment("to_char(?, 'YYYY-MM-DD')", msh.inserted_at), ^"%#{param}%") or ilike(fragment("lower(?)", u.username), ^"%#{param}%") or ilike(fragment("to_char(?, 'YYYY-MM-DD')", msh.updated_at), ^"%#{param}%") or ilike(fragment("lower(?)", uu.username), ^"%#{param}%") or ilike(fragment("lower(?)", msh.status), ^"%#{param}%")) and not is_nil(msh.status)
      ),
      group_by: msh.id
    )

    query
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      member: [:principal, :account_group]
    ])

  end

  def skip_type_pending(param, type) do
    param = param["search_value"]
    query = (
      from msh in MemberSkippingHierarchy,
      join: m in Member, on: msh.member_id == m.id,
      join: ag in AccountGroup, on: m.account_code == ag.code,
      join: u in User, on: msh.created_by_id == u.id,
      where: ((ilike(fragment("lower(?)", fragment("concat(?,' ',?)", m.first_name, m.last_name)), ^"%#{param}%") or ilike(fragment("CAST(? As varchar(50))", m.id), ^"%#{param}%") or ilike(fragment("lower(?)", fragment("concat(?,' ',?)", ag.code, ag.name)), ^"%#{param}%") or ilike(fragment("to_char(?, 'YYYY-MM-DD')", msh.inserted_at), ^"%#{param}%") or ilike(fragment("lower(?)", u.username), ^"%#{param}%")) and (msh.status == "" or is_nil(msh.status)) and m.step >= 5
      ),
      group_by: msh.id
    )

    query
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      member: [:principal, :account_group]
    ])
  end
  #End Skipping Hierarchy

  #Loa Function

  def update_member_product_payor_pays(member_product, attr) do
    member_product
    |> MemberProduct.changeset_loa_payor_pays(attr)
    |> Repo.update()
  end

  #End Loa Function
  #member product seeds
  def insert_or_update_member_product(params) do
    member_product = get_mp_by_account_product_member(params)
    if is_nil(member_product) do
      create_a_member_product(params)
    else
      update_a_member_product(member_product.id, params)
    end
  end

  def get_mp_by_account_product_member(params) do
    MemberProduct
    |> Repo.get_by(account_product_id: params.account_product_id, member_id: params.member_id)
  end

  def create_a_member_product(param) do
    %MemberProduct{}
    |> MemberProduct.changeset(param)
    |> Repo.insert
  end

  def update_a_member_product(id, param) do
    id
    |> get_member_product()
    |> List.first()
    |> MemberProduct.changeset(param)
    |> Repo.update
  end

  def update_member_status(account_code) do
    account =
      Account
      |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
      |> join(:inner, [a, ag], m in Member, ag.code == m.account_code)
      |> where([a, ag], ag.code == ^account_code and a.status == ^"Active")
      |> Repo.all()

    if Enum.empty?(account) do
      account =
        Account
        |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
        |> join(:inner, [a, ag], m in Member, ag.code == m.account_code)
        |> where([a, ag], ag.code == ^account_code)
        |> order_by([a], desc: a.inserted_at)
        |> limit(1)
        |> Repo.one

        Member
        |> join(:inner, [m], ag in AccountGroup, m.account_code == ag.code)
        |> where([m, ag], ag.id == ^account.account_group_id)
        |> Repo.update_all(set: [status: account.status])
    end
  end

  # SCHEMALESS CHANGESET FOR MEMBERLINK EMERGENCY CONTACT
  def emergency_contact_changeset(user) do
    params = setup_emergency_contact_params(user)
    types = %{
      # fields from member schema
      blood_type: :string,
      allergies: :string,
      medication: :string,

      #fields from member emergency contact schema
      ecp_name: :string,
      ecp_relationship: :string,
      ecp_phone: :string,
      ecp_phone2: :string,
      ecp_email: :string,
      hospital_name: :string,
      hospital_telephone: :string,
      hmo_name: :string,
      member_name: :string,
      card_number: :string,
      policy_number: :string,
      customer_care_number: :string
    }
    {%{}, types} |> Changeset.cast(params, Map.keys(types))
  end

  defp setup_emergency_contact_params(user) do
    %{
      blood_type: user.member.blood_type,
      allergies: user.member.allergies,
      medication: user.member.medication
    } |> Map.merge(setup_emergency_card_params(user))
  end

  defp setup_emergency_card_params(user) do
    if is_nil(user.member.emergency_contact) do
      %{}
    else
      %{
        ecp_name: user.member.emergency_contact.ecp_name,
        ecp_relationship: user.member.emergency_contact.ecp_relationship,
        ecp_phone: user.member.emergency_contact.ecp_phone,
        ecp_phone2: user.member.emergency_contact.ecp_phone2,
        ecp_email: user.member.emergency_contact.ecp_email,
        hospital_name: user.member.emergency_contact.hospital_name,
        hospital_telephone: user.member.emergency_contact.hospital_telephone,
        hmo_name: user.member.emergency_contact.hmo_name,
        member_name: user.member.emergency_contact.member_name,
        card_number: user.member.emergency_contact.card_number,
        policy_number: user.member.emergency_contact.policy_number,
        customer_care_number: user.member.emergency_contact.customer_care_number,
      }
    end
  end

  def insert_or_update_member_emergency_info(member, member_params) do
    if is_nil(member.emergency_contact) do
      changeset = EmergencyContact.changeset(%EmergencyContact{}, Map.put(member_params, "member_id", member.id))
      Repo.insert(changeset)
    else
      changeset = EmergencyContact.changeset(member.emergency_contact, member_params)
      Repo.update(changeset)
    end
  end

  def get_pwd_id do
    Member
    |> where([m], not is_nil(m.pwd_id))
    |> select([m], m.pwd_id)
    |> Repo.all()
  end

  def get_senior_id do
    Member
    |> where([m], not is_nil(m.senior_id))
    |> select([m], m.senior_id)
    |> Repo.all()
  end

  def get_mobile_number(mobile) do
    Member
    |> where([m], m.mobile == ^mobile)
    |> select([m], m.mobile)
    |> Repo.all()
  end

  ## for Comment
  def insert_single_comment(id, params, current_user_id) do
    %MemberComment{}
    |> MemberComment.changeset(
      %{
        member_id: id,
        comment: params["comment"],
        created_by_id: current_user_id,
        updated_by_id: current_user_id
      }
    )
    |> Repo.insert()
  end

  # Member Logs in Member Page

  def create_member_log(user, member) do
    member_name = "#{member.first_name} #{member.middle_name} #{member.last_name}"
    message = "<b>#{user.username} </b> enrolled a member named <b> <i>#{member_name} </b> </i>"

    insert_log(%{
      member_id: member.id,
      user_id: user.id,
      message: message
    })
  end

  def logs_for_edit_member(user, member, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message =  "<b>#{user.username} </b> edited #{changes} in <b> #{tab} tab. </b>"
      insert_log(%{
        member_id: member.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def movement_member_log(user, member, params, movement) do
    cond do
      movement == "cancel" ->
        changes = insert_changes_to_string(params)
        message = "<b> #{user.username} </b> Cancelled an member where #{changes}."
        insert_log(%{
          member_id: member.id,
          user_id: user.id,
          message: message
        })
      movement == "suspend" ->
        changes = insert_changes_to_string(params)
        message = "<b> #{user.username} </b> Suspend an member where #{changes}."
        insert_log(%{
          member_id: member.id,
          user_id: user.id,
          message: message
        })
      movement == "reactivate" ->
        changes = insert_changes_to_string(params)
        message = "<b> #{user.username} </b> Suspend an member where #{changes}."
        insert_log(%{
          member_id: member.id,
          user_id: user.id,
          message: message
        })
      movement == "retract" ->
        changes = insert_changes_to_string(params)
        message = "<b> #{user.username} </b> Retracted a movement where #{changes}."
        insert_log(%{
          member_id: member.id,
          user_id: user.id,
          message: message
        })
    end
  end

  def add_member_product_log(user, account_product_ids, member_id) do
    product_codes = for ap_id <- account_product_ids do
      AccountContext.get_account_product!(ap_id).product.code
    end
    product_code = Enum.join(product_codes, ",")
    message = "<b>#{user.username} </b> added a plan where plan codes are <b> #{product_code} </b>"
    insert_log(%{
      member_id: member_id,
      user_id: user.id,
      message: message
    })
  end

  def payorlink_one_peme_member_log(user_id, member_id, message) do
    insert_log(%{
      member_id: member_id,
      user_id: user_id,
      message: message
    })
  end

  def update_card_no_and_policy_and_integration_id(response, member) do
    member
    |> Member.changeset_update_peme_member_payorlink_one(%{
      integration_id: response["EmpID"],
      card_no: response["CardNo"],
      policy_no: response["PolicyNo"],
      status: "Active",
      step: 5
    })
    |> Repo.update()
    # payorlink_one_peme_member_log(member.created_by_id,
    #                               member.id,
    #                               "Successfully inserted peme member in Payorlink I")
  end

  def delete_member_product_log(user, ap_id, member_id) do
    product_code = AccountContext.get_account_product!(ap_id).product.code
    message = "<b>#{user.username} </b> deleted a plan where plan code is <b> #{product_code} </b>"
    insert_log(%{
      member_id: member_id,
      user_id: user.id,
      message: message
    })
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      "<b> <i> Cluster #{transform_atom(key)} </b> </i> from <b> <i> #{Map.get(changeset.data, key)} </b> </i> to <b> <i> #{new_value} </b> </i>"
    end
    changes |> Enum.join(", ")
  end

  defp insert_changes_to_string(params) do
    changes = for {key, new_value} <- params, into: [] do
      "<b> <i> #{transform_atom(key)} </b> </i> is <b> <i> #{new_value} </b> </i>"
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  def insert_log(params) do
    changeset = MemberLog.changeset(%MemberLog{}, params)
    Repo.insert!(changeset)
  end

  def get_member_logs(member_id) do
    MemberLog
    |> where([rl], rl.member_id == ^member_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  #for member index
  def get_all_members_query(params, offset) do
    Member
    |> join(:inner, [m], ag in AccountGroup, m.account_code == ag.code)
    |> where([m, ag],
             ilike(fragment("CAST(? AS TEXT)", m.id), ^"%#{params}%") or
             ilike(fragment("lower(?)",
fragment("concat(?, ' ', ?)", m.first_name, m.last_name)),

^"%#{params}%") or
ilike(fragment("lower(?)",
fragment("concat(?, ' ', ?)", m.last_name, m.first_name)),
^"%#{params}%") or
ilike(m.card_no, ^"%#{params}%") or
ilike(ag.name, ^"%#{params}%") or
ilike(m.status, ^"%#{params}%")
    )
    |> limit(100)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([
      :account_group,
      skipped_dependents: :created_by,
      products: [account_product: :product]
    ])
  end

  def get_active_without_evoucher do
    Member
    |> where(
      [m],
      fragment(
        "? > current_date - interval '3' day",
        m.inserted_at
      )
      and is_nil(m.evoucher_number)
      and m.status == "Active"
    )
    |> Repo.all()
    |> Repo.preload([
      :principal,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        account_product: [
          product: [
            product_coverages: [
              product_coverage_facilities: :facility
            ],
            product_benefits: [
              benefit: [
                :benefit_procedures,
                :benefit_diagnoses,
                [
                  benefit_packages: [
                    package: :package_payor_procedure
                  ]
                ],
                [benefit_coverages: :coverage]
              ]
            ],
            product_exclusions: [
              exclusion: :exclusion_diseases
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share:
               :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ]},
    ])
  end

  defp get_enrolled_today do
    Member
    |> where(
      [m],
      fragment(
        "?::date = now()::date",
        m.inserted_at
      )
    )
    |> Repo.all()
    |> Repo.preload([
      :principal,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        account_product: [
          product: [
            product_coverages: [
              product_coverage_facilities: :facility
            ],
            product_benefits: [
              benefit: [
                :benefit_procedures,
                :benefit_diagnoses,
                [
                  benefit_packages: [
                    package: :package_payor_procedure
                  ]
                ],
                [benefit_coverages: :coverage]
              ]
            ],
            product_exclusions: [
              exclusion: :exclusion_diseases
            ],
            product_coverages: [
              :coverage,
              [product_coverage_risk_share:
               :product_coverage_risk_share_facilities]
            ]
          ]
        ]
      ]},
    ])
  end

  def get_enrolled_tody_members_by_product do
    MemberProduct
    |> join(:inner, [mp], m in Member, mp.member_id == m.id)
    |> join(:inner, [mp, m], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [mp, m, ap], a in Account, ap.account_id == a.id)
    |> join(:inner, [mp, m, ap, a], ag in AccountGroup, a.account_group_id == ag.id)
    |> join(:inner, [mp, m, ap, a, ag], p in Product, ap.product_id == p.id)
    |> select([mp, m, ap, a, ag, p], %{
      id: mp.id,
      member_id: m.id,
      member_status: m.status,
      member_type: m.type,
      account_group_code: ag.code,
      product_code: p.code
    })
    |> where(
      [mp, m, ap, a, ag],
      fragment(
        # "?::date = now()::date",
        "to_char(?::date, 'YYYYMMDD') = to_char((now() - interval '1 day'), 'YYYYMMDD')",
        m.inserted_at
      )
    )
    |> Repo.all()
  end

  def generate_balancing_file do
    members = get_enrolled_tody_members_by_product()
    content =
      members
      |> Enum.group_by(&(&1.account_group_code))
      |> Enum.map(fn({account_group_code, members}) ->
        grouped = Enum.group_by(members, &(&1.product_code))
        Enum.map(grouped, fn({product_code, members}) ->
          [
            account_group_code,
            product_code,
            count_members_grand_total(members),
            count_member_by_status(members, "Active", "Dependent"),
            count_member_by_status(members, "Active", "Guardian"),
            count_member_by_status(members, "Active", "Principal"),
            count_member_by_status(members, "Active"),
            count_member_by_status(members, "Cancelled", "Dependent"),
            count_member_by_status(members, "Cancelled", "Guardian"),
            count_member_by_status(members, "Cancelled", "Principal"),
            count_member_by_status(members, "Cancelled"),
            count_member_by_status(members, "Pending", "Dependent"),
            count_member_by_status(members, "Pending", "Guardian"),
            count_member_by_status(members, "Pending", "Principal"),
            count_member_by_status(members, "Pending"),
            count_member_by_status(members, "Lapsed", "Dependent"),
            count_member_by_status(members, "Lapsed", "Guardian"),
            count_member_by_status(members, "Lapsed", "Principal"),
            count_member_by_status(members, "Lapsed"),
            count_member_by_status(members, "For Approval", "Dependent"),
            count_member_by_status(members, "For Approval", "Guardian"),
            count_member_by_status(members, "For Approval", "Principal"),
            count_member_by_status(members, "For Approval")
          ]
        end)
      end)
    content = Enum.concat(content)
    headers = [
      "account_code",
      "product_code",
      "grand_total",
      "active_dependent",
      "active_guardian",
      "active_principal",
      "active_total",
      "cancelled_dependent",
      "cancelled_guardian",
      "cancelled_principal",
      "cancelled_total",
      "pending_for_activation_dependent",
      "pending_for_activation_guardian",
      "pending_for_activation_principal",
      "pending_for_activation_total",
      "lapsed_dependent",
      "lapsed_guardian",
      "lapsed_principal",
      "lapsed_total",
      "for_approval_dependent",
      "for_approval_guardian",
      "for_approval_principal",
      "for_approval_total"
    ]
    hehe =
      [headers] ++ content
      |> CSV.encode()
      |> Enum.to_list()
      |> to_string()
    insert_balancing_file(hehe)
  end

  defp insert_balancing_file(content) do
    {:ok, file} = insert_balancing_file()
    pathsample = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
      :dev ->
        Path.expand('./uploads/files/')
      :prod ->
        Path.expand('./uploads/files/')
      _ ->
        nil
    end
    File.mkdir_p!(Path.expand('./uploads/files'))
    File.write!(pathsample <> "/balancing_file.csv", content)
    attatch_balancing_file(pathsample, file)
    File.rm_rf("#{pathsample}/balancing_file.csv")
  end

  defp insert_balancing_file do
    %BalancingFile{}
    |> BalancingFile.changeset(%{name: "balancing_file"})
    |> Repo.insert()
  end

  defp attatch_balancing_file(path, file) do
    file_params = %{"file" => %Plug.Upload{
      content_type: "application/csv",
      path: "#{path}/balancing_file.csv",
      filename: "#{date_today_string()}_#{file.id}.csv"
    }}

    file
    |> BalancingFile.changeset_file(file_params)
    |> Repo.update()
  end

  defp date_today_string do
    Ecto.Date.to_string(Ecto.Date.utc())
  end

  defp count_members_grand_total(members) do
    Enum.count(members, fn(member) ->
      member.member_status == "Active" or
      member.member_status == "Cancelled" or
      member.member_status == "Pending" or
      member.member_status == "Lapsed" or
      member.member_status == "For Approval"
    end)
  end

  defp count_member_by_status(members, status) do
    Enum.count(members, &(&1.member_status == status))
  end

  defp count_member_by_status(members, status, member_type) do
    Enum.count(members, &(&1.member_status == status and &1.member_type == member_type))
  end

  def generate_evoucher(members, application) do
    Enum.map(members, fn(member) ->
      if is_nil(acu_checker(member)) do
        nil
      else
        insert_evoucher(member, acu_checker(member), application)
      end
    end)
  end

  defp acu_checker(member) do
    Enum.find(member.products, fn(member_product) ->
      member_product.account_product.product.product_coverages
      |> Enum.map(&(&1.coverage.name))
      |> Enum.member?("ACU")
    end)
  end

  defp insert_evoucher(member, member_product, application) do
    acu_coverage =
      member_product.account_product.product.product_coverages
      |> Enum.find(fn(product_coverage) ->
        product_coverage.coverage.description == "ACU"
      end)
    acu_package = get_acu_package_code(member, member_product)
    if acu_package == {:not_eligble} do
      nil
    else
      {acu_type, benefit_package} = acu_package
      evoucher_number = generate_evoucher_number(acu_type)
      evoucher_qr = "#{evoucher_number}|#{benefit_package.package.code}"
      {:ok, member} =
        member
        |> Member.changeset_evoucher(%{
          evoucher_number: evoucher_number,
          evoucher_qr_code: evoucher_qr
        })
        |> Repo.update()
        # notify_member(member, acu_coverage, application)
    end
  end

  defp notify_member(member, acu_coverage, application) do
    contact_number = member.mobile
    message = acu_facility_checker(member, acu_coverage)
    SMS.send(%{
      text: message,
      to: "63#{contact_number}"
    })
    evoucher_email(member, acu_coverage, application)
  end

  defp evoucher_email(member, acu_coverage, application) do
    if not is_nil(member.email) do
      message = "Your eVoucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}."
      if application == "payor_link" do
        member
        |> PayorEmailSmtp.evoucher(message)
        |> PayorMailer.deliver_now()
      else
        member
        |> AccountEmailSmtp.evoucher(message)
        |> AccountMailer.deliver_now()
      end
    end
  end

  defp email_facility_checker(member, acu_coverage) do
    case acu_coverage.type do
      "inclusion" ->
        if Enum.count(acu_coverage.product_coverage_facilities) > 1 do
          "Dear #{member.first_name} #{member.last_name},

          Your eVoucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. To avail your ACU click wwww.maxicare.com.ph. To view affiliated facility https://viewacufacility.com.ph."
        else
          facility = List.first(acu_coverage.product_coverage_facilities).facility
          facility_address = "#{facility.line_1} #{facility.line_2} #{facility.city} #{facility.province} #{facility.region}"
          "Your e-voucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. You may avail your annual check up at #{facility.name} located at #{facility_address}. Please schedule an appointment first before you visit the Hospital/Clinic. #{facility_phone_checker(facility.phone_no)}"
        end
      "exception" ->
        "Your e-voucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. View affiliated hospitals here https://viewacuhospitals.com.ph"
      _ ->
        "Your e-voucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. View affiliated hospitals here https://viewacuhospitals.com.ph"
    end
  end

  defp acu_facility_checker(member, acu_coverage) do
    case acu_coverage.type do
      "inclusion" ->
        if Enum.count(acu_coverage.product_coverage_facilities) > 1 do
          "Dear #{member.first_name} #{member.last_name}, \n \n Your eVoucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. To avail your ACU click wwww.maxicare.com.ph. To view affiliated facility https://viewacufacility.com.ph."
        else
          facility = List.first(acu_coverage.product_coverage_facilities).facility
          facility_address = "#{facility.line_1} #{facility.line_2} #{facility.city} #{facility.province} #{facility.region}"
          "Dear #{member.first_name} #{member.last_name}, \n \n Your eVoucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. You may avail your annual check up at #{facility.name} located at #{facility_address}."
        end
      "exception" ->
        "Dear #{member.first_name} #{member.last_name}, \n \n Your eVoucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. To avail your ACU click wwww.maxicare.com.ph. To view affiliated facility https://viewacufacility.com.ph."
      _ ->
        "Your e-voucher number is (#{member.evoucher_number}) valid until #{member.expiry_date}. View affiliated hospitals here https://viewacuhospitals.com.ph"
    end
  end

  defp facility_phone_checker(phone_no) do
    if is_nil(phone_no) do
      ""
    else
      "Contact No: #{String.slice(phone_no, 0..2)}-#{String.slice(phone_no, 3..6)}"
      ""
    end
  end

  defp get_acu_package_code(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    acu_benefits = filter_acu_benefits(member_product)
    product_benefit = Enum.find(acu_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_procedures, fn(benefit_procedure) ->
        String.contains?(benefit_procedure.gender, member.gender) and
        check_age_from_to(age, benefit_procedure.age_from..benefit_procedure.age_to)
      end)
    end)
    if product_benefit do
      {product_benefit.benefit.acu_type, List.first(product_benefit.benefit.benefit_packages) || %{package: %{code: ""}}}
    else
      {:not_eligble}
    end
  end

  defp check_age_from_to(age, range) do
    list = for x <- range, do: x
    Enum.member?(list, age)
  end

  defp filter_acu_benefits(member_product) do
    Enum.filter(member_product.account_product.product.product_benefits, fn(product_benefit) ->
      product_benefit.benefit.benefit_coverages
      |> Enum.map(&(&1.coverage.name))
      |> Enum.member?("ACU")
    end)
  end

  defp generate_evoucher_number(acu_type) do
    random_number = Enum.random(100_000..999_999)
    evoucher_number = "#{acu_type_checker(acu_type)}-#{random_number}"
    checker =
      Member
      |> where([m], m.evoucher_number == ^evoucher_number)
      |> Repo.all()
    if Enum.empty?(checker) do
      evoucher_number
    else
      generate_evoucher_number(acu_type)
    end
  end

  defp acu_type_checker(acu_type) do
    if acu_type == "Executive" do
      "ECU"
    else
      "ACU"
    end
  end

  def get_member_by_id_and_card_number(member_id, card_number) do
    Member
    |> Repo.get_by(id: member_id, card_no: card_number)
  end

  def get_acu_affiliated_facilities(member_id) do

    member = try do
      get_a_member!(member_id)
    rescue
      _ ->
        nil
    end

    with true <- not is_nil(member),
         coverage <- CoverageContext.get_coverage_by_name("ACU")
    do
      member_products =
        for member_product <- member.products do
          member_product
        end

      member_products =
        member_products
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()

      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member_products,
          coverage.id
        )

      product = member_product.account_product.product
      ProductContext.get_acu_affiliated_facilities(product.id)
      else
      _ ->
        {:error}
    end
  end

  def get_member_account_name_by_code(account_code) do
    account =
      AccountGroup
      |> Repo.get_by(code: account_code)

    account.name

    if not is_nil(account_code) or account_code == "" do
      account =
        AccountGroup
        |> Repo.get_by(code: account_code)

        account.name
    else
      "Account Code Missing"
    end
  end

  def get_acu_product_by_member_id(member_id) do
    member = try do
      get_a_member!(member_id)
    rescue
      _ ->
        nil
    end

    with true <- not is_nil(member),
         coverage <- CoverageContext.get_coverage_by_name("ACU")
    do
      member_products =
        for member_product <- member.products do
          member_product
        end

      member_products =
        member_products
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()

      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member_products,
          coverage.id
        )

      if is_nil(member_product.account_product) do
        product = nil
      else
        product = member_product.account_product.product
      end
      else
      _ ->
        {:error}
    end
  end

  def get_authorization_member_products(member_product_id) do
    AuthorizationDiagnosis
    |> where([ad], ad.member_product_id == ^member_product_id)
    |> Repo.all
  end

  def check_acu_loa_by_member(member_id) do
    # Check ACU Loa by Member if Member has already availed ACU.

    coverage = CoverageContext.get_coverage_by_name("ACU")
    authorizations =
      Authorization
      |> where([a], a.coverage_id == ^coverage.id
               and a.status == ^"Approved"
               and a.member_id == ^member_id)
               |> Repo.all

    if Enum.empty?(authorizations) do
      Authorization
      |> where([a], a.coverage_id == ^coverage.id
               and a.member_id == ^member_id)
               |> Repo.delete_all

               {:ok}
    else
      {:error}
    end
  end

  def get_member_by_card_no_memberlink(card_no) do
    member =
      Member
      |> Repo.get_by(card_no: card_no)
      |> Repo.preload([:user,
                       account_group: [:account]
      ])
    if is_nil(member) do
      {:not_found}
    else
      if is_nil(member.user) do
        {:not_found}
      else
        {:ok, member}
      end
    end
  end

  def validate_evoucher(evoucher) do
    evoucher = String.slice(evoucher, 5..10)
    with peme_member = %PemeMember{} <- MemberContext.get_member_peme_by_evoucher(evoucher),
         {:valid} <- validate_evoucher_loa_m(peme_member.member),
         {:valid} <- validate_evoucher_not_edited(peme_member.member)
         #  {:valid} <- validate_evoucher_age_gender(peme_member.member)
    do
      {:ok, peme_member.member.id}
    else
      {:loa, false} ->
        {:error_loa}
      {:invalid, message} ->
        {:invalid, message}
      _ ->
        {:error}
    end
  end

  defp validate_evoucher_age_gender(params, peme) do
    for bppp <- peme.package.package_payor_procedure do
      male = false
      female = false
      if params["gender"] == "Male" do
        male = true
      else
        female = true
      end

      cond do
        bppp.male == male ->
          validate_age(params["birthdate"], peme.member, bppp)
        bppp.female == female ->
          validate_age(params["birthdate"], peme.member, bppp)
        true ->
          {:invalid,
            "You are not eligible to avail this e-voucher Reason: #{params["gender"]} is not eligible to avail this package"}
      end
    end
    |> List.flatten
    |> List.first
  end

  defp validate_age(birth_date, member, bppp) do
    {:ok, birth_date} = Ecto.Date.cast(birth_date)
    age = UtilityContext.age(birth_date)
    if bppp.age_from <= age and age <= bppp.age_to do
      {:valid}
    else
      {:invalid, "You are not eligible to avail this e-voucher Reason: #{age} years old is not eligible to avail this package"}
    end
  end

  defp validate_evoucher_loa_m(member) do
    if Enum.empty?(member.authorizations) do
      {:valid}
    else
      {:loa, false}
    end
  end

  defp validate_evoucher_not_edited(member) do
    with true <- member.first_name == "Temporary",
         true <- member.last_name == "Member"
    do
      {:valid}
    else
      _ ->
        {:error}
    end
  end

  def update_evoucher_member_accountlink(conn, params) do
    evoucher = String.slice(params["evoucher"], 5..10)
    peme = get_peme_by_member_id(params["id"])

    with {:valid} <- validate_evoucher_age_gender(params, peme) do
      member =
        Member
        |> where([m], m.id == ^params["id"])
        |> Repo.one

      changeset = Member.changeset_update_evoucher(member, params)
      Repo.update(changeset)
      peme_facility = if not is_nil(peme.facility.code) do
        peme.facility.code
      else
        nil
      end

      member_card_no = member.card_no

      rp_params = %{
        "origin" => "Accountlink",
        "member_id" => params["id"],
        "facility_code" => peme_facility,
        "card_no" => member_card_no,
        "coverage_code" => "PEME",
        "evoucher" => evoucher,
        "member" => params
      }

      result = %{
        member: member,
        rp_params: rp_params
      }

      {:ok, result}

      # if not is_nil(peme_facility) do
      #    with {:ok} <- request_peme_loa(conn, rp_params) do
      # else
      #    end
      # end
    else
      {:invalid, message} ->
        {:invalid, message}
      _ ->
        {:error, ""}
    end
  end

  # def request_peme_loa(conn, rp_params) do
  #   AuthorizationAPI.get_peme_details(conn, rp_params)
  # end

  def update_evoucher_member_status(id, params) do
    member =
      Member
      |> where([m], m.id == ^id)
      |> Repo.one()
    member
    |> Member.changeset_peme_evoucher(params)
    |> Repo.update()
  end

  def get_all_peme(account_group_id) do
    Peme
    |> join(:left, [p], ag in AccountGroup, ag.id == p.account_group_id)
    |> where([p, ag], ag.id == ^account_group_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:facility, :package, :member])
  end

  def get_peme(id) do
    Peme
    |> Repo.get(id)
    # |> Repo.preload(peme_members: from(pm in PemeMember, order_by: [asc: pm.inserted_at]))
    |> Repo.preload([
      :facility,
      :account_group,
      [
        authorization: [
          :authorization_amounts,
          authorization_benefit_packages: :benefit_package,
          authorization_practitioners: :practitioner

        ]
      ],
      [
        member: :account_group
      ],
      [
        package: :package_payor_procedure
      ],
      [
        member: [
          :authorizations
        ]
      ]
    ])
  end

  def get_peme_procedures(id) do
    Peme
    |> join(:left, [pe], p in Package, p.id == pe.package_id)
    |> join(:left, [pe, p], ppp in PackagePayorProcedure, ppp.package_id == p.id)
    |> join(:left, [pe, p, ppp], pp in PayorProcedure, pp.id == ppp.payor_procedure_id)
    |> join(:left, [pe, p, ppp, pp], pr in Procedure, pr.id == pp.procedure_id)
    |> where([pe, p, ppp, pr], pe.id == ^id)
    |> select([pe, p, ppp, pr], %{code: pr.code, name: pr.description})
    |> Repo.all()
  end

  def get_peme_by_member_id(id) do
    peme =
      Peme
      |> where([p], p.member_id == ^id)
      |> Repo.one
      |> Repo.preload([
        :facility, :member,
        package: :package_payor_procedure,
        member: [:authorizations]
      ])
  end

  # def insert_peme_evoucher(params) do
  #   %Peme{}
  #   |> Peme.changeset(params)
  #   |> Repo.insert()
  # end

  def insert_peme_member_v2(params, counts, account_products, account_group) do
    for count <- 1..String.to_integer(counts) do
      package = PackageContext.get_package(params["package_id"])
      evoucher_number = generate_peme_evoucher_number
      {today, time} = :calendar.now_to_datetime(:erlang.now)
      request_date = Ecto.DateTime.from_erl({today, time})
      peme_param = Map.merge(params, %{
        "account_group_id" => account_group.id,
        "evoucher_number" => evoucher_number,
        "evoucher_qrcode" => "#{evoucher_number}|#{package.code}",
        "status" => "Pending",
        "request_date" => request_date
      })

      peme =
        %Peme{}
        |> Peme.changeset(peme_param)
        |> Repo.insert()
    end
  end

  def send_evoucher_electronically(params, counts, account_products, account_group, locale) do
    for count <- 1..String.to_integer(params["member_count"]) do
      emails = Enum.at(params["email_address"], count-1)
      mobiles = Enum.at(params["mobile_number"], count-1)
      mobile_code = Enum.at(params["mobile_code"], count-1)
      package = PackageContext.get_package(params["package_id"])
      evoucher_number = generate_peme_evoucher_number
      {today, time} = :calendar.now_to_datetime(:erlang.now)
      request_date = Ecto.DateTime.from_erl({today, time})
      peme_param = Map.merge(params, %{
        "account_group_id" => account_group.id,
        "evoucher_number" => evoucher_number,
        "evoucher_qrcode" => "#{evoucher_number}|#{package.code}",
        "status" => "Pending",
        "request_date" => request_date,
        "email_address" => emails,
        "mobile_number" => mobiles
      })
      %Peme{}
      |> Peme.changeset(peme_param)
      |> Repo.insert()

      email_address = Enum.at(params["email_address"], count-1)
      mobile_number = Enum.at(params["mobile_number"], count-1)
      mobile_number_code = Enum.at(params["mobile_code"], count-1)

      if not is_nil(email_address) and email_address != "" do
        send_evoucher_thru_email(email_address, evoucher_number, account_group.id, locale)
      end

      if not is_nil(mobile_number) and mobile_number != "" do
        send_evoucher_thru_mobile(mobile_number, mobile_number_code,  evoucher_number, account_group.id, locale)
      end
    end
  end

  def send_evoucher_thru_email(emails, evoucher_number, account_group_id, locale) do
    url =
      ApiAddress
      |> Repo.get_by(name: "PORTAL")

    account_code_name = get_account_group_name_by_id(account_group_id)

    emails
    |> EmailSmtp.evoucher_peme(evoucher_number, account_code_name, url, locale)
    |> Mailer.deliver_now
  end

  def send_evoucher_thru_mobile(mobiles, mobile_code , evoucher_number, account_group_id, locale) do
    url =
      ApiAddress
      |> Repo.get_by(name: "PORTAL")

    account_code_name = get_account_group_name_by_id(account_group_id)
    {:ok, result} = SMS.send(%{
      text: "Your Pre-employment Medical Evaluation E-voucher for #{account_code_name} is #{evoucher_number}. Please follow the ff steps. 1. Go to #{url.address}/#{locale}/evoucher. 2. Fill out information. 3. Print. 4. Present e-voucher to the selected facility. 5. Have your Pre-employment medical examination done!",
      to: "#{mobile_code}#{mobiles}"
    })

    {:ok, sms_result} = Poison.decode(result.body)
    if sms_result["isvalid"] == false or sms_result["IsValid"] == false do
      send_evoucher_thru_mobile(mobiles, mobile_code , evoucher_number, account_group_id, locale)
    end

    {:ok, result}
  end

  def get_account_group_name_by_id(id) do
    account =
      AccountGroup
      |> Repo.get_by(id: id)

    account.name
  end

  def insert_peme_member_id(peme, member_id) do
    peme
    |> Ecto.Changeset.change(%{member_id: member_id, status: "Pending"})
    |> Repo.update()
  end

  def generate_peme_evoucher_number do
    random_number = Enum.random(100_000..999_999)
    evoucher_number = "PEME-#{random_number}"
    checker =
      Peme
      |> where([p], p.evoucher_number == ^evoucher_number)
      |> Repo.all()

    if Enum.empty?(checker) do
      evoucher_number
    else
      generate_peme_evoucher_number()
    end
  end

  def cancel_evoucher(id) do
    params = %{
      status: "Cancelled"
    }

    Member
    |> Repo.get(id)
    |> Member.changeset_status_cast(params)
    |> Repo.update
  end

  def cancel_evoucher_peme(id) do
    params = %{
      status: "Cancelled"
    }

    Peme
    |> Repo.get(id)
    |> Peme.status_changeset(params)
    |> Repo.update
  end

  def cancel_evoucher_peme(peme, params) do
    params = Map.put(params, "status", "Cancelled")

    peme
    |> Peme.status_changeset(params)
    |> Repo.update()
  end

  def validate_cancel_evoucher(member_id) do
    member =
      Member
      |> Repo.get(member_id)
      |> Repo.preload([:authorizations, :peme])

    with true <- validate_evoucher_loa(member)
    do
      {:ok}
    else
      {:error} ->
        {:error}
      _ ->
        {:error}
    end
  end

  def validate_evoucher_loa(member) do
    peme_auth = member.peme.authorization_id
      if check_peme_loa_status(peme_auth) do
        cancel_evoucher(member.id)
        cancel_evoucher_peme(member.peme.id)
        true
      else
        {:error}
      end
  end

  def check_peme_loa_status(authorization_id) do
   auth =
    Authorization
    |> Repo.get_by(id: authorization_id, status: "Cancelled")

    if not is_nil(auth) do
      true
    else
      false
    end
  end

  def get_member_evoucher(member_id) do
    peme =
      Peme
      |> where([p], p.member_id == ^member_id)
      |> Repo.one
    peme.evoucher_number
  end

  def get_peme_member(peme_member_id) do
    # PemeMember
    # |> where([pm], pm.id == ^peme_member_id)
    # |> Repo.one
    # |> Repo.preload([
    #   :member,
    #   peme: [
    #     :facility,
    #     :package
    #   ]
    # ])
    # rescue
    # _ ->
    nil
  end

  def update_cop_member_products(product_codes, member) do
    codes =
      product_codes
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    account =
      member.account_group.id
      |> AccountContext.get_latest_account
      |> Repo.preload([
        account_products: :product
      ])

    ap_codes =
      account.account_products
      |> Enum.map(
        &(
          &1.product.code
          |> String.upcase
        )
      )
    member_product = load_member_product_with_tier(member.id)

    last_mp_tier =
      if not Enum.empty?(member_product) do
        member_product
        |> List.last
        |> Enum.at(1)
      else
        0
      end

    for {pc, index} <- Enum.with_index(codes, last_mp_tier + 1) do
      if Enum.member?(ap_codes, pc) do
        ap =
          account.account_products
          |> Enum.map(
            &(
              if String.upcase(&1.product.code) == pc, do: &1
            )
          )
          |> Enum.filter(&(not is_nil(&1)))
          |> List.first

        params = %{
          member_id: member.id,
          account_product_id: ap.id,
          tier: index
        }

        try do
          %MemberProduct{}
          |> MemberProduct.changeset(params)
          |> Repo.insert
        rescue
          _ ->
            MemberProduct
            |> where(
              [mp], mp.member_id == ^params.member_id
              and mp.account_product_id == ^params.account_product_id
            )
            |> Repo.one
            |> MemberProduct.changeset_is_archived(
              %{
                is_archived: false,
                tier: index
              }
            )
            |> Repo.update
        end
      end
    end
  end

  def delete_cop_member_products(product_codes, member) do
    codes =
      product_codes
      |> String.split(";")
      |> Enum.map(&(String.upcase(&1)))

    for mp <- member.products do
      pc =
        mp.account_product.product.code
        |> String.upcase

      if Enum.member?(codes, pc) do
        mp
        |> MemberProduct.changeset_is_archived(%{is_archived: true})
        |> Repo.update
      end
    end
  end

  defp load_member_product_with_tier(member_id) do
    query = (
      from mp in MemberProduct,
      where: mp.is_archived != true and mp.member_id == ^member_id,
      order_by: [
        asc: mp.tier
      ],
      select: [
        mp.id,
        mp.tier
      ]
    )

    Repo.all(query)
  end

  def reassign_tier_cop_mp(member_id) do
    member_products = load_member_product_with_tier(member_id)

    if not Enum.empty?(member_products) do
      for {mp, index} <- Enum.with_index(member_products, 1) do
        id = Enum.at(mp, 0)

        MemberProduct
        |> where([mp], mp.id == ^id)
        |> Repo.one
        |> MemberProduct.changeset_tier(%{tier: index})
        |> Repo.update
      end
    end
  end

  def get_acu_package_based_on_member(member, nil), do: nil

  def get_acu_package_based_on_member(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    acu_benefits = filter_acu_benefits(member_product)
    product_benefit = Enum.find(acu_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
        get_acu_package_based_on_member2(age, member, benefit_package, product_benefit)
      end)
    end)
  end

  def get_acu_package_based_on_member2(age, member, benefit_package, product_benefit) do
    cond do
      benefit_package.male == true && benefit_package.female == false ->
        package_gender = "Male"
      benefit_package.female == true && benefit_package.male == false ->
        package_gender = "Female"
      Enum.all?([benefit_package.male, benefit_package.female]) ->
        package_gender = "Male & Female"
      true ->
        package_gender = "nil"
    end

    if String.contains?(package_gender, member.gender) and
    check_age_from_to(age, benefit_package.age_from..benefit_package.age_to) do
      product_benefit
    end
  end

  def get_acu_package_based_on_member_for_schedule(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    acu_benefits = filter_acu_benefits(member_product)
    product_benefit = Enum.map(acu_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
        get_acu_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit)
      end)
    end)
  end

  def get_acu_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit) do
    cond do
      benefit_package.male == true && benefit_package.female == false ->
        package_gender = "Male"
      benefit_package.female == true && benefit_package.male == false ->
        package_gender = "Female"
      Enum.all?([benefit_package.male, benefit_package.female]) ->
        package_gender = "Male & Female"
      true ->
        package_gender = "nil"
    end

    if String.contains?(package_gender, member.gender) and
    check_age_from_to(age, benefit_package.age_from..benefit_package.age_to) do
      benefit_package
    end
  end

  defp filter_acu_benefits_based_on_product(product) do
    Enum.filter(product.product_benefits, fn(product_benefit) ->
      product_benefit.benefit.benefit_coverages
      |> Enum.map(&(&1.coverage.name))
      |> Enum.member?("ACU")
    end)
  end

  def get_acu_member(member, acu_product, facility_id) do
    age = UtilityContext.age(member.birthdate)
    acu_benefits = filter_acu_benefits_based_on_product(acu_product)
    member = Enum.map(acu_benefits, fn(acu_benefit) ->
      x = Enum.map(acu_benefit.benefit.benefit_procedures, fn(benefit_procedure) ->
        get_member_based_on_acu(age, member, benefit_procedure, acu_benefit, facility_id)
      end)
      Enum.find(x, fn(y) -> y end)
    end)

    member = Enum.find(member, fn(m) ->
      m
    end)
  end

  def get_member_based_on_acu(age, member, benefit_procedure, acu_benefit, facility_id) do
    if String.contains?(benefit_procedure.gender, member.gender) and
    check_age_from_to(age, benefit_procedure.age_from..benefit_procedure.age_to) do
      member
    end
  end

  def unutilized_preload_member(member) do
    member
    |> Repo.preload([
      :member_logs,
      [
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]}
      ],
      [
        dependents:  {from(m in Member, where: m.step >= 5), [:skipped_dependents]}
      ],
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                benefit: [
                  benefit_coverages: :coverage,
                  benefit_packages: [
                    package: [
                      package_payor_procedure: [
                        :payor_procedure
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]}
      ],
      [
        account_group: [
          account: [
            account_products: [
              product: [
                product_benefits: [
                  benefit: [
                    benefit_coverages: :coverage,
                    benefit_packages: [
                      package: [
                        package_payor_procedure: [
                          :payor_procedure
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ],
      [
        authorizations: {from(a in Authorization, where: a.status == "Approved"), [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :authorization_amounts,
          batch_authorizations: [:batch],
          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
        }
      ]
    ])
  end

  def utilized_preload_member(member) do
    member
    |> Repo.preload([
      :principal,
      :created_by,
      :updated_by,
      :member_logs,
      :kyc_bank,
      [
        dependents: :skipped_dependents
      ],
      [
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]}
      ],
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                benefit: [
                  :benefit_diagnoses,
                  benefit_coverages: :coverage,
                  benefit_packages: [
                    package: [
                      package_payor_procedure: [
                        :payor_procedure
                      ]
                    ]
                  ]
                ]
              ],
              product_exclusions: [
                exclusion: :exclusion_diseases
              ],
              product_coverages: [
                :coverage,
                [product_coverage_risk_share:
                 :product_coverage_risk_share_facilities]
              ]
            ]
          ]
        ]}
      ],
      [
        prinicipal_member_product: [
          account_product: :product
        ]
      ],
      [
        account_group: [
          :members,
          :payment_account,
          account: [
            account_products: [
              product: [
                product_benefits: [
                  benefit: [
                    benefit_coverages: :coverage,
                    benefit_packages: [
                      package: [
                        package_payor_procedure: [
                          :payor_procedure
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ],
      [
        authorizations: {from(a in Authorization, where: a.status == "Availed"), [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :approved_by,
          :authorization_amounts,
          #:authorization_diagnosis,
          batch_authorizations: [:batch],
          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
        }
      ]
    ])
  end

  def preload_member(member) do
    member
    |> Repo.preload([
      :principal,
      :created_by,
      :updated_by,
      :member_logs,
      :kyc_bank,
      [
        dependents: :skipped_dependents
      ],
      [
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]}
      ],
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                benefit: [
                  :benefit_diagnoses,
                  benefit_coverages: :coverage,
                  benefit_packages: [
                    package: [
                      package_payor_procedure: [
                        :payor_procedure
                      ]
                    ]
                  ]
                ]
              ],
              product_exclusions: [
                exclusion: :exclusion_diseases
              ],
              product_coverages: [
                :coverage,
                [product_coverage_risk_share:
                 :product_coverage_risk_share_facilities]
              ]
            ]
          ]
        ]}
      ],
      [
        prinicipal_member_product: [
          account_product: :product
        ]
      ],
      [
        account_group: [
          :members,
          :payment_account,
          account: [
            account_products: [
              product: [
                product_benefits: [
                  benefit: [
                    benefit_coverages: :coverage,
                    benefit_packages: [
                      package: [
                        package_payor_procedure: [
                          :payor_procedure
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ],
      [
        authorizations: [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :authorization_amounts,
          #:authorization_diagnosis,
          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
      ]
    ])
  end

  def get_age(date) do
    year_of_date = to_string(date)
    year_today =  Date.utc
    year_today = to_string(year_today)
    datediff1 = Timex.parse!(year_of_date, "%Y-%m-%d", :strftime)
    datediff2 = Timex.parse!(year_today, "%Y-%m-%d", :strftime)
    diff_in_years = Timex.diff(datediff2, datediff1, :years)
    diff_in_years
  end

  def get_all_active_members() do
    coverage_id = CoverageContext.get_coverage_by_code("ACU").id
    Member
    |> where([m], m.status == "Active")
    |> Repo.all()
    |> utilized_preload_member_active(coverage_id)
  end

  def get_all_active_members_by_batch_no(batch_no) do
    test = get_all_members_by_batch_no(batch_no)

    member_ids = Enum.map(test, fn(x) ->
      Enum.map(x.batch_authorizations, fn(ba) ->
        ba.authorization.member.id
      end)
    end)

    member_ids =
      member_ids
      |> List.flatten()

    coverage_id = CoverageContext.get_coverage_by_code("ACU").id
    Member
    |> where([m], m.status == "Active" and m.id in ^member_ids)
    |> Repo.all()
    |> utilized_preload_member_active(coverage_id)
  end

  def get_all_members_by_batch_no(batch_no) do
    Batch
    |> where([b], b.batch_no == ^batch_no)
    |> Repo.all()
    |> Repo.preload([
      :facility,
      :practitioner,
      :created_by,
      [
        batch_authorizations: [
          authorization: [
            :authorization_amounts,
            :member,
            :coverage
          ]
        ]
      ]
    ])
  end

  def generate_claims_file do
    members = get_all_active_members()
    year = get_d_hms().year
    month = get_d_hms().month
    day = get_d_hms().day
    hour = get_d_hms().hour
    minute = get_d_hms().minute
    second = get_d_hms().second
    date_today = "#{year}#{month}#{day}#{hour}#{minute}#{second}"

    url = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/claims_file/')
      :dev ->
        Path.expand('./uploads/claims_file/')
      :prod ->
        Path.expand('./uploads/claims_file/')
      _ ->
        nil
    end

    File.mkdir_p!(Path.expand(url))

    head_header = Enum.join(["Batch Number|Claim Number|LOE|LOA|Principal ID|Member ID|Principal PolicyNo|MemberID PolicyNo|Corporate Code|Plan ID|Age|",
                             "Effective Date|Expiry Date|Funding Arrangement|ClaimType|Source|Class (Medical/Surgical)|Coverage|Availment Type|Diagnosis Code|",
                             "Diagnosis Desc|ProviderCode|DoctorCode|ClaimRemarks|LOA Remarks|SOA|Received Date(SOA Date)|SOA AMOUNT|Service Date|Admission Date|",
                             "Discharge Date|Approved Date|Approved By|Claim Status|Assessed Amount|Billed Amount|Approved Amount|Total Deduction|Total VAT|",
                             "Total PF|Total HB|Total PFExcess|Total HBExcess|Provider Excess|Member Excess|SpecialApproval Amount|HB SpecialApproval Amount|",
                             "PF SpecialApproval Amount|Corporate Guarantee|ASO Override|Fee for Service|Ex Gratia|Advanced Limit|ASO Rider|TotalCopay|",
                             "TotalPFCopay|TotalHBCopay|Rider Code|Maternity Flag|Dental Flag|ACU Flag|OPMed Flag|PEME|Reimbursement? (Y/N)|MRC|UpgradeRoomReason|",
                             "Emergency Tag|Create Date|LOA Creation Date|LOA Approval Date|Estimate Due|LOA Type|OP Type|XP? (Y/N)|RTP Type|RTP Reason|RTP Scan Doc Link|",
                             "RTP Claimlink|RTP Amount|RFR No|RRF Amount|RFR Status|RRF Reason|Billing Doc Number|AP Posted|GP STATUS|Applied to Payment|Applied to CM|",
                             "Voided\n"])

    item_header = Enum.join(["Batch Number|Claim Number|Item Number|Diagnosis Code|Coverage Item|CPT|CPT Description|",
                             "Benefit ID|Benefit Description|Physician/ Doctor|Billed Amount|PHIC|Coverage Amount|ExcessCoveredByHosp|ExcessCoveredByMember|",
                             "PayableAmt|Copay|NoofDays|RUV|RUV Code|RUV Mltiplier|RoomType|Vatable|Individual/Umbrella|ClaimNoGP|Corporate Guarantee|ASO Override|Fee For Service|",
                             "Ex Gratia|Advance Limit|REAL_MEMBEREXCESS|AP Document Number+Company Code + Year|Payment Document Number|RFR No|RFR Amount|XP\n"])

    count_header = Enum.join(["Batch Number|SOA Number|Received Date|Provider Code|LOE COUNT|CLAIM COUNT|\n"])

    File.write!("#{url}/HEADER#{date_today}.txt", head_header)
    File.write!("#{url}/ITEMS#{date_today}.txt", item_header)
    File.write!("#{url}/COUNT#{date_today}.txt", count_header)

    Enum.map(members, fn(member) ->
      # try do
      member = get_acu_verified_member(member.id)
      member =
        member
        |> List.first()

      coverage = CoverageContext.get_coverage_by_code("ACU")

      if is_nil(member.authorizations) or member.authorizations == [] do
        true
      else
        cond do
          coverage.code == "ACU" ->
            authorization_id = Enum.map(member.authorizations, fn(auth) ->
              auth.id
            end)

            header = generate_acu_file(member, coverage, url).header_body
            item = generate_acu_file(member, coverage, url).item_body
            count = generate_acu_file(member, coverage, url).count_body

            File.write!("#{url}/HEADER#{date_today}.txt", header, [:append])
            File.write!("#{url}/ITEMS#{date_today}.txt", item, [:append])
            File.write!("#{url}/COUNT#{date_today}.txt", count, [:append])

            AuthorizationContext.claims_file_update_authorization(flatten_data(authorization_id), %{"is_claimed?" => true})
          true ->
        end
      end
      #rescue
      #  _ ->
      #    true
      # end
    end)

    local_path = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:claims_dir)

    with {:ok} <- ftp_transfer_file("HEADER#{date_today}.txt", local_path),
         {:ok} <- ftp_transfer_file("ITEMS#{date_today}.txt", local_path),
         {:ok} <- ftp_transfer_file("COUNT#{date_today}.txt", local_path)
    do
      attach_claim_file(url, date_today)
      File.rm_rf("#{url}/HEADER#{date_today}.txt")
      File.rm_rf("#{url}/ITEMS#{date_today}.txt")
      File.rm_rf("#{url}/COUNT#{date_today}.txt")
    else
      {:error, message} ->
        {:error, message}
      _ ->
        {:error, "Error"}
    end
  end

  def generate_claims_file_by_batch_no(batch_no) do
    members = get_all_active_members_by_batch_no(batch_no)
    year = get_d_hms().year
    month = get_d_hms().month
    day = get_d_hms().day
    hour = get_d_hms().hour
    minute = get_d_hms().minute
    second = get_d_hms().second
    date_today = "#{year}#{month}#{day}#{hour}#{minute}#{second}"

    url = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/claims_file/')
      :dev ->
        Path.expand('./uploads/claims_file/')
      :prod ->
        Path.expand('./uploads/claims_file/')
      _ ->
        nil
    end

    File.mkdir_p!(Path.expand(url))

    head_header = Enum.join(["Batch Number|Claim Number|LOE|LOA|Principal ID|Member ID|Principal PolicyNo|MemberID PolicyNo|Corporate Code|Plan ID|Age|",
                             "Effective Date|Expiry Date|Funding Arrangement|ClaimType|Source|Class (Medical/Surgical)|Coverage|Availment Type|Diagnosis Code|",
                             "Diagnosis Desc|ProviderCode|DoctorCode|ClaimRemarks|LOA Remarks|SOA|Received Date(SOA Date)|SOA AMOUNT|Service Date|Admission Date|",
                             "Discharge Date|Approved Date|Approved By|Claim Status|Assessed Amount|Billed Amount|Approved Amount|Total Deduction|Total VAT|",
                             "Total PF|Total HB|Total PFExcess|Total HBExcess|Provider Excess|Member Excess|SpecialApproval Amount|HB SpecialApproval Amount|",
                             "PF SpecialApproval Amount|Corporate Guarantee|ASO Override|Fee for Service|Ex Gratia|Advanced Limit|ASO Rider|TotalCopay|",
                             "TotalPFCopay|TotalHBCopay|Rider Code|Maternity Flag|Dental Flag|ACU Flag|OPMed Flag|PEME|Reimbursement? (Y/N)|MRC|UpgradeRoomReason|",
                             "Emergency Tag|Create Date|LOA Creation Date|LOA Approval Date|Estimate Due|LOA Type|OP Type|XP? (Y/N)|RTP Type|RTP Reason|RTP Scan Doc Link|",
                             "RTP Claimlink|RTP Amount|RFR No|RRF Amount|RFR Status|RRF Reason|Billing Doc Number|AP Posted|GP STATUS|Applied to Payment|Applied to CM|",
                             "Voided\n"])

    item_header = Enum.join(["Batch Number|Claim Number|Item Number|Diagnosis Code|Coverage Item|CPT|CPT Description|",
                             "Benefit ID|Benefit Description|Physician/ Doctor|Billed Amount|PHIC|Coverage Amount|ExcessCoveredByHosp|ExcessCoveredByMember|",
                             "PayableAmt|Copay|NoofDays|RUV|RUV Code|RUV Mltiplier|RoomType|Vatable|Individual/Umbrella|ClaimNoGP|Corporate Guarantee|ASO Override|Fee For Service|",
                             "Ex Gratia|Advance Limit|REAL_MEMBEREXCESS|AP Document Number+Company Code + Year|Payment Document Number|RFR No|RFR Amount|XP\n"])

    count_header = Enum.join(["Batch Number|SOA Number|Received Date|Provider Code|LOE COUNT|CLAIM COUNT|\n"])

    File.write!("#{url}/HEADER#{date_today}.txt", head_header)
    File.write!("#{url}/ITEMS#{date_today}.txt", item_header)
    File.write!("#{url}/COUNT#{date_today}.txt", count_header)

    Enum.map(members, fn(member) ->
      #try do
      member = get_acu_verified_member(member.id)
      member =
        member
        |> List.first()

    coverage = CoverageContext.get_coverage_by_code("ACU")

      if is_nil(member.authorizations) do
        true
      else
        cond do
          coverage.code == "ACU" ->
            authorization_id = Enum.map(member.authorizations, fn(auth) ->
              auth.id
            end)

            header = generate_acu_file(member, coverage, url).header_body
            item = generate_acu_file(member, coverage, url).item_body
            count = generate_acu_file(member, coverage, url).count_body

            File.write!("#{url}/HEADER#{date_today}.txt", header, [:append])
            File.write!("#{url}/ITEMS#{date_today}.txt", item, [:append])
            File.write!("#{url}/COUNT#{date_today}.txt", count, [:append])

            AuthorizationContext.claims_file_update_authorization(flatten_data(authorization_id), %{"is_claimed?" => true})
          true ->
        end
      end
      #rescue
      #  _ ->
      #    true
      #end
    end)

    attach_claim_file(url, date_today)
    # File.rm_rf("#{url}/HEADER#{date_today}.txt")
    # File.rm_rf("#{url}/ITEMS#{date_today}.txt")
    # File.rm_rf("#{url}/COUNT#{date_today}.txt")
  end

  defp attach_claim_file(path, date) do
    with {:ok, header} <- insert_header_claim_file(path, date),
         {:ok, item} <- insert_item_claim_file(path, date),
         {:ok, count} <- insert_count_claim_file(path, date)
    do
      {:ok}
    else
      _ ->
        {:error}
    end
  end

  defp insert_header_claim_file(path, date) do
    {:ok, file} =
      %ClaimFile{}
      |> ClaimFile.changeset(%{name: "claim_file"})
      |> Repo.insert()

    file_params = %{"file" => %Plug.Upload{
      content_type: "application/txt",
      path: "#{path}/HEADER#{date}.txt",
      filename: "HEADER#{date}.txt"
    }}

    file
    |> ClaimFile.changeset_file(file_params)
    |> Repo.update()
  end

  defp insert_item_claim_file(path, date) do
    {:ok, file} =
      %ClaimFile{}
      |> ClaimFile.changeset(%{name: "claim_file"})
      |> Repo.insert()

    file_params = %{"file" => %Plug.Upload{
      content_type: "application/txt",
      path: "#{path}/ITEMS#{date}.txt",
      filename: "ITEMS#{date}.txt"
    }}

    file
    |> ClaimFile.changeset_file(file_params)
    |> Repo.update()
  end

  defp insert_count_claim_file(path, date) do
    {:ok, file} =
      %ClaimFile{}
      |> ClaimFile.changeset(%{name: "claim_file"})
      |> Repo.insert()

    file_params = %{"file" => %Plug.Upload{
      content_type: "application/txt",
      path: "#{path}/COUNT#{date}.txt",
      filename: "COUNT#{date}.txt"
    }}

    file
    |> ClaimFile.changeset_file(file_params)
    |> Repo.update()
  end

  defp insert_claim_file() do
    %ClaimFile{}
    |> ClaimFile.changeset(%{name: "claim_file"})
    |> Repo.insert()
  end

  defp generate_acu_file(member, coverage, url)do
    principal_id = if is_nil(member.principal) do
      ""
    else
      member.principal.id
    end

    diagnosis_code = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_diagnosis, fn(ad) ->
        ad.diagnosis.code
      end)
    end)

    diagnosis_description = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_diagnosis, fn(ad) ->
        ad.diagnosis.description
      end)
    end)

    facility_code = Enum.map(member.authorizations, fn(auth) ->
      auth.facility.code
    end)

    approved_datetime = Enum.map(member.authorizations, fn(auth) ->
      auth.approved_datetime
    end)
    approved_datetime = nil_date_checker(approved_datetime)


    admission_datetime = Enum.map(member.authorizations, fn(auth) ->
      auth.admission_datetime
    end)

    admission_datetime = nil_date_checker(admission_datetime)

    discharge_datetime = Enum.map(member.authorizations, fn(auth) ->
      auth.discharge_datetime
    end)
    discharge_datetime = nil_date_checker(flatten_data(discharge_datetime))

    created_date = Enum.map(member.authorizations, fn(auth) ->
      auth.inserted_at
    end)

    created_date = nil_date_checker(created_date)

    user_id = Enum.map(member.authorizations, fn(auth) ->
      auth.approved_by_id
    end)

    if user_id == [] do
      user = ""
    else
      user = UserContext.get_user!(flatten_data(user_id))
    end

    total_amount = Enum.map(member.authorizations, fn(auth) ->
      auth.authorization_amounts.total_amount
    end)

    payor_pays = Enum.map(member.authorizations, fn(auth) ->
      auth.authorization_amounts.payor_covered
    end)

    member_pays = Enum.map(member.authorizations, fn(auth) ->
      auth.authorization_amounts.member_covered
    end)

    status = Enum.map(member.authorizations, fn(auth) ->
      auth.status
    end)

    product_code = Enum.map(member.products, fn(member_product) ->
      member_product.account_product.product.code
    end)

    acu_type = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.benefit.acu_type
      end)
    end)

    availment_type = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.benefit.acu_coverage
      end)
    end)

    package_name = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.package.name
      end)
    end)

    package_code = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.package.code
      end)
    end)

    loa_number = Enum.map(member.authorizations, fn(auth) ->
      auth.number
    end)

    loe_number = Enum.map(member.authorizations, fn(auth) ->
      auth.loe_number
    end)

    assessed_amount = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.assessed_amount
      end)
    end)

    availment_date = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.availment_date
      end)
    end)

    availment_date = nil_date_checker(availment_date)

    soa_amount = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.soa_amount
      end)
    end)

    soa_ref_no = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.soa_ref_no
      end)
    end)

    no_of_claims = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.estimate_no_of_claims
      end)
    end)

    date_received = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.date_received
      end)
    end)
    date_received = nil_date_checker(date_received)

    date_due = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.date_due
      end)
    end)
    date_due = nil_date_checker(date_due)

    funding_arrangement = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.funding_arrangement
      end)
    end)

    batch_no = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.batch_authorizations, fn (ba) ->
        ba.batch.batch_no
      end)
    end)

    acu_benefit_id = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.benefit.id
      end)
    end)

    acu_benefit_code = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        abp.benefit_package.benefit.code
      end)
    end)

    acu_benefit_description = Enum.map(member.authorizations, fn(auth) ->
      Enum.map(auth.authorization_benefit_packages, fn(abp) ->
        "#{abp.benefit_package.benefit.code} - #{abp.benefit_package.benefit.name} "
      end)
    end)

    loa_type = Enum.map(member.authorizations, fn(auth) ->
      auth.availment_type
    end)

    transaction_no = Enum.map(member.authorizations, fn(auth) ->
      auth.transaction_no
    end)

    batch_number = flatten_data(batch_no)
    claim_number = flatten_data(transaction_no)
    loe = flatten_data(loe_number)
    loa = flatten_data(loa_number)
    principal_id = member.id
    member_id = member.id
    principal_policy_no = member.policy_no
    member_policy_no = member.policy_no
    corporate_code = member.account_group.code
    plan_id = product_code
    age = get_age(member.birthdate)
    effective_date = to_string(member.effectivity_date)
    expiry_date = to_string(member.expiry_date)
    funding_arrangement = flatten_data(funding_arrangement)
    claim_type = flatten_data(acu_type)
    source = "P"
    class = ""
    coverage = coverage.code
    availment_type = flatten_data(availment_type)
    diagnosis_code = flatten_data(diagnosis_code)
    diagnosis_desc = flatten_data(diagnosis_description)
    provider_code = flatten_data(facility_code)
    doctor_code = ""
    claim_remarks = ""
    loa_remarks = ""
    soa = flatten_data(soa_ref_no)
    soa_received_date = date_received
    soa_amount = flatten_data(soa_amount)
    service_date = availment_date
    admission_date = admission_datetime
    discharge_date = discharge_datetime
    approve_date = approved_datetime
    if is_nil(user) or user == "" do
      approve_by = ""
    else
      approve_by = "#{user.first_name} #{user.middle_name} #{user.last_name}"
    end

    claim_status = get_claim_status(flatten_data(status))
    assessed_amount = flatten_data(assessed_amount)
    billed_amount = flatten_data(total_amount)
    approved_amount = flatten_data(payor_pays)
    total_deduction = "0"
    total_vat = "0"
    total_pf = "0"
    total_hb = "0"
    total_pfexcess = "0"
    total_hbexcess = "0"
    provider_excess = "0"
    member_excess = flatten_data(member_pays)
    special_approval_amount = "0"
    hb_special_approval_amount = "0"
    pf_special_approval_amount = "0"
    corporate_guarantee = ""
    aso_override = ""
    fee_for_service = "0"
    ex_gratia = ""
    advance_limit = "0"
    aso_rider = ""
    total_copay = "0"
    total_pf_copay = "0"
    total_hb_copay = "0"
    rider_code = ""
    maternity_flag = "N"
    dental_flag = "N"
    acu_flag = "Y"
    opmed_flag = "N"
    peme = "N"
    is_reimbursement = "N"
    mrc = "N"
    upgrade_room_reason = ""
    emergency_tag = ""
    create_date = created_date
    loa_creation_date = created_date
    loa_approval_date = approved_datetime
    estimate_due = date_due
    loa_type = flatten_data(loa_type)
    op_type = ""
    is_xp = "N"
    rtp_type = ""
    rtp_reason = ""
    rtp_scan_doclink = ""
    rtp_claimlink = ""
    rtp_amount = "0"
    rfr_no = ""
    rrf_amount = "0"
    rfr_status = ""
    rrf_reason = ""
    billing_doc_number = "N"
    ap_posted = ""
    gp_status = ""
    applied_to_payment = ""
    applied_to_cm = ""
    voided = "N"

    item_number = "1"
    coverage_item = ""
    cpt = flatten_data(package_code)
    cpt_description = flatten_data(package_name)
    benefit_id = flatten_data(acu_benefit_code)
    benefit_description = flatten_data(acu_benefit_description)
    doctor = ""
    phic = ""
    coverage_amount = flatten_data(payor_pays)
    excess_covered_hosp = "0"
    excess_covered_member = flatten_data(member_pays)
    payable_amt = flatten_data(total_amount)
    co_pay = "0"
    no_of_days = "0"
    ruv = ""
    ruv_code = ""
    ruv_multiplier = "0"
    room_type = ""
    vatable = ""
    is_individual = ""
    claim_no_op = "0"
    ex_gratia_items = "0"
    advance_limit = "0"
    real_member_excess = "0"
    ap_document_number = ""
    payment_document_number = ""
    rfr_no = "0"
    rfr_amount = "0"
    is_xp = ""
    loe_count = "1"
    claim_count = "1"

    header_body = Enum.join(["#{batch_number}|#{claim_number}|#{loe}|#{loa}|#{principal_id}|#{member_id}|#{principal_policy_no}|#{member_policy_no}|",
                             "#{corporate_code}|#{plan_id}|#{age}|#{effective_date}|#{expiry_date}|#{funding_arrangement}|#{claim_type}|#{source}|#{class}|",
                             "#{coverage}|#{availment_type}|#{diagnosis_code}|#{diagnosis_desc}|#{provider_code}|#{doctor_code}|#{claim_remarks}|#{loa_remarks}|",
                             "#{soa}|#{soa_received_date}|#{soa_amount}|#{service_date}|#{admission_date}|#{discharge_date}|#{approve_date}|#{approve_by}|#{claim_status}|",
                             "#{assessed_amount}|#{billed_amount}|#{approved_amount}|#{total_deduction}|#{total_vat}|#{total_pf}|#{total_hb}|#{total_pfexcess}|#{total_hbexcess}|",
                             "#{provider_excess}|#{member_excess}|#{special_approval_amount}|#{hb_special_approval_amount}|#{pf_special_approval_amount}|#{corporate_guarantee}|",
                             "#{aso_override}|#{fee_for_service}|#{ex_gratia}|#{advance_limit}|#{aso_rider}|#{total_copay}|#{total_pf_copay}|#{total_hb_copay}|#{rider_code}|",
                             "#{maternity_flag}|#{dental_flag}|#{acu_flag}|#{opmed_flag}|#{peme}|#{is_reimbursement}|#{mrc}|#{upgrade_room_reason}|#{emergency_tag}|#{create_date}|",
                             "#{loa_creation_date}|#{loa_approval_date}|#{estimate_due}|#{loa_type}|#{op_type}|#{is_xp}|#{rtp_type}|#{rtp_reason}|#{rtp_scan_doclink}|#{rtp_claimlink}|",
                             "#{rtp_amount}|#{rfr_no}|#{rrf_amount}|#{rfr_status}|#{rrf_reason}|#{billing_doc_number}|#{ap_posted}|#{gp_status}|#{applied_to_payment}|#{applied_to_cm}|",
                             "#{voided}\n"])

    item_body = Enum.join(["#{batch_number}|#{claim_number}|#{item_number}|#{diagnosis_code}|#{coverage_item}|#{cpt}|#{cpt_description}|#{benefit_id}|",
                           "#{benefit_description}|#{doctor}|#{billed_amount}|#{phic}|#{coverage_amount}|#{excess_covered_hosp}|#{excess_covered_member}|#{payable_amt}|#{co_pay}|",
                           "#{no_of_days}|#{ruv}|#{ruv_code}|#{ruv_multiplier}|#{room_type}|#{vatable}|#{is_individual}|#{claim_no_op}|",
                           "#{corporate_guarantee}|#{aso_override}|#{fee_for_service}|#{ex_gratia_items}|#{advance_limit}|#{real_member_excess}|",
                           "#{ap_document_number}|#{payment_document_number}|#{claim_status}|",
                           "#{rfr_no}|#{rfr_amount}|#{is_xp}\n"])

    count_body = Enum.join(["#{batch_number}|#{soa}|#{soa_received_date}|#{provider_code}|#{loe_count}|#{claim_count}\n"])

    %{
      header_body: header_body,
      item_body: item_body,
      count_body: count_body
    }
  end

  defp get_d_hms() do
    date_today = to_string(Ecto.DateTime.from_erl(:erlang.localtime))
    splitted_date = String.split(date_today, " ")
    day = Enum.at(splitted_date, 0)
    time = Enum.at(splitted_date, 1)

    splitted_day = String.split(day, "-")
    year = Enum.at(splitted_day, 0)
    month = Enum.at(splitted_day, 1)
    day = Enum.at(splitted_day, 2)

    splitted_time = String.split(time, ":")
    hour = Enum.at(splitted_time, 0)
    minute = Enum.at(splitted_time, 1)
    second = Enum.at(splitted_time, 2)

    %{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second
    }
  end

  defp get_claim_status(status) do
    if status == "Approved" or status == "Availed" do
      "90"
    else
      "50"
    end
  end

  defp flatten_data(data) do
    data =
      data
      |> List.flatten()
      |> List.first()
  end

  defp nil_date_checker(date) do
    if is_nil(date) or date == [] or date == "" or date == [nil] or date == [[]]
    or date == [[nil]] do
      ""
    else
      to_string(Ecto.Date.cast!(flatten_data(date)))
    end
  end

  def utilized_preload_member_active(member, coverage_id) do
    member
    |> Repo.preload([
      :principal,
      :created_by,
      :updated_by,
      :member_logs,
      :kyc_bank,
      [
        dependents: :skipped_dependents
      ],
      [
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]}
      ],
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                benefit: [
                  :benefit_diagnoses,
                  benefit_coverages: :coverage,
                  benefit_packages: [
                    package: [
                      package_payor_procedure: [
                        :payor_procedure
                      ]
                    ]
                  ]
                ]
              ],
              product_exclusions: [
                exclusion: :exclusion_diseases
              ],
              product_coverages: [
                :coverage,
                [product_coverage_risk_share:
                 :product_coverage_risk_share_facilities]
              ]
            ]
          ]
        ]}
      ],
      [
        prinicipal_member_product: [
          account_product: :product
        ]
      ],
      [
        account_group: [
          :members,
          :payment_account,
          account: [
            account_products: [
              product: [
                product_benefits: [
                  benefit: [
                    benefit_coverages: :coverage,
                    benefit_packages: [
                      package: [
                        package_payor_procedure: [
                          :payor_procedure
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ],
      [
        authorizations: {from(a in Authorization, where: a.status == "Availed" and a.is_claimed? != true and a.coverage_id == ^coverage_id and not is_nil(a.approved_by_id)), [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :authorization_amounts,
          #:authorization_diagnosis,
          batch_authorizations: [:batch],
          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
        }
      ]
    ])
  end

  def account_member_csv_download(params) do
    params["search_value"]
    # AccountGroup
    # |> join(:left, [ag], m in Member, m.account_code == ag.code)
    # |> where([ag], ag.code == ^account_group_code)
    # |> where([ag, m], ilike(ag.code, ^"%#{params}%") or ilike(m.type, ^"%#{params}%") or ilike(m.status, ^"%#{params}%"))
    # |> order_by([ag, m], ag.code)
    # |> select([ag, m], [
    #   %{
    #     account_type: ag.type,
    #     account_code: ag.code,
    #     account_name: ag.name,
    #     member_type: m.type,
    #     member_first_name: m.first_name,
    #     member_middle_name: m.middle_name,
    #     member_last_name: m.middle_name,
    #     member_card_no: m.card_no,
    #     member_status: m.status,
    #   }
    # ])
    # |> Repo.all()

    query = (
      from ag in AccountGroup,
      join: m in Member, on: ag.code == m.account_code,
      # where: ag.code == ^account_group_code,

      # to be follow
      where:
      ilike(m.type, ^("%#{params}%")) or
      ilike(fragment("CONCAT(?, ' ',?, ' ', ?)", m.first_name, m.middle_name, m.last_name), ^("%#{params}%")) or
      ilike(m.status, ^("%#{params}%")) or
      ilike(ag.name, ^("%#{params}%")) or
      ilike(ag.type, ^("%#{params}%")) or
      ilike(m.card_no, ^("%#{params}%")),
      order_by: ag.code,
      select: [

        ag.type,
        ag.code,
        ag.name,
        m.first_name,
        m.middle_name,
        m.last_name,
        m.type,
        fragment("concat('''', ?)", m.card_no),
        m.status

      ]
    )

    query = Repo.all(query)
  end

  def account_group_member_search(params) do
    account_code = params["account_code"]
    member_type = params["member_type"]
    member_status = params["member_status"]

    query = (
      from ag in AccountGroup,
      join: m in Member, on: ag.code == m.account_code,

      where:
      ilike(ag.code, ^("%#{account_code}%")) and
      ilike(m.type, ^("%#{member_type}%")) and
      ilike(m.status, ^("%#{member_status}%")),

      order_by: ag.code,
      select: [
        %{
          account_type: ag.type,
          account_code: ag.code,
          account_name: ag.name,
          member_type: m.type,
          member_first_name: m.first_name,
          member_middle_name: m.middle_name,
          member_last_name: m.last_name,
          member_card_no: m.card_no,
          # # member_card_no: fragment("Concat('''', ?)", m.card_no),
          member_status: m.status
        }
      ]
    )

    {:ok, Repo.all(query) |> List.flatten}
  end

  def get_member_any_status(id) do
    Member
    |> Repo.get!(id)
    |> Repo.preload([
      [account_group: :account],
      :acu_schedule_members,
      :principal,
      :created_by,
      :updated_by,
      dependents: :skipped_dependents,
      products: {from(mp in MemberProduct, order_by: mp.tier), [
        :member,
        account_product: [
          product: [
            [
              product_exclusions: [
                exclusion: [
                  :exclusion_durations,
                  exclusion_procedures: :procedure,
                  exclusion_diseases: :disease
                ]
              ]
            ],
            [
              product_benefits: [
                [product: [product_coverages: :coverage]],
                :product_benefit_limits,
                benefit: [
                  benefit_ruvs: :ruv,
                  benefit_diagnoses: :diagnosis,
                  benefit_coverages: :coverage,
                  benefit_packages: [package: [package_payor_procedure: [payor_procedure: :procedure], package_facility: :facility]],
                  benefit_procedures: :procedure
                ]
              ]
            ],
            product_coverages: [
              :product_coverage_facilities,
              :coverage,
              [
                product_coverage_risk_share: [
                  product_coverage_risk_share_facilities: [
                    product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
                  ]
                ]
              ]
            ]
          ]
        ]
      ]},
      account_group: [
        :payment_account,
        account: [
          account_products: [
            product: :product_benefits
          ]
        ]
      ],
      member_contacts: [contact: [:phones, :emails]],
    ])
  end

  def account_group_member_search_csv_download(params) do
    account_code = params["account_code"]
    member_type = params["member_type"]
    member_status = params["member_status"]
    search_value = params["search_value"]

    query = (
      from ag in AccountGroup,
      join: m in Member, on: ag.code == m.account_code,

      where:
      ilike(ag.code, ^("%#{account_code}%")) and
      ilike(m.type, ^("%#{member_type}%")) and
      ilike(m.status, ^("%#{member_status}%")) and
      (
        ilike(m.type, ^("%#{search_value}%")) or
        # ilike(m.card_no, ^("%#{search_value}%")) or
        ilike(fragment("Concat('''',?)", m.card_no),^("%#{search_value}%")) or
        ilike(m.first_name, ^("%#{search_value}%")) or
        ilike(m.middle_name, ^("%#{search_value}%")) or
        ilike(m.last_name, ^("%#{search_value}%"))

      ),
      order_by: ag.code,
      select: [
        ag.type,
        ag.name,
        m.first_name,
        m.middle_name,
        m.last_name,
        m.type,
        fragment("CONCAT('''', ?)", m.card_no),
        m.status
      ]
    )
    Repo.all(query)
  end

  def latest_authorization_facility(member) do
    Authorization
    |> join(:inner, [a], f in Facility, f.id == a.facility_id)
    |> join(:inner, [a, f], d in Dropdown, d.id == f.ftype_id)
    |> where([a, f, d], a.member_id == ^member.id)
    |> where([a, f, d], a.status != "Pending")
    |> where([a, f, d], a.status != "Draft")
    |> where([a, f, d], d.value != "MOBILE")
    |> order_by([a, f, d], desc: a.inserted_at)
    |> select([a, f, d], %{name: f.name})
    |> Repo.all()
  end

  def random_facility(member, name) do
    Facility
    |> join(:inner, [f], d in Dropdown, d.id == f.ftype_id)
    |> where([f, d], f.name != ^name)
    |> where([f, d], d.value != "MOBILE")
    |> select([f, d], %{name: f.name})
    |> limit(100)
    |> Repo.all()
  end

  def latest_op_consult(member) do
    Authorization
    |> where([a], a.member_id == ^member.id and not is_nil(a.consultation_type))
    |> Repo.all()
  end

  def valid_evoucher?(evoucher_number, account_name) do
    peme =
      Peme
      |> join(:inner, [p], ag in AccountGroup, ag.id == p.account_group_id)
      |> where([p, ag],
               p.evoucher_number == ^evoucher_number and
               (fragment("lower(?)", ag.name) == fragment("lower(?)", ^account_name))
      )
      |> Repo.one()
    validate_evoucher_status(peme)
  end

  defp validate_evoucher_status(peme) do
    if is_nil(peme) do
      {:error, "E-voucher Number and/or company is invalid"}
    else
      case peme.status do
        "Availed" ->
          {:error, "E-voucher is already expired"}
        "Cancelled" ->
          {:error, "E-voucher is already expired"}
        "Registered" ->
          {:error, "Your information has already been encoded. Click Reprint to view your voucher"}
        "Issued" ->
          {:ok, peme}
        _ ->
          {:ok, peme}
      end
    end
  end

  def get_package_age(peme, "male") do
    with false <- is_nil(peme.package),
         procedure = %PackagePayorProcedure{} <- List.first(peme.package.package_payor_procedure),
         true <- procedure.male
    do
      {procedure.age_from, procedure.age_to}
    else
      _ ->
        {nil, nil}
    end
  end

  def get_package_age(peme, "female") do
    with false <- is_nil(peme.package),
         procedure = %PackagePayorProcedure{} <- List.first(peme.package.package_payor_procedure),
         true <- procedure.female
    do
      {procedure.age_from, procedure.age_to}
    else
      _ ->
        {nil, nil}
    end
  end

  def get_package_gender(peme, "male") do
    with false <- is_nil(peme.package),
         procedure = %PackagePayorProcedure{} <- List.first(peme.package.package_payor_procedure)
    do
      {procedure.male}
    else
      _ ->
        {nil}
    end
  end

  def get_package_gender(peme, "female") do
    with false <- is_nil(peme.package),
         procedure = %PackagePayorProcedure{} <- List.first(peme.package.package_payor_procedure)
    do
      {procedure.female}
    else
      _ ->
        {nil}
    end
  end

  def update_evoucher_member(member, params) do
    member
    |> Member.changeset_update_evoucher(params)
    |> Repo.update()
  end

  def create_evoucher_member(peme, params) do
    account_product =
      AccountGroup
      |> join(:inner, [ag], a in Account, a.account_group_id == ag.id)
      |> join(:inner, [ag, a], ap in AccountProduct, ap.account_id == a.id)
      |> join(:inner, [ag, a, ap], p in Product, p.id == ap.product_id)
      |> where([ag, a, ap, p], a.status == ^"Active")
      |> where([ag, a, ap, p], p.product_category == ^"PEME Plan")
      |> where([ag, a, ap, p], ag.id == ^peme.account_group_id)
      |> order_by([ag, a, ap, p], asc: ap.rank)
      |> select([ag, a, ap, p], %{
        account_product: ap.id,
        code: ag.code,
        start_date: a.start_date,
        end_date: a.end_date
      })
      |> Repo.all()

    account_code =
      account_product
      |> Enum.map(&(&1.code))
      |> List.first()

    effectivity_date =
      account_product
      |> Enum.map(&(&1.start_date))
      |> List.first()

    expiry_date =
      account_product
      |> Enum.map(&(&1.end_date))
      |> List.first()

    params =
      params
      |> Map.put("account_code", account_code)
      |> Map.put("effectivity_date", effectivity_date)
      |> Map.put("expiry_date", expiry_date)
      |> Map.put("temporary_member", true)

    member_changeset =
      %Member{}
      |> Member.changeset_peme_evoucher(params)

    if member_changeset.valid? do
      {:ok, member} =
        member_changeset
        |> Repo.insert()

        peme
        |> Peme.changeset_member(%{
          member_id: member.id
        })
        |> Repo.update()

        for ap <- account_product do
          %MemberProduct{}
          |> MemberProduct.changeset(
            %{
              tier: 1,
              member_id: member.id,
              account_product_id: ap.account_product
            }
          )
          |> Repo.insert()
        end

      {:ok, member}
      else
      member_changeset
      |> Repo.insert()
    end
  end

  def insert_evoucher_member(params) do
    %Member{}
    |> Member.changeset_update_evoucher(params)
    |> Repo.insert()
  end

  def preload_member_products(member) do
    member
    |> Repo.preload([
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_coverages: [
                [
                  :product_coverage_facilities
                ]
              ]
            ]
          ]
        ]}
      ]
    ])
  end

  def update_peme_facility(peme, facility_id) do
    peme
    |> Peme.changeset_facility(%{facility_id: facility_id})
    |> Repo.update()
  end

  def update_peme_authorization(peme, authorization_id) do
    peme
    |> Peme.changeset_authorization(%{authorization_id: authorization_id})
    |> Repo.update()
  end

  def update_peme_status(peme, status_param) do
    peme
    |> Peme.status_changeset(status_param)
    |> Repo.update()
  end

  def update_peme_status_pending(peme) do
    peme
    |> Ecto.Changeset.change(status: "Pending", registration_date: nil)
    |> Repo.update()
  end

  # PEME

  def get_peme_package_based_on_member(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    peme_benefits = filter_peme_benefits(member_product)
    product_benefit = Enum.map(peme_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
        get_peme_package_based_on_member2(age, member, benefit_package, product_benefit)
      end)
    end)
  end

  defp filter_peme_benefits(member_product) do
    member_product
    Enum.filter(member_product.account_product.product.product_benefits, fn(product_benefit) ->
      product_benefit.benefit.benefit_coverages
      |> Enum.map(&(&1.coverage.name))
      |> Enum.member?("PEME")
    end)
  end

  def get_peme_package_based_on_member2(age, member, benefit_package, product_benefit) do
    cond do
      benefit_package.male == true && benefit_package.female == false ->
        package_gender = "Male"
      benefit_package.female == true && benefit_package.male == false ->
        package_gender = "Female"
      Enum.all?([benefit_package.male, benefit_package.female]) ->
        package_gender = "Male & Female"
      true ->
        package_gender = "nil"
    end

    if String.contains?(package_gender, member.gender) and
    check_age_from_to(age, benefit_package.age_from..benefit_package.age_to) do
      product_benefit
    end
  end

  def get_peme_package_based_on_member_for_schedule(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    peme_benefits = filter_peme_benefits(member_product)
    benefit_package = Enum.map(peme_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
        get_peme_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit)
      end)
    end)
  end

  def get_peme_package_based_on_member_for_schedule2(member, member_products) do
    age = UtilityContext.age(member.birthdate)
    peme_benefits = filter_peme_benefits2(member_products)

    benefit_package = Enum.map(peme_benefits, fn(product_benefits) ->
      Enum.map(product_benefits, fn(product_benefit) ->
        Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
          get_peme_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit)
        end)
      end)
    end)
  end

  defp filter_peme_benefits2(member_products) do
    member_products
    Enum.map(member_products, fn(member_product) ->
      Enum.filter(member_product.account_product.product.product_benefits, fn(product_benefit) ->
        product_benefit.benefit.benefit_coverages
        |> Enum.map(&(&1.coverage.name))
        |> Enum.member?("PEME")
      end)
    end)
  end

  def get_peme_package_pp_based_on_member(member, member_product) do
    age = UtilityContext.age(member.birthdate)
    peme_benefits = filter_peme_benefits(member_product)
    benefit_package = Enum.map(peme_benefits, fn(product_benefit) ->
      Enum.find(product_benefit.benefit.benefit_packages, fn(benefit_package) ->
        get_peme_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit)
      end)
    end)
    bp = Enum.map(benefit_package, fn(x) ->
      x.package.package_payor_procedure
    end)
    bp =
      bp
      |> List.first()
  end

  def get_peme_package_based_on_member2_for_schedule(age, member, benefit_package, product_benefit) do
    bpp = benefit_package.package.package_payor_procedure

    bpp =
      bpp
      |> List.first()

    cond do
      bpp.male == true && bpp.female == false ->
        package_gender = "Male"
      bpp.female == true && bpp.male == false ->
        package_gender = "Female"
      Enum.all?([bpp.male, bpp.female]) ->
        package_gender = "Male & Female"
      true ->
        package_gender = "nil"
    end

    check_age(age, package_gender, member.gender, bpp)
  end

  defp check_age(_age, _package_gender, nil, _bpp), do: nil
  defp check_age(age, package_gender, gender, bpp) do
    if String.contains?(package_gender, gender) and
       check_age_from_to(age, bpp.age_from..bpp.age_to)
    do
      bpp
    end
  end

  def get_all_mobile(account_code, member_id) do
    Member
    |> where([m], m.account_code == ^account_code and not is_nil(m.mobile) and m.id != ^member_id)
    |> select([m], m.mobile)
    |> distinct(true)
    |> Repo.all()
  end

  def get_peme_facility(id) do
    peme =
      Peme
      |> join(:inner, [p], ag in AccountGroup, p.account_group_id == ag.id)
      |> where([p, ag], p.id == ^id)
      |> select([p, ag], %{facility_id: p.facility_id,
        account_group_id: p.account_group_id,
        account_code: ag.code})
        |> Repo.one()

    peme_facility = if not is_nil(peme), do: peme.facility_id, else: nil
    peme_account_group = if not is_nil(peme.account_group_id), do: peme.account_group_id, else: nil

    peme_f_ag = %{peme_fac: peme_facility, peme_ag: peme_account_group, account_code: peme.account_code}
  end

  def valid_evoucher_reprint?(mobile, account_name) do
    peme =
      Peme
      |> join(:inner, [p], m in Member, m.id == p.member_id)
      |> join(:inner, [p, m], ag in AccountGroup, ag.code == m.account_code)
      |> where([p, m, ag],
               m.mobile == ^mobile and
               ag.name == ^account_name and
               p.status == "Registered"
      )
      |> Repo.all()
      |> List.first()
  end

  # PRODUCT BENEFIT PEME

  def get_peme_product_benefit_based_on_member_for_schedule2(member, member_products) do
    age = UtilityContext.age(member.birthdate)
    peme_benefits = filter_peme_benefits2(member_products)

    benefit_package = Enum.map(peme_benefits, fn(product_benefits) ->
      Enum.map(product_benefits, fn(product_benefit) ->
        product_benefit
      end)
    end)
  end

  def utilization_show(member) do
    member
    |> Repo.preload([
      :principal,
      :created_by,
      :updated_by,
      :member_logs,
      :kyc_bank,
      [
        dependents: :skipped_dependents
      ],
      [
        member_comments: {from(mc in MemberComment, order_by: [desc: mc.inserted_at]), [:updated_by, :created_by]}
      ],
      [
        products: {from(mp in MemberProduct, order_by: mp.tier), [
          account_product: [
            product: [
              product_benefits: [
                benefit: [
                  :benefit_diagnoses,
                  benefit_coverages: :coverage,
                  benefit_packages: [
                    package: [
                      package_payor_procedure: [
                        :payor_procedure
                      ]
                    ]
                  ]
                ]
              ],
              product_exclusions: [
                exclusion: :exclusion_diseases
              ],
              product_coverages: [
                :coverage,
                [product_coverage_risk_share:
                 :product_coverage_risk_share_facilities]
              ]
            ]
          ]
        ]}
      ],
      [
        prinicipal_member_product: [
          account_product: :product
        ]
      ],
      [
        account_group: [
          :members,
          :payment_account,
          account: [
            account_products: [
              product: [
                product_benefits: [
                  benefit: [
                    benefit_coverages: :coverage,
                    benefit_packages: [
                      package: [
                        package_payor_procedure: [
                          :payor_procedure
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ],
      [
        authorizations: {from(a in Authorization, where: a.status == "Availed" or a.status == "Pending" or a.status == "Approved"), [
          :facility,
          :special_approval,
          :room,
          :created_by,
          :approved_by,
          :authorization_amounts,
          #:authorization_diagnosis,
          batch_authorizations: [:batch],
          authorization_practitioner_specializations: [practitioner_specialization: :practitioner],
          authorization_diagnosis: [:diagnosis, product_benefit: :benefit],
          coverage: [coverage_benefits: :benefit],
          authorization_procedure_diagnoses: [:diagnosis, product_benefit: :benefit],
          authorization_benefit_packages: [benefit_package: [:benefit, :package]]
        ]
        }
      ]
    ])
  end

  def ftp_transfer_file(file_name, local_path) do
    host = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:host)
    port = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:port)
    encrypted_username = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:username)
    encrypted_password = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:password)
    username = UtilityContext.formatter("#{encrypted_username}", "decrypt")
    password = UtilityContext.formatter("#{encrypted_password}", "decrypt")
    host_path = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:host_dir)

    with {:ok, session} <- FTP.start('#{host}', '#{username}', '#{password}', port),
         {:ok, remote_path} <- FTP.set_remote_dir(session, '#{host_path}'),
         {:ok, local_path} <- FTP.set_local_dir(session, '#{local_path}'),
         :ok <- FTP.transfer_file(session, '#{file_name}'),
         :ok <- FTP.stop(session)
    do
      {:ok}
    else
      {:error, message} ->
        {:error, message}
      _ ->
        {:error, "Error"}
    end
  end

  def load_member(id) do
    member =
      Member
      |> join(:left, [m], ag in AccountGroup, m.account_code == ag.code)
      |> where([m], m.id == ^id)
      |> select([m, ag], %{
        id: m.id,
        #contact info
        first_name: m.first_name,
        middle_name: m.middle_name,
        last_name: m.last_name,
        suffix: m.suffix,
        birthdate: m.birthdate,
        gender: m.gender,
        civil_status: m.civil_status,
        email: m.email,
        email2: m.email2,
        mobile: m.mobile,
        mobile2: m.mobile2,
        telephone: m.telephone,
        postal: m.postal,
        unit_no: m.unit_no,
        building_name: m.building_name,
        street_name: m.street_name,
        city: m.city,
        province: m.province,
        region: m.region,
        photo: m.photo,
        status: m.status,
        cancel_date: m.cancel_date,
        suspend_date: m.suspend_date,
        reactivate_date: m.reactivate_date,

        #account info
        employee_no: m.employee_no,
        philhealth: m.philhealth,
        date_hired: m.date_hired,
        is_regular: m.is_regular,
        regularization_date: m.regularization_date,
        tin: m.tin,
        account_code: m.account_code,
        type: m.type,
        senior: m.senior,
        pwd: m.pwd,
        card_no: m.card_no,
        senior_id: m.senior_id,
        senior_photo: m.senior_photo,
        pwd_id: m.pwd_id,
        pwd_photo: m.pwd_photo,
        account_name: ag.name,
        principal_id: m.principal_id
      })
      |> Repo.one

    if is_nil(member) do
      nil
    else
      member =
        member
        |> load_member_products()
        |> load_relationship_information(member.type)

    end
  end

  defp load_relationship_information(member, type) when type == "Principal" do
    dependent =
      Member
      |> where([m], m.principal_id == ^member.id)
      |> select([m], %{
        id: m.id,
        first_name: m.first_name,
        middle_name: m.middle_name,
        last_name: m.last_name,
        card_no: m.card_no
      })
      |> Repo.all()

    member
    |> Map.put(:relationship_information, dependent)
  end

  defp load_relationship_information(member, type) when type == "Guardian" do
    dependent =
      Member
      |> where([m], m.principal_id == ^member.id)
      |> select([m], %{
        id: m.id,
        first_name: m.first_name,
        middle_name: m.middle_name,
        last_name: m.last_name,
        card_no: m.card_no
      })
      |> Repo.all()

    member
    |> Map.put(:relationship_information, dependent)
  end

  defp load_relationship_information(member, type) when type == "Dependent" do
    if is_nil(member.principal_id) do
      nil
    else

    principal =
      Member
      |> where([m], m.id == ^member.principal_id)
      |> select([m], %{
        id: m.id,
        first_name: m.first_name,
        middle_name: m.middle_name,
        last_name: m.last_name,
        card_no: m.card_no
      })
      |> Repo.all()

    member
    |> Map.put(:relationship_information, principal)
    end
  end

  defp load_relationship_information(member, type) when is_nil(type) do
    {:invalid, "Error loading data"}
  end

  defp load_member_products(member) do

    member_product =
      MemberProduct
      |> join(:left, [mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:left, [mp, ap], p in Product, ap.product_id == p.id)
      |> where([mp, ap, p], mp.member_id == ^member.id)
      |> select([mp, ap, p], %{
        tier: mp.tier,
        code: p.code,
        name: p.name,
        product_id: p.id,
        limit_type: p.limit_type,
        limit_amount: p.limit_amount
      })
      |> Repo.all()
      |> load_benefit_count([])

    member
    |> Map.put(:member_products, member_product)
  end

  defp load_benefit_count([head | tails], result) do
    benefit_count =
      ProductBenefit
      |> where([pb], pb.product_id == ^head.product_id)
      |> select([pb], count(pb.id))
      |> Repo.one()

    head =
      head
      |> Map.put(:benefit_count, benefit_count)

    result = result ++ [head]

    load_benefit_count(tails, result)
  end

  defp load_benefit_count([], result), do: result
  defp is_finished?(struct), do:
  is_equal?(struct.count, struct.member_upload_logs |> Enum.count())

  defp is_equal?(x, y), do: if x == y, do: true, else: false
  def check_upload_status(member_upload_file_id) do
    muf =
      MemberUploadFile
      |> Repo.get(member_upload_file_id)
      |> Repo.preload([:member_upload_logs])

    is_valid =
      muf
      |> is_finished?()

    mul_count =
      muf.id
      |> get_mul_count()

    %{
      valid: is_valid,
      mul_count: mul_count
    }
  end

  defp to_valid_date(date) do
    UtilityContext.transform_string_dates(date)
  end

  defp get_mul_count(id) do
    result =
      MemberUploadLog
      |> where([mul], mul.member_upload_file_id == ^id)
      |> select([mul], mul.status)
      |> Repo.all()

    %{
      "success" => Enum.count(result, &(&1 == "success")),
      "failed" => Enum.count(result, &(&1 == "failed")),
      "total" => Enum.count(result)
    }
  end

  def get_peme_by_evoucher(evoucher) do
    Peme
    |> Repo.get_by(evoucher_number: evoucher)
    |> Repo.preload([:created_by])
  end

  def delete_peme_member(peme) do
    peme
    |> Ecto.Changeset.change(member_id: nil)
    |> Repo.update()
  end

  def get_account_code_by_member_id(member_id) do
    Member
    |> where([m], m.id == ^member_id)
    |> select([:account_code])
    |> Repo.one()
  end

  def update_primary_id(%Member{} = member, attrs) do
    member
    |> Member.changeset_primary_id(attrs)
    |> Repo.update()
  end

  def update_secondary_id(%Member{} = member, attrs) do
    member
    |> Member.changeset_secondary_id(attrs)
    |> Repo.update()
  end

  def update_peme_status_to_stale_or_cancel do
    job_name = "Innerpeace.Db.Base.MemberContext, :update_peme_status_to_stale_or_cancel"
    # params = create_json_params_for_stale(get_peme_loa_for_stale)
    # count = count_loas_for_stale(params.loa_ids)

    # with false <- Enum.empty?(get_peme_loa_for_stale),
    #      {:ok, response} <- update_provider_link_loa_stale(params),
    #      {:ok, response} <- check_update_provider_link_response(response)
    # do
    #       update_loa_status_stale(params.loa_ids)
    #       insert_scheduler_logs(job_name, "Successfully Updated Loa Statuses To Stale", count)
    # else
    #   true ->
    #     insert_scheduler_logs(job_name, "No authorizations found to stale.", 0)
    #   {:error} ->
    #     insert_scheduler_logs(job_name, "Error in Sign-in: ProviderLink", count)

    #   {:error, peme_loas} ->
    #     insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)

    #   {:unable_to_login, response} ->
    #     insert_scheduler_logs(job_name, response, count)

    #   {:error_update, response} ->
    #     insert_scheduler_logs(job_name, "Error Updating Loa Status in ProviderLink", count)

    #   _ ->
    #     insert_scheduler_logs(job_name, "Update Stale To Loa Statuses Failed", count)

    # end

    with false <- Enum.empty?(get_peme_for_cancel) do
      pemes = get_peme_for_cancel
      count = Enum.count(pemes)
      Enum.map(pemes, fn(p) ->
        update_peme_status(p, %{status: "Stale"})
      end)

      insert_scheduler_logs(job_name, "Successfully Updated PEME Statuses To Stale", count)
    else
      true ->
        insert_scheduler_logs(job_name, "No PEMEs found to cancel.", 0)
    end
  end

  # def create_json_params_for_stale(peme_loa_stale) when not is_nil(peme_loa_stale) do
  #   peme_loa_ids = get_loa_ids_stale(peme_loa_stale)
  #   params = %{loa_ids: peme_loa_ids}
  # end

  # defp get_loa_ids_stale(map) do
  #   map
  #   |> Enum.map(fn(map) ->
  #     asc_id = map.authorization_id
  #   end)
  # end

  # def get_peme_loa_for_stale do
  #   Authorization
  #   |> join(:inner, [a], f in Facility, a.facility_id == f.id)
  #   |> join(:inner, [a, f], c in Coverage, a.coverage_id == c.id)
  #   |> join(:inner, [a, f, c], m in Member, a.member_id == m.id)
  #   |> where([a, f, c, m], (a.status == "Approved"
  #             or a.status == "Draft"
  #             or a.status == "Pending") and (c.name == "PEME")
  #             and (fragment("now()::date - ?::date >= ?", a.inserted_at, f.prescription_term))
  #   )
  #   |> select([a, f, c, m], %{authorization_id: a.id})
  #   |> Repo.all()
  # end

  def get_peme_for_cancel do
    Peme
    |> where([p], (fragment("((now() + interval '8 hour')::date - ?::date) > 0", p.date_to)))
    |> where([p], p.status == "Pending")
    |> Repo.all()
  end

  def count_loas_for_stale(nil), do: 0
  def count_loas_for_stale(loa_ids) when not is_nil(loa_ids), do: Enum.count(loa_ids)

  def count_pemes_for_stale(nil), do: 0
  def count_pemes_for_stale(peme_ids) when not is_nil(peme_ids), do: Enum.count(peme_ids)

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

  def check_update_provider_link_response(response) do
    resp = Poison.decode!(response.body)
    if resp["message"] == "Loas Successfully Updated Status as Stale" do
      {:ok, response}
    else
      {:error_update, response}
    end
  end

  defp update_loa_status_stale(loa_ids) do
    Authorization
    |> where([a], a.id in ^loa_ids)
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

  def get_peme_member_by_mobile(account_code) do
    m =
      Member
      |> where([m], m.account_code == ^account_code and not is_nil(m.mobile))
      |> select([m], m.mobile)
      |> Repo.all()
      |> Enum.uniq()
  end

  def update_peme_member_primary_id(member, member_params) do
    member
    |> Member.changeset_primary_id(member_params)
    |> Repo.update()
  end

  def update_peme_member_secondary_id(member, member_params) do
    member
    |> Member.changeset_secondary_id(member_params)
    |> Repo.update()
  end

  defp check_member_details(_, nil), do: []
  defp check_member_details(member, member_details) do
    member =
      member
      |> Map.put_new(:details, member_details)
  end

  defp send_error_to_sentry(user_id, err_msg) do
    user = UserContext.get_user!(user_id)

    err_msg
    |> Sentry.capture_exception([
      stacktrace: System.stacktrace(),
      tags: %{
        "app_version" => "#{Application.spec(:payor_link, :vsn)}",
        "user_id" => user.id,
        "username" => user.username
      }
    ])
  end

  def convert_base_64_image(params) do
    with {:ok, photo_params} <- FileUpload.convert_base64_img(params) do
      photo_params["photo"]
    else
      _ ->
        {:error}
    end
  end

  def delete_local_image(params) do
    with {:ok, _} <- FileUpload.delete_local_img(params["filename"], params["extension"]) do
      {:ok}
    else
      _ ->
        {:error}
    end
  end

  def update_member_products_by_package_id(nil, _, _), do: []
  def update_member_products_by_package_id(_, nil, _), do: []
  def update_member_products_by_package_id(member_id, package_id, consume) do
    MemberProduct
    |> join(:inner, [mp], ap in AccountProduct, ap.id == mp.account_product_id)
    |> join(:inner, [mp, ap], p in Product, p.id == ap.product_id)
    |> join(:inner, [mp, ap, p], pb in ProductBenefit, pb.product_id == p.id)
    |> join(:inner, [mp, ap, p, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:inner, [mp, ap, p, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:inner, [mp, ap, p, pb, b, bp], pa in Package, pa.id == bp.package_id)
    |> where([mp, ap, p, pb, b, bp, pa], pa.id == ^package_id)
    |> where([mp, ap, p, pb, b, bp, pa], mp.member_id == ^member_id)
    |> Repo.update_all(set: [is_acu_consumed: consume])
  end

  def update_member_products_status({
        benefit,
        benefit_package,
        package,
        product,
        product_benefit,
        member_product,
        package_rate
      })
  do
    MemberProduct
    |> join(:inner, [mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [mp, ap], p in Product, ap.product_id == p.id)
    |> join(:inner, [mp, ap, p], pb in ProductBenefit, p.id == pb.product_id)
    |> join(:inner, [mp, ap, p, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
    |> join(:inner, [mp, ap, p, pb, bp], pk in Package, bp.package_id == pk.id)
    |> where([mp, ap, p, pb, bp, pk], mp.member_id == ^member_product.member_id and pk.id == ^package.id)
    |> Repo.update_all(set: [is_acu_consumed: true])
  end

end

defmodule Innerpeace.Db.Base.AcuScheduleContext do
  @moduledoc """
  """
  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Ecto.Changeset

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook

  alias Innerpeace.Db.{
    Repo,
    Schemas.AcuSchedule,
    Schemas.AcuScheduleMember,
    Schemas.AcuSchedulePackage,
    Schemas.AcuScheduleProduct,
    Schemas.User,
    Schemas.AcuScheduleLog,
    Schemas.JobAcuSchedule,
    Schemas.TaskAcuSchedule,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.AccountProduct,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.Coverage,
    Schemas.Member,
    Schemas.MemberProduct,
    Schemas.AcuScheduleProduct,
    Schemas.Facility,
    Schemas.Dropdown,
    Schemas.AccountProductBenefit,
    Schemas.ProductBenefit,
    Schemas.Benefit,
    Schemas.BenefitPackage,
    Schemas.Package,
    Schemas.PackageFacility,
    Schemas.AcuScheduleMember,
    Schemas.Authorization,
    Schemas.AuthorizationBenefitPackage,
    Schemas.BenefitCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.BenefitProcedure,
    Schemas.Cluster,
    Base.Api.UtilityContext,
    Base.AccountContext,
    Base.ProductContext,
    Base.ApiAddressContext,
    Base.AuthorizationContext,
    Base.MemberContext,
    Base.CoverageContext,
    Base.FacilityContext,
    Base.BenefitContext,
    Base.UserContext
  }

  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationAPI
  alias Innerpeace.Db.Base.Api.FacilityContext, as: FacilityContextAPI
  alias Innerpeace.Db.Validators.ACUValidator
  alias Innerpeace.Db.Validators.ACUScheduleValidator
  alias Innerpeace.PayorLink.Web.Main.AcuScheduleView
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController, as: AC

  def get_acu_schedule(id) do
    AcuSchedule
    |> Repo.get(id)
    |> Repo.preload([
      :account_group,
      :cluster,
      :created_by,
      :updated_by,
      :facility,
      [acu_schedule_products: [
        product: [
          product_benefits: [
            benefit: [benefit_packages:
                      [package:
                       [package_payor_procedure: :payor_procedure
                       ]
                      ]
            ]
          ]
        ]
      ],
       acu_schedule_members: [
         member: :account_group
       ],
       acu_schedule_packages: [
         :package,
         [acu_schedule_product: :product]
       ]
      ]
    ])
  end

  def get_acu_schedule_no_preload(id) do
    AcuSchedule
    |> Repo.get(id)
  end

  def get_acu_schedule_v2(id) do
    AcuSchedule
    |> Repo.get(id)
    |> Repo.preload([
      :account_group,
      :cluster,
      :created_by,
      :updated_by,
      :facility,
      [acu_schedule_products: [
        product: [
          product_benefits: [
            benefit: [benefit_packages:
                      [package:
                       [package_payor_procedure: :payor_procedure
                       ]
                      ]
            ]
          ]
        ]
      ],
       acu_schedule_members: [
         member: :account_group
       ],
       acu_schedule_packages: {
        from(asp in AcuSchedulePackage,
            distinct: asp.package_id),
        [
         :package,
         [acu_schedule_product: :product]
       ]}
      ]
    ])
  end

  def get_all_acu_schedules do
    AcuSchedule
    |> order_by([as], desc: as.inserted_at)
    |> Repo.all()
    |> Repo.preload([
      :facility,
      :account_group,
      :created_by,
      [acu_schedule_products: :product]
    ])
  end

  def get_all_acu_schedule_members(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> Repo.all()
    |> Repo.preload([:member])
  end

  def get_all_acu_schedule_member_id(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> select([asm], asm.member_id)
    |> Repo.all()
  end

  def get_all_acu_schedule_products(acu_schedule_id) do
    AcuScheduleProduct
    |> where([asp], asp.acu_schedule_id == ^acu_schedule_id)
    |> Repo.all()
  end

  def get_all_acu_schedule_products_edit(acu_schedule_id) do
    AcuScheduleProduct
    |> join(:inner, [asp], p in Product, asp.product_id == p.id)
    |> where([asp, p], asp.acu_schedule_id == ^acu_schedule_id)
    |> select([asp, p], p.code)
    |> Repo.all()
  end

  def get_all_remove_acu_schedule_members(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> Repo.all()
    |> Repo.preload([:member])
  end

  def list_active_accounts_acu do
    Account
    |> join(:inner, [a], ap in AccountProduct, a.id == ap.account_id)
    |> join(:inner, [a, ap], p in Product, p.id == ap.product_id)
    |> join(:inner, [a, ap, p], pc in ProductCoverage, pc.product_id == p.id)
    |> join(:inner, [a, ap, p, pc], c in Coverage, pc.coverage_id == c.id)
    |> where([a, ap, p, pc, c], a.status == "Active" and c.name == "ACU")
    |> distinct(true)
    |> Repo.all()
    |> Repo.preload([:account_group])
  end

  def get_acu_products_by_account_code(account_code) do
    benefit_based_products =
      Product
      |> join(:inner, [p], ap in AccountProduct, ap.product_id == p.id)
      |> join(:inner, [p, ap], apb in AccountProductBenefit, apb.account_product_id == ap.id)
      |> join(:inner, [p, ap, apb], pb in ProductBenefit, pb.id == apb.product_benefit_id)
      |> join(:inner, [p, ap, apb, pb], b in Benefit, b.id == pb.benefit_id)
      |> join(:inner, [p, ap, apb, pb, b], a in Account, a.id == ap.account_id)
      |> join(:inner, [p, ap, apb, pb, b, a], ag in AccountGroup, a.account_group_id == ag.id)
      |> where([p, ap, apb, pb, b, a, ag], ag.code == ^account_code and p.product_base == "Benefit-based")
      |> where([p, ap, apb, pb, b, a, ag],
               ilike(b.provider_access, "%Mobile"))
      |> where([p, ap, apb, pb, b, a, ag], p.loa_facilitated == true)
      |> select([p, ap, apb, pb, b, a, ag], p.code)
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_members_by_account_code_and_product_code(ac, pc) do
    Member
    |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
    |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [m, mp, ap], p in Product, ap.product_id == p.id)
    |> where([m, mp, ap, p], m.account_code == ^ac and p.code == ^pc)
    |> Repo.all()
  end

  def get_all_acu_schedule do
    AcuSchedule
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

 def load_acu(id) do
    AcuSchedule
    |> Repo.get!(id)
    |> Repo.preload([
      :facility,
      :created_by,
      account_group: [
        :account_group_address
      ],
      acu_schedule_members: [
        member: [
          products: [
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
          ]
        ]
      ],
      acu_schedule_products: [
        product: [
          product_benefits: [
            benefit: [
              benefit_packages: [
                package: [
                  package_payor_procedure: :payor_procedure
                ]
              ]
            ]
          ]
        ]
      ]
    ])
  end

  def get_member_by_schedule_id(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id)
    |> where([asm], is_nil(asm.status))
    |> Repo.all()
    |> Repo.preload(member: from(m in Member, order_by: [desc: m.last_name]))
  end

  def get_member_by_schedule_id2(acu_schedule_id) do
    Member
    |> join(:inner, [m], asm in AcuScheduleMember, asm.member_id == m.id)
    |> where([m, asm], asm.acu_schedule_id == ^acu_schedule_id)
    |> where([m, asm], is_nil(asm.status))
    |> order_by([m, asm], asc: m.last_name)
    |> Repo.all()
  end

  defp get_username_by_acu_schedule(acu_schedule_id) do
    User
    |> where([u], u.id == ^acu_schedule_id)
    |> select([u], u.username)
    |> Repo.one
  end

  def get_acu_facilities_inclusion(inclusion_product) do
    inclusion =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf], pr.code in ^inclusion_product and pc.type == "inclusion")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf], f.step > 6 and f.status == "Affiliated" and
                 d.text == "MOBILE")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf], ilike(b.provider_access, "%Mobile"))
      |> where([f, d, pf, p, bp, b, pb, pr], not is_nil(pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_acu_facilities_exclusion(exception_product) do
     Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], pcf in ProductCoverageFacility,
                 pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc, pcf], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], pr.code in ^exception_product and pc.type == "exception")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], f.step > 6 and f.status == "Affiliated"
                 and d.text == "MOBILE"
                 and c.code == "ACU"
                 and pcf.facility_id == pf.facility_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], ilike(b.provider_access, "%Mobile"))
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], fragment("? is distinct from null", pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_acu_facilities(product_code) do
    inclusion_product =
      Product
      |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
      |> join(:inner, [p, pc], c in Coverage, pc.coverage_id == c.id)
      |> where([p, pc, c], p.code in ^product_code and pc.type == "inclusion" and c.code == "ACU")
      |> select([p], p.code)
      |> Repo.all()
      |> Enum.uniq()

    exception_product =
      Product
      |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
      |> join(:inner, [p, pc], c in Coverage, pc.coverage_id == c.id)
      |> where([p, pc, c], p.code in ^product_code and pc.type == "exception" and c.code == "ACU")
      |> select([p], p.code)
      |> Repo.all()
      |> Enum.uniq()

    inclusion_product =
      inclusion_product
      |> Enum.uniq()
      |> List.delete(nil)
    exception_product =
      exception_product
      |> Enum.uniq()
      |> List.delete(nil)

    inclusion = get_acu_facilities_inclusion(inclusion_product)

    exception = get_acu_facilities_exclusion(exception_product)

    package_facilities =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc], pr.code in ^exception_product and pc.type == "exception")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, c], f.step > 6 and f.status == "Affiliated" and
                 d.text == "MOBILE" and c.code == "ACU")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, c], ilike(b.provider_access, "%Mobile"))
      |> where([f, d, pf, p, bp, b, pb, pr], fragment("? is distinct from null", pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
    exception = package_facilities -- exception
    f = inclusion ++ exception
    #  f = if Enum.empty?(inclusion) do
    #    package_facilities -- exception
    #  else
    #    package_facilities ++ inclusion
    #  end

    Enum.uniq(f)
  end

  def get_peme_facilities_inclusion(inclusion_product) do
    inclusion =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], pcf in ProductCoverageFacility, pcf.facility_id == f.id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf], pr.code in ^inclusion_product and pc.type == "inclusion")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf], f.step > 6 and f.status == "Affiliated")
      |> where([f, d, pf, p, bp, b, pb, pr], not is_nil(pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_peme_facilities_exclusion(exception_product) do
     Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], pcf in ProductCoverageFacility,
                 pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc, pcf], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], pr.code in ^exception_product and pc.type == "exception")
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], f.step > 6 and f.status == "Affiliated" and pcf.facility_id == pf.facility_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], fragment("? is distinct from null", pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_all_peme_facilities(product_code) do
    Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], pcf in ProductCoverageFacility,
                 pc.id == pcf.product_coverage_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc, pcf], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], pr.code in ^product_code)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], f.step > 6 and f.status == "Affiliated" and pcf.facility_id == pf.facility_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, pcf, c], fragment("? is distinct from null", pf.rate))
      |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  def get_peme_facilities(product_code, package_id) do
    f =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc], pr.code in ^product_code)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, c], f.step > 6 and f.status == "Affiliated" and c.code == "PEME")
      |> where([f, d, pf, p, bp, b, pb, pr], fragment("? is distinct from null", pf.rate))
      |> where([f, d, pf, p, bp, b, pb, pr], p.id == ^package_id)
      |> select([f],
                %{
                  "id" => f.id,
                  "code" => f.code,
                  "name" => f.name,
                  "line_1" => f.line_1,
                  "line_2" => f.line_2,
                  "city" => f.city,
                  "province" => f.province,
                  "region" => f.region,
                  "country" => f.country,
                  "postal_code" => f.postal_code,
                  "phone_no" => f.phone_no,
                  "latitude" => f.latitude,
                  "longitude" => f.longitude,
                  "logo" => f.logo,
                  "title" => fragment("? || ? || ? || ?, ?", f.name, " | ", f.line_1, " ", f.line_2)
                }
      )
      |> Repo.all()
      |> Enum.uniq()

    Enum.uniq(f)
  end

  def get_peme_facilities(facility_id) do
    f =
      Facility
      |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
      |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
      |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
      |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
      |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
      |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr], pc in ProductCoverage, pc.product_id == pr.id)
      |> join(:inner, [f, d, pf, p, bp, b, pb, pr, pc], c in Coverage, c.id == pc.coverage_id)
      |> where([f, d, pf, p, bp, b, pb, pr, pc, c], f.step > 6 and f.status == "Affiliated" and c.code == "PEME")
      |> where([f, d, pf, p, bp, b, pb, pr], fragment("? is distinct from null", pf.rate))
      |> where([f], f.id == ^facility_id)
      |> select([f],
                %{
                  "id" => f.id,
                  "code" => f.code,
                  "name" => f.name,
                  "line_1" => f.line_1,
                  "line_2" => f.line_2,
                  "city" => f.city,
                  "province" => f.province,
                  "region" => f.region,
                  "country" => f.country,
                  "postal_code" => f.postal_code,
                  "phone_no" => f.phone_no,
                  "latitude" => f.latitude,
                  "longitude" => f.longitude,
                  "logo" => f.logo,
                  "title" => fragment("? || ? || ? || ?, ?", f.name, " | ", f.line_1, " ", f.line_2)
                }
      )
      |> Repo.all()
      |> Enum.uniq()

    Enum.uniq(f)
  end

  def get_all_facilities_for_acu do
    Facility
    |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
    |> Repo.all()
  end

  def get_products_by_facility_inclusion(inclusion_product, facility_id) do
      Product
    |> join(:inner, [pr], pb in ProductBenefit, pr.id == pb.product_id)
    |> join(:inner, [pr, pb], b in Benefit, pb.benefit_id == b.id)
    |> join(:inner, [pr, pb, b], bp in BenefitPackage, b.id == bp.benefit_id)
    |> join(:inner, [pr, pb, b, bp], p in Package, bp.package_id == p.id)
    |> join(:inner, [pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> join(:inner, [pr, pb, b, bp, p, pf], pc in ProductCoverage, pr.id == pc.product_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc, pcf], f in Facility, f.id == pf.facility_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc, pcf, f], c in Coverage, pc.coverage_id == c.id)
    |> where([pr, pb, b, bp, p, pf, pc, pcf, f, c], pr.code in ^inclusion_product and
             f.step > 6 and f.status == "Affiliated"
             and c.code == "ACU"
             and f.id == ^facility_id
             and pcf.facility_id == ^facility_id
             and pf.facility_id == ^facility_id
             and pc.type == "inclusion"
    )
    |> where([pr, pb, b, bp, p, pf, pc, pcf, f, c], fragment("? is distinct from null", pf.rate))
    |> select([pr], pr.code)
    |> Repo.all()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def get_products_by_facility_exception(exception_product, facility_id) do
    Product
    |> join(:inner, [pr], pb in ProductBenefit, pr.id == pb.product_id)
    |> join(:inner, [pr, pb], b in Benefit, pb.benefit_id == b.id)
    |> join(:inner, [pr, pb, b], bp in BenefitPackage, b.id == bp.benefit_id)
    |> join(:inner, [pr, pb, b, bp], p in Package, bp.package_id == p.id)
    |> join(:inner, [pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> join(:inner, [pr, pb, b, bp, p, pf], pc in ProductCoverage, pr.id == pc.product_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc, pcf], f in Facility, f.id == pf.facility_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc, pcf, f], c in Coverage, pc.coverage_id == c.id)
    |> where([pr, pb, b, bp, p, pf, pc, pcf, f, c], pr.code in ^exception_product and
             f.step > 6 and f.status == "Affiliated"
             and c.code == "ACU"
             and f.id == ^facility_id
             and pcf.facility_id == ^facility_id
             and pf.facility_id == ^facility_id
             and pc.type == "exception"
    )
    |> where([pr, pb, b, bp, p, pf, pc, pcf, f, c], fragment("? is distinct from null", pf.rate))
    |> select([pr], pr.code)
    |> Repo.all()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def get_products_by_facility_package_product(exception_product, facility_id) do
    Product
    |> join(:inner, [pr], pb in ProductBenefit, pr.id == pb.product_id)
    |> join(:inner, [pr, pb], b in Benefit, pb.benefit_id == b.id)
    |> join(:inner, [pr, pb, b], bp in BenefitPackage, b.id == bp.benefit_id)
    |> join(:inner, [pr, pb, b, bp], p in Package, bp.package_id == p.id)
    |> join(:inner, [pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> join(:inner, [pr, pb, b, bp, p, pf], pc in ProductCoverage, pr.id == pc.product_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc], f in Facility, f.id == pf.facility_id)
    |> join(:inner, [pr, pb, b, bp, p, pf, pc, f], c in Coverage, pc.coverage_id == c.id)
    |> where([pr, pb, b, bp, p, pf, pc, f, c], pr.code in ^exception_product and
             f.step > 6 and f.status == "Affiliated"
             and c.code == "ACU"
             and f.id == ^facility_id
             and pf.facility_id == ^facility_id
             and pc.type == "exception"
    )
    |> where([pr, pb, b, bp, p, pf, pc, f, c], fragment("? is distinct from null", pf.rate))
    |> select([pr], pr.code)
    |> Repo.all()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def get_products_by_facility(product_code, facility_id) do
    inclusion_product =
      Product
      |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
      |> join(:inner, [p, pc], c in Coverage, pc.coverage_id == c.id)
      |> where([p, pc, c], p.code in ^product_code and pc.type == "inclusion" and c.code == "ACU")
      |> select([p], p.code)
      |> Repo.all()
      |> Enum.uniq()

    inclusion_product =
      inclusion_product
      |> Enum.uniq()
      |> List.delete(nil)

    exception_product =
      Product
      |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
      |> join(:inner, [p, pc], c in Coverage, pc.coverage_id == c.id)
      |> where([p, pc, c], p.code in ^product_code and pc.type == "exception" and c.code == "ACU")
      |> select([p], p.code)
      |> Repo.all()
      |> Enum.uniq()

    exception_product =
      exception_product
      |> Enum.uniq()
      |> List.delete(nil)

    inclusion = get_products_by_facility_inclusion(inclusion_product, facility_id)
    exception = get_products_by_facility_exception(exception_product, facility_id)

    package_product = get_products_by_facility_package_product(exception_product, facility_id)

    products = (package_product -- exception) ++ inclusion
  end

  def get_active_members_by_type(facility_id, [], product_codes, account_code), do: []
  def get_active_members_by_type(facility_id, [nil], product_codes, account_code), do: []
  def get_active_members_by_type(nil, [], [], nil), do: []
  def get_active_members_by_type(facility_id, [], [], nil), do: []
  def get_active_members_by_type(facility_id, member_type, product_codes, account_code) do
    coverage = CoverageContext.get_coverage_by_code("ACU")
    account_group = AccountContext.get_account_by_code(account_code)
    acu_products = get_products_by_facility(product_codes, facility_id)
    active_members =
      Member
      |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
      |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [m, mp, ap], a in Account, ap.account_id == a.id)
      |> join(:inner, [m, mp, ap, a], ag in AccountGroup, ag.id == a.account_group_id)
      |> join(:inner, [m, mp, ap, a, ag], p in Product, ap.product_id == p.id)
      |> join(:inner, [m, mp, ap, a, ag, p], pb in ProductBenefit, pb.product_id == p.id)
      |> join(:inner, [m, mp, ap, a, ag, p, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
      |> join(:inner, [m, mp, ap, a, ag, p, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
      |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf], f in Facility, pf.facility_id == f.id)
      |> join(:left, [m, mp, ap, a, ag, p, pb, bp, pf, f], au in Authorization, m.id == au.member_id)
      |> join(:left, [m, mp, ap, a, ag, p, pb, bp, pf, f, au], abp in AuthorizationBenefitPackage, (au.id == abp.authorization_id) and (abp.benefit_package_id == bp.id))
      |> where([m, mp, ap, a, ag, p, pb, bp, pf, f], pf.facility_id == ^facility_id)
      |> where([m, mp, ap, a, ag, p, pb, bp, pf, f], (fragment("date_part('year', age(?))",
               m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
      |> where([m, mp, ap, a, ag, p, pb, bp, pf, f], (bp.male == true and m.gender == "Male") or
                        (bp.female == true and m.gender == "Female"))
      |> where([m, mp, ap, a, ag, p], p.code in ^acu_products and m.type in ^member_type)
      |> where([m, mp, ap, a, ag, p], a.account_group_id == ^account_group.id)
      |> where([m, mp, ap, a, ag, p, pb, bp, pf, f, au, abp], is_nil(abp.benefit_package_id))
      |> where([m], m.status == "Active")
      |> distinct([m, mp, ap, a, ag, p, pb, bp, pf, f, au, abp], m.id)
      |> select([m, mp, ap, a, ag, p, pb, bp, pf, f, au], %{id: m.id, authorization_id: au.id})
      |> Repo.all()
      |> Enum.uniq()
  end

  defp active_member_ibnr_checker(authorization_id, member_id) do
    Member
    |> join(:inner, [m], a in Authorization, a.member_id == m.id)
    |> join(:inner, [m, a], c in Coverage, c.id == a.coverage_id)
    |> where([m, a, c], a.id  == ^authorization_id)
    |> where([m, a, c], c.name != "ACU")
    |> where([m, a, c], m.id == ^member_id)
    |> select([m], %{id: m.id})
    |> Repo.one()
  end

  defp member_acu_checker(member, acu_product, facility_id) do
    # coverage = CoverageContext.get_coverage_by_code("ACU")
    # member = MemberContext.get_a_member!(member.id)
    # member_products = member.products

    # member_products
    # |> Enum.uniq()
    # |> List.delete(nil)
    # |> List.flatten()

    # member_product =
    #   AuthorizationContext.get_member_product_with_coverage_and_tier(
    #     member_products,
    #     coverage.id
    #   )

    acu_member =
      MemberContext.get_acu_member(
        member,
        acu_product,
        facility_id
      )
  end

  defp member_ibnr_checker(authorization_id, member_id) do
    Member
    |> join(:inner, [m], a in Authorization, a.member_id == m.id)
    |> join(:inner, [m, a], abp in AuthorizationBenefitPackage, abp.authorization_id == a.id)
    |> join(:inner, [m, a, abp], bp in BenefitPackage, bp.id == abp.benefit_package_id)
    |> join(:inner, [m, a, abp, bp], b in Benefit, b.id == bp.benefit_id)
    |> join(:inner, [m, a, abp, bp, b], cb in BenefitCoverage, cb.benefit_id == b.id)
    |> join(:inner, [m, a, abp, bp, b, cb], c in Coverage, c.id == cb.coverage_id)
    |> where([m, a, abp, bp, b, cb, c], a.id  == ^authorization_id)
    |> where([m, a, abp, bp, b, cb, c], c.name != "ACU")
    |> where([m, a, abp, bp, b, cb, c], m.id == ^member_id)
    |> select([m], %{id: m.id})
    |> Repo.one()
  end

  def create_acu_schedule(params, user_id) do
    time_from = String.split(params["time_from"], ":")
    time_to = String.split(params["time_to"], ":")
    account_group = AccountContext.get_account_by_code(params["account_code"])

    if account_group == {:account_not_found} do
      {:account_not_found}
    else
      params =
        params
        |> Map.put("no_of_selected_members", params["no_of_selected_members"])
        |> Map.put("created_by_id", user_id)
        |> Map.put("updated_by_id", user_id)
        |> Map.put("no_of_members", params["number_of_members_val"])
        |> Map.put("batch_no", generate_random_batch_no)
        |> Map.put("account_group_id", account_group.id)
        |> Map.put("time_from", cast_to_time(time_from))
        |> Map.put("time_to", cast_to_time(time_to))

        params =
          check_member_type(
            {Map.has_key?(params,  "principal"), Map.has_key?(params, "dependent")},
            params
          )

          %AcuSchedule{}
          |> AcuSchedule.changeset(params)
          |> Repo.insert()
    end
  end

  def create_acu_schedule_product(acu_schedule_id, product_codes) do
    acu_products = Enum.map(product_codes, fn(pc) ->
      product = ProductContext.get_product_by_code(pc)
      if not is_nil(product) do
        params = %{
          "acu_schedule_id" => acu_schedule_id,
          "product_id" => product.id
        }
        %AcuScheduleProduct{}
        |> AcuScheduleProduct.changeset(params)
        |> Repo.insert!()
      end
    end)
    acu_products =
      acu_products
      |> Enum.reject(&(&1 == nil))
    {:ok, acu_products}
  end

  def create_acu_schedule_member(acu_schedule_id, product_code, account_code) do
    acu_schedule = get_acu_schedule(acu_schedule_id)

    cond do
      acu_schedule.member_type == "Principal" ->
        member_type = ["Principal"]
      acu_schedule.member_type == "Dependent" ->
        member_type = ["Dependent"]
      true ->
        member_type = ["Principal", "Dependent"]
    end

    members = get_active_members_by_type(acu_schedule.facility_id, member_type, product_code, account_code)
  end

  defp generate_random_batch_no do
    numbers = "0123456789"
    rand = UtilityContext.randomizer(8, :numeric)
    with true <- String.contains?(rand, String.split(numbers, "", trim: true)) do
      rand
    else
      _ ->
      generate_random_batch_no()
    end
  end

  def acu_schedule_api_params(acu_schedule) do
    guaranteed_amount = get_guaranteed_amount(acu_schedule.acu_schedule_members, acu_schedule.id)
    Repo.update(Ecto.Changeset.change acu_schedule, guaranteed_amount: guaranteed_amount)
    user = acu_schedule.created_by
    aga = AccountContext.get_account_group_address!(acu_schedule.account_group.id, "Account Address")
    md =
      if not is_nil(user.middle_name) do
         user.middle_name
      else
        ""
      end
    user_fullname = Enum.join([user.first_name, md, user.last_name], " ")

    prescription_term =
      FacilityContext.get_facility_prescription_term(acu_schedule.facility.id).prescription_term

    %{
      "facility_id" => acu_schedule.facility.id,
      "account_code" => acu_schedule.account_group.code,
      "account_name" => acu_schedule.account_group.name,
      "batch_no" => acu_schedule.batch_no,
      "created_by" => user.username,
      "date_from" => acu_schedule.date_from,
      "date_to" => acu_schedule.date_to,
      "no_of_members" => acu_schedule.no_of_members,
      "no_of_selected_members" => acu_schedule.no_of_selected_members,
      "guaranteed_amount" => acu_schedule.guaranteed_amount,
      "packages" => Enum.concat(Enum.map(acu_schedule.acu_schedule_products, fn(asp) ->
          get_benefit_package(asp.product.product_benefits)
      end)),
      "payorlink_acu_schedule_id" => acu_schedule.id,
      "time_from" => acu_schedule.time_from,
      "time_to" => acu_schedule.time_to,
      "account_address" => Enum.join([aga.line_1, aga.line_2, aga.city, aga.province, aga.region, aga.country, aga.postal_code], " "),
      "prescription_term" => prescription_term
    }
  end

  def member_benefit_package(member) do
    member = MemberContext.get_a_member!(member.id)
    coverage = CoverageContext.get_coverage_by_code("ACU")

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
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()

    if is_nil(benefit_package) do
      nil
    else
      benefit_package
    end
    rescue
    _ ->
      nil
  end

  def get_package_id(member_id) do
    member = MemberContext.get_a_member!(member_id)
    coverage = CoverageContext.get_coverage_by_code("ACU")

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
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()
    benefit_package.package_id
  end

  defp get_benefit_package(product_benefits) do
    Enum.map(product_benefits, fn(pb) ->
      bp = List.first(pb.benefit.benefit_packages)
      %{
        "package_code" => bp.package.code,
        "package_name" => bp.package.name,
        "package_description" => Enum.map(bp.package.package_payor_procedure, fn(ppp) -> ppp.payor_procedure.description end),
        "benefit_package_id" => bp.id
       }
    end)
  end

  defp from_ecto_to_date(date) do
    date
    |> Ecto.Date.to_erl()
    |> Date.from_erl()
    |> elem(1)
  end

  defp remove_seconds(time) do
    time
    |> Ecto.Time.to_erl()
    |> Time.from_erl()
    |> elem(1)
    |> Time.to_string()
    |> String.split(":")
    |> List.delete_at(2)
    |> List.insert_at(1, ":")
    |> Enum.join("")
  end

  def get_date_range(d1, d2, t1, t2) do
    d1 = from_ecto_to_date(d1)
    d2 = from_ecto_to_date(d2)
    t1 = remove_seconds(t1)
    t2 = remove_seconds(t2)

    date_diff = Date.diff(d2, d1)
    if date_diff != 0 do
      get_dates_for_acu([d1], d2, t1, t2, [])
    else
      day = Timex.weekday(d1)
      weekday = Timex.day_name(day)
      month = get_month_name(d1)
      year = get_year(d1)
      list = [["#{weekday}, #{month} #{year}; #{t1}-#{t2}"]]
    end
  end

  def get_dates_for_acu(date_list, date_to, t1, t2, days) do
    last_date =
      date_list
      |> List.last()

    first_date =
      date_list
      |> List.first()

    case Date.compare(date_to, last_date) do
      :eq ->
        day1 = Timex.weekday(first_date)
        weekday1 = Timex.day_name(day1)
        month1 = get_month_name(first_date)
        year1 = get_year(first_date)
        f_day = [["#{weekday1}, #{month1} #{year1}; #{t1}-#{t2}"]]
        list = f_day ++ days
      :gt ->
        new_date = Date.add(last_date, 1)
        day = Timex.weekday(new_date)
        weekday = Timex.day_name(day)
        list = date_list ++ [new_date]

        month = get_month_name(new_date)
        year = get_year(new_date)

        list2 = days ++ [["#{weekday}, #{month} #{year}; #{t1}-#{t2}"]]
        get_dates_for_acu(list, date_to, t1, t2, list2)
    end
  end

  defp get_month_name(new_date) do
    month =
      new_date
      |> Date.to_string()
      |> String.split("-")
      |> List.delete_at(0)
      |> List.delete_at(1)
      |> Enum.join("")
      |> String.split("")

    if Enum.at(month, 0) == "0" do
      month =  List.delete_at(month, 0)
    end

    month  =
      month
      |> Enum.join("")
      |> String.to_integer()
      |> Timex.month_name
  end

  defp get_year(new_date) do
    new_date
    |> Timex.format!("{0M}-{D}-{YYYY}")
    |> String.split("-")
    |> List.delete_at(0)
    |> Enum.join(", ")
  end

  def get_age(date) do
    year_of_date = to_string(date)
    year_today =  Date.utc_today
    year_today = to_string(year_today)
    datediff1 = Timex.parse!(year_of_date, "%Y-%m-%d", :strftime)
    datediff2 = Timex.parse!(year_today, "%Y-%m-%d", :strftime)
    diff_in_years = Timex.diff(datediff2, datediff1, :years)
    diff_in_years
  end

  defp border_design do
    left = [style: :thin, color: "#000000"]
    right = [style: :thin, color: "#000000"]
    top = [style: :thin, color: "#000000"]
    bottom = [style: :thin, color: "#000000"]

    [left: left, right: right, top: top, bottom: bottom]
  end

   def get_package_acu_schedule_batch(record) do
    record.acu_schedule_products
    |> Enum.map(&(&1.product))
    |> List.flatten()
    |> Enum.map(&(&1.product_benefits))
    |> List.flatten()
    |> Enum.map(&(&1.benefit))
    |> List.flatten()
    |> Enum.map(&(&1.benefit_packages))
    |> List.flatten()
    |> Enum.map(&(&1.package))
    |> List.flatten()
    |> Enum.uniq_by(&(&1.id))
  end

  #ACU SCHEDULE API
  def create_acu_schedule_api(user_id, params) do
    with {:ok, response} <- connect_to_api_post(params) do
      case response.status_code do
        404 ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Not found create schedule api")
          |> insert_acu_log()
        400 ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Bad request create schedule api")
          |> insert_acu_log()
        200 ->
          {:ok}
        500 ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Internal server error create schedule api")
          |> insert_acu_log()
        403 ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Forbidden create schedule api")
          |> insert_acu_log()
        421 ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Misdirected request create schedule api")
          |> insert_acu_log()
        _ ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Error in create schedule api")
          |> insert_acu_log()
      end
    else
      {:error_connecting_api} ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Error connecting to create schedule api")
          |> insert_acu_log()
      {:unable_to_login} ->
          params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Unable to login in create schedule api")
          |> insert_acu_log()
      {:bad_request} ->
        params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Bad request error")
          |> insert_acu_log()
      _ ->
        params["payorlink_acu_schedule_id"]
          |> log_params(params["member_id"], "Error creating schedule")
          |> insert_acu_log()
    end
  end

  def provider_link_sign_in(new) do
    api_address =
      "PROVIDERLINK_2"
      |> ApiAddressContext.get_api_address_by_name()

    with false <- new,
          true <- is_nil(api_address.token) || api_address.token == ""
    do
      api_address
      |> request_new_token_providerlink()
    else
      # new return
      true ->
        api_address
        |> request_new_token_providerlink()
      # is_nil return
      false ->
        {:ok, api_address.token}
      end
  end

  defp request_new_token_providerlink(api_address) do
    providerlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(providerlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      api_address.id
      |> ApiAddressContext.update_api_address(%{"token" => decoded["token"]})

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
    end
  end

  def providerlink_sign_in_v2() do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    providerlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(providerlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Providerlink"}
    end
  end

  # for refactoring
  def connect_to_api_post(conn, params) do
    with {:ok, token} <- provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/create_schedule"], "")
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
          with {:ok, token} <- provider_link_sign_in(true) do
            api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
            api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/create_schedule"], "")
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

  # for refactoring
  def connect_to_api_post(params) do
    with {:ok, token} <- provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/create_schedule"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(params)
      with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
           200 <- response.status_code
      do
        {:ok, response}
      else
        {:error, response} ->
          {:error_connecting_api}
        400 ->
          {:bad_request}
        401 ->
          with {:ok, token} <- provider_link_sign_in(true) do
            api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
            api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/create_schedule"], "")
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
  #end of api

  def if_acu_sched_notif?(user) do
    user = UserContext.get_user!(user.id)
    user.acu_schedule_notification
    applications = Enum.map(user.roles, fn(ur) ->
      Enum.map(ur.role_applications, fn(ra) ->
        ra.application.name
      end)
    end)
    |> Enum.uniq()
    |> List.flatten()

    permissions = Enum.map(user.roles, fn(ur) ->
      Enum.map(ur.role_permissions, fn(rp) ->
        rp.permission.name
      end)
    end)
    |> Enum.uniq()
    |> List.flatten()

    if Enum.all?([
      Enum.member?(applications, "ProviderLink"),
      Enum.member?(permissions, "Manage ACU Schedules"),
      user.acu_schedule_notification
    ]) do
     true
    else
      false
    end
  end

  def get_acu_package(acu_schedule_id, product_id, package_id) do
    AcuSchedulePackage
    |> join(:inner, [asp], ap in AcuScheduleProduct, asp.acu_schedule_product_id == ap.id)
    |> where([asp, ap], asp.acu_schedule_id == ^acu_schedule_id)
    # |> where([asp, ap], asp.acu_schedule_id == ^acu_schedule_id and ap.product_id == ^product_id)
    |> where([asp, ap], asp.package_id == ^package_id)
    |> Repo.one()
  end

  def create_acu_loa(user_id, member_id, acu_schedule_id, token, coverage_id, task_acu_sched_id) do
    member = MemberContext.get_acu_member!(member_id)
    task_acu_sched = get_task_acu_schedule_by_id(task_acu_sched_id)
    acu_schedule = get_acu_schedule_no_preload(acu_schedule_id)
    facility_id = acu_schedule.facility_id
    with {:ok, params} <- setup_acu_loa_params(member, coverage_id, facility_id, acu_schedule.id),
         {:ok, authorization} <- generate_acu_loa(member.id, user_id, facility_id, coverage_id, acu_schedule.date_to),
         {:ok} <- insert_acu_details(authorization, params, user_id, member)
    do
      MemberContext.update_member_products_status(params)
      request_providerlink_acu(member, authorization, params, acu_schedule, token, task_acu_sched)
    else
      _ ->
        acu_schedule.id
        |> log_params(member.id, "Setup error")
        |> insert_acu_log()
    end
  end

  def generate_acu_loa(member_id, user_id, facility_id, coverage_id, date_to) do
    date_created = Date.utc_today()
    valid_until = Date.add(date_created, 2)
    transaction_number = AuthorizationContext.generate_random_transaction_no()
    admission_datetime = Ecto.DateTime.cast!("#{date_to} 00:00:00")
    authorization_params = %{
      "member_id" => member_id,
      "facility_id" => facility_id,
      "coverage_id" => coverage_id,
      "step" => 5,
      "created_by_id" => user_id,
      "origin" => "payorlink",
      "approved_by_id" => user_id,
      "approved_datetime" => Ecto.DateTime.utc(),
      "updated_by_id" => user_id,
      "otp" => "false",
      "version" => 1,
      "status" => "Approved",
      "valid_until" => valid_until,
      "transaction_no" => transaction_number,
      "admission_datetime" => admission_datetime
    }
    changeset =
      %Authorization{}
      |> Authorization.changeset_acu_sched(authorization_params)
    Repo.insert(changeset)
  end

  def setup_acu_loa_params(member, coverage_id, facility_id, acu_sched_id) do
    with %MemberProduct{} = member_product <- filter_member_products(member, coverage_id, acu_sched_id),
         %Product{} = product <- member_product.account_product.product,
         %ProductBenefit{} = product_benefit <- MemberContext.get_acu_package_based_on_member(member, member_product),
         %Benefit{} = benefit <- product_benefit.benefit,
         %BenefitPackage{} = benefit_package <- get_benefit_package(member, member_product),
         pbl <- ProductContext.get_product_benefit(product_benefit.id).product_benefit_limits,
         benefit_limit_amount <- get_benefit_limit_amount(pbl)
    do
      package = benefit_package.package
      package_facility_rate = package_facility_rate(package.package_facility, facility_id)
      package = Map.put(package, :package_facility_rate, package_facility_rate)
      benefit = Map.put(benefit, :limit_amount, benefit_limit_amount)
      package_rate = get_acu_package(acu_sched_id, product.id, package.id).rate
      {:ok,
        {
          benefit,
          benefit_package,
          package, product,
          product_benefit,
          member_product,
          package_rate
        }
      }
    else
      _ ->
        {:error, "Setup error"}
    end
  end

  def insert_acu_details(authorization, params, user_id, member) do
    {
      benefit,
      benefit_package,
      package,
      product,
      product_benefit,
      member_product,
      package_rate
    } = params
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))
    acu_params = %{
      user_id: user_id,
      member_id: authorization.member_id,
      benefit_package_id: benefit_package.id,
      product_id: product.id,
      product: product,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: "payorlink",
      product_benefit: product_benefit,
      product: product,
      benefit_package: benefit_package,
      member: member,
      package_rate: package_rate,
      authorization: authorization
    }
    ACUScheduleValidator.insert_acu_details(acu_params)
  end

  defp request_providerlink_acu(member, authorization, params, acu_schedule, token, task_acu_sched) do
    {
      benefit,
      benefit_package,
      package,
      product,
      product_benefit,
      member_product,
      package_rate
    } = params
    package_details = Enum.map(package.package_payor_procedure, &(&1.payor_procedure.procedure.description))
    payor_procedures = payor_procedures(package, member)
    provider_acu_schedule_params =
      %{
        member_id: member.id,
        member_first_name: member.first_name,
        member_middle_name: member.middle_name,
        member_last_name: member.last_name,
        member_suffix: member.suffix,
        member_card_no: member.card_no,
        member_birth_date: member.birthdate,
        member_age: UtilityContext.age(member.birthdate),
        member_status: member.status,
        member_expiry_date: member.expiry_date,
        member_gender: member.gender,
        status: authorization.status,
        issue_date: authorization.requested_datetime,
        loa_number: authorization.number,
        control_number: authorization.control_number,
        authorization_id: authorization.id,
        acu_type: benefit.acu_type,
        acu_coverage: benefit.acu_coverage,
        benefit_package_id: benefit_package.id,
        benefit_code: benefit.code,
        benefit_provider_access: benefit.provider_access,
        limit_amount: benefit.limit_amount,
        package_facility_rate: package_rate,
        acu_schedule_id: acu_schedule.id,
        acu_schedule_date_to: acu_schedule.date_to,
        admission_date: authorization.admission_datetime,
        package: %{
          id: package.id,
          code: package.code,
          name: package.name,
          details: Enum.join(package_details, ", ")
        },
        payor_procedure: Enum.into(payor_procedures, [], fn(pp) ->
          %{
            id: pp.procedure.id,
            code: pp.procedure.code,
            description: pp.procedure.description
          }
        end)
      }
    request_acu_provider_api(acu_schedule.id, provider_acu_schedule_params, token, task_acu_sched)
  end

  defp get_benefit_package(member, member_product) do
    member
    |> MemberContext.get_acu_package_based_on_member_for_schedule(member_product)
    |> List.first()
  end

  defp filter_member_products(member, coverage_id, acu_sched_id) do
    asm = get_acu_schedule_member_by_acu_and_member(acu_sched_id, member.id)
    if is_nil(asm.package_code) || asm.package_code == "" do
      member.products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()
      |> AuthorizationContext.get_member_product_with_coverage_and_tier(coverage_id)
    else
      get_member_product_by_package(member, asm.acu_schedule, asm.package_code)
      |> AuthorizationContext.get_member_product_with_coverage_and_tier(coverage_id)
    end
  end

  defp get_benefit_limit_amount(pbl) do
    if Enum.empty?(pbl) do
      limit_amount = Decimal.new(0)
    else
      pbl = List.first(pbl)
      pbl.limit_amount || Decimal.new(0)
    end
  end

  # def create_acu_loa2(user_id, member_id, acu_schedule_id, token, coverage_id) do
  #     user = Repo.get(User, user_id)
  #     member = Repo.get(Member, member_id)
  #     acu_schedule = get_acu_schedule(acu_schedule_id)
  #     acu_details_params = %{
  #       "origin" => "payorlink",
  #       "card_no" => member.card_no,
  #       "facility_code" => acu_schedule.facility.code,
  #       "coverage_code" => "ACU",
  #       "acu_schedule_id" => acu_schedule.id
  #     }
  #     with {authorization, benefit, benefit_package, package, payor_procedures,
  #       product} <- insert_acu_details(user, acu_details_params) do

  #       loa_params = %{
  #         "authorization_id" => authorization.id,
  #         "card_no" => member.card_no,
  #         "facility_code" => acu_schedule.facility.code,
  #         "coverage_code" => "ACU",
  #         "origin" =>  "payorlink",
  #         "acu_schedule_id" => acu_schedule.id
  #       }
  #       with {:ok, authorization} <- update_request_acu(user, loa_params) do
  #         # package_rate = get_acu_schedule_package_by_acu_and_package(acu_schedule.id, package.id).rate
  #         package_rate = get_acu_package(acu_schedule.id, product.id, package.id).rate
  #         package_details = Enum.map(package.package_payor_procedure, &(&1.payor_procedure.procedure.description))
  #         provider_acu_schedule_params =
  #          %{
  #            member_id: member.id,
  #            member_first_name: member.first_name,
  #            member_middle_name: member.middle_name,
  #            member_last_name: member.last_name,
  #            member_suffix: member.suffix,
  #            member_card_no: member.card_no,
  #            member_birth_date: member.birthdate,
  #            member_age: UtilityContext.age(member.birthdate),
  #            member_status: member.status,
  #            member_expiry_date: member.expiry_date,
  #            member_gender: member.gender,
  #            status: authorization.status,
  #            issue_date: authorization.requested_datetime,
  #            loa_number: authorization.number,
  #            control_number: authorization.control_number,
  #            authorization_id: authorization.id,
  #            acu_type: benefit.acu_type,
  #            acu_coverage: benefit.acu_coverage,
  #            benefit_package_id: benefit_package.id,
  #            benefit_code: benefit.code,
  #            benefit_provider_access: benefit.provider_access,
  #            limit_amount: benefit.limit_amount,
  #            package_facility_rate: package_rate,
  #            acu_schedule_id: acu_schedule.id,
  #            package: %{
  #              id: package.id,
  #              code: package.code,
  #              name: package.name,
  #              details: Enum.join(package_details, ", ")
  #            },
  #            payor_procedure: Enum.into(payor_procedures, [], fn(pp) ->
  #              %{
  #                id: pp.procedure.id,
  #                code: pp.procedure.code,
  #                description: pp.procedure.description
  #              }
  #            end)
  #          }
  #         request_acu_provider_api(acu_schedule_id, provider_acu_schedule_params, token)
  #       else
  #       {:error, remarks} ->
  #         acu_schedule.id
  #         |> log_params(member.id, remarks)
  #         |> insert_acu_log()
  #         _ ->
  #           acu_schedule.id
  #           |> log_params(member.id, "Error in loa 2nd validation")
  #           |> insert_acu_log()
  #       end
  #     else
  #     {:error, remarks} ->
  #       acu_schedule.id
  #       |> log_params(member.id, remarks)
  #       |> insert_acu_log()
  #     end
  #     {:ok, acu_schedule}
  #   # rescue
  #   #    e in DBConnection.ConnectionError ->
  #   #     acu_schedule_id
  #   #     |> log_params(member_id, "Connection timeout")
  #   #     |> insert_acu_log()
  # end

  # for refactoring
  def request_acu_provider_api(acu_schedule_id, params) do
    with {:ok, token} <- provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/#{acu_schedule_id}/insert_schedule_member_from_payorlink"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(params)
      with {:ok, response} <- HTTPoison.post(api_method, body, headers, [timeout: 60_000, recv_timeout: 60_000]),
            200 <- response.status_code
      do
        {:ok, response}
        keys = "#{params.member_first_name} #{params.member_last_name}, #{params.member_card_no}, #{params.member_birth_date}"

        acu_schedule_id
        |> log_params(params.member_id, keys)
        |> insert_acu_log()
      else
        {:error, response} ->
          case HTTPoison.post(api_method, body, headers, [timeout: 60_000, recv_timeout: 60_000]) do
            {:ok, response} ->
              keys = "#{params.member_first_name} #{params.member_last_name}, #{params.member_card_no}, #{params.member_birth_date}"

              acu_schedule_id
              |> log_params(params.member_id, keys)
              |> insert_acu_log()
            _ ->
              acu_schedule_id
              |> log_params(params["member_id"], response)
              |> insert_acu_log()

              {:error_connecting_api}
          end
        401 ->
          with {:ok, token} <- provider_link_sign_in(true) do
                api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
                api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/#{acu_schedule_id}/insert_schedule_member_from_payorlink"], "")
                headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
                body = Poison.encode!(params)
                with {:ok, response} <- HTTPoison.post(api_method, body, headers, [timeout: 60_000, recv_timeout: 60_000]),
                      200 <- response.status_code
                do
                  {:ok, response}
                  keys = "#{params.member_first_name} #{params.member_last_name}, #{params.member_card_no}, #{params.member_birth_date}"

                  acu_schedule_id
                  |> log_params(params.member_id, keys)
                  |> insert_acu_log()
                else
                  {:error, response} ->
                    acu_schedule_id
                    |> log_params(params["member_id"], response)
                    |> insert_acu_log()

                    {:error_connecting_api}
                  401 ->
                    acu_schedule_id
                    |> log_params(params["member_id"], "error 401")
                    |> insert_acu_log()

                    {:error_connecting_api}
                end
          else
            {:unable_to_login, response} ->
              acu_schedule_id
              |> log_params(params["member_id"], response)
              |> insert_acu_log()
              {:unable_to_login}
          end
      end
    else
      {:unable_to_login, response} ->
          acu_schedule_id
          |> log_params(params["member_id"], response)
          |> insert_acu_log()
        {:unable_to_login}
    end
  end

  # for refactoring
  def update_verified(authorization_id) do
    with {:ok, token} <- provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/loas/#{authorization_id}/update_verified"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(%{})
      with {:ok, response} <- HTTPoison.put(api_method, body, headers, []),
            200 <- response.status_code
      do
        {:ok, response}
      else
        {:error, response} ->
          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
          {:error_connecting_api}
        401 ->
          with {:ok, token} <- provider_link_sign_in(true) do
          api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
          api_method = Enum.join([api_address.address, "/api/v1/loas/#{authorization_id}/update_verified"], "")
          headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
          body = Poison.encode!(%{})
            with {:ok, response} <- HTTPoison.put(api_method, body, headers, []),
                  200 <- response.status_code
            do
              {:ok, response}
            else
              {:error, response} ->
                return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
                return
                |> insert_acu_log()
                {:error_connecting_api}
              401 ->
                return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
                return
                |> insert_acu_log()
                {:error_connecting_api}
            end
          else
            {:unable_to_login} ->
              return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
              return
              |> insert_acu_log()
              {:unable_to_login}
          end
      end
    else
      {:unable_to_login} ->
        return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
        return
        |> insert_acu_log()
        {:unable_to_login}
    end
  end

  # for refactoring
  def update_forfeited(authorization_id) do
    with {:ok, token} <- provider_link_sign_in(false) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/loas/#{authorization_id}/update_forfeited"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(%{})
      with {:ok, response} <- HTTPoison.put(api_method, body, headers, []),
           200 <- response.status_code
      do
           {:ok, response}
      else
        {:error, response} ->
          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
          {:error_connecting_api}
        401 ->
    with {:ok, token} <- provider_link_sign_in(true) do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/loas/#{authorization_id}/update_forfeited"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(%{})
      with {:ok, response} <- HTTPoison.put(api_method, body, headers, []),
           200 <- response.status_code
      do
           {:ok, response}
      else
        {:error, response} ->
          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
          {:error_connecting_api}
        401 ->

          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
          {:error_connecting_api}
      end
    else
      {:unable_to_login} ->

          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
        {:unable_to_login}
    end
      end
    else
      {:unable_to_login} ->

          return = log_params(nil, nil, "#{authorization_id} : error updating verified loa status")
          return
          |> insert_acu_log()
        {:unable_to_login}
    end
  end

  defp current_time(date_now) do
    date_now
    |> DateTime.to_time()
    |> Time.to_erl()
    |> Ecto.Time.from_erl()
  end

  defp export_package(package) do
    package
    |> Enum.map(fn(package) ->
      details =
        Enum.map(package.package_payor_procedure, fn(ppp) ->
          ppp.payor_procedure.description
        end)
        details =
          details
          |> List.flatten()
          |> Enum.join(",")
          [
            [package.code, border: border_design],
            [package.name, border: border_design],
            [details, border: border_design]
          ]
    end)
  end

  def export_date_schedule(id, date_ranges) do
   record = load_acu(id)
     for {value, index} <- Enum.with_index(date_ranges) do
        if index == 0 do
          Enum.concat(value, ["", "#{record.no_of_guaranteed}"])
        else
          Enum.concat(value, ["", ""])
        end
     end
  end

defp export_member(members) do
    members
    |> Enum.into([], fn(x) ->
      [
        [x.card_number, border: border_design],
        [x.fullname, border: border_design],
        [x.gender, border: border_design],
        [x.birthdate, border: border_design],
        [x.age, border: border_design],
        [x.package_code, border: border_design],
        ["", border: border_design]
      ]
    end)
  end

  defp export_account_loc(id) do
    record = load_acu(id)
    loc =
      Enum.join([
        List.first(record.account_group.account_group_address).line_1,
        List.first(record.account_group.account_group_address).line_2,
        List.first(record.account_group.account_group_address).city
      ], " ")

    loc2 =
      Enum.join([
        List.first(record.account_group.account_group_address).province,
        List.first(record.account_group.account_group_address).region,
        List.first(record.account_group.account_group_address).postal_code,
        List.first(record.account_group.account_group_address).country
      ], " ")
    location =
      %{
        loc: loc,
        loc2: loc2
      }
  end

  defp export_facility_loc(id) do
    record = load_acu(id)
    facility_loc =
      Enum.join([
        record.facility.line_1,
        record.facility.line_2,
        record.facility.city
      ], " ")

    facility_loc2 =
      Enum.join([
        record.facility.province,
        record.facility.region,
        record.facility.postal_code,
        record.facility.country
      ], " ")
    location =
      %{
        loc: facility_loc,
        loc2: facility_loc2
      }
  end

  defp sheet1(id, datetime, acu_schedule_members) do
    members = get_member_by_schedule_id2(id)
    packages = get_selected_package(acu_schedule_members)
    record = load_acu(id)
    username = get_username_by_acu_schedule(record.created_by_id)
    date_now = DateTime.utc_now()
    location = export_account_loc(id)
    facility_loc = export_facility_loc(id)
    date_ranges = get_date_range(record.date_from, record.date_to, record.time_from, record.time_to)
    package = get_package_acu_schedule_batch(record)
    sheet1 =
      %Sheet{
        name: "Batch Details",
        rows: [
          [["Batch No.", bold: true, size: 10, font: "Liberation Sans"]],
          [Integer.to_string(record.batch_no)],
          [],
          [["Facility Code/Name", bold: true, size: 10, font: "Liberation Sans"],
           "",
           ["Facility Address", bold: true, size: 10, font: "Liberation Sans"]],
          ["#{record.facility.code} / #{record.facility.name}", "", "#{facility_loc.loc}"],
          ["", "" , "#{facility_loc.loc2}"],
          [],
          [["Account Code/Name", bold: true, size: 10, font: "Liberation Sans"],
           "",
          ["Account Address", bold: true, size: 10, font: "Liberation Sans"]],
          ["#{record.account_group.code} / #{record.account_group.name}", "", location.loc],
          ["", "", "#{location.loc2}"],
          []] ++ [
          [["ACU Date(From/To;Duration/time)", bold: true, size: 10, font: "Liberation Sans"],
           "",
           ["No. of guaranteed heads", bold: true, size: 10, font: "Liberation Sans"]],
          ] ++ export_date_schedule(id, date_ranges) ++ [[]]
          ++ [[["Schedule Created By", bold: true, size: 10, font: "Liberation Sans"],
               "",
               ["Date and Time of Masterlist Generation", bold: true, size: 10, font: "Liberation Sans"]],
               ["#{username}", "", datetime],
              [],
              [["Legend:", bold: true, size: 10, font: "Liberation Sans"]],
              [["Package Code", border: border_design, bold: true, size: 10, font: "Liberation Sans"],
               ["Package Name", border: border_design, bold: true, size: 10, font: "Liberation Sans"],
               ["Package Details", border: border_design, bold: true, size: 10, font: "Liberation Sans"]]
          ] ++ export_package(package),
        merge_cells: [
          {"A5", "B5"},
          {"C5", "G5"},
          {"C8", "G8"},
          {"A4", "B4"},
          {"A10", "B10"}
        ]
      }
      |> Sheet.set_col_width("C", 45.0)
      |> Sheet.set_col_width("A", 35.0)
      |> Sheet.set_col_width("B", 20.0)
  end

  defp sheet2(id, acu_schedule) do
    members =
      acu_schedule.acu_schedule_members
      |> Enum.filter(&( is_nil(&1.status) ))
      |> Enum.map(fn(a) ->
         %{
          card_number: a.member.card_no,
          fullname: "#{a.member.first_name} #{a.member.middle_name} #{a.member.last_name}",
          gender: a.member.gender,
          birthdate: Timex.format!(a.member.birthdate, "{0M}-{D}-{YYYY}"),
          age: Integer.to_string(get_age(a.member.birthdate)),
          package_code: a.package_code
        }
      end)

    sheet2 =
      %Sheet{name: "Member Details",
        rows: [[["Card Number", align_horizontal: :center, border: border_design],
                ["Full Name", align_horizontal: :center, border: border_design],
                ["Gender", align_horizontal: :center, border: border_design],
                ["Birthdate", align_horizontal: :center, border: border_design],
                ["Age", align_horizontal: :center, border: border_design],
                ["Package Code", align_horizontal: :center, border: border_design],
                ["Signature", align_horizontal: :center, border: border_design]]] ++ export_member(members),
      }
      |> Sheet.set_col_width("C", 8.0)
      |> Sheet.set_col_width("A", 14.0)
      |> Sheet.set_col_width("B", 24.0)
      |> Sheet.set_col_width("D", 12.0)
      |> Sheet.set_col_width("E", 8.0)
      |> Sheet.set_col_width("F", 40.0)
      |> Sheet.set_col_width("G", 12.0)
  end

  def acu_schedule_export(id, datetime) do
    acu_schedule = get_acu_schedule_v2(id)
    record = load_acu(id)
    date_now = DateTime.utc_now()
    filename = "#{record.batch_no}-#{record.account_group.code}-#{DateTime.to_date(date_now)}.xlsx"
    workbook = %Workbook{sheets: [sheet1(id, datetime, acu_schedule.acu_schedule_members)]}
    workbook =
      workbook
      |> Workbook.insert_sheet(sheet2(id, acu_schedule), 1)
      |> Elixlsx.write_to_memory(filename)
  end

  def get_selected_package(acu_schedule_members) do
    acu_schedule_members
    |> Enum.map(&(&1.package_code))
    |> List.flatten()
    # package_code
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

  def bgworker(member_id, acu_schedule_id, user_id) do
    params = %{
      "acu_schedule_id" => acu_schedule_id,
      "member_id" => member_id
      # "status" => "removed"
    }
    {:ok, asm} =
      %AcuScheduleMember{}
      |> AcuScheduleMember.changeset(params)
      |> Repo.insert()
  end

  # def bgworker_loa(acu_schedule, user_id) do
  #   Enum.into(acu_schedule.acu_schedule_members, [], fn(asm) ->
  #     if asm.status != "removed" do
  #       create_acu_loa(user_id, asm.member_id, acu_schedule.id)
  #     end
  #   end)
  # end

  def get_package_by_products_and_facility(product_codes, facility_id, member_ids) do
    packages =
      Product
      |> join(:inner, [pr], ap in AccountProduct, pr.id == ap.product_id)
      |> join(:inner, [pr, ap], mp in MemberProduct, ap.id == mp.account_product_id)
      |> join(:inner, [pr, ap, mp], m in Member, mp.member_id == m.id)
      |> join(:inner, [pr, ap, mp, m], pb in ProductBenefit, pr.id == pb.product_id)
      |> join(:inner, [pr, ap, mp, m, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
      |> join(:inner, [pr, ap, mp, m, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
      |> join(:inner, [pr, ap, mp, m, pb, bp, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [pr, ap, mp, m, pb, bp, pf, p], f in Facility, pf.facility_id == f.id)
      |> where([pr, ap, mp, m, pb, bp, pf, p, f], pr.code in ^product_codes and
        f.step > 6 and f.status == "Affiliated"
        and f.id == ^facility_id
        and pf.facility_id == ^facility_id
        and m.id in ^member_ids
      )
      |> where([pr, ap, mp, m, pb, bp, pf, p, f], fragment("? is distinct from null", pf.rate))
      |> select([pr, ap, mp, m, pb, bp, pf, p, f], [p.id, pf.rate, pf.facility_id, pr.id])
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def insert_acu_schedule_packages(params) do
    %AcuSchedulePackage{}
    |> AcuSchedulePackage.changeset(params)
    |> Repo.insert()
  end

  def update_acu_schedule_package_rate(params) do
    acu_schedule_package = get_acu_schedule_package(params["id"])
    params = %{
      rate: Decimal.new(String.replace(params["rate"], ",", ""))
    }
    acu_schedule_package
    |> AcuSchedulePackage.changeset_rate(params)
    |> Repo.update()
  end

  def get_acu_schedule_package(id) do
    AcuSchedulePackage
    |> Repo.get(id)
  end

  def get_all_acu_schedule_packages(acu_schedule_id) do
    AcuSchedulePackage
    |> where([asp], asp.acu_schedule_id == ^acu_schedule_id)
    |> Repo.all()
    |> Repo.preload(:package)
  end

  def get_acu_schedule_package_by_acu_and_package(id, package_id) do
    AcuSchedulePackage
    |> where([asp], asp.id == ^id and asp.package_id == ^package_id)
    |> Repo.one()
  end

  def update_asm_status(asm_ids, status) do
    asm_count =
      asm_ids
      |> Enum.count()

    if asm_count >= 5000 do
      lists =
        asm_ids
        |> partition_list(4999, [])

        Enum.map(lists, fn(x) ->
          AcuScheduleMember
          |> where([asm], asm.id in ^x)
          |> Repo.update_all(set: [status: nil])
        end)
    else
      AcuScheduleMember
      |> where([asm], asm.id in (^asm_ids))
      |> Repo.update_all(set: [status: nil])
    end
  end

  def update_removed_asm_status(asm_ids), do: update_removed_asm_status2(Enum.count(asm_ids), asm_ids)

  defp update_removed_asm_status2(1, asm_ids), do: update_removed_status(asm_ids)
  defp update_removed_asm_status2(count, asm_ids) when count >= 5000, do: update_many_removed_status(asm_ids)
  defp update_removed_asm_status2(_, asm_ids), do: update_removed_status2(asm_ids)

  defp update_removed_status(asm_ids) do
    id =
      asm_ids
      |> Enum.at(0)

    asm =
      AcuScheduleMember
      |> Repo.get_by(id: id)
      |> Repo.preload([
        acu_schedule: [
          [acu_schedule_products: :product],
          :account_group
        ]
      ])

    recall_available_packages = new_get_active_members_by_type(
      asm.acu_schedule.facility_id,
      asm.acu_schedule.member_type |> String.split(" and "),
      asm.acu_schedule.acu_schedule_products |> Enum.map(&(&1.product.code)),
      asm.acu_schedule.account_group.code,
      asm.member_id
    )

    asm
    |> Ecto.Changeset.change(%{status: "removed", package_code: recall_available_packages})
    |> Repo.update()
  end

  defp update_removed_status2(asm_ids) do
    AcuScheduleMember
    |> where([asm], asm.id in (^asm_ids))
    |> Repo.update_all(set: [status: "removed"])
  end

  defp update_many_removed_status(asm_ids) do
    lists =
      asm_ids
      |> partition_list(4999, [])

    Enum.map(lists, fn(x) ->
      AcuScheduleMember
      |> where([asm], asm.id in ^x)
      |> Repo.update_all(set: [status: nil])
    end)
  end

  def delete_all_as_products(acu_schedule_id) do
    AcuScheduleProduct
    |> where([asp], asp.acu_schedule_id == ^acu_schedule_id)
    |> Repo.delete_all()
  end

  def delete_all_as_members(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id)
    |> Repo.delete_all()
  end

  def delete_all_as_packages(acu_schedule_id) do
    AcuSchedulePackage
    |> where([asp], asp.acu_schedule_id == ^acu_schedule_id)
    |> Repo.delete_all()
  end

  def delete_acu_schedule(id) do
    AcuSchedule
    |> where([as], as.id == ^id)
    |> Repo.delete_all()
  end

  def update_acu_schedule(acu_schedule, params, user_id) do
    with {:ok, time_from} <- get_time(params["time_from"]),
         {:ok, time_to} <- get_time(params["time_to"]),
         account_group = %AccountGroup{} <- get_account_group(params["account_code"])
    do
      params =
        params
        |> Map.put("updated_by_id", user_id)
        |> Map.put("no_of_members", params["number_of_members_val"])
        |> Map.put("account_group_id", account_group.id)
        |> Map.put("time_from", cast_to_time(time_from))
        |> Map.put("time_to", cast_to_time(time_to))

      params =
        check_member_type(
          {Map.has_key?(params,  "principal"), Map.has_key?(params, "dependent")},
          params
        )
      acu_schedule
      |> AcuSchedule.changeset(params)
      |> Repo.update()
    else
      _ ->
        {:error}
    end
  end

  defp get_time(nil), do: {:error}
  defp get_time(value), do: {:ok, String.split(value, ":")}

  defp get_account_group(nil), do: {:error}
  defp get_account_group(account_code), do: AccountContext.get_account_by_code(account_code)

  defp cast_to_time(time) do
    Ecto.Time.cast!(%{
      hour: Enum.at(time, 0),
      minute: Enum.at(time, 1)
    })
  end

  defp check_member_type(member_type, params) do
    case member_type do
      {true, false} ->
        Map.put_new(params, "member_type", params["principal"])
      {false, true} ->
        Map.put_new(params, "member_type", params["dependent"])
      {true, true} ->
        Map.put_new(params, "member_type", "Principal and Dependent")
      _ ->
        Map.put_new(params, "member_type", nil)
    end
  end

  def update_acu_schedule_status(acu_schedule, status) do
    Repo.update(Changeset.change acu_schedule, status: status)
  end

  def get_all_acu_schedule_packages_id(acu_schedule_id) do
    AcuSchedulePackage
    |> where([asp], asp.acu_schedule_id == ^acu_schedule_id)
    |> select([asp], asp.id)
    |> Repo.all()
  end

  def get_acu_schedule_member_packages(acu_schedule_member_id) do
    member = MemberContext.get_a_member!(acu_schedule_member_id)
    member_benefit_package = member_benefit_package(member)

    if is_nil(member_benefit_package) do
      "Old data"
    else
      member_benefit_package.package.code
    end
  end

  def get_acu_schedule_product_by_product_id(product_id) do
    AcuScheduleProduct
    |> where([asp], asp.product_id == ^product_id)
    |> Repo.all()
  end

  def insert_acu_details(user, params) do
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    # asm = Enum.map(member.acu_schedule_members, &(if is_nil(&1.status), do: &1))
    asm = get_acu_schedule_member_by_acu_and_member(params["acu_schedule_id"], member.id)
    with coverage = %Coverage{} <- CoverageContext.get_coverage_by_code(coverage_code) do
      member_products = if is_nil(asm.package_code) || asm.package_code == "" do
        member_products =
          for member_product <- member.products do
            member_product
          end

        member_products =
          member_products
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.flatten()
      else
          get_member_product_by_package(member, asm.acu_schedule, asm.package_code)
      end

      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member_products,
          coverage.id
        )

      product = member_product.account_product.product
      product_benefit =
        MemberContext.get_acu_package_based_on_member(
          member,
          member_product
        )
      pbl = ProductContext.get_product_benefit(product_benefit.id).product_benefit_limits

      limit_amount = if Enum.empty?(pbl) do
        limit_amount = Decimal.new(0)
      else

        product_benefit_limit =
          pbl
          |> List.first()

        limit_amount = product_benefit_limit.limit_amount || Decimal.new(0)
      end

      benefit = product_benefit.benefit
      benefit_package =
        MemberContext.get_acu_package_based_on_member_for_schedule(
          member,
          member_product
        )

      benefit_package = benefit_package
                        |> List.first()

      package = benefit_package.package
      payor_procedures = payor_procedures(package, member)

      with true <- AuthorizationAPI.validate_acu(member, coverage),
           true <- AuthorizationAPI.validate_acu_pf_schedule(facility.id, member.id, coverage, product_benefit)
      do
        package_facility_rate =
          package_facility_rate(
            package.package_facility,
            facility.id
          )

        package =
          package
          |> Map.merge(%{package_facility_rate: package_facility_rate})

        benefit =
          benefit
          |> Map.merge(%{limit_amount: limit_amount})

        authorization_params = %{
          "member_id" => member.id,
          "facility_id" => facility.id,
          "coverage_id" => coverage.id,
          "step" => 3,
          "created_by_id" => user.id,
          "origin" => origin
        }

        with {:ok, authorization} <-
          AuthorizationContext.create_authorization_api(
            user.id,
            authorization_params
          )
        do
          {authorization, benefit, benefit_package, package, payor_procedures, product}
        else
          _ ->
            {:error_inserting_acu}
        end
      else
        false ->
          {:error, "Failed in loa first validation"}
        {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."} ->
          {:error, "Member is not eligible to avail ACU in this Hospital / Clinic."}
        {:invalid_coverage, "No package facility rate setup."} ->
          {:error, "No package facility rate setup"}
        {:invalid_coverage, "Member is not eligible to avail ACU. Reason: Package is not available in this facility."} ->
          {:error, "Member is not eligible to avail ACU. Reason: Package is not available in this facility."}
        _ ->
          {:error, "Error in ACU setup"}
      end
    else
      _ ->
        {:error, "No coverage"}
    end
  end

  def get_member_product_by_package(member, acu_schedule, package_code) do
    AcuSchedule
    |> join(:inner, [as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:inner, [as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:inner, [as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:inner, [as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:inner, [as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:inner, [as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> join(:inner, [as, asp, pr, pb, b, bp, p], ap in AccountProduct, pr.id == ap.product_id)
    |> join(:inner, [as, asp, pr, pb, b, bp, p, ap], mp in MemberProduct, mp.account_product_id == ap.id)
    |> join(:inner, [as, asp, pr, pb, b, bp, p, ap, mp], m in Member, mp.member_id == m.id)
    |> where([as, asp, pr, pb, b, bp, p, ap, mp, m], as.id == ^acu_schedule.id and p.code == ^package_code and m.id == ^member.id)
    |> distinct([as, asp, pr, pb, b, bp, p, ap, mp, m], mp.id)
    |> select([as, asp, pr, pb, b, bp, p, ap, mp, m], mp)
    |> Repo.all()
    |> Repo.preload([
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
      ])
  end

  def update_request_acu(user, params) do
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    discharge_date = params["discharge_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

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
    product_benefit =
      MemberContext.get_acu_package_based_on_member(
        member,
        member_product
      )

    benefit = product_benefit.benefit
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()
    package = benefit_package.package

    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )
    acu_params = %{
      authorization_id: authorization.id,
      user_id: user.id,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: "",
      benefit_package_id: benefit_package.id,
      admission_date: admission_date,
      discharge_date: discharge_date,
      product_id: product.id,
      product: product,
      internal_remarks: authorization.internal_remarks,
      valid_until: valid_until,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: origin,
      product_benefit: product_benefit
    }

    acu_params = if is_nil(params["acu_schedule_id"]) do
      acu_params
    else
      acu_params
      |> Map.put_new(:acu_schedule_id, params["acu_schedule_id"])
    end
    with {:ok, changeset} <- ACUValidator.request_acu(acu_params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(
          changeset.changes.authorization_id
        )
       {:ok, authorization} = AuthorizationAPI.update_status_to_approved(authorization_id)
       {:ok, authorization}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, "Error inserting loa 2nd validation"}
      {:invalid_coverage, error} ->
        {:error, error}
      _ ->
        {:error, "Error in setup loa 2nd validation"}
    end
  end

  def payor_procedures(package, member) do
    age = UtilityContext.age(member.birthdate)

    payor_procedure = for ppp <- package.package_payor_procedure do
      if (ppp.male and member.gender == "Male") or
      (ppp.female and member.gender == "Female") do
        if age >= ppp.age_from and age <= ppp.age_to do
          ppp.payor_procedure
        end
      end
    end

    _payor_procedure =
      payor_procedure
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten
  end

  def package_facility_rate(package_facilities, facility_id) do
    if Enum.count(package_facilities) > 1 do
      rate = for package_facility <- package_facilities do
        if package_facility.facility_id == facility_id do
          package_facility.rate
        end
      end

      rate =
        rate
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
    else
      package_facility = List.first(package_facilities)
      rate = package_facility.rate
    end
  end

  def delete_acu_schedule_member(acu_schedule_id, member_ids) do
    for member_id <- member_ids do
      AcuScheduleMember
      |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and asm.member_id == ^member_id)
      |> Repo.delete_all()
    end
  end

  def update_acu_schedule_member(acu_schedule_id, member_ids) do
    for member_id <- member_ids do
      AcuScheduleMember
      |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and asm.member_id == ^member_id)
      |> Repo.update_all(set: [status: "removed"])
    end
  end

  def get_all_acu_schedule_member_ids(acu_schedule_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> select([asm], asm.member_id)
    |> Repo.all()
  end

  def get_all_asm_members_for_modal(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      # fragment("? = coalesce(?, ?)", m.birthdate, ^"%#{params}%", m.birthdate) or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> order_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: p.code, status: asm.status})
    |> offset(^offset)
    |> limit(100)
    |> Repo.all()
  end

  def get_all_removed_asm_members_for_modal(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      # fragment("? = coalesce(?, ?)", m.birthdate, ^"%#{params}%", m.birthdate) or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> order_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: p.code})
    |> offset(^offset)
    # |> limit(100)
    |> Repo.all()
  end

  def get_all_acu_schedules_index do
    AcuSchedule
    |> join(:left, [as], c in Cluster, c.id == as.cluster_id)
    |> join(:left, [as, c], f in Facility, f.id == as.facility_id)
    |> join(:left, [as, c, f], ag in AccountGroup, ag.id == as.account_group_id)
    |> join(:left, [as, c, f, ag], u in User, u.id == as.created_by_id)
    |> order_by([as], desc: as.updated_at)
    |> select([as, c, f, ag, u], %{
        id: as.id, facility_code: f.code, facility_name: f.name,
        account_group_code: ag.code, account_group_name: ag.name, created_by: u.username,
        batch_no: as.batch_no, status: as.status, date_from: as.date_from, date_to: as.date_to,
        time_from: as.time_from, time_to: as.time_to, no_of_guaranteed: as.no_of_guaranteed,
        no_of_members: as.no_of_members, inserted_at: as.inserted_at,
        cluster_code: c.code, cluster_name: c.name, guaranteed_amount: as.guaranteed_amount
        })
    |> Repo.all()
  end

  def update_selected_members(acu_schedule, selected_members) do
    selected_members = String.to_integer(selected_members)
    Repo.update(Changeset.change acu_schedule, no_of_selected_members: selected_members)
  end

  def get_rate(package_id, acu_schedule_id) do
    AcuSchedulePackage
    |> where([asp], asp.package_id == ^package_id and asp.acu_schedule_id == ^acu_schedule_id)
    |> select([asp], asp.rate)
    |> Repo.one
  end

  def get_guaranteed_amount(acu_schedule_members, acu_schedule_id) do
    acu_schedule_members
    |> Enum.reject(&(&1.status == "removed"))
    |> Enum.into([], &(get_package_id(&1.member_id)))
    |> Enum.into([], &(get_rate(&1, acu_schedule_id)))
    |> Enum.reduce(fn(x, acc) -> Decimal.add(x, acc) end)
  end

  def get_package_id(member_id) do
    member = MemberContext.get_a_member!(member_id)
    coverage = CoverageContext.get_coverage_by_code("ACU")

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
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()
    benefit_package.package_id
  end

  # LOAD

  def create_acu_schedule_members_batch(members, acu_schedule) do
    acu_schedule_members = Enum.map(members, fn(member) ->
      if Map.has_key?(member, :package_code) do
        %{
          member_id: member.id,
          acu_schedule_id: acu_schedule.id,
          inserted_at: Ecto.DateTime.utc(),
          updated_at: Ecto.DateTime.utc(),
          package_code: member.package_code
        }
      else
        %{
          member_id: member.id,
          acu_schedule_id: acu_schedule.id,
          inserted_at: Ecto.DateTime.utc(),
          updated_at: Ecto.DateTime.utc()
        }
      end
    end)

    asm_count =
      acu_schedule_members
      |> Enum.count()

    if asm_count >= 5000 do
      lists =
        acu_schedule_members
        |> partition_list(4999, [])

        Enum.map(lists, fn(x) ->
          AcuScheduleMember
          |> Repo.insert_all(x)
        end)
    else
      AcuScheduleMember
      |> Repo.insert_all(acu_schedule_members)
    end
  end

  defp partition_list([], limit, result), do: result
  defp partition_list(list, limit, result) do

    temp = Enum.slice(list, 0..limit)
    result = result ++ [temp]
    temp_result = list -- temp

    partition_list(temp_result, limit, result)
  end

  # LOAD DATATABLE

  # LOAD MEMBERS

  def get_clean_asm_count(params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", m.birthdate), ^"%#{params}%") or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> group_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> Repo.all()
    |> Enum.uniq()
    |> Enum.count()
  end

  def get_clean_asm(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", m.birthdate), ^"%#{params}%") or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> order_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: p.code, status: asm.status})
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_cols([])
  end

  defp convert_to_tbl_cols([head | tails], tbl) do
    delete_button = generate_delete_button(head.id)
    tbl =
      tbl ++ [[
        head.card_no,
        Enum.join([head.first_name, head.middle_name, head.last_name], " "),
        head.gender,
        UtilityContext.convert_date_format(head.birthdate),
        get_age(head.birthdate),
        head.package,
        delete_button
      ]]

    convert_to_tbl_cols(tails, tbl)
  end
  defp convert_to_tbl_cols([], tbl), do: tbl

  defp generate_delete_button(id),
    do:
      "<a class='clickable-row asm_update_status' href='#'' asm_id='#{id}' id='asm_update_status' ><i class='red trash icon'></i></a>"

  # LOAD MEMBERS SHOW

  def get_clean_asm_show(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status))
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", m.birthdate), ^"%#{params}%") or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> order_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: p.code, status: asm.status})
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_cols([])
  end

  defp convert_to_tbl_cols([head | tails], tbl) do
    tbl =
      tbl ++ [[
        head.card_no,
        Enum.join([head.first_name, head.middle_name, head.last_name], " "),
        head.gender,
        head.birthdate,
        get_age(head.birthdate),
        head.package
      ]]

    convert_to_tbl_cols(tails, tbl)
  end
  defp convert_to_tbl_cols([], tbl), do: tbl

  # LOAD REMOVED MEMBERS

  def get_clean_removed_asm_count(params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", m.birthdate), ^"%#{params}%") or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> select([asm, m, as, asp, pr, pb, b, bp, p], count(asm.id))
    |> Repo.one()
  end

  def get_clean_removed_asm(offset, limit, params, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> where([asm, m, as, asp, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m, as, asp, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", m.birthdate), ^"%#{params}%") or
      # fragment("EXTRACT(YEAR FROM age(cast(? as date))) = ?", m.birthdate, ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> distinct([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> order_by([asm, m, as, asp, pr, pb, b, bp, p], asm.id)
    |> select([asm, m, as, asp, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: p.code, status: asm.status})
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_asm_removed_cols([])
  end

  defp convert_to_tbl_asm_removed_cols([head | tails], tbl) do
    checkbox = generate_checkbox(head.id)
    tbl =
      tbl ++ [[
        checkbox,
        head.card_no,
        Enum.join([head.first_name, head.middle_name, head.last_name], " "),
        head.gender,
        UtilityContext.convert_date_format(head.birthdate),
        get_age(head.birthdate),
        head.package
      ]]

      convert_to_tbl_asm_removed_cols(tails, tbl)
  end
  defp convert_to_tbl_asm_removed_cols([], tbl), do: tbl

  defp generate_checkbox(id),
    do:
    "<input id='acu_sched_id' type='checkbox' value='#{id}' class='selection'>"

  def new_create_acu_schedule(params, user_id) do
    time_from = String.split(params["time_from"], ":")
    time_to = String.split(params["time_to"], ":")
    account_group = AccountContext.get_account_by_code(params["account_code"])
    guaranteed_amount = if String.contains?(params["guaranteed_amount"], ",") do
      params["guaranteed_amount"]
      |> String.split(",")
      |> Enum.join()
    else
      params["guaranteed_amount"]
    end

    if account_group == {:account_not_found} do
      {:account_not_found}
    else
      params =
        params
        |> Map.put("no_of_selected_members", params["no_of_selected_members"])
        |> Map.put("created_by_id", user_id)
        |> Map.put("updated_by_id", user_id)
        |> Map.put("no_of_members", params["number_of_members_val"])
        |> Map.put("batch_no", generate_random_batch_no)
        |> Map.put("account_group_id", account_group.id)
        |> Map.put("time_from", cast_to_time(time_from))
        |> Map.put("time_to", cast_to_time(time_to))
        |> Map.put("guaranteed_amount", guaranteed_amount)

        params =
          check_member_type(
            {Map.has_key?(params,  "principal"), Map.has_key?(params, "dependent")},
            params
          )

          %AcuSchedule{}
          |> AcuSchedule.new_changeset(params)
          |> Repo.insert()
    end
  end

  def new_create_acu_schedule_member(acu_schedule_id, product_code, account_code) do
    acu_schedule = get_acu_schedule(acu_schedule_id)

    cond do
      acu_schedule.member_type == "Principal" ->
        member_type = ["Principal"]
      acu_schedule.member_type == "Dependent" ->
        member_type = ["Dependent"]
      true ->
        member_type = ["Principal", "Dependent"]
    end

    members = new_get_active_members_by_type(acu_schedule.facility_id, member_type, product_code, account_code)
  end

  def new_update_acu_schedule(acu_schedule, params, user_id) do
    time_from = String.split(params["time_from"], ":")
    time_to = String.split(params["time_to"], ":")
    account_group = AccountContext.get_account_by_code(params["account_code"])
    guaranteed_amount = if String.contains?(params["guaranteed_amount"], ",") do
      params["guaranteed_amount"]
      |> String.split(",")
      |> Enum.join()
    else
      params["guaranteed_amount"]
    end
    updated_at = DateTime.utc_now()
    params =
      params
      |> Map.put("updated_by_id", user_id)
      |> Map.put("no_of_members", params["number_of_members_val"])
      |> Map.put("account_group_id", account_group.id)
      |> Map.put("time_from", cast_to_time(time_from))
      |> Map.put("time_to", cast_to_time(time_to))
      |> Map.put("guaranteed_amount", guaranteed_amount)
      |> Map.put("updated_at", updated_at)

    params =
      check_member_type(
        {Map.has_key?(params,  "principal"), Map.has_key?(params, "dependent")},
        params
      )
    acu_schedule
    |> AcuSchedule.new_changeset(params)
    |> Repo.update()
  end

  def new_get_all_asm_members_for_modal(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], mp in MemberProduct, m.id == mp.member_id)
    |> join(:left, [asm, m, as, asp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:left, [asm, m, as, asp, mp, ap], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and is_nil(asm.status) and ap.product_id == pr.id)
    |> where(
      [asm, m, as, asp, mp, ap, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%")
    )
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (fragment("date_part('year', age(?))",
               m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (bp.male == true and m.gender == "Male") or
                        (bp.female == true and m.gender == "Female"))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf], pf.facility_id == as.facility_id)
    |> distinct([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [asm.id])
    |> order_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.id)
    |> group_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [asm.id, m.id, m.card_no, m.first_name, m.middle_name, m.last_name, m.gender, m.birthdate, asm.status])
    |> select([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: fragment("string_agg(DISTINCT CONCAT(?), ', ')", p.code), status: asm.status})
    |> offset(^offset)
    # |> limit(^limit)
    |> Repo.all
  end

  ###### as of 10102018 this is an unused function, proceed to its v3 below for new fetching of acu_schedule_members
  def get_all_removed_asm_members_for_modal_v2(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], mp in MemberProduct, m.id == mp.member_id)
    |> join(:left, [asm, m, as, asp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:left, [asm, m, as, asp, mp, ap], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf], a in Authorization, a.member_id == m.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf, a], abp in AuthorizationBenefitPackage, (abp.authorization_id == a.id) and (abp.benefit_package_id == bp.id))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed" and ap.product_id == pr.id)
    |> where(
      [asm, m, as, asp, mp, ap, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("to_char(extract(year from age(cast(? as date))), ?)", m.birthdate, "9999"), ^"%#{params}%")
    )
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (fragment("date_part('year', age(?))",
               m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (bp.male == true and m.gender == "Male") or
             (bp.female == true and m.gender == "Female"))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf], pf.facility_id == as.facility_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf, a, abp], is_nil(abp.benefit_package_id))
    |> distinct([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [m.id])
    |> order_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.id)
    |> group_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [asm.id, m.id, m.card_no, m.first_name, m.middle_name, m.last_name, m.gender, m.birthdate, asm.status, p.code])
    |> select([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: fragment("string_agg(DISTINCT CONCAT(?), ', ')", p.code), status: asm.status})
    |> offset(^offset)
    |> limit(100)
    |> Repo.all
  end

  ####### new v3 / modal removed members
  def get_all_removed_asm_members_for_modal_v3(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed")
    |> where(
      [asm, m],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(asm.package_code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("to_char(extract(year from age(cast(? as date))), ?)", m.birthdate, "9999"), ^"%#{params}%")
    )
    |> order_by([asm, m], asm.id)
    |> select([asm, m], %{
      id: asm.id,
      member_id: m.id,
      card_no: m.card_no,
      first_name: m.first_name,
      middle_name: m.middle_name,
      last_name: m.last_name,
      gender: m.gender,
      birthdate: m.birthdate,
      package: asm.package_code,
      status: asm.status
    })
    |> offset(^offset)
    |> limit(100)
    |> Repo.all
  end

  def new_get_all_removed_asm_members_for_modal(params, offset, acu_schedule_id) do
    AcuScheduleMember
    |> join(:left, [asm], m in Member, m.id == asm.member_id)
    |> join(:left, [asm, m], as in AcuSchedule, as.id == asm.acu_schedule_id)
    |> join(:left, [asm, m, as], asp in AcuScheduleProduct, asp.acu_schedule_id == as.id)
    |> join(:left, [asm, m, as, asp], mp in MemberProduct, m.id == mp.member_id)
    |> join(:left, [asm, m, as, asp, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:left, [asm, m, as, asp, mp, ap], pr in Product, pr.id == asp.product_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr], pb in ProductBenefit, pb.product_id == pr.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b], bp in BenefitPackage, bp.benefit_id == b.id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp], p in Package, p.id == bp.package_id)
    |> join(:left, [asm, m, as, asp, mp, ap, pr, pb, b, bp, p], pf in PackageFacility, p.id == pf.package_id)
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.acu_schedule_id == ^acu_schedule_id and asm.status == ^"removed" and ap.product_id == pr.id)
    |> where(
      [asm, m, as, asp, mp, ap, pr, pb, b, bp, p],
      ilike(m.card_no, ^"%#{params}%") or
      ilike(m.gender, ^"%#{params}%") or
      ilike(p.code, ^"%#{params}%") or
      ilike(fragment("lower(?)", fragment("concat(?, ' ', ?)", m.first_name, m.last_name)), ^"%#{params}%") or
      ilike(m.card_no, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", m.birthdate), ^"%#{params}%") or
      ilike(fragment("to_char(extract(year from age(cast(? as date))), ?)", m.birthdate, "9999"), ^"%#{params}%")
    )
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (fragment("date_part('year', age(?))",
               m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], (bp.male == true and m.gender == "Male") or
             (bp.female == true and m.gender == "Female"))
    |> where([asm, m, as, asp, mp, ap, pr, pb, b, bp, p, pf], pf.facility_id == as.facility_id)
    |> distinct([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [asm.id])
    |> order_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], asm.id)
    |> group_by([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], [asm.id, m.id, m.card_no, m.first_name, m.middle_name, m.last_name, m.gender, m.birthdate, asm.status])
    |> select([asm, m, as, asp, mp, ap, pr, pb, b, bp, p], %{id: asm.id, member_id: m.id, card_no: m.card_no, first_name: m.first_name, middle_name: m.middle_name, last_name: m.last_name, gender: m.gender, birthdate: m.birthdate, package: fragment("string_agg(DISTINCT CONCAT(?), ', ')", p.code), status: asm.status})
    |> offset(^offset)
    # |> limit(^limit)
    |> Repo.all
  end

  #### ongoing refactor upon saving an acu_schedule
  def new_get_active_members_by_type(facility_id, member_type, product_codes, account_code) do
    account_group = AccountContext.get_account_by_code(account_code)
    acu_products = get_products_by_facility(product_codes, facility_id)

    Member
    |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
    |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [m, mp, ap], a in Account, ap.account_id == a.id)
    |> join(:inner, [m, mp, ap, a], ag in AccountGroup, ag.id == a.account_group_id)
    |> join(:inner, [m, mp, ap, a, ag], p in Product, ap.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p], pb in ProductBenefit, pb.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf], pk in Package, pk.id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf, pk], f in Facility, pf.facility_id == f.id)
    # |> join(:left, [m, mp, ap, a, ag, p, pb, bp, pf, pk, f], au in subquery( get_available_packages() ), pk.code == au.code and au.member_id == m.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], pf.facility_id == ^facility_id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], mp.is_acu_consumed == false or is_nil(mp.is_acu_consumed))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (fragment("date_part('year', age(?))", m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (bp.male == true and m.gender == "Male") or (bp.female == true and m.gender == "Female"))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], p.code in ^acu_products and m.type in ^member_type)
    |> where([m, mp, ap, a, ag, p], a.account_group_id == ^account_group.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.status == "Active")
    # |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], is_nil(au.code))
    |> order_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> group_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> select([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], %{id: m.id, package_code: fragment("string_agg(DISTINCT CONCAT(?), ', ')", pk.code)})
    |> Repo.all()
  end

  def new_get_active_members_by_type_count(facility_id, member_type, product_codes, account_code) do
    account_group = AccountContext.get_account_by_code(account_code)
    acu_products = get_products_by_facility(product_codes, facility_id)

    Member
    |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
    |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [m, mp, ap], a in Account, ap.account_id == a.id)
    |> join(:inner, [m, mp, ap, a], ag in AccountGroup, ag.id == a.account_group_id)
    |> join(:inner, [m, mp, ap, a, ag], p in Product, ap.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p], pb in ProductBenefit, pb.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf], pk in Package, pk.id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf, pk], f in Facility, pf.facility_id == f.id)
    # |> join(:left, [m, mp, ap, a, ag, p, pb, bp, pf, pk, f], au in subquery( get_available_packages() ), pk.code == au.code and au.member_id == m.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], pf.facility_id == ^facility_id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], mp.is_acu_consumed == false or is_nil(mp.is_acu_consumed))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (fragment("date_part('year', age(?))", m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (bp.male == true and m.gender == "Male") or (bp.female == true and m.gender == "Female"))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], p.code in ^acu_products and m.type in ^member_type)
    |> where([m, mp, ap, a, ag, p], a.account_group_id == ^account_group.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.status == "Active")
    # |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], is_nil(au.code))
    |> order_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> group_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> select([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], %{id: m.id, package_code: fragment("string_agg(DISTINCT CONCAT(?), ', ')", pk.code)})
    |> Repo.all()
    |> Enum.count()
  end

  def new_get_active_members_by_type(facility_id, member_type, product_codes, account_code, member_id) do
    account_group = AccountContext.get_account_by_code(account_code)
    acu_products = get_products_by_facility(product_codes, facility_id)

    Member
    |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
    |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
    |> join(:inner, [m, mp, ap], a in Account, ap.account_id == a.id)
    |> join(:inner, [m, mp, ap, a], ag in AccountGroup, ag.id == a.account_group_id)
    |> join(:inner, [m, mp, ap, a, ag], p in Product, ap.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p], pb in ProductBenefit, pb.product_id == p.id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf], pk in Package, pk.id == bp.package_id)
    |> join(:inner, [m, mp, ap, a, ag, p, pb, bp, pf, pk], f in Facility, pf.facility_id == f.id)
    # |> join(:left, [m, mp, ap, a, ag, p, pb, bp, pf, pk, f], au in subquery( get_available_packages() ), pk.code == au.code and au.member_id == m.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], pf.facility_id == ^facility_id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], mp.is_acu_consumed == false or is_nil(mp.is_acu_consumed))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (fragment("date_part('year', age(?))", m.birthdate) >= bp.age_from) and (fragment("date_part('year', age(?))", m.birthdate) <= bp.age_to))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], (bp.male == true and m.gender == "Male") or (bp.female == true and m.gender == "Female"))
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], p.code in ^acu_products and m.type in ^member_type)
    |> where([m, mp, ap, a, ag, p], a.account_group_id == ^account_group.id)
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.status == "Active")
    |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id == ^member_id)
    # |> where([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], is_nil(au.code))
    |> order_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> group_by([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], m.id)
    |> select([m, mp, ap, a, ag, p, pb, bp, pf, pk, f, au], fragment("string_agg(DISTINCT CONCAT(?), ', ')", pk.code))
    |> Repo.one()
  end

  defp get_available_packages() do
    Member
    |> join(:inner, [m], a in Authorization, m.id == a.member_id)
    |> join(:inner, [m, a], abp in AuthorizationBenefitPackage, a.id == abp.authorization_id)
    |> join(:inner, [m, a, abp], bp in BenefitPackage, bp.id == abp.benefit_package_id)
    |> join(:inner, [m, a, abp, bp], p in Package, bp.package_id == p.id)
    |> select([m, a, abp, bp, p], %{member_id: m.id, code: p.code})
  end

  def update_acu_schedule_member_package(asm_ids, package_code) do
    if asm_ids |> Enum.count() >= 5000 do
        asm_ids
        |> partition_list(4999, [])
        |> Enum.map(fn(x) ->
          AcuScheduleMember
          |> where([asm], asm.id in ^x)
          |> Repo.update_all(set: [package_code: package_code])
        end)
    else
      AcuScheduleMember
      |> where([asm], asm.id in ^asm_ids)
      |> Repo.update_all(set: [package_code: package_code])
    end
  end

  def new_update_selected_members(acu_schedule, params) do
    selected_members = String.to_integer(params["no_of_selected_members"])
    no_of_guaranteed = String.to_integer(params["no_of_guaranteed"])
    Repo.update(Changeset.change acu_schedule, %{no_of_selected_members: selected_members, no_of_guaranteed: no_of_guaranteed})
  end

  defp check_adjustment_rate(""), do: Decimal.new(0)
  defp check_adjustment_rate(nil), do: Decimal.new(0)
  defp check_adjustment_rate(adjustment_rate) do
      adjustment_rate
      |> String.split(",")
      |> Enum.join()
      |> Decimal.new()
    rescue
     _ ->
      Decimal.new(0)
  end


  def new_update_acu_schedule_package_rate(params) do
    if ((params["adjustment_type"] == "" or params["adjustment_rate"] == "") or (is_nil(params["adjustment_type"]) or is_nil(params["adjustment_type"]))) do
      {:error, %{}}
    else
      asp = get_acu_schedule_package(params["id"])
      params = if params["adjustment_type"] == "Add" do
        %{
          rate: Decimal.add(asp.rate, check_adjustment_rate(params["adjustment_rate"]))
        }
      else
        %{
          rate: Decimal.sub(asp.rate, check_adjustment_rate(params["adjustment_rate"]))
        }
      end
      asp
      |> AcuSchedulePackage.changeset_rate(params)
      |> Repo.update()
    end
  end

  def new_acu_schedule_api_params(acu_schedule) do
    # guaranteed_amount = get_guaranteed_amount(acu_schedule.acu_schedule_members, acu_schedule.id)
    # Repo.update(Ecto.Changeset.change acu_schedule, guaranteed_amount: guaranteed_amount)
    user = acu_schedule.created_by
    aga = AccountContext.get_account_group_address!(acu_schedule.account_group.id, "Account Address")
    md =
      if not is_nil(user.middle_name) do
         user.middle_name
      else
        ""
      end
    user_fullname = Enum.join([user.first_name, md, user.last_name], " ")
    %{
      "facility_id" => acu_schedule.facility.id,
      "account_code" => acu_schedule.account_group.code,
      "account_name" => acu_schedule.account_group.name,
      "batch_no" => acu_schedule.batch_no,
      "created_by" => user.username,
      "date_from" => acu_schedule.date_from,
      "date_to" => acu_schedule.date_to,
      # "members" => Enum.map(acu_schedule.acu_schedule_members, fn(acu_member) ->
      #   %{"member_id" => acu_member.member.id,
      #     "benefit_package_id" => member_benefit_package(acu_member.member).id,
      #     "member_first_name" => acu_member.member.first_name,
      #     "member_middle_name" => acu_member.member.middle_name,
      #     "member_last_name" => acu_member.member.last_name,
      #     "member_suffix" => acu_member.member.suffix,
      #     "member_birth_date" => acu_member.member.birthdate,
      #     "member_age" => UtilityContext.age(acu_member.member.birthdate),
      #     "member_card_no" => acu_member.member.card_no,
      #     "member_evoucher_number" => acu_member.member.evoucher_number,
      #     "member_evoucher_qr_code" => acu_member.member.evoucher_qr_code,
      #     "member_status" => acu_member.member.status,
      #     "member_evoucher_number" => acu_member.member.evoucher_number,
      #     "member_email" => Enum.join([acu_member.member.email, acu_member.member.email2], ", "),
      #     "member_mobile" => Enum.join([acu_member.member.mobile, acu_member.member.mobile2], ", "),
      #     "member_type" => acu_member.member.type,
      #     "member_account_code" => acu_member.member.account_group.code,
      #     "member_account_name" => acu_member.member.account_group.name,
      #     "member_gender" => acu_member.member.gender,
      #     "member_attempts" => acu_member.member.attempts,
      #     "member_attempt_expiry" => acu_member.member.attempt_expiry
      #   }
      #   end),
      "no_of_guaranteed" => acu_schedule.no_of_guaranteed,
      "no_of_members" => acu_schedule.no_of_members,
      "no_of_selected_members" => acu_schedule.no_of_selected_members,
      "guaranteed_amount" => acu_schedule.guaranteed_amount,
      "packages" => Enum.concat(Enum.map(acu_schedule.acu_schedule_products, fn(asp) ->
          get_benefit_package(asp.product.product_benefits)
      end)),
      "payorlink_acu_schedule_id" => acu_schedule.id,
      "time_from" => acu_schedule.time_from,
      "time_to" => acu_schedule.time_to,
      "account_address" => Enum.join([aga.line_1, aga.line_2, aga.city, aga.province, aga.region, aga.country, aga.postal_code], " ")
    }
  end

  def providerlink_sign_in_v2 do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    providerlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(providerlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Providerlink"}
    end
  end

  def request_acu_provider_api(acu_schedule_id, params, token, task_acu_sched) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/acu_schedules/#{acu_schedule_id}/insert_schedule_member_from_payorlink"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(params)

    with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
         200 <- response.status_code
    do
      {:ok, response}
      keys = "#{params.member_first_name} #{params.member_last_name}, #{params.member_card_no}, #{params.member_birth_date}"

      acu_schedule_id
      |> log_params(params.member_id, keys)
      |> insert_acu_log()

      task_acu_sched.updated_by_id
      |> task_acu_schedule_update_params("Success #{keys}")
      |> update_task_acu_schedule(task_acu_sched)

    else
      {:error, response} ->
        acu_schedule_id
        |> log_params(params["member_id"], response)
        |> insert_acu_log()

        task_acu_sched.updated_by_id
        |> task_acu_schedule_update_params("Error #{response}")
        |> update_task_acu_schedule(task_acu_sched)

      _ ->
        acu_schedule_id
        |> log_params(params["member_id"], "Error occurs when attempting to insert LOA")
        |> insert_acu_log()

        task_acu_sched.updated_by_id
        |> task_acu_schedule_update_params("Error occurs when attempting to insert LOA")
        |> update_task_acu_schedule(task_acu_sched)
    end
  end

  def new_create_acu_schedule_members_batch(members, acu_schedule) do
    acu_schedule_members = Enum.map(members, fn(member) ->
      if Map.has_key?(member, :package_code) do
        %{
          member_id: member.id,
          acu_schedule_id: acu_schedule.id,
          inserted_at: Ecto.DateTime.utc(),
          updated_at: Ecto.DateTime.utc(),
          package_code: member.package_code,
          status: "removed"
        }
      end
    end)

    asm_count =
      acu_schedule_members
      |> Enum.count()

    if asm_count >= 5000 do
      lists =
        acu_schedule_members
        |> partition_list(4999, [])

        Enum.map(lists, fn(x) ->
          AcuScheduleMember
          |> Repo.insert_all(x)
        end)
    else
      AcuScheduleMember
      |> Repo.insert_all(acu_schedule_members)
    end
  end

  def get_acu_schedule_member_by_acu_and_member(acu_schedule_id, member_id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^acu_schedule_id  and asm.member_id == ^member_id)
    |> Repo.one()
    |> Repo.preload([:acu_schedule])
  end

  def new_get_package_by_products_and_facility(product_codes, facility_id, packages) do
    packages =
      Product
      |> join(:inner, [pr], ap in AccountProduct, pr.id == ap.product_id)
      |> join(:inner, [pr, ap], mp in MemberProduct, ap.id == mp.account_product_id)
      |> join(:inner, [pr, ap, mp], m in Member, mp.member_id == m.id)
      |> join(:inner, [pr, ap, mp, m], pb in ProductBenefit, pr.id == pb.product_id)
      |> join(:inner, [pr, ap, mp, m, pb], bp in BenefitPackage, pb.benefit_id == bp.benefit_id)
      |> join(:inner, [pr, ap, mp, m, pb, bp], pf in PackageFacility, pf.package_id == bp.package_id)
      |> join(:inner, [pr, ap, mp, m, pb, bp, pf], p in Package, pf.package_id == p.id)
      |> join(:inner, [pr, ap, mp, m, pb, bp, pf, p], f in Facility, pf.facility_id == f.id)
      |> where([pr, ap, mp, m, pb, bp, pf, p, f], pr.code in ^product_codes and
        f.step > 6 and f.status == "Affiliated"
        and f.id == ^facility_id
        and pf.facility_id == ^facility_id
        and p.code in ^packages
      )
      |> where([pr, ap, mp, m, pb, bp, pf, p, f], fragment("? is distinct from null", pf.rate))
      |> distinct([pr, ap, mp, m, pb, bp, pf, p, f], p.id)
      |> select([pr, ap, mp, m, pb, bp, pf, p, f], [p.id, pf.rate, pf.facility_id, pr.id])
      |> Repo.all()
      |> List.delete(nil)
  end

  def new_update_acu_schedule_status(acu_schedule, status) do
    updated_at = DateTime.utc_now()
    Repo.update(Changeset.change acu_schedule, status: status, updated_at: updated_at)
  end

  def update_acu_schedule_batch_id(nil, batch_id), do: false

  def update_acu_schedule_batch_id(batch_no, batch_id) do
    acu_schedule = Repo.get_by(AcuSchedule, batch_no: batch_no)
    Repo.update(Ecto.Changeset.change acu_schedule, batch_id: batch_id)
  end

  def get_selected_acu_schedule_members(id) do
    AcuScheduleMember
    |> where([asm], asm.acu_schedule_id == ^id  and is_nil(asm.status))
    |> select([asm], %{id: asm.id})
    |> Repo.all()
  end

  def get_package_by_asm(id) do
    AcuScheduleMember
    |> where([asm], asm.id == ^id)
    |> select([asm], asm.package_code)
    |> limit(1)
    |> Repo.one()
  end

  def get_asm_by_package_count(id, package) do
    AcuScheduleMember
    |> where([asm], asm.package_code == ^package)
    |> where([asm], asm.acu_schedule_id == ^id and is_nil(asm.status))
    |> Repo.all()
    |> Enum.count()
  end

  def job_acu_schedule_params(user_id, acu_schedule_id, task_count) do
    params = %{
      type: "batch_schedule",
      created_by_id: user_id,
      updated_by_id: user_id,
      task_count: task_count,
      start: DateTime.utc_now(),
      request: %{acu_schedule_id: acu_schedule_id}
    }
  end

  def task_acu_schedule_params(jacs_id, user_id, request) do
    params = %{
      created_by_id: user_id,
      updated_by_id: user_id,
      start: DateTime.utc_now(),
      request: request,
      job_acu_schedule_id: jacs_id
    }
  end

  def task_acu_schedule_update_params(user_id, result) do
    params = %{
      updated_by_id: user_id,
      finish: DateTime.utc_now(),
      result: %{result: result}
    }
  end

  def insert_job_acu_schedule(params)do
    %JobAcuSchedule{}
    |> JobAcuSchedule.changeset(params)
    |> Repo.insert()
  end

  def insert_task_acu_schedule(params)do
    %TaskAcuSchedule{}
    |> TaskAcuSchedule.changeset(params)
    |> Repo.insert()
  end

  def update_task_acu_schedule(params, task_acu_sched)do
    task_acu_sched
    |> TaskAcuSchedule.update_changeset(params)
    |> Repo.update()
  end

  defp get_task_acu_schedule_by_id(id) do
    TaskAcuSchedule
    |> Repo.get(id)
  end

  def get_job_acu_schedule_by_id(id) do
    JobAcuSchedule
    |> Repo.get(id)
  end

  def check_job_acu_schedule do
    JobAcuSchedule
    |> join(:inner, [jas], tas in TaskAcuSchedule, jas.id == tas.job_acu_schedule_id)
    |> where([jas, tas], is_nil(jas.finish))
    |> where([jas, tas], not is_nil(tas.finish))
    |> select([jas, tas], %{id: jas.id})
    |> group_by([jas, tas], jas.id)
    |> having([jas, tas], fragment("COUNT(?) = ?", tas.id, jas.task_count))
    |> order_by([jas, tas], jas.inserted_at)
    |> Repo.all()
  end

  def check_finish_date_task_acu_schedule(job_acu_sched_id) do
    TaskAcuSchedule
    |> where([tas], tas.job_acu_schedule_id == ^job_acu_sched_id)
    |> select([tas], %{finish: tas.finish})
    |> order_by([tas], desc: tas.finish)
    |> limit(1)
    |> Repo.one()
  end

  def update_job_acu_schedule do
    with jas <- check_job_acu_schedule(),
         false <- Enum.empty?(jas)
    do
      jas = check_job_acu_schedule()
      jas
      |> Enum.each(fn(jas)->
        Exq.Enqueuer.enqueue(
          Exq.Enqueuer,
          "check_job_acu_schedules_job",
          "Innerpeace.Db.Worker.Job.CheckJobAcuSchedulesJob",
          [jas.id]
        )
      end)
    else
      _ ->
        nil
    end
  end

  def update_job_acu_schedule(job_acu_schedules_id, finish) do
    jas = get_job_acu_schedule_by_id(job_acu_schedules_id)
    jas
    |> JobAcuSchedule.changeset(finish)
    |> Repo.update()
  end
end

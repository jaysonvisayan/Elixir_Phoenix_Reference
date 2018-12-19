defmodule Innerpeace.Db.Base.Api.AcuScheduleContext do
  @moduledoc """
  """
  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.AcuSchedule,
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
    Base.Api.UtilityContext,
    Base.AccountContext,
    Base.ProductContext
  }

  def get_acu_schedule(id) do
    AcuSchedule
    |> Repo.get!(id)
    |> Repo.preload([
      :account_group,
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
      acu_schedule_members: :member
      ]
    ])
  end

  def get_acu_schedule_by_batch_no(batch_no) do
    AcuSchedule
    |> where([as], as.batch_no == ^batch_no)
    |> Repo.one()
    |> Repo.preload([
      :account_group,
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
      acu_schedule_members: :member
      ]
    ])
  end

  def get_all_acu_schedules do
    AcuSchedule
    |> order_by([as], as.inserted_at)
    |> Repo.all()
    |> Repo.preload([
      :account_group,
      :created_by,
      [acu_schedule_products: :product]
    ])
  end

  def list_active_accounts_acu do
    Account
    |> join(:inner, [a], ap in AccountProduct, a.id == ap.account_id)
    |> join(:inner, [a, ap], p in Product, p.id == ap.product_id)
    |> join(:inner, [a, ap, p], pc in ProductCoverage, pc.product_id == p.id)
    |> join(:inner, [a, ap, p, pc], c in Coverage, pc.coverage_id == c.id)
    |> where([a, ap, p, pc, c], a.status == "Active")
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
      |> where([p, ap, apb, pb, b, pv, c, a, ag],
               ilike(b.provider_access, "%Mobile"))
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

  def get_acu_facilities(product_code) do
    Facility
    |> join(:inner, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:inner, [f, d], pf in PackageFacility, pf.facility_id == f.id)
    |> join(:inner, [f, d, pf], p in Package, pf.package_id == p.id)
    |> join(:inner, [f, d, pf, p], bp in BenefitPackage, bp.package_id == p.id)
    |> join(:inner, [f, d, pf, p, bp], b in Benefit, bp.benefit_id == b.id)
    |> join(:inner, [f, d, pf, p, bp, b], pb in ProductBenefit, b.id == pb.benefit_id)
    |> join(:inner, [f, d, pf, p, bp, b, pb], pr in Product, pb.product_id == pr.id)
    |> where([f, d, pf, p, bp, b, pb, pr], pr.code in ^product_code)
    |> where([f, d, pf, p, bp, b, pb, pr], f.step > 6 and f.status == "Affiliated" and
             d.text == "MOBILE")
    |> select([f], %{facility_code: f.code, facility_name: f.name, facility_id: f.id})
    |> Repo.all()
    |> Enum.uniq()
  end

  def get_active_members_by_type(member_type, product_code) do
    active_members =
      Member
      |> join(:inner, [m], mp in MemberProduct, m.id == mp.member_id)
      |> join(:inner, [m, mp], ap in AccountProduct, mp.account_product_id == ap.id)
      |> join(:inner, [m, mp, ap], p in Product, ap.product_id == p.id)
      |> where([m, mp, ap, p], p.code in ^product_code and m.type in ^member_type)
      |> Repo.all()
      |> Repo.preload(:authorizations)

    filtered_members = Enum.map(active_members, fn(m) ->
      if Enum.empty?(m.authorizations) do
        m
      else
        authorization_ids = Enum.map(m.authorizations, fn(a) ->
          a.id
        end)
        Enum.map(authorization_ids, fn(x) ->
          member_ibnr_checker(x, m.id)
        end)
      end
    end)

    filtered_members
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1)))
    |> Enum.uniq()
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
    |> Repo.one()
  end

  def create_acu_schedule(params, user_id) do
    account_group = AccountContext.get_account_by_code(params["account_code"])
    params = Map.merge(params, %{
      "created_by_id" => user_id,
      "updated_by_id" => user_id,
      "no_of_members" => params["number_of_members_val"],
      "batch_no" => generate_random_batch_no,
      "account_group_id" => account_group.id
    })

    cond do
      Map.has_key?(params, "principal") && not Map.has_key?(params, "dependent") ->
        params = Map.put_new(params, "member_type", params["principal"])
      Map.has_key?(params, "dependent") && not Map.has_key?(params, "principal") ->
        params = Map.put_new(params, "member_type", params["dependent"])
      Map.has_key?(params, "principal") && Map.has_key?(params, "dependent") ->
        params = Map.put_new(params, "member_type", "Principal and Dependent")
      true ->
        param = Map.put_new(params, "member_type", nil)
    end
    %AcuSchedule{}
    |> AcuSchedule.changeset(params)
    |> Repo.insert()
  end

  def create_acu_schedule_product(acu_schedule_id, product_codes) do
    acu_products = Enum.map(product_codes, fn(pc) ->
      product = ProductContext.get_product_by_code(pc)
      params = %{
        "acu_schedule_id" => acu_schedule_id,
        "product_id" => product.id
      }
      %AcuScheduleProduct{}
      |> AcuScheduleProduct.changeset(params)
      |> Repo.insert!()
    end)
    {:ok}
  end

  def create_acu_schedule_member(acu_schedule_id, product_code) do
    acu_schedule = get_acu_schedule(acu_schedule_id)

    cond do
      acu_schedule.member_type == "Principal" ->
        member_type = ["Principal"]
      acu_schedule.member_type == "Dependent" ->
        member_type = ["Dependent"]
      true ->
        member_type = ["Principal, Dependent"]
    end

    members = get_active_members_by_type(member_type, product_code)
    members = Enum.map(members, fn(m) ->
      params = %{
        "acu_schedule_id" => acu_schedule.id,
        "member_id" => m.id
      }
      %AcuScheduleMember{}
      |> AcuScheduleMember.changeset(params)
      |> Repo.insert()
    end)
    {:ok}
  end

  defp generate_random_batch_no do
    numbers = "0123456789"
    rand = UtilityContext.do_randomizer(8, String.split("#{numbers}", "", trim: true))
    with true <- String.contains?(rand, String.split(numbers, "", trim: true))
    do
      rand
    else
      _ ->
      generate_random_batch_no()
    end
  end

end

 defmodule Innerpeace.Db.Base.ProductContext do
  @moduledoc """
    Business Logic in relative to Product module
  """

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Product,
    Schemas.Dropdown,
    Schemas.Coverage,
    Schemas.Benefit,
    Schemas.ProductBenefit,
    Schemas.ProductBenefitLimit,
    Schemas.Facility,
    Schemas.ProductFacility,
    Schemas.BenefitLimit,
    Schemas.BenefitCoverage,
    Schemas.Payor,
    Schemas.ProductRiskShare,
    Schemas.ProductRiskShareFacility,
    Schemas.ProductRiskShareFacilityProcedure,
    Schemas.ProductExclusion,
    Schemas.Exclusion,
    Schemas.Payor,
    Schemas.ProductLog,
    Schemas.Procedure,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.ProductCoverageRoomAndBoard,
    Schemas.ProductCoverageRiskShare,
    Schemas.ProductCoverageRiskShareFacility,
    Schemas.ProductCoverageRiskShareFacilityPayorProcedure,
    Schemas.FacilityPayorProcedure,
    Schemas.ProductConditionHierarchyOfEligibleDependent,
    Schemas.User,
    Schemas.ExclusionDisease,
    Schemas.ExclusionDuration,
    Schemas.Diagnosis,
    Schemas.Member,
    Schemas.ProductCoverageLimitThreshold,
    Schemas.ProductCoverageLimitThresholdFacility,
    Schemas.ProductExclusionLimit,
    Schemas.FacilityLocationGroup,
    Schemas.LocationGroup,
    Schemas.ProductExclusionLimit,
    Schemas.ChangeOfProductLog,
    Schemas.ChangedMemberProduct,
    Schemas.AccountProduct,
    Schemas.AccountGroupCoverageFund,
    Schemas.AccountGroup,
    Schemas.Account,
    Schemas.ProductCoverageDentalRiskShare,
    Schemas.ProductCoverageDentalRiskShareFacility,
    Schemas.ProductCoverageLocationGroup
  }

  alias Ecto.UUID

  alias Innerpeace.Db.Base.{
    ExclusionContext,
    FacilityContext,
    BenefitContext,
    FacilityContext,
    CoverageContext,
    LocationGroupContext,
    Api.UtilityContext
  }

  #################### START -- Functions related to Product.

  def get_all_products_for_index(params, offset) do
    Product
    |> join(:left, [p], u in User, u.id == p.created_by_id)
    |> join(:left, [p, u], uu in User, uu.id == p.updated_by_id)
    |> where(
      [p, u, uu],
      ilike(p.code, ^"%#{params}%") or ilike(p.name, ^"%#{params}%") or
        ilike(p.description, ^"%#{params}%") or ilike(u.username, ^"%#{params}%") or
        ilike(uu.username, ^"%#{params}%")
    )
    |> order_by([p], p.code)
    |> offset(^offset)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([
      :created_by,
      :updated_by,
      :payor,
      product_coverages: [
        :product_coverage_facilities
      ]
    ])
  end

  def get_all_products do
    # Returns all products in the database.

    Product
    |> Repo.all()
    |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: :procedure,
          benefit_coverages: :coverage
        ]
      ],
      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        product_coverage_limit_threshold: [:product_coverage_limit_threshold_facilities],
        product_coverage_facilities: [facility: [:category, :type]],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
          ]
        ]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]]
    ])
  end

  def get_product_by_name(name) do
    # Searches a product record by name.

    Product
    |> Repo.get_by(name: name)
  end

  def get_product_by_id(id) do
    # Searches a product record by name.

    Product
    |> Repo.get(id)
  end

  def get_product!(id) do
    # Searches a product record by ID.

    Product
    |> Repo.get(id)
    |> Repo.preload([
      :account_products,
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,

      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: :procedure,
          benefit_coverages: :coverage
        ]
      ],

      product_coverages: [
        :coverage,
        :product_coverage_room_and_board,
        [product_coverage_dental_risk_share: [product_coverage_dental_risk_share_facilities: :facility]],
        product_coverage_limit_threshold: [
          product_coverage_limit_threshold_facilities: [:facility]
        ],
        product_coverage_facilities: [
          facility: [:category, :type, facility_location_groups: :location_group]
        ],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
          ]
        ],
        product_coverage_location_groups: [
          location_group: [
            facility_location_group: [
              :facility
            ]
          ]
        ]
      ],
      product_exclusions: [
        :product_exclusion_limit,
        [exclusion: [:exclusion_diseases, :exclusion_procedures]]
      ]
    ])
  end

  def get_product(id) do
    Product
    |> Repo.get(id)
    |> Repo.preload([
      [account_products:
      [member_products:
      [:authorization_diagnosis,
      :authorization_procedure_diagnoses]]],
      :payor,
      :logs,
      :product_condition_hierarchy_of_eligible_dependents,
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          :created_by,
          :updated_by,
          :benefit_limits,
          benefit_procedures: :procedure,
          benefit_coverages: :coverage
        ]
      ],
      product_coverages: [
        :product,
        :coverage,
        :product_coverage_room_and_board,
        [product_coverage_dental_risk_share: :product_coverage_dental_risk_share_facilities],
        product_coverage_limit_threshold: [
          product_coverage_limit_threshold_facilities: [:facility]
        ],
        product_coverage_facilities: [
          facility: [:category, :type, facility_location_groups: :location_group]
        ],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
          ]
        ],
        product_coverage_location_groups: [
          location_group: [
            facility_location_group: [
              :facility
            ]
          ]
        ]
      ],
      product_exclusions: [exclusion: [:exclusion_diseases, :exclusion_procedures]]
    ])
  end

  def get_all_benefit_coverage(product_id) do
    # Searches a Product record along with its Benefit Coverages.

    Product
    |> Repo.get!(product_id)
    |> Repo.preload(product_benefits: [benefit: [benefit_coverages: :coverage]])
  end

  def create_product(product_params \\ %{}) do
    # Inserts a product record.
    maxicare = Repo.get_by(Payor, name: "Maxicare")
    product_params = Map.merge(product_params, %{"payor_id" => maxicare.id})

    %Product{}
    |> Product.changeset_general(product_params)
    |> Repo.insert()
  end

  def create_product_peme(product_params \\ %{}) do
    # Inserts a product record.
    maxicare = Repo.get_by(Payor, name: "Maxicare")
    product_params = Map.merge(product_params, %{"payor_id" => maxicare.id})

    %Product{}
    |> Product.changeset_general_peme(product_params)
    |> Repo.insert()
  end

  def save_draft_product_dental(product_params \\ %{}) do
    # Inserts a product record.
    maxicare = Repo.get_by(Payor, name: "Maxicare")
    product_params = Map.merge(product_params, %{"payor_id" => maxicare.id})

    with {:ok, benefit_ids} <- validate_benefit_ids(product_params["benefit_ids"]),
         {:ok, benefit_limit_datas} <- validate_benefit_limit_datas(product_params["benefit_limit_datas"]),
         {:ok, product} <- save_dental_product_general(product_params),
         {:ok} <- insert_product_benefits(product.id, benefit_ids, benefit_limit_datas, product_params["created_by_id"])
    do
        {:ok, product}
    else
      nil ->
        save_draft_product_dental2(product_params)
      {:error, %Ecto.Changeset{} = changeset_general_dental} ->
        {:error, %Ecto.Changeset{} = changeset_general_dental}
      _ ->
        {:error}
    end
  end

  defp save_draft_product_dental2(product_params) do
    with {:ok, product} <- save_dental_product_general(product_params)
    do
      {:ok, product}
    else
      {:error, %Ecto.Changeset{} = changeset_general_dental} ->
        {:error, %Ecto.Changeset{} = changeset_general_dental}
      _ ->
        {:error}
    end
  end

  defp validate_benefit_ids(nil), do: nil
  defp validate_benefit_ids([]), do: nil
  defp validate_benefit_ids([""]), do: nil
  defp validate_benefit_ids(b_ids), do: {:ok, Enum.uniq(b_ids)}

  defp validate_benefit_limit_datas(nil), do: nil
  defp validate_benefit_limit_datas([]), do: nil
  defp validate_benefit_limit_datas([""]), do: nil
  defp validate_benefit_limit_datas(b_lds), do: {:ok, Enum.uniq(b_lds)}

  def create_product_dental(product_params \\ %{}) do
    # Inserts a product record.
    maxicare = Repo.get_by(Payor, name: "Maxicare")
    product_params = Map.merge(product_params, %{"payor_id" => maxicare.id})
    # coverage_id = get_product_coverage_dental_id("Dental")
    with {:ok, benefit_ids} <- validate_benefit_ids(product_params["benefit_ids"]),
         {:ok, benefit_limit_datas} <- validate_benefit_limit_datas(product_params["benefit_limit_datas"]),
         {:ok, product} <- create_dental_product_general(product_params),
         {:ok} <- insert_product_benefits(product.id, benefit_ids, benefit_limit_datas, product_params["created_by_id"])
    do
       # insert_product_coverage_id(coverage_id, product.id)
      {:ok, product}
    else
      {:error, %Ecto.Changeset{} = changeset_general_dental} ->
        {:error, %Ecto.Changeset{} = changeset_general_dental}
      _ ->
        {:error}
    end
  end

  def update_product_dental(product, product_params \\ %{}) do
    benefit_ids =
      product_params["benefit_ids"]
      |> check_ids()

    benefit_limit_datas =
      product_params["benefit_limit_datas"]
      |> check_ids()

    maxicare = Repo.get_by(Payor, name: "Maxicare")
    product_params = Map.merge(product_params, %{"payor_id" => maxicare.id})

    if product_params["benefit_ids"] == "" and product_params["benefit_ids_main"] == "" do
      with {:ok, product} <- update_dental_product_general(product, product_params)
      do
        {:ok, product, "no_benefit"}
      else
        {:error, %Ecto.Changeset{} = changeset_general_dental} ->
          {:error, %Ecto.Changeset{} = changeset_general_dental}

        _ ->
          {:error}
      end
    else
        with {:ok, product} <- update_dental_product_general(product, product_params),
             {:ok} <- update_product_benefits(product.id, product_params["benefit_ids"], product_params["benefit_limit_datas"], product_params["created_by_id"])
        do
          {:ok, product, "with_benefit"}
        else
          {:error, %Ecto.Changeset{} = changeset_general_dental} ->
            {:error, %Ecto.Changeset{} = changeset_general_dental}

          _ ->
            {:error}
        end
    end
  end

  defp check_ids(nil), do: []
  defp check_ids(ids), do: Enum.uniq(ids)
  defp update_product_benefits(product_id, benefit_ids) do
    for benefit_id <- benefit_ids do
      result = benefit_checker(product_id, benefit_id)

      if result == true do
        params = %{benefit_id: benefit_id, product_id: product_id}
        changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

        product_benefit =
          changeset
          |> Repo.insert!()
          |> Repo.preload(benefit: :benefit_limits)

          product = get_product!(product_id)
          set_product_coverage(product)

          for benefit_limit <- product_benefit.benefit.benefit_limits do
            params = %{
              coverages: benefit_limit.coverages,
              limit_type: benefit_limit.limit_type,
              limit_percentage: benefit_limit.limit_percentage,
              limit_amount: benefit_limit.limit_amount,
              limit_session: benefit_limit.limit_session,
              limit_tooth: benefit_limit.limit_tooth,
              limit_quadrant: benefit_limit.limit_quadrant,
              limit_classification: benefit_limit.limit_classification,
              product_benefit_id: product_benefit.id,
              benefit_limit_id: benefit_limit.id
            }

            changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
            Repo.insert!(changeset)
          end
      end
    end

    {:ok}

  end

  def create_dental_product_general(product_params) do
    %Product{}
    |> Product.changeset_general_dental(product_params)
    |> Repo.insert()
  end

  ###Genera Product Coverage##
  defp insert_product_coverage_id(coverage_id, product_id) do
    product_coverage_params = %{
      coverage_id: coverage_id,
      product_id: product_id
    }
    # raise get_product_coverage_dental_id_draft(product_id, coverage_id)
       # |> insert_product_coverage()
  end

  defp get_product_coverage_dental_id_draft(product_id, coverage_id) do
      ProductCoverage
      |> where([pc], (pc.product_id == ^product_id and pc.coverage_id == ^coverage_id))
      |> select([pc], pc.id)
      |> Repo.one()
  end

  defp get_product_coverage_dental_id(coverage) do
    coverage_id =
      Coverage
      |> where([c], c.name == ^coverage)
      |> select([c], c.id)
      |> Repo.one()
  end

  defp insert_product_coverage(product_coverage_params) do
    %ProductCoverage{}
    |> ProductCoverage.changeset(product_coverage_params)
    |> Repo.insert()
  end
  ###########################

  def update_dental_product_general(product, product_params) do
    product
    |> Product.changeset_step1_draft(product_params)
    |> Repo.update()
  end

  def save_dental_product_general(product_params) do
    %Product{}
    |> Product.changeset_step1_draft(product_params)
    |> Repo.insert()
  end

  def pl_pbl_checker(product, submitted_limit_amount) do
    ### product limit amount checker for the highest in benefit's limit
    product =
      product
      |> Repo.preload(product_benefits: [:product_benefit_limits, benefit: :benefit_limits])

    all_pbl =
      for product_benefit <- product.product_benefits do
        for product_benefit_limit <- product_benefit.product_benefit_limits do
          if not is_nil(product_benefit_limit.limit_type) do
            product_benefit_limit.limit_amount
          end
        end
      end

    per_pbl_total = add_all_peso_limit(all_pbl)

    highest_pbl = List.first(recursion_highest_decimal(per_pbl_total))

    if is_nil(highest_pbl) do
      nil
    else
      submitted_limit_amount =
        submitted_limit_amount
        |> Decimal.new()
        |> Decimal.compare(highest_pbl)
        |> Decimal.to_integer()

      case submitted_limit_amount do
        -1 ->
          {:pl_pbl_lessthan, highest_pbl}

        0 ->
          {:pl_pbl_equal}

        1 ->
          {:pl_pbl_greaterthan}
      end
    end
  end

  defp add_all_peso_limit(all_pbl) do
    for add <- all_pbl do
      add = Enum.filter(add, fn x -> x != nil end)
      ### this is for acu
      if Enum.empty?(add) do
        recursion_decimal([Decimal.new(0)])
      else
        recursion_decimal(add)
      end
    end
  end

  def recursion_highest_decimal(list) do
    list_count =
      list
      |> Enum.count()

    if list_count > 1 do
      first = Enum.at(list, 0)
      second = Enum.at(list, 1)

      result = Decimal.to_integer(Decimal.compare(first, second))

      case result do
        -1 ->
          list = List.delete_at(list, 0)
          recursion_highest_decimal(list)

        0 ->
          ## pick any of two to delete
          list = List.delete_at(list, 0)
          recursion_highest_decimal(list)

        1 ->
          list = List.delete_at(list, 1)
          recursion_highest_decimal(list)
      end
    else
      list
    end
  end

  def recursion_decimal(list) do
    list_count = Enum.count(list)

    if list_count > 1 do
      list_first = Enum.at(list, 0)
      list_second = Enum.at(list, 1)
      result = Decimal.add(list_first, list_second)

      new_list =
        list
        |> List.delete(list_first)
        |> List.replace_at(0, result)

      new_list_count = Enum.count(new_list)

      if new_list_count > 1 do
        recursion_decimal(new_list)
      else
        Enum.at(new_list, 0)
      end
    else
      Enum.at(list, 0)
    end
  end

  def update_product_peme(%Product{} = product, product_params) do
      refactor_update_product(product, product_params)
  end

  def update_product(%Product{} = product, product_params) do
    if product_params["limit_amount"] == "" || is_nil(product_params["limit_amount"]) do
      refactor_update_product(product, product_params)
    else
      if product_params["product_base"] == "Exclusion-based" do
        refactor_update_product(product, product_params)
      else
        case pl_pbl_checker(product, product_params["limit_amount"]) do
          {:pl_pbl_lessthan, highest_pbl} ->
            {:error_product_limit,
             "Plan Limit must be equal or greater than each benefit's limit. Plan cannot be saved., current highest pb amount is #{highest_pbl}"}

          {:pl_pbl_equal} ->
            refactor_update_product(product, product_params)

          {:pl_pbl_greaterthan} ->
            refactor_update_product(product, product_params)

          nil ->
            refactor_update_product(product, product_params)
        end
      end
    end
  end

  def refactor_update_product(product, product_params) do
    old_product = product
    keys = Map.keys(product_params)
    is_existing = Enum.member?(keys, "member_type")

    # if member_type checkbox has not been selected
    # this is to catch the empty member_type field
    if is_existing == false do
      product_params =
        product_params
        |> Map.put("member_type", "")
    end

    if product_params["limit_applicability"] == "Principal" do
      product_params = Map.put(product_params, "shared_limit_amount", "")
    else
      product_params
    end
    # Updated a product record.
    if product.product_category == "PEME Plan" do
      product_params =
        product_params
        |> Map.put_new("in_lieu_of_acu", false)
    product =
      product
      |> Product.changeset_general_peme(product_params)
      |> Repo.update()

    else
    product =
      product
      |> Product.changeset_general(product_params)
      |> Repo.update()
    end
    case product do
      {:ok, product} ->
        if product.member_type == ["Dependent"] do
          deleting_eligible_condition(product)
        else
          {:ok, product}
        end

        ### deleting product coverage
        if product.product_base == old_product.product_base do
          {:ok, product}
        else
          ### deleting product_benefit, product_coverage, product_exclusion
          onchange_delete_pc(product.id)
          {:ok, product}
        end

        if not Enum.member?(product.member_type, "Principal") do
          delete_sop(product, "principal")
        end

        if not Enum.member?(product.member_type, "Dependent") do
          delete_sop(product, "dependent")
        end

        {:ok, product}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_sop(product, type) do
    params = %{
      "sop_#{type}": nil
    }

    product
    |> Product.changeset_update_sop(params)
    |> Repo.update()
  end

  def deleting_eligible_condition(product) do
    ## deleting all hierarchy data if the user change its member_type to ["Dependent"]
    ProductConditionHierarchyOfEligibleDependent
    |> where([pchoed], pchoed.product_id == ^product.id)
    |> Repo.delete_all()

    params = %{
      principal_max_age: "",
      principal_max_type: "",
      principal_min_age: "",
      principal_min_type: "",
      nem_principal: "",
      mded_principal: ""
    }

    product
    |> Product.changeset_condition_for_nil(params)
    |> Repo.update()
  end

  def update_product_step(%Product{} = product, product_params) do
    # Updates 'step' field in Product table.

    product
    |> Product.changeset_step(product_params)
    |> Repo.update()
  end

  def delete_product(id) do
    # Deletes a Product record.

    id
    |> get_product!()
    |> Repo.delete()
  end


  def insert_or_update_product(params) do
    # If a there was no Product record found,
    #the parameters given will be inserted into the Products table,
    #or else, the existing Product record will be searched and will be updated
    # by the parameters provided.

    product = get_product_by_name(params["name"])

    if is_nil(product) do
      {:ok, products} = create_product(params)
      update_product_step(products, params)
      update_product_condition(products, params)
    else
      update_product(product, params)
      update_product_step(product, params)
      update_product_condition(product, params)
    end
  end

  def update_product_facilities_included(%Product{} = product, include_all_facilities) do
    # Updates 'include_all_facilities' field of Product

    params = %{include_all_facilities: include_all_facilities}

    product
    |> Product.changeset_facilities_included(params)
    |> Repo.update()
  end

  def update_product_facility_coverage(%Product{} = product, coverage_id) do
    # Updates 'coverage_id' field of Product.

    params = %{coverage_id: coverage_id}

    product
    |> Product.changeset_update_coverage(params)
    |> Repo.update()
  end

  def update_product_prsf_coverage(%Product{} = product, coverage_id) do
    # Updates 'prsf_cov_id' field of Product.

    params = %{prsf_cov_id: coverage_id}

    product
    |> Product.changeset_update_prsf_coverage(params)
    |> Repo.update()
  end

  def delete_product_all(product_id) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> Repo.delete_all()

    ProductExclusion
    |> where([pe], pe.product_id == ^product_id)
    |> Repo.delete_all()

    product_benefits =
      ProductBenefit
      |> where([pb], pb.product_id == ^product_id)
      |> Repo.all()
      |> Repo.preload([
        :product_benefit_limits,
        benefit: [benefit_coverages: :coverage]
      ])

    for pb <- product_benefits do
      ProductBenefitLimit
      |> where([pbl], pbl.product_benefit_id == ^pb.id)
      |> Repo.delete_all()
    end

    ProductBenefit
    |> where([pb], pb.product_id == ^product_id)
    |> Repo.delete_all()

    Product
    |> Repo.get_by(id: product_id)
    |> Repo.delete()
  rescue
    _ ->
      {:error, "Error deleting all products"}
  end

  #################### END -- Functions related to Product.

  #################### START -- Functions related to ProductBenefit.

  def get_product_benefit(product_benefit_id) do
    # Searches a ProductBenefit record by its ID with its BenefitLimit, Benefit, and BenefitCoverages.
    ProductBenefit
    |> Repo.get(product_benefit_id)
    |> Repo.preload([
      :product_benefit_limits,
      benefit: [benefit_coverages: :coverage]
    ])
  end

  def get_product_benefit_by_ids(p_id, b_id) do
    # Searches a ProductBenefit record by its ID with its BenefitLimit, Benefit, and BenefitCoverages.
    ProductBenefit
    |> where([pb], pb.benefit_id == ^b_id and pb.product_id == ^p_id)
    |> Repo.all()
    |> Repo.preload([
      :product_benefit_limits,
      benefit: [benefit_coverages: :coverage]
    ])
  end

  ## connected to controller
  def remaining_age_range_checker(product) do
    product.product_benefits
    |> Enum.map(&(
      &1.benefit.benefit_coverages
      |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
        do: &1.benefit_id
      end)
    ))
    |> List.flatten()
    |> Enum.filter(fn(b) -> b != nil end)
    |> Enum.map(fn(a) ->
      BenefitContext.get_benefit(a).benefit_packages
      |> Enum.into([], fn(x) ->
        get_ppp(x)
      end)
    end)
    |> List.flatten()
    |> remaining_acu_age_checker()

  end

  def remaining_acu_age_checker(pb_acu_packages) do
    ## change structure due to OR condition for gender with their ages
    enumerable =
      0..100
      |> Enum.to_list()

    with {:true} <- atleast_one_acu_included?(pb_acu_packages),
         {:satisfied, gender_result} <- atleast_male_or_female_have_zero_to_100(pb_acu_packages)
    do
      check_ages_if_male_or_female_have_ages(gender_result, enumerable, pb_acu_packages)
    else
      {:false} ->
        {:no_pb_acu_found}

    end
  end

  defp check_ages_if_male_or_female_have_ages(gender_result, enumerable, pb_acu_packages) do
    cond do
      gender_result.male == true and gender_result.female == true ->
        # IO.puts "male, female"
        both_have_ages(enumerable, pb_acu_packages)

      gender_result.male == true and gender_result.female == false ->
        # IO.puts "male"
        male_ages_only(enumerable, pb_acu_packages)

      gender_result.male == false and gender_result.female == true ->
        # IO.puts "female"
        female_ages_only(enumerable, pb_acu_packages)

      true ->
        raise "Invalid"
    end
  end

  defp both_have_ages(enumerable, pb_acu_packages) do
    with {:zero_to_100_fulfilled} <- enumerable |> collect_ages_male(pb_acu_packages),
         {:zero_to_100_fulfilled} <- enumerable |> collect_ages_female(pb_acu_packages)
    do
      {:zero_to_100_fulfilled}
    else
      {:unfulfilled_age_male, message} ->
        {:unfulfilled_age_male, message}

      {:unfulfilled_age_female, message} ->
        {:unfulfilled_age_female, message}
    end
  end

  defp male_ages_only(enumerable, pb_acu_packages) do
    with {:zero_to_100_fulfilled} <- enumerable |> collect_ages_male(pb_acu_packages)
    do
      {:zero_to_100_fulfilled}
    else
      {:unfulfilled_age_male, message} ->
        {:unfulfilled_age_male, message}

    end
  end

  defp female_ages_only(enumerable, pb_acu_packages) do
    with {:zero_to_100_fulfilled} <- enumerable |> collect_ages_female(pb_acu_packages)
    do
      {:zero_to_100_fulfilled}
    else
      {:unfulfilled_age_female, message} ->
        {:unfulfilled_age_female, message}

    end
  end

  defp atleast_one_acu_included?(pb_acu_packages) do
    if pb_acu_packages |> Enum.empty?() do
      {:false}
    else
      {:true}
    end
  end

  defp atleast_male_or_female_have_zero_to_100(pb_acu_packages) do
    male_result =
      pb_acu_packages
      |> Enum.filter(&(&1.male == true))

    female_result =
      pb_acu_packages
      |> Enum.filter(&(&1.female == true))

    check_whos_empty?(male_result, female_result)
  end

  defp check_whos_empty?(male_result, female_result) do
    male = not Enum.empty?(male_result)
    female = not Enum.empty?(female_result)

    if male == true or female == true do
      {:satisfied, %{male: male, female: female}}
    else
      {:false}
    end

  end

  defp collect_ages_male(enumerable, pb_acu_packages) do
    current_ages_from_pb_packages =
      pb_acu_packages
      |> Enum.filter(&(&1.male == true))
      |> Enum.map(&(&1.age_from..&1.age_to |> Enum.to_list()))
      |> List.flatten()

    # IO.inspect enumerable -- current_ages_from_pb_packages, charlists: false <- this is for devside only
    enumerable -- current_ages_from_pb_packages
    |> is_empty?(:unfulfilled_age_male, "male")
  end

  defp collect_ages_female(enumerable, pb_acu_packages) do
    current_ages_from_pb_packages =
      pb_acu_packages
      |> Enum.filter(&(&1.female == true))
      |> Enum.map(&(&1.age_from..&1.age_to |> Enum.to_list()))
      |> List.flatten()

    # IO.inspect enumerable -- current_ages_from_pb_packages, charlists: false <- this is for devside only
    enumerable -- current_ages_from_pb_packages
    |> is_empty?(:unfulfilled_age_female, "female")
  end

  defp is_empty?(list, atom_gender, gender) do
    list =
      list
      |> Enum.empty?()

    if list do
      {:zero_to_100_fulfilled}
    else
      {atom_gender,
        "Incomplete ACU benefits.
        Please add ACU benefits that have an age range from 0 to 100 years old for #{gender}"
      }
    end
  end

  def get_ppp(x) do
    x.package.package_payor_procedure
    |> Enum.map(fn(y) -> package_pp_details(y) end)
    |> ppp_gender_age_checker(x.package.name)
  end

  defp check_value(benefit, search_value) when search_value == "", do: benefit
  defp check_value(benefit, search_value) do
    benefit
    |> where([b], ilike(b.code, ^"%#{search_value}%") or ilike(b.name, ^"%#{search_value}%")) ## search
  end

  def get_all_benefits_step3(search_value, offset, product) do
    coverages = Enum.map(product.product_coverages, &(&1.coverage.code))
    product_benefits =
      product.product_benefits
      |> Enum.map(&(&1.benefit_id))

    if product.product_category == "PEME Plan" do
      Benefit
      |> join(:left, [b], bc in BenefitCoverage, bc.benefit_id == b.id)
      |> join(:left, [b, bc], c in Coverage, bc.coverage_id == c.id)
      |> where([b, bc, c], c.code == "PEME")
      |> where([b, bc, c], b.id not in ^product_benefits) ## b -- pb
      |> where([b, bc, c], is_nil(b.status))
      |> check_value(search_value)
      |> select([b, bc, c], b)
      |> offset(^offset)
      |> order_by([b], b.code)
      |> limit(100)
      |> Repo.all()
      |> Repo.preload([
        :benefit_limits,
        benefit_coverages: :coverage
      ])
    else
      if Enum.member?(coverages, "ACU") do
        ## if already exist this benefit should not be included in the list

        if product.product_category != "PEME Plan" do
          Benefit
          |> join(:left, [b], bl in BenefitLimit, bl.benefit_id == b.id)
          |> join(:left, [b, bl], bc in BenefitCoverage, bc.benefit_id == b.id)
          |> join(:left, [b, bl, bc], c in Coverage, bc.coverage_id == c.id)
          |> distinct([b, bl, bc, c], b.id)
          |> select([b, bl, bc, c], b)
          |> group_by([b], b.id)
          |> group_by([b, bl, bc, c], [b.id, bc.id] )
          |> having([b, bl], fragment("sum(?)  <= ? ", bl.limit_amount, ^product.limit_amount) or (is_nil(sum(bl.limit_amount))) )
          |> where([b], b.id not in ^product_benefits) ## b -- pb
          |> check_value(search_value)
          |> where([b, bl, bc, c], c.name != "ACU")
          |> offset(^offset)
          |> order_by([b], b.code)
          |> limit(100)
          |> Repo.all()
          |> Repo.preload([
            :benefit_limits,
            benefit_coverages: :coverage
          ])
        else
          []
        end
      else
        ## if already exist this benefit should not be included in the list
        product_benefits =
          product.product_benefits
          |> Enum.map(&(&1.benefit_id))

          Benefit
          |> join(:left, [b], bl in BenefitLimit, bl.benefit_id == b.id)
          |> join(:left, [b, bl], bc in BenefitCoverage, bc.benefit_id == b.id)
          |> join(:left, [b, bl, bc], c in Coverage, bc.coverage_id == c.id)
          |> distinct([b, bl, bc, c], b.id)
          |> select([b, bl, bc, c], b)
          |> group_by([b, bl, bc, c], [b.id, bc.id] )
          |> having([b, bl], fragment("sum(?)  <= ? ", bl.limit_amount, ^product.limit_amount) or (is_nil(sum(bl.limit_amount))) )
          |> where([b], b.id not in ^product_benefits) ## b -- pb
          |> check_value(search_value)
          |> where([b, bl, bc, c], c.name != "PEME")
          |> offset(^offset)
          |> order_by([b], b.code)
          |> limit(100)
          |> Repo.all()
          |> Repo.preload([
            :benefit_limits,
            benefit_coverages: :coverage
          ])

      end
    end
  end

  def get_all_benefits_dental(search_value, offset) do
    Benefit
    |> join(:left, [b], bc in BenefitCoverage, bc.benefit_id == b.id)
    |> join(:left, [b, bc], c in Coverage, bc.coverage_id == c.id)
    |> where([b, bc, c], c.code == "DENTL")
    |> where([b, bc, c], is_nil(b.status))
    |> check_value(search_value)
    |> select([b, bc, c], b)
    |> offset(^offset)
    |> order_by([b], b.code)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([
      :benefit_limits,
      :benefit_procedures,
      benefit_coverages: :coverage,
    ])
  end

  # def delete_benefit_dental_datatable()

  # end

  def print_sql(queryable) do
    IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, queryable))
    queryable
  end

  def set_product_benefits(product, benefit_ids, user_id) do
    case product.product_category do
      "Regular Plan" ->
        benefit_ids
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "ACU"))
        |> Enum.count()
        |> result_count(product.id, benefit_ids, "Only one ACU benefit can be added.", "ACU", user_id)

      "PEME Plan" ->
        benefit_ids
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "PEME"))
        |> Enum.count()
        |> result_count(product.id, benefit_ids, "Only one PEME benefit can be added.", "PEME", user_id)

      "Dental Plan" ->
        benefit_ids
        |> Enum.into([], fn(x) -> BenefitContext.get_benefit(x).benefit_coverages
        |> Enum.map(fn(y) -> y.coverage.description end)
        end)
        |> List.flatten()
        |> Enum.filter(&(&1 == "Dental"))
        |> Enum.count()
        |> result_count(product.id, benefit_ids, "", "Dental", user_id)

      _ ->
        {:error, "Error in Plan Category"}
    end

    # rescue
    #   _ ->
    #     {:error, "Error in Plan Category"}
  end

  defp result_count(count, id, benefit_ids, message, category, user_id) when category == "Dental", do: insert_product_benefits(id, benefit_ids, user_id)
  defp result_count(count, id, benefit_ids, message, category, user_id) when category != "Dental", do: if count > 1, do: {:error, message}, else: insert_product_benefits_reg_or_peme(id, benefit_ids, user_id)

  defp insert_product_benefits(product_id, benefit_ids, user_id) do
    with {true, user_id} <- UtilityContext.valid_uuid?(user_id) do
      for benefit_id <- benefit_ids do
        result = benefit_checker(product_id, benefit_id)

        if result == false do
          params = %{benefit_id: benefit_id, product_id: product_id}
          changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

          product_benefit =
            changeset
            |> Repo.insert!()
            |> Repo.preload(benefit: :benefit_limits)

          product = get_product!(product_id)
          set_product_coverage(product)

          for benefit_limit <- product_benefit.benefit.benefit_limits do
            params = %{
              coverages: benefit_limit.coverages,
              limit_type: benefit_limit.limit_type,
              limit_percentage: benefit_limit.limit_percentage,
              limit_amount: benefit_limit.limit_amount,
              limit_session: benefit_limit.limit_session,
              limit_classification: benefit_limit.limit_classification,
              product_benefit_id: product_benefit.id,
              benefit_limit_id: benefit_limit.id,
              created_by_id: user_id,
              updated_by_id: user_id,
              limit_area: benefit_limit.limit_area,
              limit_area_type: benefit_limit.limit_area_type
            }

            changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
            Repo.insert!(changeset)
          end
        end
      end
    {:ok}
    else
      {:invalid_id} ->
        {:error, "Invalid user id"}
      _ ->
        {:error, "Error"}
    end
  end

  defp insert_product_benefits_reg_or_peme(product_id, benefit_ids, user_id) do
    with {true, user_id} <- UtilityContext.valid_uuid?(user_id) do
      for benefit_id <- benefit_ids do
        result = benefit_checker_reg_or_peme(product_id, benefit_id)

        if result == true do
          params = %{benefit_id: benefit_id, product_id: product_id}
          changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

          product_benefit =
            changeset
            |> Repo.insert!()
            |> Repo.preload(benefit: :benefit_limits)

          product = get_product!(product_id)
          set_product_coverage(product)

          for benefit_limit <- product_benefit.benefit.benefit_limits do
            params = %{
              coverages: benefit_limit.coverages,
              limit_type: benefit_limit.limit_type,
              limit_percentage: benefit_limit.limit_percentage,
              limit_amount: benefit_limit.limit_amount,
              limit_session: benefit_limit.limit_session,
              limit_classification: benefit_limit.limit_classification,
              product_benefit_id: product_benefit.id,
              benefit_limit_id: benefit_limit.id,
              created_by_id: user_id,
              updated_by_id: user_id
            }

            changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
            Repo.insert!(changeset)
          end
        end
      end
    {:ok}
    else
      {:invalid_id} ->
        {:error, "Invalid user id"}
      _ ->
        {:error, "Error"}
    end
  end

  ## if already have product_benefit and user intends to set another acu benefit,
  ## checks if that benefit will overlaps the existing acu benefits
  defp if_overlaps_pb_lvl1(product_id, benefit_ids) do
     get_product!(product_id).product_benefits
     |> Enum.map(&(
       &1.benefit.benefit_coverages
       |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
         do: &1.benefit_id
       end)
     ))
     |> List.flatten()
     |> Enum.filter(fn(b) -> b != nil end)
     |> if_overlaps_pb_lvl2(benefit_ids)
  end

  defp if_overlaps_pb_lvl2(list, benefit_ids) do
    {:merged_ids, benefit_ids ++ list}
  end

  def validate_male_multiple_acu(benefit_ids) do
    benefit_ids
    |> Enum.map(&(
      BenefitContext.get_benefit(&1)).benefit_coverages
      |> Enum.into([], fn(a) -> if a.coverage.name == "ACU", do: a.benefit_id end)
      |> if_not_acu_clear_nil()
    )
    |> List.flatten()
    |> Enum.map(fn(b) ->
      BenefitContext.get_benefit(b).benefit_packages
      |> Enum.into([], fn(x) ->
        x.package.package_payor_procedure
        |> Enum.map(fn(y) -> package_pp_details(y) end)
        |> ppp_gender_age_checker(x.package.name)
      end)
    end)
    |> List.flatten()
    |> collecting_all_male()
  end

  defp if_not_acu_clear_nil(list) do
    ## if all of its coverage is not acu == [nil, nil, nil]
    list
    |> Enum.uniq
    |> List.delete(nil)
  end

  def validate_female_multiple_acu(benefit_ids) do
    benefit_ids
    |> Enum.map(&(
      BenefitContext.get_benefit(&1)).benefit_coverages
      |> Enum.into([], fn(a) -> if a.coverage.name == "ACU", do: a.benefit_id end)
      |> if_not_acu_clear_nil()
    )
    |> List.flatten()
    |> Enum.map(fn(b) ->
      BenefitContext.get_benefit(b).benefit_packages
      |> Enum.into([], fn(x) ->
        x.package.package_payor_procedure
        |> Enum.map(fn(y) -> package_pp_details(y) end)
        |> ppp_gender_age_checker(x.package.name)
      end)
    end)
    |> List.flatten()
    |> collecting_all_female()
  end

  defp collecting_all_male(list) do
    list
    |> Enum.filter(&(&1.male == true))
    |> validate_overlapping_age()
  end

  defp collecting_all_female(list) do
    list
    |> Enum.filter(&(&1.female == true))
    |> validate_overlapping_age()
  end

  def validate_overlapping_age([head|tail]) do
    # recursion for overlapping age
      tail
      |> Enum.map(&(
        if comparing_age(head, &1) do
          true
        else
          with true <- comparing_age(&1, head)
          do
            true
          else
            _ ->
              false
          end

        end
      ))
      |> result_false_checker(tail)

  end

  def validate_overlapping_age([]), do: {:recursion_done}

  defp result_false_checker(result, tail) do
    if Enum.member?(result, false) do
      {:error_overlapping_age, "Benefit/s cannot be added. Selected benefit/s have ACU packages with overlapping age and gender."}
    else
      validate_overlapping_age(tail)
    end
  end

  defp comparing_age(a, b) do
    if a.age_from > b.age_to do
      true
    else
      false
    end
  end

  ## package payor procedure details
  defp package_pp_details(ppp_struct) do
    %{
      age_from: ppp_struct.age_from,
      age_to: ppp_struct.age_to,
      male: ppp_struct.male,
      female: ppp_struct.female
    }
  end

  defp ppp_gender_age_checker(list_maps, x) do
    ##  - package payor procedure gender and age checker
    ##     - take all package_payor_procedure of this package and distinct
    %{
      package_name: x,
      age_from: check_age_from(list_maps),
      age_to: check_age_to(list_maps),
      male: take_gender(list_maps, :male),
      female: take_gender(list_maps, :female)
    }
  end

  defp take_gender(list_maps, gender) do
    list_maps
    |> Enum.into([], &(&1[gender]))
    |> Enum.uniq()
    |> List.first()
  end

  defp check_age_from(ages) do
    ages
    |> Enum.into([], &(&1.age_from))
    |> Enum.uniq()
    |> List.first()
  end

  defp check_age_to(ages) do
    ages
    |> Enum.into([], &(&1.age_to))
    |> Enum.uniq()
    |> List.first()
  end

  def benefit_checker_reg_or_peme(product_id, benefit_id) do
    checker_query =
      from(
        pb in ProductBenefit,
        where: pb.product_id == ^product_id and pb.benefit_id == ^benefit_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def benefit_checker(product_id, benefit_id) do
    checker_query =
      from(
        pb in ProductBenefit,
        where: pb.product_id == ^product_id and pb.benefit_id == ^benefit_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      false
    else
      true
    end
  end


  def get_product_benefit_data(product_id, benefit_id) do
    checker_query =
      from(
        pb in ProductBenefit,
        where: pb.product_id == ^product_id and pb.benefit_id == ^benefit_id
      )

    result = Repo.all(checker_query) |> Repo.preload([:product_benefit_limits])
  end

  defp select_all_pc(product) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product.id)
    |> Repo.all()
  end

  defp for_product_coverage(product, product_coverage, coverage_ids) do
    if product_coverage == [] do
      for coverage_id <- coverage_ids do
        params = %{
          product_id: product.id,
          coverage_id: coverage_id
        }

        changeset = ProductCoverage.changeset(%ProductCoverage{}, params)
        Repo.insert!(changeset)
      end
    else
      product_coverage_ids =
        [] ++
          for pc <- product_coverage do
            pc.coverage_id
          end

      product_coverage_ids =
        product_coverage_ids
        |> List.flatten()

      coverage_left = coverage_ids -- product_coverage_ids

      coverage_left =
        coverage_left
        |> List.flatten()
        |> Enum.uniq()

      ## if coverage_left is [] it will ignore this for loop below
      for coverage <- coverage_left do
        params = %{
          product_id: product.id,
          coverage_id: coverage
        }

        changeset = ProductCoverage.changeset(%ProductCoverage{}, params)
        Repo.insert!(changeset)
      end
    end
  end

  defp for_rnb_rs_lt(product) do
    updated_product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()
      |> Repo.preload(:coverage)

    for upc <- updated_product_coverage do

      ### for room and board
      pcrnb_checker =
        ProductCoverageRoomAndBoard
        |> where([pcrnb], pcrnb.product_coverage_id == ^upc.id)
        |> Repo.all()

      if pcrnb_checker == [] do
        params = %{
          product_coverage_id: upc.id
        }

        if upc.coverage.description == "Maternity" or upc.coverage.description == "Inpatient" do
          changeset =
            ProductCoverageRoomAndBoard.changeset(%ProductCoverageRoomAndBoard{}, params)
            Repo.insert(changeset)
        end

        ## special checker for acu executive inpatient
        product
        |> check_acu_executive_inpatient(upc)

      end

      ### for product coverage risk share
      pcrs_checker =
        ProductCoverageRiskShare
        |> where([pcrs], pcrs.product_coverage_id == ^upc.id)
        |> Repo.all()

      if pcrs_checker == [] do
        params = %{
          product_coverage_id: upc.id
        }

        changeset = ProductCoverageRiskShare.changeset(%ProductCoverageRiskShare{}, params)
        Repo.insert(changeset)
      end

      ### for product coverage limit treshold
      pclt_checker =
        ProductCoverageLimitThreshold
        |> where([pclt], pclt.product_coverage_id == ^upc.id)
        |> Repo.all()

      if pclt_checker == [] do
        params = %{
          product_coverage_id: upc.id
        }

        changeset =
          ProductCoverageLimitThreshold.changeset(%ProductCoverageLimitThreshold{}, params)

          Repo.insert(changeset)
      end

    end
  end

  defp check_acu_executive_inpatient(product, upc) do
    product.product_benefits
    |> Enum.map(&(
      &1.benefit.benefit_coverages
      |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
        do: &1.benefit_id
      end)
    ))
    |> List.flatten()
    |> Enum.filter(fn(b) -> b != nil end)
    |> Enum.map(fn(a) -> check_benefit_acu_state(BenefitContext.get_benefit(a)) end)
    |> List.flatten()
    |> Enum.filter(fn(y) -> y.acu_type == "Executive" and y.acu_coverage == "Inpatient" end)
    |> contains_exec_inpatient?(upc)
  end

  def check_benefit_acu_state(benefit) do
    %{
      benefit_name: benefit.name,
      acu_type: benefit.acu_type,
      acu_coverage: benefit.acu_coverage
    }
  end

  def contains_exec_inpatient?(list, upc) do
    with false <- list |> Enum.empty?() do
      if upc.coverage.description == "ACU" do

        %ProductCoverageRoomAndBoard{}
        |> ProductCoverageRoomAndBoard.changeset(%{product_coverage_id: upc.id})
        |>  Repo.insert()

      end
    else
      true ->
        nil

      _ ->
        raise "Invalid collectable"
    end
  end

  defp check_rnb(product) do
    for product_benefit <- product.product_benefits do
      # Select all product coverages
      latest_product_coverage =
        ProductCoverage
        |> where([pc], pc.product_id == ^product.id)
        |> Repo.all()
        |> Repo.preload(:coverage)

      rnb_acu_checker(product_benefit, latest_product_coverage)

    end
  end

  defp rnb_acu_checker(product_benefit, latest_product_coverage) do
    for benefit_coverage <- product_benefit.benefit.benefit_coverages do
      coverage_name = benefit_coverage.coverage.name

      if coverage_name == "ACU" do

        cond do
          product_benefit.benefit.acu_type == "Executive" && product_benefit.benefit.acu_coverage == "Inpatient" ->
            accept_rnb(product_benefit, latest_product_coverage)

          product_benefit.benefit.acu_type == "Executive" && product_benefit.benefit.acu_coverage == "Outpatient" ->
            reject_rnb(product_benefit, latest_product_coverage)

          product_benefit.benefit.acu_type == "Regular" ->
            reject_rnb(product_benefit, latest_product_coverage)

          true ->
          ""

        end ## for cond do

      end ## if coverage_name == "ACU"

    end ## for benefit_coverage loop
  end

  defp accept_rnb(product_benefit, latest_product_coverage) do
    for lpc <- latest_product_coverage do
      if lpc.coverage.name == "ACU" do
        params = %{
          acu_product_benefit_id: product_benefit.id
        }

        changeset = ProductCoverage.changeset_acu_product_benefit(lpc, params)
        Repo.update!(changeset)
      end
    end
  end

  defp reject_rnb(product_benefit, latest_product_coverage) do
    for lpc <- latest_product_coverage do
      if lpc.coverage.name == "ACU" do
        params = %{
          product_coverage_id: lpc.id
        }

        pcrnb =
          ProductCoverageRoomAndBoard
          |> Repo.get_by(product_coverage_id: lpc.id)
        if is_nil(pcrnb) do
          {:ok, %{test: nil}}
        else
          Repo.delete(pcrnb)
        end
      end
    end
  end

  def set_product_coverage(product) do
    # Selects all coverages used in ProductBenefit and inserts it to ProductCoverage.
    coverage_ids =
      [] ++
        for product_benefit <- product.product_benefits do
          # Select all coverages from ProductBenefit.
          for benefit_coverage <- product_benefit.benefit.benefit_coverages do
            benefit_coverage.coverage.id
          end
        end

    coverage_ids =
      coverage_ids
      |> List.flatten()
      |> Enum.uniq()

    # Select all coverages from ProductCoverages.
    product_coverage = select_all_pc(product)

    ### inserting product_coverage
    for_product_coverage(product, product_coverage, coverage_ids)

    ### updating product_benefit.product_coverage_id exclusive only for ACU/s
    update_pb_pc(product)

    ### for room and board, riskshare and limittreshold
    for_rnb_rs_lt(product)

  end

  defp update_pb_pc(product) do
    product_coverage_id =
      product.product_coverages
      |> Enum.filter(&(&1.coverage.name == "ACU"))
      |> Enum.into([], &(&1.id))
      |> List.first()

    acu_product_benefits =
      product.product_benefits
      |> Enum.map(&(&1.benefit.benefit_coverages
      |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
        do: product_benefit_details(product, x, &1)
      end)
      ))
      |> List.flatten()
      |> Enum.reject(&(is_nil(&1)))

      updating_pb_for_only_acu(acu_product_benefits, product_coverage_id)
  end

  defp product_benefit_details(product, x, y) do
    %{
      benefit_id: x.benefit_id,
      benefit_name: y.benefit.name,
      product_id: product.id,
      coverage: x.coverage.name
    }
  end

  defp updating_pb_for_only_acu(acu_product_benefits, product_coverage_id) do
    acu_product_benefits
    |> Enum.each(&(
        ProductBenefit
        |> Repo.get_by(product_id: &1.product_id, benefit_id: &1.benefit_id)
        |> ProductBenefit.update_pc_changeset(%{product_coverage_id: product_coverage_id})
        |> Repo.update()
    ))
  end

  def clear_product_benefit(product) do
    # Deleting a ProductBenefit record.

    for product_benefit <- product.product_benefits do
      ProductBenefitLimit
      |> where([pbl], pbl.product_benefit_id == ^product_benefit.id)
      |> Repo.delete_all()
    end

    ProductBenefit
    |> where([pb], pb.product_id == ^product.id)
    |> Repo.delete_all()
  end

  def insert_or_update_product_benefit(params) do
    # If a there was no ProductBenefit record found,
    # the parameters given will be inserted into the ProductBenefit table,
    # or else, the existing ProductBenefit record will be searched and will be
    # updated by the parameters provided.
    product_benefit = get_by_product_and_benefit(params.product_id, params.benefit_id)

    if is_nil(product_benefit) do
      create_product_benefit(params)
    else
      update_a_product_benefit(product_benefit.id, params)
    end
  end

  def get_by_product_and_benefit(product_id, benefit_id) do
    # Search a ProductBenefit record by its 'product_id' and 'benefit_id'.

    ProductBenefit
    |> Repo.get_by(product_id: product_id, benefit_id: benefit_id)
  end

  def get_product_benefits(id) do
    # Search a ProductBenefit record by its ID.

    ProductBenefit
    |> Repo.get!(id)
  end

  def create_product_benefit(product_benefit_param) do
    # Inserts a new ProductBenefit record.

    %ProductBenefit{}
    |> ProductBenefit.changeset(product_benefit_param)
    |> Repo.insert()
  end

  def update_a_product_benefit(id, product_benefit_param) do
    # Updates a ProductBenefit record.

    id
    |> get_product_benefits()
    |> ProductBenefit.changeset(product_benefit_param)
    |> Repo.update()
  end

  ############ Start of product benefit limit seed
  def insert_or_update_product_benefit_limit(params) do
    product_benefit_limit =
      get_by_product_benefit_and_benefit_limit(params.product_benefit_id, params.benefit_limit_id)

    if is_nil(product_benefit_limit) do
      create_product_benefit_limit(params)
    else
      update_a_product_benefit_limit(product_benefit_limit.id, params)
    end
  end

  def get_by_product_benefit_and_benefit_limit(product_benefit_id, benefit_limit_id) do
    ProductBenefitLimit
    |> Repo.get_by(product_benefit_id: product_benefit_id, benefit_limit_id: benefit_limit_id)
  end

  def get_product_benefit_limit(id) do
    ProductBenefitLimit
    |> Repo.get!(id)
  end

  def create_product_benefit_limit(product_benefit_limit_param) do
    %ProductBenefitLimit{}
    |> ProductBenefitLimit.changeset(product_benefit_limit_param)
    |> Repo.insert()
  end

  def update_a_product_benefit_limit(id, product_benefit_param) do
    id
    |> get_product_benefit_limit()
    |> ProductBenefitLimit.changeset(product_benefit_param)
    |> Repo.update()
  end

  ############ End of product benefit limit seed

  ############ Start of product coverage facility seed
  def insert_or_update_product_coverage_facility(params) do
    product_coverage_facility =
      get_by_product_coverage_and_facility(params.product_coverage_id, params.facility_id)

    if is_nil(product_coverage_facility) do
      create_product_coverage_facility(params)
    else
      update_a_product_coverage_facility(product_coverage_facility.id, params)
    end
  end

  def get_by_product_coverage_and_facility(product_coverage_id, facility_id) do
    ProductCoverageFacility
    |> Repo.get_by(product_coverage_id: product_coverage_id, facility_id: facility_id)
  end

  def get_product_coverage_facility(id) do
    ProductCoverageFacility
    |> Repo.get(id)
  end

  def create_product_coverage_facility(product_coverage_facility_param) do
    %ProductCoverageFacility{}
    |> ProductCoverageFacility.changeset(product_coverage_facility_param)
    |> Repo.insert()
  end

  def update_a_product_coverage_facility(id, product_coverage_facility_param) do
    id
    |> get_product_coverage_facility()
    |> ProductCoverageFacility.changeset(product_coverage_facility_param)
    |> Repo.update()
  end

  ############ End of product coverage facility seed

  def benefit_hard_delete(product, product_benefit) do
    # Deletes a ProductBenefit record and all of the records that depends on it.

    # checks if selected benefitAcu that want to remove is carrying a data "Executive"-"Inpatient"
    product
    |> check_deleted_if_acu(product_benefit)

    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()

    deleted_coverages =
      for bc <- product_benefit.benefit.benefit_coverages do
        bc.coverage.id
      end

    product_coverage_ids =
      [] ++
        for pc <- product_coverage do
          pc.coverage_id
        end

    all_product_benefit_coverages =
      [] ++
        for product_benefit <- product.product_benefits do
          # Select all coverages from ProductBenefit.
          for benefit_coverage <- product_benefit.benefit.benefit_coverages do
            benefit_coverage.coverage.id
          end
        end

    all_product_benefit_coverages =
      all_product_benefit_coverages
      |> List.flatten()

    product_coverages = Enum.sort(product_coverage_ids)
    decremented = all_product_benefit_coverages -- deleted_coverages

    result =
      decremented
      |> Enum.uniq()
      |> Enum.sort()

    if result == product_coverages do
      nil
    else
      final_result = product_coverages -- result

      for dc <- final_result do
        ProductCoverage
        |> Repo.get_by(coverage_id: dc, product_id: product.id)
        |> Repo.delete()
      end
    end

    ProductBenefitLimit
    |> where([pbl], pbl.product_benefit_id == ^product_benefit.id)
    |> Repo.delete_all()

    ProductBenefit
    |> where([pb], pb.id == ^product_benefit.id)
    |> Repo.delete_all()
  end

  defp check_deleted_if_acu(product, product_benefit) do
    product.product_benefits
    |> Enum.map(&(
      &1.benefit.benefit_coverages
      |> Enum.into([], fn(x) -> if x.coverage.name == "ACU",
        do: &1.benefit_id
      end)
    ))
    |> List.flatten()
    |> Enum.filter(fn(b) -> b != nil end)
    |> Enum.map(fn(a) -> check_benefit_acu_state(BenefitContext.get_benefit(a)) end)
    |> List.flatten()
    |> check_excess(product_benefit, product)

  end

  defp check_excess(product_benefits, product_benefit, product) do
    product_benefit =
      product_benefit.benefit
      |> check_benefit_acu_state()

      product_benefits -- [product_benefit]
      |> Enum.filter(fn(y) -> y.acu_type == "Executive" and y.acu_coverage == "Inpatient" end)
      |> still_have_acu_exec_inpatient?(product)
  end

  defp still_have_acu_exec_inpatient?(list, product) do
    with true <- list |> Enum.empty?() do

      product.product_coverages
      |> Enum.filter(&(&1.coverage.name == "ACU"))
      |> Enum.at(0)
      |> delete_product_coverage_rnb()
    else
      false ->
        nil

      _ ->
        raise "Invalid collectable"
    end
  end

  defp delete_product_coverage_rnb(acu_product_coverage) do
    if is_nil(acu_product_coverage) do
      nil
    else
      pcrnb =
        ProductCoverageRoomAndBoard
        |> Repo.get_by(product_coverage_id: acu_product_coverage.id)
        if is_nil(pcrnb) do
          {:ok, %{test: nil}}
        else
          Repo.delete(pcrnb)
        end
    end
  end

  #################### END -- Functions related to ProductBenefit.

  #################### START -- Functions related to ProductBenefitLimit.

  # Searches a ProductBenefitLimit by its ID.
  def get_product_benefit_limit(id), do: Repo.get!(ProductBenefitLimit, id)

  def update_product_benefit_limit(%ProductBenefitLimit{} = product_benefit_limit, product_params) do
    # Updates a ProductBenefitLimit record.

    product_benefit_limit
    |> ProductBenefitLimit.changeset(product_params)
    |> Repo.update()
  end

  ##################### END -- Functions related to ProductBenefitLimit.

  ##################### START -- Functions related to ProductExclusion.

  # Searches a ProductExclusion record accoring to its ID.
  def get_product_exclusion(id), do: Repo.get!(ProductExclusion, id)

  def set_genex(product_id, exclusions_ids) do
    # Inserts a new ProductExclusion record with a coverage of 'Exclusion'.
    for exclusion_id <- exclusions_ids do
      result = genex_and_pre_existing_checker(product_id, exclusion_id)

      if result == true do
        params = %{product_id: product_id, exclusion_id: exclusion_id}
        changeset_genex = ProductExclusion.changeset_genex(%ProductExclusion{}, params)
        Repo.insert!(changeset_genex)
      end
    end
  end

  def set_pre_existing(product_id, exclusions_ids) do
    # Inserts a new ProductExclusion record with a coverage of 'Pre-existing condition'.

    result =
      exclusions_ids
      |> validate_exclusions

    if result == true do
      exclusions =
        exclusions_ids
        |> insert_product_exclusions(product_id)
        {:ok, exclusions}
    else
      {:error}
    end
  end

  defp validate_exclusions(exclusion_ids) do
     # Validates Exclusion if it has Exclusion Limit.

    result = for exclusion_id <- exclusion_ids do
      exclusion = ExclusionContext.get_exclusion(exclusion_id)

      if is_nil(exclusion.limit_type) do
        true
      end
    end

    if Enum.member?(result, true) do
      false
    else
      true
    end
  end

  defp insert_product_exclusions(exclusions_ids, product_id) do
    for exclusion_id <- exclusions_ids do
      result = genex_and_pre_existing_checker(product_id, exclusion_id)

      if result == true do
        params = %{product_id: product_id, exclusion_id: exclusion_id}

        changeset_pre_existing =
          ProductExclusion.changeset_pre_existing(%ProductExclusion{}, params)

        product_exclusion = Repo.insert!(changeset_pre_existing)

        exclusion = ExclusionContext.get_exclusion(exclusion_id)

        limit_peso =
          if exclusion.limit_type == "Peso" do
            exclusion.limit_amount
          else
            nil
          end

        limit_percentage =
          if exclusion.limit_type == "Percentage" do
            exclusion.limit_percentage
          else
            nil
          end

        limit_session =
          if exclusion.limit_type == "Sessions" do
            exclusion.limit_session
          else
            nil
          end

        pe_params = %{
          product_exclusion_id: product_exclusion.id
        }

        limit_params = %{
          product_exclusion_id: product_exclusion.id,
          limit_type: exclusion.limit_type,
          limit_peso: limit_peso,
          limit_percentage: limit_percentage,
          limit_session: limit_session
        }

        product_exclusion_limit = create_product_exclusion_limit(pe_params)

        product_exclusion_limit
        |> ProductExclusionLimit.changeset_pec_limit(limit_params)
        |> Repo.update!()
        |> Repo.preload(product_exclusion: [:exclusion, :product])
      end
    end
  end

  def genex_and_pre_existing_checker(product_id, exclusion_id) do
    checker_query =
      from(
        pe in ProductExclusion,
        where: pe.product_id == ^product_id and pe.exclusion_id == ^exclusion_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def clear_genex(product) do
    # Clears all ProductExclusion record with a coverage of 'Exclusion'.

    ProductExclusion
    |> join(:inner, [pe], e in assoc(pe, :exclusion))
    |> where([pe, e], pe.product_id == ^product.id and e.coverage == "Exclusion")
    |> Repo.delete_all()
  end

  def clear_pre_existing(product) do
    # Clears all ProductExlusion record with a coverage of 'Pre-existing condition'.

    ProductExclusion
    |> join(:inner, [pe], e in assoc(pe, :exclusion))
    |> where([pe, e], pe.product_id == ^product.id and e.coverage == "Pre-existing condition")
    |> Repo.delete_all()
  end

  def delete_product_exclusion!(product, product_exclusion_id) do
    # Deletes a product Exclusion record.

    ProductExclusion
    |> Repo.get(product_exclusion_id)
    |> Repo.delete()
  end

  ###################### END -- Functions related to ProductExclusion.

  ###################### START -- Functions related to Benefit.

  def get_benefit_coverage(benefit_id) do
    # Returns Benefit record with its coverages

    Benefit
    |> Repo.get!(benefit_id)
    |> Repo.preload(benefit_coverages: :coverage)
  end

  # END -- Functions related to Benefit.

  # START -- Functions related to Facility.

  def get_list_of_facilities do
    # Returns all records inside the Facility table.

    Facility
    |> Repo.all()
    |> Repo.preload([
      :category,
      :type,
      :facility_payor_procedures
    ])
  end

  ###################### END -- Functions related to Facility.

  ####################### START -- Functions related to Procedure.

  def get_all_procedure do
    # Returns all Procedure records

    Procedure
    |> Repo.all()
  end

  ######################## END -- Functions related to Procedure.

  ######################## START -- Functions related to Logs.

  def create_product_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        product_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end



def create_product_log_join_tables(product_id, user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."

      insert_log(%{
        product_id: product_id,
        user_id: user.id,
        message: message
      })
    end
  end


  def delete_product_benefit_log(user, product_benefit, product_id) do
    # product_benefit_id = product_benefit["benefit_id"]
    benefit_code = BenefitContext.get_benefits_by_id(product_benefit)
    code = benefit_code.code
    # code = product_benefit
    # code = product_id
    message = "#{user.username} deleted a benefit where benefit code is #{code}."
    insert_log(%{
      product_id: product_id,
      user_id: user.id,
      message: message
    })
  end

  defp changes_to_string(changeset) do
    changes =
      for {key, new_value} <- changeset.changes, into: [] do
        "#{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
      end

    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = ProductLog.changeset(%ProductLog{}, params)
    Repo.insert!(changeset)
  end

  ######################### END -- Functions related to Log.

  ######################### START -- Functions related to ProductCoverage.

  def get_product_coverage(product_id) do
    # Searches a ProductCoverage record according to Product ID.

    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> Repo.all()
    |> Repo.preload([
      :coverage,
      product_coverage_facilities: [
        facility: [:category, :type, facility_location_groups: :location_group]
      ],
      product_coverage_risk_share: [
        product_coverage_risk_share_facilities: [
          :facility,
          product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
        ]
      ]
    ])
  end

  def get_product_coverage_by_id(product_coverage_id) do
    # Searches a ProductCoverage record according to its ID.

    ProductCoverage
    |> where([pc], pc.id == ^product_coverage_id)
    |> Repo.one!()
    |> Repo.preload(
      product_coverage_facilities: [facility: [:category, :type]],
      product_coverage_risk_share: [
        product_coverage_risk_share_facilities: [
          :facility,
          product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
        ]
      ]
    )
  end

  def get_pc_rnb(product_coverage_rnb_id) do
    # get one ProductCoverageRNB record according to its ID.
    ProductCoverageRoomAndBoard
    |> Repo.get(product_coverage_rnb_id)
    |> Repo.preload([
      :product_coverage
    ])
  end

  def set_product_coverage_type(nil, _), do: nil
  def set_product_coverage_type(product_coverage, attrs) do
    # Sets the coverage type of ProductCoverage.

    product_coverage
    |> ProductCoverage.changeset(attrs)
    |> Repo.update()
  end

  def insert_or_update_product_coverage(params) do
    product_coverage =
      ProductCoverage
      |> Repo.get_by(product_id: params.product_id, coverage_id: params.coverage_id)

    if is_nil(product_coverage) do
      create_product_coverage(params)
    else
      update_a_product_coverage(product_coverage.id, params)
    end
  end

  def create_product_coverage(product_coverage_param) do
    # Inserts a new ProductBenefit record.

    %ProductCoverage{}
    |> ProductCoverage.changeset(product_coverage_param)
    |> Repo.insert()
  end

  def update_a_product_coverage(id, product_coverage_param) do
    # Updates a ProductBenefit record.
    id
    |> get_product_coverage_by_id()
    |> ProductCoverage.changeset(product_coverage_param)
    |> Repo.update()
  end

  ######################### END -- Functions related to ProductCoverage.

  ######################### START -- Functions related to ProductCoverageFacility.

  def clear_product_facility(product_coverage_id) do
    # Clear all ProductCoverageFacility according to its ProductCoverage ID.

    ProductCoverageFacility
    |> where([pcf], pcf.product_coverage_id == ^product_coverage_id)
    |> Repo.delete_all()
  end

  def clear_product_risk_share_facility(product_coverage_id) do
    pcdrs_ids =
      ProductCoverageDentalRiskShare
      |> where([pcdrs], pcdrs.product_coverage_id == ^product_coverage_id)
      |> join(:inner, [pcdrs], pcdrsf in ProductCoverageDentalRiskShareFacility, pcdrs.id == pcdrsf.product_coverage_dental_risk_share_id)
      |> select([pcdrs], pcdrs.id)
      |> Repo.all()

    pcdrsf =
      ProductCoverageDentalRiskShareFacility
      |> where([pcdrsf], pcdrsf.product_coverage_dental_risk_share_id in ^pcdrs_ids)
      |> Repo.delete_all()

    # ProductCoverageDentalRiskShare
    # |> where([pcdrs], pcdrs.id in ^pcdrs_ids)
    # |> Repo.delete_all()

    # ProductCoverageDentalRiskShare
    # |> Repo.update_all(set: [asdf_type: nil, asdf_amount: nil, asdf_percentage: nil, asdf_special_handling: nil])
  end

  def clear_pclt_facility(pclt_id) do
    # Clear all ProductCoverageFacility according to its ProductCoverage ID.

    ProductCoverageLimitThresholdFacility
    |> where([pcltf], pcltf.product_coverage_limit_threshold_id == ^pclt_id)
    |> Repo.delete_all()
  end

  def get_product_facility(product_coverage_facility_id) do
    # Returns all ProductCoverageFacility according to its ProductCoverage ID.

    ProductCoverageFacility
    |> where([pcf], pcf.id == ^product_coverage_facility_id)
    |> Repo.all()
    |> Repo.preload(facility: [:category, :type, facility_location_groups: :location_group])
  end

  def set_product_facility(nil, _), do: nil
  def set_product_facility(product_coverage_id, facility_ids) do
    # Inserts a record into ProductCoverageFacility.

    for facility_id <- facility_ids do
      params = %{facility_id: facility_id, product_coverage_id: product_coverage_id}
      changeset = ProductCoverageFacility.changeset(%ProductCoverageFacility{}, params)
      Repo.insert!(changeset)
    end
  end

  def delete_product_facility(product_facility_id) do
    # Deletes a ProductCoverageFacility according to its ID.

    ProductCoverageFacility
    |> where([pcf], pcf.id == ^product_facility_id)
    |> Repo.delete_all()
  end

  def delete_product_facilities(product_coverage_id) do
    # Deletes a ProductCoverageFacility according to its ProductCoverage.

    ProductCoverageFacility
    |> where([pcf], pcf.product_coverage_id == ^product_coverage_id)
    |> Repo.delete_all()

    delete_pclt_records(product_coverage_id)
  end

  def delete_pclt_records(product_coverage_id) do
    pclt_records =
      ProductCoverageLimitThreshold
      |> where([pclt], pclt.product_coverage_id == ^product_coverage_id)
      |> Repo.all()

    for pclt_record <- pclt_records do
      params = %{
        product_coverage_id: product_coverage_id,
        limit_threshold: nil
      }

      ProductCoverageLimitThreshold
      |> Repo.get(pclt_record.id)
      |> ProductCoverageLimitThreshold.changeset(params)
      |> Repo.update()

      ProductCoverageLimitThresholdFacility
      |> where([pcltf], pcltf.product_coverage_limit_threshold_id == ^pclt_record.id)
      |> Repo.delete_all()
    end
  end

  ######################### END -- Functions related to ProductCoverageFacility.

  ######################### START -- Functions related to ProductCondition.

  def update_product_condition(%Product{} = product, product_params) do
    # Updates all fields regarding Condition.

    if Map.has_key?(product_params, "availment_type") do
      if Enum.member?(product_params["availment_type"], "LOA facilitated") && Enum.member?(product_params["availment_type"], "Reimbursement") do
        product_params =
          product_params
          |> Map.put("availment_type", "LOA facilitated, Reimbursement")
      else
        availment_type = List.first(product_params["availment_type"])
        product_params =
          product_params
          |> Map.put("availment_type", availment_type)
      end
    end

    if product_params["is_medina"] == "false" do
      product_params = Map.put(product_params, "smp_limit", "")
    else
      product_params
    end
    product
    |> Product.changeset_condition(product_params)
    |> Repo.update()
  end

  def clear_product_condition_hierarchy(product_id) do
    ProductConditionHierarchyOfEligibleDependent
    |> where([pchoed], pchoed.product_id == ^product_id)
    |> Repo.delete_all()
  end

  def insert_product_condition_hierarchy(product_id, hierarchy_type, dependent, ranking) do
    params = %{
      product_id: product_id,
      hierarchy_type: hierarchy_type,
      dependent: dependent,
      ranking: ranking
    }

    changeset =
      ProductConditionHierarchyOfEligibleDependent.changeset(
        %ProductConditionHierarchyOfEligibleDependent{},
        params
      )

    Repo.insert!(changeset)
  end

  def update_pc_rnb_batch(product_params) do
    rnb_list =
      product_params["rnb_array"]
      |> String.split(",")

    rnb_records =
      [] ++
        for rnb <- rnb_list do
          rnb =
            rnb
            |> String.split("_")

          product_coverage_rnb = get_pc_rnb(Enum.at(rnb, 0))
          room_and_board = Enum.at(rnb, 1)

          room_upgrade =
            if Enum.at(rnb, 4) == "nil" do
              nil
            else
              Enum.at(rnb, 4)
            end

          case room_and_board do
            "Alternative" ->
              params = %{
                "product_coverage_room_and_board_id" => Enum.at(rnb, 0),
                "room_and_board" => Enum.at(rnb, 1),
                "room_limit_amount" => Enum.at(rnb, 3),
                "room_upgrade" => room_upgrade,
                "room_type" => Enum.at(rnb, 2),
                "room_upgrade_time" => Enum.at(rnb, 5),
                "step" => product_params["step"],
                "updated_by_id" => product_params["updated_by_id"]
              }

              product_coverage_rnb
              |> ProductCoverageRoomAndBoard.changeset_update(params)
              |> Repo.update()

            "Nomenclature" ->
              params = %{
                "product_coverage_room_and_board_id" => Enum.at(rnb, 0),
                "room_and_board" => Enum.at(rnb, 1),
                "room_limit_amount" => nil,
                "room_upgrade" => room_upgrade,
                "room_type" => Enum.at(rnb, 2),
                "room_upgrade_time" => Enum.at(rnb, 5),
                "step" => product_params["step"],
                "updated_by_id" => product_params["updated_by_id"]
              }

              product_coverage_rnb
              |> ProductCoverageRoomAndBoard.changeset_update(params)
              |> Repo.update()

            "Peso Based" ->
              params = %{
                "product_coverage_room_and_board_id" => Enum.at(rnb, 0),
                "room_and_board" => Enum.at(rnb, 1),
                "room_limit_amount" => Enum.at(rnb, 3),
                "room_upgrade" => room_upgrade,
                "room_type" => nil,
                "room_upgrade_time" => Enum.at(rnb, 5),
                "step" => product_params["step"],
                "updated_by_id" => product_params["updated_by_id"]
              }

              product_coverage_rnb
              |> ProductCoverageRoomAndBoard.changeset_update(params)
              |> Repo.update()

            _ ->
              nil
              ## do nothing
          end
        end
  end

  def update_pc_rnb(%ProductCoverageRoomAndBoard{} = product_coverage_rnb, product_params) do
    # Updates a ProductCoverageRoomAndBoard.

    rnb = product_params["room_and_board"]

    case rnb do
      "Alternative" ->
        params = %{
          "product_coverage_room_and_board_id" =>
            product_params["product_coverage_room_and_board_id"],
          "room_and_board" => product_params["room_and_board"],
          "room_limit_amount" => product_params["room_limit_amount"],
          "room_upgrade" => product_params["room_upgrade"],
          "room_type" => product_params["room_type"],
          "room_upgrade_time" => product_params["room_upgrade_time"],
          "step" => product_params["step"],
          "updated_by_id" => product_params["updated_by_id"]
        }

        product_coverage_rnb
        |> ProductCoverageRoomAndBoard.changeset_update(params)
        |> Repo.update()

      "Nomenclature" ->
        params = %{
          "product_coverage_room_and_board_id" =>
            product_params["product_coverage_room_and_board_id"],
          "room_and_board" => product_params["room_and_board"],
          "room_limit_amount" => nil,
          "room_upgrade" => product_params["room_upgrade"],
          "room_type" => product_params["room_type"],
          "room_upgrade_time" => product_params["room_upgrade_time"],
          "step" => product_params["step"],
          "updated_by_id" => product_params["updated_by_id"]
        }

        product_coverage_rnb
        |> ProductCoverageRoomAndBoard.changeset_update(params)
        |> Repo.update()

      "Peso Based" ->
        params = %{
          "product_coverage_room_and_board_id" =>
            product_params["product_coverage_room_and_board_id"],
          "room_and_board" => product_params["room_and_board"],
          "room_limit_amount" => product_params["room_limit_amount"],
          "room_upgrade" => product_params["room_upgrade"],
          "room_upgrade_time" => product_params["room_upgrade_time"],
          "room_type" => nil,
          "step" => product_params["step"],
          "updated_by_id" => product_params["updated_by_id"]
        }

        product_coverage_rnb
        |> ProductCoverageRoomAndBoard.changeset_update(params)
        |> Repo.update()

      _ ->
        nil
        ## do nothing
    end
  end

  def insert_or_update_product_coverage_room_and_board(params) do
    product_coverage_room_and_board =
      ProductCoverageRoomAndBoard
      |> Repo.get_by(product_coverage_id: params.product_coverage_id)

    if is_nil(product_coverage_room_and_board) do
      create_product_coverage_room_and_board(params)
    else
      update_a_product_coverage_room_and_board(product_coverage_room_and_board.id, params)
    end
  end

  def create_product_coverage_room_and_board(product_coverage_room_and_board_param) do
    # Inserts a new ProductCoverageRoomAndBoard record.
    %ProductCoverageRoomAndBoard{}
    |> ProductCoverageRoomAndBoard.changeset(product_coverage_room_and_board_param)
    |> Repo.insert()
  end

  def update_a_product_coverage_room_and_board(id, product_coverage_room_and_board_param) do
    # Updates a ProductBenefit record.

    id
    |> get_pc_rnb()
    |> ProductCoverageRoomAndBoard.changeset(product_coverage_room_and_board_param)
    |> Repo.update()
  end

  ######################### END -- Functions related to ProductCondition.

  ######################### START -- Functions related to ProductRiskShare.

  def set_product_risk_share(product, product_params) do
    # Inserts or updated ProductRiskShare record.

    for {id, val} <- product_params["funding"] do
      riskshare =
        ProductRiskShare
        |> Repo.get_by(%{product_id: product.id, coverage_id: id})

      if riskshare do
        params = %{fund: val}
        changeset = ProductRiskShare.changeset(riskshare, params)
        Repo.update!(changeset)
      else
        params = %{
          fund: val,
          product_id: product.id,
          coverage_id: id
        }

        changeset = ProductRiskShare.changeset(%ProductRiskShare{}, params)
        Repo.insert!(changeset)
      end
    end
  end

  def set_product_coverage_funding(product, product_params) do
    # Updating ProductCoverage.funding_arrangement field.
    for {product_coverage_id, val} <- product_params["funding_arrangement"] do
      product_coverage =
        ProductCoverage
        |> Repo.get(product_coverage_id)

      params = %{funding_arrangement: val}
      changeset = ProductCoverage.changeset_funding(product_coverage, params)
      Repo.update(changeset)
    end
  end

  def get_product_risk_shares(product) do
    # Returns all ProductRiskShare according to its Product ID.

    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()

    pcrs_list =
      for pc <- product_coverage do
        ProductCoverageRiskShare
        |> where([pcrs], pcrs.product_coverage_id == ^pc.id)
        |> Repo.one!()
        |> Repo.preload(
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
          ]
        )
      end
  end

  def get_facility_payor_procedure(product) do
    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()

    for pc <- product_coverage do
      product_coverage_risk_share =
        ProductCoverageRiskShare
        |> where([pcrs], pcrs.product_coverage_id == ^pc.id)
        |> Repo.all()

      for pcrs <- product_coverage_risk_share do
        product_coverage_risk_share_facility =
          ProductCoverageRiskShareFacility
          |> where([pcrsf], pcrsf.product_coverage_risk_share_id == ^pcrs.id)
          |> Repo.all()
          |> Repo.preload(
            :facility,
            product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
          )

        pcrsfpp_list =
          for pcrsf <- product_coverage_risk_share_facility do
            product_coverage_risk_share_facility_payor_procedure =
              ProductCoverageRiskShareFacilityPayorProcedure
              |> where([pcrsfpp], pcrsfpp.product_coverage_risk_share_facility_id == ^pcrsf.id)
              |> Repo.all()
              |> Repo.preload([:facility_payor_procedure])
          end
      end
    end
  end

  def get_facility_payor_procedure_by_product_id(product_id) do
    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product_id)
      |> Repo.all()

    for pc <- product_coverage do
      product_coverage_risk_share =
        ProductCoverageRiskShare
        |> where([pcrs], pcrs.product_coverage_id == ^pc.id)
        |> Repo.all()

      for pcrs <- product_coverage_risk_share do
        product_coverage_risk_share_facility =
          ProductCoverageRiskShareFacility
          |> where([pcrsf], pcrsf.product_coverage_risk_share_id == ^pcrs.id)
          |> Repo.all()
          |> Repo.preload(
            :facility,
            product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedures
          )

        pcrsfpp_list =
          for pcrsf <- product_coverage_risk_share_facility do
            product_coverage_risk_share_facility_payor_procedure =
              ProductCoverageRiskShareFacilityPayorProcedure
              |> where([pcrsfpp], pcrsfpp.product_coverage_risk_share_facility_id == ^pcrsf.id)
              |> Repo.all()
              |> Repo.preload([:facility_payor_procedures])
          end
      end
    end
  end

  def get_fpp(prsf_id) do
    pcrsfs =
      ProductCoverageRiskShareFacility
      |> where([pcrs], pcrs.id == ^prsf_id)
      |> Repo.all()
      |> Repo.preload(
        :facility,
        product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedures
      )

    for pcrsf <- pcrsfs do
      facility_payor_procedure =
        FacilityPayorProcedure
        |> where([fpp], fpp.facility_id == ^pcrsf.facility_id)
        |> Repo.all()
    end
  end

  def get_product_coverages_rnb(product) do
    # Returns all ProductCoverage according to its Product ID.
    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()

    all_pcrnbs =
      ProductCoverageRoomAndBoard
      |> Repo.all()
      |> Repo.preload(product_coverage: :coverage)

    pcrnb_list =
      for pc <- product_coverage do
        for all_pcrnb <- all_pcrnbs do
          if pc.id == all_pcrnb.product_coverage_id do
            all_pcrnb
          end
        end
      end

    pcrnb_list =
      pcrnb_list
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def get_product_coverages_lt(product) do
    # Returns all ProductCoverage according to its Product ID.
    product_coverage =
      ProductCoverage
      |> where([pc], pc.product_id == ^product.id)
      |> Repo.all()

    all_pclts =
      ProductCoverageLimitThreshold
      |> Repo.all()
      |> Repo.preload(
        product_coverage: :coverage,
        product_coverage_limit_threshold_facilities: :facility
      )

    pclt_list =
      for pc <- product_coverage do
        for all_pclt <- all_pclts do
          if pc.id == all_pclt.product_coverage_id do
            all_pclt
          end
        end
      end

    pclt_list =
      pclt_list
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def update_product_risk_share(%ProductCoverageRiskShare{} = product_risk_share, product_params) do
    # Updates a ProductRiskShare.
    # get rid of af_checker and naf_checker

    af_type = product_params["af_type"]
    naf_type = product_params["naf_type"]

    af_covered = product_params["af_covered_percentage"]
    naf_covered = product_params["naf_covered_percentage"]

    if af_type == "N/A" or af_type == "CoInsurance" do
      if naf_type == "N/A" or naf_type == "CoInsurance" do
        params = %{
          product_coverage_risk_share_id: product_params["risk_share_id"],
          af_type: product_params["af_type"],
          af_value: nil,
          af_value_percentage: product_params["af_value"],
          af_value_amount: nil,
          af_covered_percentage: af_covered,
          af_covered_amount: nil,
          naf_reimbursable: product_params["naf_reimbursable"],
          naf_type: product_params["naf_type"],
          naf_value: nil,
          naf_value_percentage: product_params["naf_value"],
          naf_value_amount: nil,
          naf_covered_percentage: naf_covered,
          naf_covered_amount: nil
        }
      else
        params = %{
          product_coverage_risk_share_id: product_params["risk_share_id"],
          af_type: product_params["af_type"],
          af_value: nil,
          af_value_percentage: product_params["af_value"],
          af_value_amount: nil,
          af_covered_percentage: af_covered,
          af_covered_amount: nil,
          naf_reimbursable: product_params["naf_reimbursable"],
          naf_type: product_params["naf_type"],
          naf_value: nil,
          naf_value_percentage: nil,
          naf_value_amount: product_params["naf_value"],
          naf_covered_percentage: naf_covered,
          naf_covered_amount: nil
        }
      end
    else
      if naf_type == "N/A" or naf_type == "CoInsurance" do
        params = %{
          product_coverage_risk_share_id: product_params["risk_share_id"],
          af_type: product_params["af_type"],
          af_value: nil,
          af_value_percentage: nil,
          af_value_amount: product_params["af_value"],
          af_covered_percentage: af_covered,
          af_covered_amount: nil,
          naf_reimbursable: product_params["naf_reimbursable"],
          naf_type: product_params["naf_type"],
          naf_value: nil,
          naf_value_percentage: product_params["naf_value"],
          naf_value_amount: nil,
          naf_covered_percentage: naf_covered,
          naf_covered_amount: nil
        }
      else
        params = %{
          product_coverage_risk_share_id: product_params["risk_share_id"],
          af_type: product_params["af_type"],
          af_value: nil,
          af_value_percentage: nil,
          af_value_amount: product_params["af_value"],
          af_covered_percentage: af_covered,
          af_covered_amount: nil,
          naf_reimbursable: product_params["naf_reimbursable"],
          naf_type: product_params["naf_type"],
          naf_value: nil,
          naf_value_percentage: nil,
          naf_value_amount: product_params["naf_value"],
          naf_covered_percentage: naf_covered,
          naf_covered_amount: nil
        }
      end
    end

    product_risk_share
    |> ProductCoverageRiskShare.changeset(params)
    |> Repo.update()
  end

  def get_product_risk_share(risk_share_id) do
    # Returns a ProductRiskShare record according to its ID.

    ProductCoverageRiskShare
    |> Repo.get!(risk_share_id)
    |> Repo.preload(product_coverage_risk_share_facilities: :facility)
  end

  def get_product_riskshare_facility(risk_share_id, facility_id) do
    # Returns a ProductRiskShareFacility record according to its ProductRiskShare ID and Facility ID.

    ProductCoverageRiskShareFacility
    |> Repo.get_by(product_coverage_risk_share_id: risk_share_id, facility_id: facility_id)
    |> Repo.preload([:product_coverage_risk_share, facility: [:category, :type, :facility_location_groups]])
  end

  def get_product_riskshare_facility_procedure(product_risk_share_facility_id, procedure_id) do
    # Returns a ProductRiskShareFacilityProcedure record according to its ProductRiskShareFacility ID and Procedure ID.

    ProductCoverageRiskShareFacilityPayorProcedure
    |> Repo.get_by(
      product_coverage_risk_share_facility_id: product_risk_share_facility_id,
      facility_payor_procedure_id: procedure_id
    )
    |> Repo.preload([
      [
        facility_payor_procedure: [
          facility: [:category, :type, :facility_location_groups],
          facility_payor_procedure_rooms: [
            facility_room_rate:
            [facility:
             [:category,
              :type,
              :facility_location_groups
             ]
            ]
          ]
        ]
      ],
      product_coverage_risk_share_facility: [
        :product_coverage_risk_share,
        facility: [:category, :type, :facility_location_groups]
      ]
    ])
  end

  def set_product_risk_share_facility(product_params) do
    # Inserts a ProductRiskShareFacility record.
    facility = validate_facility(product_params)
    type = product_params["type"]

    if type == "Copayment" do
      params = %{
        "product_coverage_risk_share_id" => product_params["product_coverage_risk_share_id"],
        "facility_id" => product_params["facility_id"],
        "type" => type,
        "value" => nil,
        "value_percentage" => nil,
        "value_amount" => product_params["value"],
        "covered" => product_params["covered"]
      }
    else
      params = %{
        "product_coverage_risk_share_id" => product_params["product_coverage_risk_share_id"],
        "facility_id" => product_params["facility_id"],
        "type" => type,
        "value" => nil,
        "value_percentage" => product_params["value"],
        "value_amount" => nil,
        "covered" => product_params["covered"]
      }
    end

    if facility do
      facility
      |> ProductCoverageRiskShareFacility.changeset(params)
      |> Repo.update()
    else
      result = prsf_checker(product_params)

      if result == true do
        %ProductCoverageRiskShareFacility{}
        |> ProductCoverageRiskShareFacility.changeset(params)
        |> Repo.insert()
      end
    end
  end

  def prsf_checker(product_params) do
    # Checks if ProductRiskShareFacility is existing.
    facility_id = product_params["facility_id"]
    product_rs = product_params["product_risk_share_id"]

    checker_query =
      from(
        prsf in ProductCoverageRiskShareFacility,
        where:
          prsf.product_coverage_risk_share_id == ^product_rs and prsf.facility_id == ^facility_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def set_product_dental_risk_share_facility(params) do
    # Inserts a ProductDentalRiskShareFacility record.
    facility = validate_dental_facility(params)

    if facility do
      facility
      |> ProductCoverageDentalRiskShareFacility.changeset(params)
      |> Repo.update()
    else
      result = pdrsf_checker(params)

      if result == true do
        %ProductCoverageDentalRiskShareFacility{}
        |> ProductCoverageDentalRiskShareFacility.changeset(params)
        |> Repo.insert()
      end
    end
  end

  def pdrsf_checker(params) do
    # Checks if ProductDentalRiskShareFacility is existing.
    facility_id = params["facility_id"]
    product_rs = params["product_dental_risk_share_id"]

    checker_query =
      from(
        pdrsf in ProductCoverageDentalRiskShareFacility,
        where:
          pdrsf.product_coverage_dental_risk_share_id == ^product_rs and pdrsf.facility_id == ^facility_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def prsfp_checker(product_params) do
    # Checks if ProductRiskShareFacilityProcedure is existing.

    product_rsf = product_params["product_risk_share_facility_id"]
    procedure_id = product_params["procedure_id"]

    checker_query =
      from(
        prsfp in ProductCoverageRiskShareFacilityPayorProcedure,
        where:
          prsfp.product_coverage_risk_share_facility_id == ^product_rsf and
            prsfp.facility_payor_procedure_id == ^procedure_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  def get_product_risk_share_facility(risk_share_facility_id) do
    # Returns ProductRiskShareFacility record according to its ID.
    ProductCoverageRiskShareFacility
    |> Repo.get!(risk_share_facility_id)
    |> Repo.preload([
      :product_coverage_risk_share_facility_payor_procedures,
      :product_coverage_risk_share,
      facility: [:category, :type, :facility_location_groups]
    ])
  end

  def set_product_risk_share_facility_procedure(product_params) do
    # Inserts or updated ProductRiskShareFacility record.
    procedure = validate_procedure(product_params)
    type = product_params["type"]

    if type == "Copayment" do
      params = %{
        product_coverage_risk_share_facility_id: product_params["product_risk_share_facility_id"],
        facility_payor_procedure_id: product_params["procedure_id"],
        type: type,
        value: nil,
        value_percentage: nil,
        value_amount: product_params["value"],
        covered: product_params["covered"]
      }
    else
      params = %{
        "product_coverage_risk_share_facility_id" =>
          product_params["product_risk_share_facility_id"],
        "facility_payor_procedure_id" => product_params["procedure_id"],
        "type" => type,
        "value" => nil,
        "value_percentage" => product_params["value"],
        "value_amount" => nil,
        "covered" => product_params["covered"]
      }
    end

    if procedure do
      procedure
      |> ProductCoverageRiskShareFacilityPayorProcedure.changeset(params)
      |> Repo.update()
    else
      result = prsfp_checker(product_params)

      if result == true do
        %ProductCoverageRiskShareFacilityPayorProcedure{}
        |> ProductCoverageRiskShareFacilityPayorProcedure.changeset(params)
        |> Repo.insert()
      end
    end
  end

  def validate_facility(product_params) do
    # Checks if the parameters provided is not blank.

    if product_params["product_risk_share_facility_id"] == "" do
      nil
    else
      ProductCoverageRiskShareFacility
      |> Repo.get(product_params["product_risk_share_facility_id"])
    end
  end

  def validate_dental_facility(product_params) do
    # Checks if the parameters provided is not blank.

    if product_params["product_dental_risk_share_facility_id"] == "" do
      nil
    else
      ProductCoverageDentalRiskShareFacility
      |> Repo.get(product_params["product_dental_risk_share_facility_id"])
    end
  end

  def validate_procedure(product_params) do
    # Checks if the parameters provided is not blank.

    if product_params["pcrsfpp"] == "" do
      nil
    else
      ProductCoverageRiskShareFacilityPayorProcedure
      |> Repo.get(product_params["pcrsfpp"])
    end
  end

  def clear_prs_facility(prsf_id) do
    # Clears ProductRiskShareFacility and ProductRiskShareFacility records according to ProductRiskShareFacility ID.

    ProductCoverageRiskShareFacilityPayorProcedure
    |> where([prsfpp], prsfpp.product_coverage_risk_share_facility_id == ^prsf_id)
    |> Repo.delete_all()

    ProductCoverageRiskShareFacility
    |> Repo.get(prsf_id)
    |> Repo.delete()
  end

  def clear_prsf_procedure(prsfp_id) do
    # Deletes a ProductRiskShareFacilityProcedure record.

    ProductCoverageRiskShareFacilityPayorProcedure
    |> Repo.get(prsfp_id)
    |> Repo.delete()
  end

  def get_prs(product_coverage_id) do
    # Returns ProductRiskShare according to its CoverageID and ProductID.

    # |> where([prs], prs.coverage_id == ^coverage_id and prs.product_id == ^product_id)
    ProductCoverageRiskShare
    |> Repo.get_by!(%{product_coverage_id: product_coverage_id})
    |> Repo.preload(product_coverage_risk_share_facilities: :facility)
  end

  def loop_facilities(facilities) do
    # Returns list of Facilities.

    for facility <- facilities do
      %{display: "#{facility.code} - #{facility.name}", id: facility.id}
    end
  end

  def get_prsf(prsf_id) do
    # Returns ProductRiskShareFacility record according to its ID.

    ProductCoverageRiskShareFacility
    |> Repo.get!(prsf_id)
    |> Repo.preload(
      product_coverage_risk_share_facility_payor_procedures: :facility_payor_procedure
    )
  end

  def loop_procedures(procedures) do
    # Returns list of Facilities.

    for procedure <- procedures do
      %{display: "#{procedure.code} - #{procedure.name}", id: procedure.id}
    end
  end

  def insert_or_update_product_coverage_risk_share(params) do
    product_coverage_risk_share =
      ProductCoverageRiskShare
      |> Repo.get_by(product_coverage_id: params.product_coverage_id)

    if is_nil(product_coverage_risk_share) do
      create_product_coverage_risk_share(params)
    else
      update_a_product_coverage_risk_share(
        product_coverage_risk_share.product_coverage_id,
        params
      )
    end
  end
  #FOR DENTAL RISK SHARE SETUP

  def get_all_dental_facility_location_group_by_pc_id(product_coverage_id) do
    LocationGroup
    |> join(:left, [lg], pclg in ProductCoverageLocationGroup, lg.id == pclg.location_group_id)
    |> join(:inner, [lg, pclg], flg in FacilityLocationGroup, flg.location_group_id == lg.id)
    |> join(:inner, [lg, pclg, flg], f in Facility, flg.facility_id == f.id)
    |> join(:inner, [lg, pclg, flg, f], d in Dropdown, f.ftype_id == d.id)
    |> where([lg, pclg, flg, f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([lg, pclg, flg, f, d], pclg.product_coverage_id == ^product_coverage_id)
    |> Repo.all()
    |> Repo.preload([
      facility_location_group:
      [
        facility: [
          :category,
          :type
        ]
      ]
    ])
    |> List.first()
  end

  def get_dental_facilities_for_risk_share(product_id) do
    pc =
      ProductCoverage
      |> where([pc], pc.product_id == ^product_id)
      |> select([pc], pc.id)
      |> Repo.all()
      |> List.first()

    pc2 = get_product_coverage_by_id(pc)

    location_group = get_all_dental_facility_location_group_by_pc_id(pc2.id)
    if is_nil(location_group) do
      []
    else
    case pc2.type do
      "exception" ->
        affiliated_facilities =
          location_group.facility_location_group
          |> Enum.map(fn(flg) ->
            flg.facility
          end)
          |> Enum.uniq()
          |> List.flatten()

        exempted_facilities =
          if Enum.empty?(pc2.product_coverage_facilities) do
            []
          else
            pc2.product_coverage_facilities
            |> Enum.map(fn(pcf) ->
              pcf.facility
            end)
            |> Enum.uniq()
            |> List.flatten()
          end

        aaf = affiliated_facilities -- exempted_facilities

      "inclusion" ->
        pc2.product_coverage_facilities
        |> Enum.map(fn(pcf) ->
          pcf.facility
        end)
        |> Enum.uniq()
        |> List.flatten()

      _ ->
        []
    end

    end

  end

  def insert_or_update_product_coverage_dental_risk_share(params) do
    product_coverage_dental_risk_share =
      ProductCoverageDentalRiskShare
      |> Repo.get_by(product_coverage_id: params.product_coverage_id)

    if is_nil(product_coverage_dental_risk_share) do
      create_product_coverage_dental_risk_share(params)
    else
      update_product_coverage_dental_risk_share(
        product_coverage_dental_risk_share.product_coverage_id,
        params
      )
    end
  end

  def create_product_coverage_dental_risk_share(params) do
    %ProductCoverageDentalRiskShare{}
    |> ProductCoverageDentalRiskShare.changeset(params)
    |> Repo.insert()
  end

  def update_product_coverage_dental_risk_share(product_coverage_id, params) do
    # Updates a ProductBenefit record.

    product_coverage_id
    |> get_pdrs()
    |> ProductCoverageDentalRiskShare.changeset(params)
    |> Repo.update()
  end

  def update_product_dental_risk_share(%ProductCoverageDentalRiskShare{} = product_dental_risk_share, params) do
    # Updates a ProductRiskShare.
    product_dental_risk_share
    |> ProductCoverageDentalRiskShare.changeset(params)
    |> Repo.update()
  end

  def get_product_coverage_dental_risk_share(drs_id) do
    # Returns a ProductRiskShare record according to its ID.

    ProductCoverageDentalRiskShare
    |> Repo.get!(drs_id)
    |> Repo.preload(product_coverage_dental_risk_share_facilities: :facility)
  end

  def get_pdrs(product_coverage_id) do
    ProductCoverageDentalRiskShare
    |> Repo.get_by!(%{product_coverage_id: product_coverage_id})
    |> Repo.preload(product_coverage_dental_risk_share_facilities: :facility)
  end

  def get_pdrsf(product_coverage_id) do
    ProductCoverageDentalRiskShareFacility
    |> Repo.get_by!(%{product_coverage_id: product_coverage_id})
    |> Repo.preload([
      [product_coverage_dental_risk_share_facilities:
        [
          product_coverage_dental_risk_share: :product_risk_share
        ]],
          :facility
      ])
  end

  def create_pdrsf(params) do
    %ProductCoverageDentalRiskShareFacility{}
    |> ProductCoverageDentalRiskShareFacility.changeset(params)
    |> Repo.insert()
  end

   def update_pdrsf(pdrsf_id, params) do
    pdrsf = Repo.get(ProductCoverageDentalRiskShareFacility, pdrsf_id)

    pdrsf
    |> ProductCoverageDentalRiskShareFacility.changeset(params)
    |> Repo.update()
  end

  def create_product_coverage_risk_share(product_coverage_risk_share_param) do
    # Inserts a new ProductBenefit record.
    %ProductCoverageRiskShare{}
    |> ProductCoverageRiskShare.changeset(product_coverage_risk_share_param)
    |> Repo.insert()
  end

  def update_a_product_coverage_risk_share(id, product_coverage_risk_share_param) do
    # Updates a ProductBenefit record.

    id
    |> get_prs()
    |> ProductCoverageRiskShare.changeset(product_coverage_risk_share_param)
    |> Repo.update()
  end

  ########################## END -- Functions related to ProductRiskShare.

  ######################################## Start of COPY PRODUCT
  def copy_product_general(conn, product) do
    maxicare = Repo.get_by(Payor, name: "Maxicare")

    new_product =
      Repo.insert!(%Product{
        limit_applicability: product.limit_applicability,
        shared_limit_amount: product.shared_limit_amount,
        type: product.type,
        limit_type: product.limit_type,
        limit_amount: product.limit_amount,
        phic_status: product.phic_status,
        standard_product: product.standard_product,
        payor_id: maxicare.id,
        created_by_id: conn.assigns.current_user.id,
        updated_by_id: conn.assigns.current_user.id,
        step: "8",
        product_category: product.product_category,
        member_type: product.member_type,
        product_base: product.product_base,
        product_category: product.product_category,
        code: Product.random_pcode()
      })

    copy_benefit_step3(product, new_product, conn.assigns.current_user.id)
    copy_exclusion_step2(product, new_product)
    # reinitialization of new_product
    new_product = get_product!(new_product.id)
    # product_type: exemption or inclusion, if you pick all affiliated facility
    copy_product_coverage_type(product, new_product)
    # when you pick specific hospital and all affli with exempted
    copy_facility_access_step4(product, new_product)
    # condition step5
    copy_condition_step5(product, new_product)

    new_product
  end

  defp copy_exclusion_step2(product, new_product) do
    for product_exclusion <- product.product_exclusions do

      new_product_exclusion = Repo.insert!(%ProductExclusion{
        exclusion_id: product_exclusion.exclusion.id,
        product_id: new_product.id
      })
      new_product_exclusion  =  Repo.preload(new_product_exclusion, [:exclusion])

      exclusion = ExclusionContext.get_exclusion(new_product_exclusion.exclusion.id)

      limit_peso =
        if exclusion.limit_type == "Peso" do
          exclusion.limit_amount
        else
          nil
        end

      limit_percentage =
        if exclusion.limit_type == "Percentage" do
          exclusion.limit_percentage
        else
          nil
        end

      limit_session =
        if exclusion.limit_type == "Sessions" do
          exclusion.limit_session
        else
          nil
        end

      limit_params = %{
        product_exclusion_id: new_product_exclusion.id,
        limit_type: exclusion.limit_type,
        limit_peso: limit_peso,
        limit_percentage: limit_percentage,
        limit_session: limit_session
      }

      cloning_pec_limit(limit_params)

    end
  end

  defp cloning_pec_limit(limit_params) do
    %ProductExclusionLimit{}
    |> ProductExclusionLimit.changeset_pec_limit(limit_params)
    |> Repo.insert()
  end

  defp copy_benefit_step3(product, new_product, user_id) do
    b_ids =
      [] ++
        for product_benefit <- product.product_benefits do
          product_benefit.benefit.id
        end

    c_ids =
      [] ++
        for product_coverage <- product.product_coverages do
          product_coverage.coverage.id
        end

    ## Inserting ProductBenefit and ProductCoverage
    if new_product.product_base == "Exclusion-based" do
      ## for Exclusion based
      set_coverage(new_product.id, c_ids)
    else
      ## for Benefit based
      set_product_benefits(new_product, b_ids, user_id)
    end
  end

  defp copy_product_coverage_type(product, new_product) do
    for product_coverage <- product.product_coverages do
      params = %{
        type: product_coverage.type,
        coverage_id: product_coverage.coverage_id,
        product_id: new_product.id
      }

      for n_product_coverage <- new_product.product_coverages do
        if n_product_coverage.coverage_id == product_coverage.coverage_id do
          set_product_coverage_type(n_product_coverage, params)
        end
      end
    end
  end

  defp copy_facility_access_step4(product, new_product) do
    for product_coverage <- product.product_coverages do
      if product_coverage.product_coverage_facilities != [] do
        f_ids =
          [] ++
            for product_coverage_facility <- product_coverage.product_coverage_facilities do
              product_coverage_facility.facility.id
            end

        for n_product_coverage <- new_product.product_coverages do
          if n_product_coverage.coverage_id == product_coverage.coverage_id do
            set_product_facility(n_product_coverage.id, f_ids)
          end
        end
      end
    end
  end

  defp copy_condition_step5(product, new_product) do
    params = %{
      nem_principal: product.nem_principal,
      nem_dependent: product.nem_dependent,
      mded_principal: product.mded_principal,
      mded_dependent: product.mded_dependent,
      principal_min_age: product.principal_min_age,
      principal_min_type: product.principal_min_type,
      principal_max_age: product.principal_max_age,
      principal_max_type: product.principal_max_type,
      adult_dependent_min_age: product.adult_dependent_min_age,
      adult_dependent_min_type: product.adult_dependent_min_type,
      adult_dependent_max_age: product.adult_dependent_max_age,
      adult_dependent_max_type: product.adult_dependent_max_type,
      minor_dependent_min_age: product.minor_dependent_min_age,
      minor_dependent_min_type: product.minor_dependent_min_type,
      minor_dependent_max_age: product.minor_dependent_max_age,
      minor_dependent_max_type: product.minor_dependent_max_type,
      overage_dependent_min_age: product.overage_dependent_min_age,
      overage_dependent_min_type: product.overage_dependent_min_type,
      overage_dependent_max_age: product.overage_dependent_max_age,
      overage_dependent_max_type: product.overage_dependent_max_type,
      adnb: product.adnb,
      adnnb: product.adnnb,
      opmnb: product.opmnb,
      opmnnb: product.opmnnb,
      no_outright_denial: product.no_outright_denial,
      no_days_valid: product.no_days_valid,
      is_medina: product.is_medina,
      smp_limit: product.smp_limit,
      hierarchy_waiver: product.hierarchy_waiver,
      sop_principal: product.sop_principal,
      sop_dependent: product.sop_dependent,
      loa_facilitated: product.loa_facilitated,
      loa_validity: product.loa_validity,
      loa_validity_type: product.loa_validity_type,
      reimbursement: product.reimbursement,
      special_handling_type: product.special_handling_type,
      type_of_payment_type: product.type_of_payment_type,
      dental_funding_arrangement: if product.product_category == "Dental Plan" do product.dental_funding_arrangement end
    }

    update_product_condition(new_product, params)

    if product.product_category != "Dental Plan" do
      ### Funding Arrangement
      funding_arrangement(product, new_product)

      ### Hierarchy of Eligible Dependents
      pchoed(product, new_product)

      ### Room and Board
      room_and_board(product, new_product)

      ## Product Coverage Risk Share
      copy_pcrs(product, new_product)

      ## Product Coverage Rsik Share Facility
      copy_pcrsf(product, new_product)

      ## Product Coverage Rsik Share Facility payor procedure
      copy_pcrsfpp(product, new_product)

      copy_limit_threshold(product, new_product)
    end
  end

  def copy_dental_product_general(conn, product) do
    maxicare = Repo.get_by(Payor, name: "Maxicare")

    new_product =
      Repo.insert!(%Product{
        limit_applicability: product.limit_applicability,
        type: product.type,
        limit_amount: product.limit_amount,
        standard_product: product.standard_product,
        payor_id: maxicare.id,
        created_by_id: conn.assigns.current_user.id,
        updated_by_id: conn.assigns.current_user.id,
        step: "8",
        product_category: product.product_category,
        product_base: product.product_base,
      })

    copy_benefit_step3(product, new_product, conn.assigns.current_user.id)
#     copy_exclusion_step2(product, new_product)
    # reinitialization of new_product
    new_product = get_product!(new_product.id)
    # product_type: exemption or inclusion, if you pick all affiliated facility
#     copy_product_coverage_type(product, new_product)
#     # when you pick specific hospital and all affli with exempted
    # copy_facility_access_step4(product, new_product)

    copy_dental_facility(product, new_product)

    new_product = get_product!(new_product.id)
#     # condition step5
    copy_condition_step5(product, new_product)

    new_product = get_product!(new_product.id)
  end

  defp copy_dental_facility(product, new_product) do
    coverages = Enum.map(product.product_coverages, &(String.downcase(&1.coverage.code)))
    type = product.product_coverages
           |> Enum.map(&(&1.type))
           |> Enum.uniq
           |> List.first()

    facility_ids =
      product.product_coverages
      |> Enum.map(fn(pc) ->
        Enum.map(pc.product_coverage_facilities, fn(pcf) ->
          pcf.facility_id
        end)
      end)
      |> List.flatten()

    case type do
      "exception" ->
        type = "All Affiliated Facilities"
        params = %{
          "coverages" => coverages,
          "dentl" => %{
            "type" => type
          }
        }
        if not Enum.empty?(facility_ids) do
          params1 =
            params["dentl"]
            |> Map.put("facility_ids", facility_ids)
          params =
            params
            |> Map.put("dentl", params1)
        end
      "inclusion" ->
        type = "Specific Facilities"
        params = %{
          "coverages" => coverages,
          "dentl" => %{
            "facility_ids" => facility_ids,
            "type" => type
          }
        }
      _ ->
        type = "All Affiliated Facilities"
        params = %{
          "coverages" => coverages,
          "dentl" => %{
            "type" => type
          }
        }
        if not Enum.empty?(facility_ids) do
          params1 =
            params["dentl"]
            |> Map.put("facility_ids", facility_ids)
          params =
            params
            |> Map.put("dentl", params1)
        end
    end

    with true <- product.product_coverages |> verify_product_coverages(params)
    do
      params["coverages"]
      |> Enum.each(&set_product_coverages(new_product, params[&1], &1))
    else
      false ->
        false
    end
  end

  def verify_product_coverages(product_coverages, product_params) do
    product_coverages
    |> Enum.map(&coverage_struct_by_id(&1.coverage_id).code)
    |> is_equal?(product_params)
  end

  def is_equal?(pc, product_params) do
    (pc --
      ((Map.keys(product_params) -- ["coverages"])
      |> Enum.map(&String.upcase(&1))))
      |> Enum.empty?()
  end

  defp check_if_contains_error_changeset_product(result) do
    if result |> Enum.map(&if &1 == {:ok}, do: true, else: false) |> Enum.all?() do
      {true, result}
    else
    {false, result}
    end
  end

  ######################################## End of COPY PRODUCT

  defp funding_arrangement(product, new_product) do
    for product_coverage <- product.product_coverages do
      params = %{
        funding_arrangement: product_coverage.funding_arrangement,
        coverage_id: product_coverage.coverage_id,
        product_id: new_product.id
      }

      for n_product_coverage <- new_product.product_coverages do
        if n_product_coverage.coverage_id == product_coverage.coverage_id do
          n_product_coverage
          |> ProductCoverage.changeset(params)
          |> Repo.update()
        end
      end
    end
  end

  defp pchoed(product, new_product) do
    for pchoed <- product.product_condition_hierarchy_of_eligible_dependents do
      params = %{
        product_id: new_product.id,
        hierarchy_type: pchoed.hierarchy_type,
        dependent: pchoed.dependent,
        ranking: pchoed.ranking
      }

      changeset =
        ProductConditionHierarchyOfEligibleDependent.changeset(
          %ProductConditionHierarchyOfEligibleDependent{},
          params
        )

      Repo.insert!(changeset)
    end
  end

  defp copy_limit_threshold(product, new_product) do
    for product_coverage <- product.product_coverages do
      if not is_nil(product_coverage.product_coverage_limit_threshold) do
        pc =
          ProductCoverage
          |> Repo.get_by(coverage_id: product_coverage.coverage_id, product_id: new_product.id)

          pclt =
            ProductCoverageLimitThreshold
            |> Repo.get_by(product_coverage_id: pc.id)

            params = %{
              product_coverage_id: pc.id,
              limit_threshold: product_coverage.product_coverage_limit_threshold.limit_threshold
            }

            pclt_result =
              pclt
              |> ProductCoverageLimitThreshold.changeset(params)
              |> Repo.update!

              old_pcltfs = product_coverage.product_coverage_limit_threshold.product_coverage_limit_threshold_facilities
              for old_pclt <- old_pcltfs do
                params = %{
                  product_coverage_limit_threshold_id: pclt_result.id,
                  facility_id: old_pclt.facility_id,
                  limit_threshold: old_pclt.limit_threshold
                }

                %ProductCoverageLimitThresholdFacility{}
                |> ProductCoverageLimitThresholdFacility.changeset(params)
                |> Repo.insert!
              end
      end
    end
  end

  defp room_and_board(product, new_product) do
    for product_coverage <- product.product_coverages do
      if product_coverage.product_coverage_room_and_board != nil do
        pc =
          ProductCoverage
          |> Repo.get_by(coverage_id: product_coverage.coverage_id, product_id: new_product.id)
          if is_nil(pc) do
            nil
          else

            rnb =
              ProductCoverageRoomAndBoard
              |> Repo.get_by(product_coverage_id: pc.id)
              if is_nil(rnb) do
                nil
              else

                params = %{
                  "product_coverage_room_and_board_id" => rnb.id,
                  "room_and_board" => product_coverage.product_coverage_room_and_board.room_and_board,
                  "room_limit_amount" =>
                  product_coverage.product_coverage_room_and_board.room_limit_amount,
                  "room_type" => product_coverage.product_coverage_room_and_board.room_type,
                  "room_upgrade" => product_coverage.product_coverage_room_and_board.room_upgrade,
                  "room_upgrade_time" =>
                  product_coverage.product_coverage_room_and_board.room_upgrade_time
                }

                update_pc_rnb(rnb, params)
              end
          end
      else
        nil
      end
    end
  end

  defp copy_pcrs(product, new_product) do
    for product_coverage <- product.product_coverages do
      if product_coverage.product_coverage_risk_share.af_type != nil do
        pc =
          ProductCoverage
          |> Repo.get_by(coverage_id: product_coverage.coverage_id, product_id: new_product.id)
          if is_nil(pc) do
            nil
          else

            pcrs =
              ProductCoverageRiskShare
              |> Repo.get_by(product_coverage_id: pc.id)

              params = %{
                "af_type" => product_coverage.product_coverage_risk_share.af_type,
                "af_value" => convert_af_value(product_coverage),
                "af_covered_percentage" =>
                product_coverage.product_coverage_risk_share.af_covered_percentage,
                "naf_reimbursable" => product_coverage.product_coverage_risk_share.naf_reimbursable,
                "naf_type" => product_coverage.product_coverage_risk_share.naf_type,
                "naf_value" => convert_naf_value(product_coverage),
                "naf_covered_percentage" =>
                product_coverage.product_coverage_risk_share.naf_covered_percentage,
                "risk_share_id" => pcrs.id
              }

              update_product_risk_share(pcrs, params)
          end
      end
    end
  end

  defp copy_pcrsf(product, new_product) do

    for product_coverage <- product.product_coverages do
      pcrsfs =
        product_coverage.product_coverage_risk_share.product_coverage_risk_share_facilities

      pc =
        ProductCoverage
        |> Repo.get_by(coverage_id: product_coverage.coverage_id, product_id: new_product.id)
      if is_nil(pc) do
        nil
      else

        pcrs =
          ProductCoverageRiskShare
          |> Repo.get_by(product_coverage_id: pc.id)

          for pcrsf <- pcrsfs do
            if pcrsf.type == "Copayment" do
              params = %{
                "covered" => pcrsf.covered,
                "facility_id" => pcrsf.facility_id,
                "product_coverage_risk_share_id" => pcrs.id,
                "product_risk_share_facility_id" => "",
                "product_risk_share_id" => pcrs.id,
                "type" => pcrsf.type,
                "value" => pcrsf.value_amount
              }

              set_product_risk_share_facility(params)
            else
              params = %{
                "covered" => pcrsf.covered,
                "facility_id" => pcrsf.facility_id,
                "product_coverage_risk_share_id" => pcrs.id,
                "product_risk_share_facility_id" => "",
                "product_risk_share_id" => pcrs.id,
                "type" => pcrsf.type,
                "value" => pcrsf.value_percentage
              }

              set_product_risk_share_facility(params)
            end
          end
      end
    end
  end

  defp copy_pcrsfpp(product, new_product) do

    for product_coverage <- product.product_coverages do
      pcrsfs =
        product_coverage.product_coverage_risk_share.product_coverage_risk_share_facilities

      pc =
        ProductCoverage
        |> Repo.get_by(coverage_id: product_coverage.coverage_id, product_id: new_product.id)
      if is_nil(pc) do
        nil
      else

        pcrs =
          ProductCoverageRiskShare
          |> Repo.get_by(product_coverage_id: pc.id)
          |> Repo.preload([:product_coverage_risk_share_facilities])

          for pcrsf <- pcrsfs do
            pcrsfpps = pcrsf.product_coverage_risk_share_facility_payor_procedures

            for pcrsfpp <- pcrsfpps do
              for new_pcrsf <- pcrs.product_coverage_risk_share_facilities do
                if pcrsf.facility_id == new_pcrsf.facility_id do
                  old_pcrs =
                    ProductCoverageRiskShare
                    |> Repo.get_by(id: pcrsf.product_coverage_risk_share_id)

                    new_pcrs =
                      ProductCoverageRiskShare
                      |> Repo.get_by(id: new_pcrsf.product_coverage_risk_share_id)

                      old_pc =
                        ProductCoverage
                        |> Repo.get_by(id: old_pcrs.product_coverage_id)

                        new_pc =
                          ProductCoverage
                          |> Repo.get_by(id: new_pcrs.product_coverage_id)

                          pcrsfpp_condition(pcrsfpp, new_pcrsf, old_pc, new_pc)
                end
              end
            end
          end
      end
    end
  end

  defp pcrsfpp_condition(pcrsfpp, new_pcrsf, old_pc, new_pc) do
    if old_pc.coverage_id == new_pc.coverage_id do
      if pcrsfpp.type == "Copayment" do
        params = %{
          "procedure_id" => pcrsfpp.facility_payor_procedure_id,
          "product_risk_share_facility_id" => new_pcrsf.id,
          "pcrsfpp" => "",
          "covered" => pcrsfpp.covered,
          "type" => pcrsfpp.type,
          "value" => pcrsfpp.value_amount
        }

        set_product_risk_share_facility_procedure(params)
      else
        params = %{
          "procedure_id" => pcrsfpp.facility_payor_procedure_id,
          "product_risk_share_facility_id" => new_pcrsf.id,
          "pcrsfpp" => "",
          "covered" => pcrsfpp.covered,
          "type" => pcrsfpp.type,
          "value" => pcrsfpp.value_percentage
        }

        set_product_risk_share_facility_procedure(params)
      end
    end
  end

  defp convert_af_value(product_coverage) do
    if product_coverage.product_coverage_risk_share.af_type == "Copayment" do
      product_coverage.product_coverage_risk_share.af_value_amount
    else
      product_coverage.product_coverage_risk_share.af_value_percentage
    end
  end

  defp convert_naf_value(product_coverage) do
    if product_coverage.product_coverage_risk_share.naf_type == "Copayment" do
      product_coverage.product_coverage_risk_share.naf_value_amount
    else
      product_coverage.product_coverage_risk_share.naf_value_percentage
    end
  end

  defp pcrnb_checker(upc) do
    ProductCoverageRoomAndBoard
    |> where([pcrnb], pcrnb.product_coverage_id == ^upc.id)
    |> Repo.all()
  end

  def pcrnb_checker2(pcrnb_checker, upc) do
    if pcrnb_checker == [] do
      params = %{
        product_coverage_id: upc.id
      }

      if upc.coverage.description == "Maternity" or upc.coverage.description == "Inpatient" do
        changeset =
          ProductCoverageRoomAndBoard.changeset(%ProductCoverageRoomAndBoard{}, params)
          Repo.insert(changeset)
      end
    end
  end

  defp pcrs_checker(upc) do
    pcrs_checker =
      ProductCoverageRiskShare
      |> where([pcrs], pcrs.product_coverage_id == ^upc.id)
      |> Repo.all()

    if pcrs_checker == [] do
      params = %{
        product_coverage_id: upc.id
      }

      changeset = ProductCoverageRiskShare.changeset(%ProductCoverageRiskShare{}, params)
      Repo.insert(changeset)
    end
  end

  defp pclt_checker(upc) do
    pclt_checker =
      ProductCoverageLimitThreshold
      |> where([pclt], pclt.product_coverage_id == ^upc.id)
      |> Repo.all()

    if pclt_checker == [] do
      params = %{
        product_coverage_id: upc.id
      }

      changeset =
        ProductCoverageLimitThreshold.changeset(%ProductCoverageLimitThreshold{}, params)

        Repo.insert(changeset)
    end
  end

  def update_product_rnb_coverage(%Product{} = product, coverage_id) do
    # Updates 'rnb_cov_id' field of Product.

    params = %{rnb_cov_id: coverage_id}

    product
    |> Product.changeset_update_rnb_coverage(params)
    |> Repo.update()
  end

  def update_product_lt_coverage(%Product{} = product, coverage_id) do
    # Updates 'lt_cov_id' field of Product.

    params = %{lt_cov_id: coverage_id}

    product
    |> Product.changeset_update_lt_coverage(params)
    |> Repo.update()
  end

  # for product_download
  def csv_product_downloads(params) do
    query =
      from(
        p in Product,
        join: u in User,
        on: u.id == p.created_by_id,
        join: uu in User,
        on: uu.id == p.updated_by_id,
        where: p.code in ^params["product_code"],
        order_by: p.code,
        select: [
          p.code,
          p.name,
          p.description,
          p.standard_product,
          u.username,
          p.inserted_at,
          uu.username,
          p.updated_at
        ]
      )

    query = Repo.all(query)
  end

  # Authorization
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
        select: %{duration: edu.duration, percentage: edu.cad_percentage}
      )

    pec = Repo.all(pec)

    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    percentage =
      for p <- pec do
        if not is_nil(pec) do
          eff_date =
            Member
            |> select([m], date_add(m.enrollment_date, ^p.duration, "month"))
            |> Repo.get(member_id)

          if eff_date > date_now do
            p.percentage
          end
        end
      end

    percentage
    |> Enum.filter(&(!is_nil(&1)))
    |> List.last()
  end

  def get_pec_consult(product_id, diagnosis_id, member_id) do
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
          d_id: d.id
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

  def get_pec_op_lab(product_id, diagnosis_ids, member_id) do
    pec =
      Product
      |> join(:inner, [p], pe in ProductExclusion, pe.product_id == p.id)
      |> join(:inner, [p, pe], e in Exclusion, e.id == pe.exclusion_id)
      |> join(:inner, [p, pe, e], ed in ExclusionDisease, ed.exclusion_id == e.id)
      |> join(:inner, [p, pe, e, ed], d in Diagnosis, d.id == ed.disease_id)
      |> join(
        :inner,
        [p, pe, e, ed, d],
        edu in ExclusionDuration,
        edu.exclusion_id == e.id and edu.disease_type == d.type
      )
      |> where(
        [p, pe, e, ed, d, edu],
        p.id == ^product_id and e.coverage == "Pre-existing Condition" and
          ed.disease_id == ^diagnosis_ids
      )
      |> order_by([p, pe, e, ed, d, edu], edu.duration)
      |> select([p, pe, e, ed, d, edu], %{duration: edu.duration, percentage: edu.cad_percentage})
      |> Repo.all()

    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    percentage =
      for p <- pec do
        if not is_nil(pec) do
          eff_date =
            Member
            |> select([m], date_add(m.enrollment_date, ^p.duration, "month"))
            |> Repo.get(member_id)

          if eff_date <= date_now do
            p.percentage
          end
        end
      end

    percentage
    |> Enum.filter(&(!is_nil(&1)))
    |> List.last()
  end

  def get_pec_oplab(product_id, diagnosis_ids, member_id) do
    pec =
      Product
      |> join(:inner, [p], pe in ProductExclusion, pe.product_id == p.id)
      |> join(:inner, [p, pe], e in Exclusion, e.id == pe.exclusion_id)
      |> join(:inner, [p, pe, e], ed in ExclusionDisease, ed.exclusion_id == e.id)
      |> join(:inner, [p, pe, e, ed], d in Diagnosis, d.id == ed.disease_id)
      |> join(
        :inner,
        [p, pe, e, ed, d],
        edu in ExclusionDuration,
        edu.exclusion_id == e.id and edu.disease_type == d.type
      )
      |> where(
        [p, pe, e, ed, d, edu],
        p.id == ^product_id and e.coverage == "Pre-existing Condition" and
          ed.disease_id in ^diagnosis_ids
      )
      |> order_by([p, pe, e, ed, d, edu], edu.duration)
      |> select([p, pe, e, ed, d, edu], %{
        duration: edu.duration,
        percentage: edu.cad_percentage,
        d_id: d.id
      })
      |> Repo.all()

    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    percentage =
      for p <- pec do
        if not is_nil(pec) do
          eff_date =
            Member
            |> select([m], date_add(m.effectivity_date, ^p.duration, "month"))
            |> Repo.get(member_id)

          if eff_date <= date_now do
            %{discount: p.percentage, d_id: p.d_id}
          end
        end
      end
      |> Enum.filter(&(!is_nil(&1)))
  end

  def get_emergency_pec(product_id, diagnosis_ids, member_id) do
    pec =
      Product
      |> join(:inner, [p], pe in ProductExclusion, pe.product_id == p.id)
      |> join(:inner, [p, pe], e in Exclusion, e.id == pe.exclusion_id)
      |> join(:inner, [p, pe, e], ed in ExclusionDisease, ed.exclusion_id == e.id)
      |> join(:inner, [p, pe, e, ed], d in Diagnosis, d.id == ed.disease_id)
      |> join(
        :inner,
        [p, pe, e, ed, d],
        edu in ExclusionDuration,
        edu.exclusion_id == e.id and edu.disease_type == d.type
      )
      |> where(
        [p, pe, e, ed, d, edu],
        p.id == ^product_id and e.coverage == "Pre-existing Condition" and
          ed.disease_id == ^diagnosis_ids
      )
      |> order_by([p, pe, e, ed, d, edu], edu.duration)
      |> select([p, pe, e, ed, d, edu], %{duration: edu.duration, percentage: edu.cad_percentage})
      |> Repo.all()

    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    percentage =
      for p <- pec do
        if not is_nil(pec) do
          eff_date =
            Member
            |> select([m], date_add(m.enrollment_date, ^p.duration, "month"))
            |> Repo.get(member_id)

          if eff_date <= date_now do
            p.percentage
          end
        end
      end

    percentage
    |> Enum.filter(&(!is_nil(&1)))
    |> List.last()
  end

  def get_pec_emergency(product_id, diagnosis_ids, member_id) do
    pec =
      Product
      |> join(:inner, [p], pe in ProductExclusion, pe.product_id == p.id)
      |> join(:inner, [p, pe], e in Exclusion, e.id == pe.exclusion_id)
      |> join(:inner, [p, pe, e], ed in ExclusionDisease, ed.exclusion_id == e.id)
      |> join(:inner, [p, pe, e, ed], d in Diagnosis, d.id == ed.disease_id)
      |> join(
        :inner,
        [p, pe, e, ed, d],
        edu in ExclusionDuration,
        edu.exclusion_id == e.id and edu.disease_type == d.type
      )
      |> where(
        [p, pe, e, ed, d, edu],
        p.id == ^product_id and e.coverage == "Pre-existing Condition" and
          ed.disease_id in ^diagnosis_ids
      )
      |> order_by([p, pe, e, ed, d, edu], edu.duration)
      |> select([p, pe, e, ed, d, edu], %{
        duration: edu.duration,
        percentage: edu.cad_percentage,
        d_id: d.id
      })
      |> Repo.all()

    {_, date_now} = Ecto.Date.dump(Ecto.Date.utc())

    percentage =
      for p <- pec do
        if not is_nil(pec) do
          eff_date =
            Member
            |> select([m], date_add(m.effectivity_date, ^p.duration, "month"))
            |> Repo.get(member_id)

          if eff_date <= date_now do
            %{discount: p.percentage, d_id: p.d_id}
          end
        end
      end
      |> Enum.filter(&(!is_nil(&1)))
  end

  # End Authorization

  def get_product_coverage_ids(product_id) do
    product_coverages =
      ProductCoverage
      |> where([p], p.product_id == ^product_id)
      |> Repo.all()

    for pc <- product_coverages do
      pc.coverage_id
    end
  end

  ### for exclusion_based set for product_coverage
  def set_coverage(product_id, coverage_ids) do
    for coverage_id <- coverage_ids do
      result = coverage_checker(product_id, coverage_id)

      if result == true do
        params = %{coverage_id: coverage_id, product_id: product_id}
        changeset = ProductCoverage.changeset(%ProductCoverage{}, params)
        product_coverage = Repo.insert(changeset)
      end

      ## for inserting pcrnb, pcrs
      updated_product_coverage =
        ProductCoverage
        |> where([pc], pc.product_id == ^product_id)
        |> Repo.all()
        |> Repo.preload(:coverage)

      for upc <- updated_product_coverage do

        ### room and board
        pcrnb_checker = pcrnb_checker(upc)
        pcrnb_checker2(pcrnb_checker, upc)

        ### product coverage risk share
        pcrs_checker(upc)

        ### product coverage limit treshold
        pclt_checker(upc)

      end

      product_coverages =
        ProductCoverage
        |> where([pc], pc.product_id == ^product_id)
        |> Repo.all()

      coverage_ids_from_pc =
        for product_coverage <- product_coverages do
          product_coverage.coverage_id
        end

      deleted_coverages = coverage_ids_from_pc -- coverage_ids

      for dc <- deleted_coverages do
        ProductCoverage
        |> Repo.get_by(coverage_id: dc, product_id: product_id)
        |> Repo.delete()
      end
    end

    {:ok}
  end

  ## checker for insertion of product_coverage using exclusion-based
  defp coverage_checker(product_id, coverage_id) do
    checker_query =
      from(
        pc in ProductCoverage,
        where: pc.product_id == ^product_id and pc.coverage_id == ^coverage_id
      )

    result = Repo.all(checker_query)

    if result == [] do
      true
    else
      false
    end
  end

  defp onchange_delete_pc(product_id) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> Repo.delete_all()

    ProductBenefit
    |> where([pb], pb.product_id == ^product_id)
    |> Repo.delete_all()

    ProductExclusion
    |> where([pe], pe.product_id == ^product_id)
    |> Repo.delete_all()
  end

  def get_product_coverages(product_id) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> Repo.all()
  end

  def get_a_product_benefit(product_id) do
    ProductBenefit
    |> where([pb], pb.product_id == ^product_id)
    |> Repo.all()
    |> Repo.preload([:product_benefit_limits, benefit: [benefit_coverages: :coverage]])
  end

  def get_a_product_benefit2(product_benefit_id) do
    ProductBenefit
    |> where([pb], pb.id == ^product_benefit_id)
    |> Repo.one()
    |> Repo.preload([:product, :product_benefit_limits, benefit: [benefit_coverages: :coverage]])
  end

  def get_a_product_benefit_limit(product_benefit_id) do
    ProductBenefitLimit
    |> where([pbl], pbl.product_benefit_id == ^product_benefit_id)
    |> order_by(asc: :limit_amount)
    |> Repo.one()
    |> Repo.preload([:benefit_limit, :product_benefit])
  end

  def get_a_product_exclusion_limit(product_exclusion_id) do
    ProductExclusionLimit
    |> where([pel], pel.product_exclusion_id == ^product_exclusion_id)
    |> order_by(asc: :limit_peso)
    |> Repo.one()
    |> Repo.preload([:product_exclusion])
  end

  def update_product_limit(id, params) do
    # Updates a Product Limit record.
    id
    |> get_product!()
    |> Product.changeset_update_product_limit(params)
    |> Repo.update()
  end

  def update_product_benefit_limits(id, params) do
    # Updates a Product Benefit Limit record.
    id
    |> get_product_benefit_limit()
    |> ProductBenefitLimit.changeset_update_product_limit(params)
    |> Repo.update()
  end

  def update_pclt(product, params) do
    all_pclt_ids =
      [] ++
        for pc <- product.product_coverages do
          pc.product_coverage_limit_threshold.id
        end

    otl = params["outer_limit_threshold"]

    if otl == nil or otl == "" do
      for id <- all_pclt_ids do
        ProductCoverageLimitThreshold
        |> Repo.get(id)
        |> ProductCoverageLimitThreshold.changeset(%{limit_threshold: nil})
        |> Repo.update()
      end

      {:ok}
    else
      pclt_ids = String.split(params["outer_limit_threshold"], ",")

      for pclt_id <- pclt_ids do
        record = String.split(pclt_id, "_")
        id = Enum.at(record, 1)

        lt = if Enum.member?(all_pclt_ids, id), do: Enum.at(record, 0), else: nil

        ProductCoverageLimitThreshold
        |> Repo.get(id)
        |> ProductCoverageLimitThreshold.changeset(%{limit_threshold: lt})
        |> Repo.update()
      end

      {:ok}
    end
  end

  def get_product_limit_threshold(product_coverage_limit_threshold_id) do
    pclt =
      ProductCoverageLimitThreshold
      |> Repo.get_by!(%{id: product_coverage_limit_threshold_id})
      |> Repo.preload([
        [product_coverage_limit_threshold_facilities: :facility],
        [product_coverage: [product_coverage_facilities: :facility]]
      ])

    pc_id = pclt.product_coverage.id
    pc_type = pclt.product_coverage.type

    pf =
      [] ++
        for pcf <- pclt.product_coverage.product_coverage_facilities do
          %{display: "#{pcf.facility.code} - #{pcf.facility.name}", id: pcf.facility.id}
        end

    pcltf =
      ProductCoverageLimitThresholdFacility
      |> where(
        [pcltf],
        pcltf.product_coverage_limit_threshold_id == ^product_coverage_limit_threshold_id
      )
      |> Repo.all()
      |> Repo.preload([
        :facility
      ])

    ltf =
      [] ++
        for fa <- pcltf do
          %{display: "#{fa.facility.code} - #{fa.facility.name}", id: fa.facility.id}
        end

    result =
      if pc_type == "inclusion" do
        pf -- ltf
      else
        facilities = get_list_of_facilities()

        f =
          [] ++
            for fa <- facilities do
              %{display: "#{fa.code} - #{fa.name}", id: fa.id}
            end

        list1 = f -- pf -- ltf
        list1 -- ltf
      end
  end

  def get_product_limit_threshold_edit(product_coverage_limit_threshold_id) do
    pcltf =
      ProductCoverageLimitThresholdFacility
      |> where(
        [pcltf],
        pcltf.product_coverage_limit_threshold_id == ^product_coverage_limit_threshold_id
      )
      |> Repo.all()
      |> Repo.preload([
        :facility
      ])

    ltf =
      [] ++
        for fa <- pcltf do
          %{display: "#{fa.facility.code} - #{fa.facility.name}", id: fa.facility.id}
        end
  end

  def insert_pcltf(pclt_id, facility_id, limit_threshold) do
    params = %{
      product_coverage_limit_threshold_id: pclt_id,
      facility_id: facility_id,
      limit_threshold: limit_threshold
    }

    %ProductCoverageLimitThresholdFacility{}
    |> ProductCoverageLimitThresholdFacility.changeset(params)
    |> Repo.insert()
  end

  def update_pcltf(pcltf_id, pclt_id, facility_id, limit_threshold) do
    ltf =
      ProductCoverageLimitThresholdFacility
      |> Repo.get(pcltf_id)

    params = %{
      product_coverage_limit_threshold_id: pclt_id,
      facility_id: facility_id,
      limit_threshold: limit_threshold
    }

    ltf
    |> ProductCoverageLimitThresholdFacility.changeset(params)
    |> Repo.update()
  end

  def get_all_pcltf_by_pclt(pclt_id) do
    ProductCoverageLimitThresholdFacility
    |> where([pcltf], pcltf.product_coverage_limit_threshold_id == ^pclt_id)
    |> Repo.all()
    |> Repo.preload([:facility, :product_coverage_limit_threshold])
  end

  def get_pclt_by_pcltf(pcltf_id) do
    ProductCoverageLimitThresholdFacility
    |> Repo.get(pcltf_id)
  end

  def delete_pcltf(pcltf_id) do
    ProductCoverageLimitThresholdFacility
    |> Repo.get(pcltf_id)
    |> Repo.delete()
  end

  def check_pclt(product_coverage_id) do
    pclt_record =
      ProductCoverageLimitThreshold
      |> where([pclt], pclt.product_coverage_id == ^product_coverage_id)
      |> Repo.one()

    if not is_nil(pclt_record) do
      # If it has no data, true. If it has existing limit threshold, false.
      pclt_result =
        if pclt_record.limit_threshold == nil do
          true
        else
          false
        end

      pcltf_records =
        ProductCoverageLimitThresholdFacility
        |> where([pcltf], pcltf.product_coverage_limit_threshold_id == ^pclt_record.id)
        |> Repo.all()

      # If it has no data, true. If it has existing records, false.
      pcltf_result =
        if pcltf_records == [] do
          true
        else
          false
        end

      if pcltf_result == true do
        {:ok}
      else
        {:has_data}
      end
    else
      {:no_lt}
    end
  end

  def insert_or_update_product_coverage_limit_threshold(params) do
    product_coverage_limit_threshold =
      ProductCoverageLimitThreshold
      |> Repo.get_by(product_coverage_id: params.product_coverage_id)

    if is_nil(product_coverage_limit_threshold) do
      create_product_coverage_limit_threshold(params)
    else
      update_a_product_coverage_limit_threshold(
        product_coverage_limit_threshold.product_coverage_id,
        params
      )
    end
  end

  def create_product_coverage_limit_threshold(product_coverage_limit_threshold_param) do
    # Inserts a new ProductCoverageLimitThreshold record.

    %ProductCoverageLimitThreshold{}
    |> ProductCoverageLimitThreshold.changeset(product_coverage_limit_threshold_param)
    |> Repo.insert()
  end

  def update_a_product_coverage_limit_threshold(id, product_coverage_limit_threshold_param) do
    # Updates a ProductCoverageLimitThreshold record.

    id
    |> get_pclt()
    |> ProductCoverageLimitThreshold.changeset(product_coverage_limit_threshold_param)
    |> Repo.update()
  end

  def get_pclt(product_coverage_id) do
    ProductCoverageLimitThreshold
    |> where([pclt], pclt.product_coverage_id == ^product_coverage_id)
    |> Repo.one()
  end

  def check_pcf(product_coverage_id) do
    product_coverage =
      ProductCoverage
      |> where([pc], pc.id == ^product_coverage_id)
      |> Repo.one()
      |> Repo.preload([
        [:coverage],
        product: [product_benefits: [:benefit]],
        product_coverage_facilities: [facility: [:category, :type]]
      ])

    pc_facilities =
      [] ++
        for pcf <- product_coverage.product_coverage_facilities do
          pcf.facility.id
        end
  end

  def get_pcf(product_coverage_id) do
    product_coverage =
      ProductCoverage
      |> where([pc], pc.id == ^product_coverage_id)
      |> Repo.one()
      |> Repo.preload([
        [:coverage],
        product: [product_benefits: [:benefit]],
        product_coverage_facilities: [
          facility: [:category, :type, facility_location_groups: :location_group]
        ]
      ])

    get_pcf2(product_coverage)
  end

  defp get_pcf2(nil), do: nil
  defp get_pcf2(pc), do: get_pcf3(pc, pc.coverage.code)
  defp get_pcf3(pc, "ACU"), do: {:ok, pcf_acu_condition(pc, "", 0)}
  defp get_pcf3(pc, _), do: {:ok, pcf_normal(pc ,"", 0)}

  def get_pcf_by_search(product_coverage_id, datatable_params) do
    # raise datatable_params["search_value"]
    product_coverage =
      ProductCoverage
      |> where([pc], pc.id == ^product_coverage_id)
      |> Repo.one()
      |> Repo.preload([
        [:coverage],
        product: [product_benefits: [:benefit]],
        product_coverage_facilities: [
          facility: [:category, :type, facility_location_groups: :location_group]
        ]
      ])

    if product_coverage.coverage.code == "ACU" do
      pcf_acu_condition(product_coverage, datatable_params["search_value"], datatable_params["offset"])
    else
      pcf_normal(product_coverage, datatable_params["search_value"], datatable_params["offset"])
    end
  end

  def get_pcf_by_region(product_coverage_id, nil) do
    get_pcf(product_coverage_id)
  end

  def get_pcf_by_region(product_coverage_id, region) do
    product_coverage =
      ProductCoverage
      |> where([pc], pc.id == ^product_coverage_id)
      |> Repo.one()
      |> Repo.preload([
        [:coverage],
        product: [product_benefits: [:benefit]],
        product_coverage_facilities: [
          facility: [:category, :type, facility_location_groups: :location_group]
        ]
      ])

    pc_facilities =
      [] ++
        for pcf <- product_coverage.product_coverage_facilities do
          pcf.facility
        end

    facilities =
      Facility
      |> join(:inner, [f], flg in FacilityLocationGroup, f.id == flg.facility_id)
      |> where([f, flg], flg.location_group_id in ^region)
      |> distinct(true)
      |> Repo.all()
      |> Repo.preload([:category, :type, facility_location_groups: :location_group])

    facility_list = facilities -- pc_facilities

    if product_coverage.coverage.code == "ACU" do
      pcf_region_acu_condition(product_coverage, facility_list)
    else
      facility_list
    end
  end

  defp pcf_normal(product_coverage, search_value, offset) do
    current_facility_ids =
      product_coverage.product_coverage_facilities
      |> Enum.map(&(&1.facility.id))

    provider_access_query(search_value, offset, current_facility_ids)
  end

  defp pcf_acu_condition(product_coverage, search_value, offset) do
    current_facility_ids =
      product_coverage.product_coverage_facilities
      |> Enum.map(&(&1.facility.id))

    product_coverage.product.product_benefits
    |> Enum.map(&(&1.benefit.provider_access))
    |> List.flatten()
    |> Enum.uniq()
    |> List.delete(nil)
    |> List.to_string()
    |> pa_condition(search_value, offset, current_facility_ids)
  end

  defp pcf_region_acu_condition(product_coverage, facility_list) do
    provider_access =
      [] ++
        for pb <- product_coverage.product.product_benefits do
          pb.benefit.provider_access
        end

    provider_access =
      provider_access
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.to_string()

    region_pa_condition(provider_access, facility_list)

  end

  defp pa_condition(provider_access, search_value, offset, current_ids) do
    provider_access_query(provider_access, search_value, offset, current_ids)
  end

  # defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital/Clinic and Mobile" do
  #   provider_access =
  #     provider_access
  #     |> String.split(["/", " ", "and"], trim: true)
  #     |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
  #     |> Enum.sort()

  #   Facility
  #   |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
  #   |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
  #   |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
  #   |> where(
  #     [f, d, flg, lg],
  #     d.text == ^Enum.at(provider_access, 0) or
  #     d.text == ^Enum.at(provider_access, 1) or
  #     d.text == ^Enum.at(provider_access, 2)
  #   )
  #   |> where(
  #     [f, d, flg, lg],
  #     ilike(f.code, ^"%#{search_value}%") or
  #     ilike(f.name, ^"%#{search_value}%") or
  #     ilike(f.region, ^"%#{search_value}%") or
  #     ilike(lg.name, ^"%#{search_value}%")
  #   )
  #   |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
  #   |> distinct(true)
  #   |> offset(^offset)
  #   |> order_by([f], f.name)
  #   |> limit(100)
  #   |> Repo.all()
  #   |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  # end

  # defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital/Clinic" do
  #   provider_access =
  #     provider_access
  #     |> String.split(["/", " ", "and"], trim: true)
  #     |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
  #     |> Enum.sort()

  #   Facility
  #   |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
  #   |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
  #   |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
  #   |> where(
  #     [f, d, flg, lg],
  #     d.text == ^Enum.at(provider_access, 0) or
  #     d.text == ^Enum.at(provider_access, 1)
  #   )
  #   |> where(
  #     [f, d, flg, lg],
  #     ilike(f.code, ^"%#{search_value}%") or
  #     ilike(f.name, ^"%#{search_value}%") or
  #     ilike(f.region, ^"%#{search_value}%") or
  #     ilike(lg.name, ^"%#{search_value}%")
  #   )
  #   |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
  #   |> distinct(true)
  #   |> offset(^offset)
  #   |> order_by([f], f.name)
  #   |> limit(100)
  #   |> Repo.all()
  #   |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  # end

defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Clinic and Hospital and Mobile" do
    provider_access =
      provider_access
      |> String.split([" ", "and", "and"], trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1) or
      d.text == ^Enum.at(provider_access, 2)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
end

defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital/Clinic and Mobile" do
  provider_access =
    provider_access
    |> String.split(["/", " ", "and"], trim: true)
    |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
    |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1) or
      d.text == ^Enum.at(provider_access, 2)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
end

defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital, Clinic and Mobile" do
  provider_access =
    provider_access
    |> String.split([",", " ", "and"], trim: true)
    |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
    |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1) or
      d.text == ^Enum.at(provider_access, 2)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital and Clinic" do
    provider_access =
      provider_access
      |> String.split([" ", "and"], trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Clinic and Hospital" do
    provider_access =
      provider_access
      |> String.split([" ", "and"], trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital/Clinic" do
    provider_access =
      provider_access
      |> String.split("/", trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Clinic and Mobile" do
  provider_access =
      provider_access
      |> String.split([" ", "and"], trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital and Mobile" do
    provider_access =
      provider_access
      |> String.split([" ", "and"], trim: true)
      |> Enum.map(&( if &1 != "Mobile", do: "#{String.upcase(&1)}-BASED", else: String.upcase(&1) ))
      |> Enum.sort()

    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      d.text == ^Enum.at(provider_access, 0) or
      d.text == ^Enum.at(provider_access, 1)
    )
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Clinic" do
    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where([f, d, flg, lg], d.text == ^String.upcase("#{String.upcase(provider_access)}-BASED"))
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Hospital" do
    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where([f, d, flg, lg], d.text == ^String.upcase("#{String.upcase(provider_access)}-BASED"))
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  defp provider_access_query(provider_access, search_value, offset, current) when provider_access == "Mobile" do
    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where([f, d, flg, lg], d.text == ^String.upcase(provider_access))
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end

  ### for normal facility listing with 2 arity
  defp provider_access_query(search_value, offset, current) do
    Facility
    |> join(:left, [f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [f, d], flg in FacilityLocationGroup, flg.facility_id == f.id)
    |> join(:left, [f, d, flg], lg in LocationGroup, flg.location_group_id == lg.id)
    |> where(
      [f, d, flg, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> where([f, d, flg, lg], f.id not in ^current) ## f -- pcf
    |> distinct(true)
    |> offset(^offset)
    |> order_by([f], f.name)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload([:category, :type, facility_location_groups: :location_group])
  end
  defp provider_access_query(provider_access), do: raise "Error matching"

  defp region_pa_condition(provider_access, facility_list) do
    facility_list_hospital = []
    facility_list_clinic = []
    facility_list_mobile = []

    if provider_access =~ "Hospital/Clinic" do
      facility_list_hospital = pa_hospital_clinic(facility_list)
    end

    if provider_access =~ "Mobile" do
      facility_list_mobile = pa_mobile(facility_list)
    end

    facility_total(facility_list_hospital, facility_list_clinic, facility_list_mobile)

  end

  defp facility_total(facility_list_hospital, facility_list_clinic, facility_list_mobile) do
    facility_total = facility_list_hospital ++ facility_list_clinic ++ facility_list_mobile

    facility_total =
      facility_total
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp pa_hospital_clinic(facility_list) do
    facility_list
    |> Enum.filter(fn(x) -> x.type.text == "HOSPITAL-BASED" or x.type.text == "CLINIC-BASED" end)
  end

  defp pa_mobile(facility_list) do
    facility_list
    |> Enum.filter(fn(x) -> x.type.text == "MOBILE" end)
  end

  def get_product_exclusion_by_product_and_exclusion(product_id, exclusion_id) do
    ProductExclusion
    |> Repo.get_by(product_id: product_id, exclusion_id: exclusion_id)
  end

  def get_product_exclusion_limit_by_product_exclusion(product_exclusion_id) do
    ProductExclusionLimit
    |> Repo.get_by(product_exclusion_id: product_exclusion_id)
  end

  def create_product_exclusion_limit(params) do
    %ProductExclusionLimit{}
    |> ProductExclusionLimit.changeset(params)
    |> Repo.insert!()
  end

  def update_pec_limit(product_id, exclusion_id, params) do
    product_exclusion = get_product_exclusion_by_product_and_exclusion(product_id, exclusion_id)

    params = %{
      limit_type: params.limit_type,
      limit_peso: params.limit_peso,
      limit_percentage: params.limit_percentage,
      limit_session: params.limit_session
    }

    with %ProductExclusionLimit{} = product_exclusion_limit <-
           get_product_exclusion_limit_by_product_exclusion(product_exclusion.id) do
      product_exclusion_limit
      |> ProductExclusionLimit.changeset_pec_limit(params)
      |> Repo.update()
    else
      _ ->
        pe_params = %{
          product_exclusion_id: product_exclusion.id
        }

        params = %{
          limit_type: params.limit_type,
          limit_peso: params.limit_peso,
          limit_percentage: params.limit_percentage,
          limit_session: params.limit_session
        }

        product_exclusion_limit = create_product_exclusion_limit(pe_params)

        product_exclusion_limit
        |> ProductExclusionLimit.changeset_pec_limit(params)
        |> Repo.update()
    end
  end

  def add_facility_by_location_group(nil, product_coverage_id), do: nil
  def add_facility_by_location_group([], product_coverage_id), do: nil
  def add_facility_by_location_group(location_group_names, product_coverage_id) do
    Enum.each(location_group_names, fn(name) ->
      facility_ids = FacilityContext.get_facilities_by_location_group(name)
      check_facility_if_existing(facility_ids, product_coverage_id)
    end)
  end

  def check_facility_if_existing([], product_coverage_id), do: nil
  def check_facility_if_existing(facility_ids, product_coverage_id) do
    Enum.each(facility_ids, fn(facility_id) ->
      pcf = get_by_product_coverage_and_facility(product_coverage_id, facility_id)
      if is_nil(pcf) do
        params = %{
          product_coverage_id: product_coverage_id,
          facility_id: facility_id
        }
        create_product_coverage_facility(params)
      end
    end)
  end

  def get_acu_affiliated_facilities(product_id) do
    case UUID.cast(product_id) do
      {:ok, product_id} ->
        load_affiliated_facilities(product_id)
      :error ->
        {:error}
    end
  end

  defp load_affiliated_facilities(product_id) do
    product =
      Product
      |> Repo.get(product_id)
      |> Repo.preload([
        product_coverages: [
          :coverage,
          product_coverage_facilities: [
            :facility
          ]
        ]
      ])

    if not is_nil(product) do
      result = for pc <- product.product_coverages do
        if pc.coverage.name == "ACU" do
          if pc.type == "inclusion" do
            for pcf <- pc.product_coverage_facilities do
              pcf.facility
            end
          else
            ef = for pcf <- pc.product_coverage_facilities do
              pcf.facility
            end

            load_exempted_facilities(ef)
          end

        end
      end
      |> List.flatten
      |> Enum.uniq
      |> List.delete(nil)

      {:ok, result}
    else
      {:ok, []}
    end
  end

  defp load_exempted_facilities(ef) do
    all_facilities =
      Facility
      |> where([f], f.step > 6 and f.status == "Affiliated")
      |> order_by([f], fragment("CASE ? WHEN ? then 1
      WHEN ? then 2
      WHEN ? then 3
      WHEN ? then 4
      WHEN ? then 5
      WHEN ? then 6
      WHEN ? then 7
      WHEN ? then 8
      WHEN ? then 9
      WHEN ? then 10
      WHEN ? then 11
      WHEN ? then 12
      WHEN ? then 13
      end", f.name, "MYHEALTH CLINIC - ALABANG",
      "PRIMARY CARE CENTER - MYHEALTH CLINIC ALABANG",
      "MYHEALTH CLINIC - SHANGRILA",
      "PRIMARY CARE CENTER - MYHEALTH CLINIC SHANGRILA",
      "MYHEALTH CLINIC - CEBU IT PARK",
      "MYHEALTH CLINIC - CEBU CYBERGATE",
      "MYHEALTH CLINIC - SM NORTH EDSA",
      "MYHEALTH CLINIC - CALAMBA",
      "MYHEALTH (ONSITE PHLEBOTOMY)",
      "MYHEALTH CLINIC - FILOMENA",
      "MYHEALTH CLINIC - CEBU CYBERGATE (MOBILE)",
      "MYHEALTH CLINIC - ROBINSONS MANILA",
      "MYHEALTH CLINIC - MCKINLEY"
      ))
      |> Repo.all

    all_facilities -- ef
  end

  def insert_change_of_product_log(params) do
    %ChangeOfProductLog{}
    |> ChangeOfProductLog.changeset(params)
    |> Repo.insert!
  end

  def insert_changed_member_product(
    %{
      cop_log_id: cop_log_id,
      new_product_code: new_product_code,
      old_product_code: old_product_code
    }
  ) do
    old_products =
      old_product_code
      |> String.split(";")
      |> Enum.uniq
      |> List.delete("")

    new_products =
      new_product_code
      |> String.split(";")
      |> Enum.uniq
      |> List.delete("")

    insert_cmp(cop_log_id, old_products, "Old")
    insert_cmp(cop_log_id, new_products, "New")
  end

  defp insert_cmp(cop_log_id, products, type) do
    for product_code <- products do
      product =
        Product
        |> where([p], p.code == ^product_code)
        |> Repo.one

      params = %{
        type: type,
        change_of_product_log_id: cop_log_id,
        product_id: product.id
      }

      %ChangedMemberProduct{}
      |> ChangedMemberProduct.changeset(params)
      |> Repo.insert
    end
  end

  # for ACU Scheduling
  def get_product_by_code(product_code) do
    Product
    |> Repo.get_by(code: product_code)
    |> Repo.preload([
      :created_by,
      :updated_by,
      :payor,
      product_coverages: [
        :product_coverage_facilities
      ],
      product_benefits: [
        benefit: [
          [benefit_coverages: :coverage],
          [benefit_packages: [package: :package_facility]],
          [:benefit_procedures]
        ]
      ]
    ])
  end

  def get_product_dental_by_code(product_code) do
    Product
    |> where([p], (fragment("lower(?)", p.code) == fragment("lower(?)", ^product_code)) and p.product_category == "Dental Plan")
    # |> Repo.get_by(code: product_code)
    |> Repo.one
    |> Repo.preload([
      :created_by,
      :updated_by,
      :payor,
      product_coverages: [
        # product_coverage_facilities: [facility: [:category, :type]],
        :coverage,
        :product,
        :product_coverage_room_and_board,
        product_coverage_limit_threshold: [
          product_coverage_limit_threshold_facilities: [:facility]
        ],
        product_coverage_facilities: [facility: [
          :category, :type, facility_location_groups: [:location_group]
        ]],
        product_coverage_risk_share: [
          product_coverage_risk_share_facilities: [
            :facility,
            product_coverage_risk_share_facility_payor_procedures: [:facility_payor_procedure]
          ],
        ],
        product_coverage_dental_risk_share: [
          product_coverage_dental_risk_share_facilities: [
            :facility,
          ],
        ],
        product_coverage_location_groups: [
          :location_group
        ]
      ],
      product_benefits: [
        :product_benefit_limits,
        benefit: [
          [benefit_coverages: :coverage],
          [benefit_packages: [package: :package_facility]],
          [:benefit_procedures],
          [:benefit_limits]
        ]
      ]

    ])
  end

  def get_all_pcf(pc_id), do: ProductCoverageFacility |> where([pcf], pcf.product_coverage_id == ^pc_id) |> pcf_preload()
  def pcf_preload(query) do
    query
    |> Repo.all()
    |> Repo.preload([
        facility: [:category, :type, facility_location_groups: :location_group]
    ])
  end

  def get_added_products(id) do
    AccountProduct
    |> where([ap], ap.account_id == ^id)
    |> select([ap], ap.product_id)
    |> Repo.all()
  end

  def get_funding_arrangement_coverage(id) do
    AccountGroupCoverageFund
    |> join(:left, [agcf], c in Coverage, agcf.coverage_id == c.id)
    |> join(:left, [agcf, c], ag in AccountGroup, agcf.account_group_id == ag.id)
    |> join(:left, [agcf, c, ag], a in Account, a.account_group_id == ag.id)
    |> where([agcf, c, ag, a], a.id == ^id)
    |> select([agcf, c, ag, a], c.id)
    |> Repo.all
  end


  def get_funding_arrangement do
    Product
    |> Repo.all
    |> Repo.preload([
      :product_coverages
    ])
  end

  def get_products_tbl_count(type, ids, coverages) do
    Product
    # |> where([p], p.step == ^"8")
    |> where([p], p.id not in ^ids)
    |> check_product_type(type)
    |> select([p], count(p.id))
    |> Repo.one()
  end

  def get_products_tbl(type, ids, coverages, params) do
    value = params["search"]["value"]
    Product
    |> join(:left, [p], u in User, u.id == p.created_by_id)
    |> join(:left, [p, u], uu in User, uu.id == p.updated_by_id)
    # |> where([p], p.step == ^"8")
    |> where([p], p.id not in ^ids)
    |> where(
      [p, u, uu],
      ilike(p.code, ^"%#{value}%") or ilike(p.name, ^"%#{value}%") or
      ilike(p.description, ^"%#{value}%") or ilike(u.username, ^"%#{value}%") or
      ilike(uu.username, ^"%#{value}%")
    )
    |> check_product_type(type)
    |> select([p], %{
      id: p.id,
      name: p.name,
      type: p.type,
      limit_type: p.limit_type,
      limit_amount: p.limit_amount
    })
    |> offset(^params["start"])
    |> limit(^params["length"])
    |> Repo.all()
    |> convert_tbl_data(coverages, [])
  end

  defp check_product_type(product, type) when type == "standard", do: product |> where([p], p.standard_product == ^"Yes")
  defp check_product_type(product, type) when type == "custom", do: product |> where([p], p.standard_product == ^"No")

  defp convert_tbl_data([head | tails], coverages, tbl) do
    benefit_count =
      ProductBenefit
      |> where([pb], pb.product_id == ^head.id)
      |> select([pb], count(pb.id))
      |> Repo.one

    funding_coverages =
      ProductCoverage
      |> where([pc], pc.product_id == ^head.id)
      |> where([pc], pc.funding_arrangement == ^"ASO")
      |> select([pc], pc.coverage_id)
      |> Repo.all

    # is_eligible = if Enum.empty?(funding_coverages -- coverages) do
    #   ""
    # else
    #   "uneligible-product"
    # end
    is_eligible = ""

    tbl =
      tbl ++ [[
        "<input type='checkbox' class='#{is_eligible}' style='height: 20px; width: 20px;' name='account_product[product_id][]'' value='#{head.id}'>",
        head.name,
        benefit_count,
        head.type,
        head.limit_type,
        head.limit_amount
      ]]

    convert_tbl_data(tails, coverages, tbl)
  end
  defp convert_tbl_data([], coverages, tbl), do: tbl

  @docp """
  NEW HTML Step4 Coverage, Schemaless Backend Validation
  """

  def set_product_coverages(product, params, coverage_code) when is_nil(params), do: {:ok}

  def set_product_coverages2(product, params, coverage_code) do
    if product.product_category == "Dental Plan" do
      with %Coverage{} = coverage <- coverage_struct_by_code(coverage_code),
           product_coverage <- get_pc_by_pid_and_cid(product.id, coverage.id),
           {:ok, product_coverage} <- update_pc_type_and_funding(product_coverage, params["type"], params)
      do
        {:ok}
      else
        nil ->
          params
          |> Map.put("details", "Coverage is not existing!")
        {:invalid, message} ->
          params
          |> Map.put("details", message)
        _ ->
          params
          |> Map.put("details", "Error")
      end
    else
      with {:ok, changeset} <- validate_coverage_params(params),
           %Coverage{} = coverage <- coverage_struct_by_code(coverage_code),
           product_coverage <- get_pc_by_pid_and_cid(product.id, coverage.id),
           {:ok, product_coverage} <- update_pc_type_and_funding(product_coverage, params["type"], params)
      do
        {:ok}
      else
        {:schemaless_error, changeset} ->
          {:schemaless_error, changeset}
        {:invalid, message} ->
          params
          |> Map.put("details", message)
        nil ->
          params
          |> Map.put("details", "Coverage is not existing!")
        _ ->
          params
          |> Map.put("details", "Error")
      end
    end
  end

  def set_product_coverages(product, params, coverage_code) do
    if product.product_category == "Dental Plan" do
      with %Coverage{} = coverage <- coverage_struct_by_code(coverage_code),
           product_coverage <- get_pc_by_pid_and_cid(product.id, coverage.id),
           {:ok, product_coverage} <- update_pc_type_and_funding(product_coverage, params["type"], params),
           {:ok} <- insert_pc_facility(product_coverage, params),
           {:ok, pclt} <- update_pc_lt(product_coverage, params),
           {:ok} <- update_pc_lt_facility(pclt, params)
      do
        {:ok}
      else
        nil ->
          params
          |> Map.put("details", "Coverage is not existing!")
        {:invalid, message} ->
          params
          |> Map.put("details", message)
        _ ->
          params
          |> Map.put("details", "Error")
      end
    else
      with {:ok, changeset} <- validate_coverage_params(params),
           %Coverage{} = coverage <- coverage_struct_by_code(coverage_code),
           product_coverage <- get_pc_by_pid_and_cid(product.id, coverage.id),
           {:ok, product_coverage} <- update_pc_type_and_funding(product_coverage, params["type"], params),
           {:ok} <- insert_pc_facility(product_coverage, params),
           {:ok, pclt} <- update_pc_lt(product_coverage, params),
           {:ok} <- update_pc_lt_facility(pclt, params)
      do
        {:ok}
      else
        {:schemaless_error, changeset} ->
          {:schemaless_error, changeset}
        {:invalid, message} ->
          params
          |> Map.put("details", message)
        nil ->
          params
          |> Map.put("details", "Coverage is not existing!")
        _ ->
          params
          |> Map.put("details", "Error")
      end
    end
  end

  def coverage_struct_by_code(coverage_code), do: coverage_code |> String.upcase() |> CoverageContext.get_coverage_by_code()
  def coverage_struct_by_id(coverage_id), do: Coverage |> Repo.get(coverage_id)

  defp validate_coverage_params(params) do
    types = %{
      funding_arrangement: :string,     # ASO, FULL RISK
      type: :string,                    # facility_access radiobutton state
      facility_ids: {:array, :string},  # facility_access_ids
      afrs: :string,                    # af_type
      afcars: :integer,                 # af_covered percentage
      # afvalue: :string,               # af_value_amount, af_value_percentage
      naf_cars: :integer,               # naf_covered percentage
      nafreimbursable: :string,
      nafrs: :string,                   # naf_type
      # nafvalue: :string,              # naf_value_amount, naf_value_percentage
      limit_threshold: :decimal,
      lt_data: {:array, :string}        # limit_threshold facility
    }
    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([
        :funding_arrangement,
        :type,
      ], message: "is required")
      |> validate_inclusion(:funding_arrangement, [
        "ASO",
        "Full Risk",
      ], message: "Only ASO and Full Risk is available")
      |> validate_inclusion(:type, [
        "All Affiliated Facilities",
        "Specific Facilities",
      ], message: "Only All Affiliated Facilities and Specific Facilities is available")
      |> validate_coverage_facility()
      |> validate_limit_threshold_facility(:type, :lt_data)
      |> validate_limit_threshold_amount(:limit_threshold, :lt_data) ## Limit Threshold: outer limit vs inner limit
      |> changeset_valid?()
  end
  defp changeset_valid?(changeset) do
    if changeset.valid? do
      {:ok, changeset}
    else
      {:schemaless_error, changeset}
    end
  end

  defp validate_coverage_facility(changeset), do: validate_coverage_facility_v2(changeset)
  defp validate_coverage_facility_v2(changeset) when changeset == %{}, do: changeset
  defp validate_coverage_facility_v2(changeset), do: validate_coverage_facility_v3(changeset, changeset.changes.type)
  defp validate_coverage_facility_v3(changeset, "All Affiliated Facilities"), do: changeset
  defp validate_coverage_facility_v3(changeset, "Specific Facilities"), do: validate_required(changeset, [:facility_ids], message: "is required")
  defp validate_coverage_facility_v3(changeset, _), do: changeset

  defp validate_limit_threshold_facility(changeset, type, lt_data) do
    with true <- changeset.changes |> Map.has_key?(type),
         true <- changeset.changes |> Map.has_key?(lt_data),
         {:ok, changeset} <- available_facility(changeset, changeset.changes.type)
    do
      changeset
    else
      false ->
        changeset

      {:error_ltf, changeset} ->
        changeset
    end
  end
  defp available_facility(changeset, "All Affiliated Facilities"), do: check_excluded_facility(changeset)
  defp available_facility(changeset, "Specific Facilities"), do: check_inclusion_facility(changeset)

  ###########################  start: exclusion all affiliated facilities
  defp fcode_to_fid(fcode), do: Facility |> select([f], f.id) |> where([f], f.code == ^fcode) |> Repo.one()
  defp check_excluded_facility(changeset) do
    with true <- changeset.changes |> Map.has_key?(:facility_ids),
         {:ok, changeset} <- excluded_facilities(changeset, changeset.changes.facility_ids, changeset.changes.lt_data)
    do
      {:ok, changeset}
    else
      false ->
        {:ok, changeset}

      {:error_ltf, changeset} ->
        {:error_ltf, changeset}
    end
  end

  defp excluded_facilities(changeset, facility_ids, lt_data) do
    lt_data
    |> Enum.map(&(&1 |> String.split("-") |> List.first() |> fcode_to_fid()))
    |> facility_vs_lt_facility(facility_ids, changeset)
  end

  defp facility_vs_lt_facility(lt_facility_ids, facility_ids, changeset) do
    facility_ids |> Enum.map(&(lt_facility_ids |> Enum.member?(&1))) |> Enum.member?(true) |> aaf_result(changeset)
  end
  defp aaf_result(true, changeset), do: {:error_ltf, add_error(changeset, :lt_data, "LT Facility is not belong to our valid facility list")}
  defp aaf_result(false, changeset), do: {:ok, changeset}
  ###########################  end: exclusion all affiliated facilities

  ##########################  start: inclusion specific facilities
  defp check_inclusion_facility(changeset) do
    with true <- changeset.changes |> Map.has_key?(:facility_ids),
         {:ok, changeset} <- included_facilities(changeset, changeset.changes.facility_ids, changeset.changes.lt_data)
    do
      {:ok, changeset}
    else
      false ->
        {:ok, changeset}

      {:error_ltf, changeset} ->
        {:error_ltf, changeset}
    end
  end
  defp included_facilities(changeset, facility_ids, lt_data) do
    # raise facility_ids
    lt_data
    |> Enum.map(&(&1 |> String.split("-") |> List.first() |> fcode_to_fid()))
    |> selected_facility_vs_lt_facility(facility_ids, changeset)
  end

  defp selected_facility_vs_lt_facility(lt_facility_ids, facility_ids, changeset) do
    var = Enum.empty?(lt_facility_ids -- facility_ids)
    sf_result(var, changeset)
    # facility_ids |> Enum.map(&(lt_facility_ids |> Enum.member?(&1))) |>  Enum.any?() |> raise  |> sf_result(changeset)
  end
  defp sf_result(false, changeset), do: {:error_ltf, add_error(changeset, :lt_data, "LT Facility is not belong to our valid facility list")}
  defp sf_result(true, changeset), do: {:ok, changeset}
  ##########################  end: inclusion specific facilities

  defp validate_limit_threshold_amount(changeset, key1, key2) do
    with true <- changeset.changes |> Map.has_key?(key1),
         true <- changeset.changes |> Map.has_key?(key2),
         changeset <- changeset |> validate_lt_outer_inner(key1)
    do
      changeset
    else
      false ->
        changeset

      {:error_lt_inner_outter, changeset} ->
        changeset
    end
  end

  defp validate_lt_outer_inner(changeset, outer_key) do
    with false <- changeset |> slice_inner_limit_and_cast() do
      changeset
    else
      true ->
        {:error_lt_inner_outter, changeset |> add_error(outer_key, "Outer Limit must not be equal to those Inner Limit per facility")}
    end
  end
  defp slice_inner_limit_and_cast(changeset) do
    changeset.changes.lt_data
    |> Enum.map(&(&1 |> String.split("-") |> List.last() |> Decimal.new()))
    |> Enum.member?([changeset.changes.limit_threshold])
  end

  def get_pc_by_pid_and_cid(product_id, coverage_id) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> where([pc], pc.coverage_id == ^coverage_id)
    |> Repo.one()
  end

  defp update_pc_type_and_funding(pc, "All Affiliated Facilities", params), do: Map.put(params, "type", "exception") |> set_pc_type(pc)
  defp update_pc_type_and_funding(pc, "Specific Facilities", params), do: Map.put(params, "type", "inclusion") |> set_pc_type(pc)
  defp update_pc_type_and_funding(pc, "Specific Dental Facilities", params), do: Map.put(params, "type", "inclusion") |> set_pc_type(pc)
  defp update_pc_type_and_funding(_, _, _), do: {:invalid, "Invalid Product Coverage Type"}
  defp set_pc_type(params, pc), do: pc |> ProductCoverage.changeset(params) |> Repo.update()

  defp insert_pc_facility(pc, params) do
    with true <- params |> Map.has_key?("facility_ids") do
      clear_product_facility(pc.id)
      params["facility_ids"]
      |> Enum.map(fn(x) ->

        %ProductCoverageFacility{}
        |> ProductCoverageFacility.changeset(%{facility_id: x, product_coverage_id: pc.id})
        |> Repo.insert!()

      end)
      {:ok}

    else
      false ->
        clear_product_facility(pc.id)
        {:ok}
    end
  end

  defp update_pc_lt(pc, params) do
    ProductCoverageLimitThreshold
    |> where([pclt], pclt.product_coverage_id == ^pc.id)
    |> Repo.one()
    |> ProductCoverageLimitThreshold.changeset(params)
    |> Repo.update()
  end

  defp update_pc_lt_facility(pclt, params) do
    with true <- params |> Map.has_key?("lt_data") do
      clear_pclt_facility(pclt.id)
      params["lt_data"]
      # |> Enum.map(&(&1 |> String.split("-") |> List.first() |> fcode_to_fid()))
      |> Enum.map(&(&1 |> String.split("-")))
      |> Enum.into([], fn(x) ->

        %ProductCoverageLimitThresholdFacility{}
        |> ProductCoverageLimitThresholdFacility.changeset(
          %{
            facility_id: x |> List.first() |> fcode_to_fid(),
            product_coverage_limit_threshold_id: pclt.id,
            limit_threshold: x |> List.last()
          })
        |> Repo.insert!()
      end)
      {:ok}

    else
      false -> {:ok}
    end
  end

  # def get_product_coverage2(product) do
  #   product_coverages =
  #     Product
  #     |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
  #     |> join(:inner, [p, pc], c in Coverage, c.id == pc.coverage_id)
  #     |> where([p, pc, c], p.id == ^product.id)
  #     |> select([p, pc, c], %{
  #       coverage_name: c.name,
  #       coverage_description: c.description,
  #       coverage_id: c.id,
  #       coverage_plan_type: c.plan_type,
  #       product_coverage_id: pc.id,
  #       product_coverage_type: pc.type,
  #       product_coverage_funding_arrangement: pc.funding_arrangement
  #     })
  #     |> Repo.all()

  #   product
  #   |> Map.put(:product_coverages, product_coverages)
  # end

  # def get_product_coverage_facility2(product) do
  #   product_coverage_facilities =
  #     Product
  #     |> join(:inner, [p], pc in ProductCoverage, p.id == pc.product_id)
  #     |> join(:inner, [p, pc], pcf in ProductCoverageFacility, pcf.product_coverage_id == pc.id)
  #     |> join(:inner, [p, pc, pcf], f in Facility, pcf.facility_id == f.id)
  #     |> where([p, pc, pcf, f], p.id == ^product.id)
  #     |> select([p, pc, pcf, f], %{
  #       product_coverage_id: pc.id,
  #       pcf_id: pcf.id,
  #       facility_name: f.name,
  #       facility_code: f.code
  #     })
  #     |> Repo.all()

  #   product[:product_coverages]
  #   |> Enum.map(&( if &1.product_coverage_id == ))

  #   |> Map.put(:product_coverage_facilities, product_coverage_facilities)
  # end

  # def load_product(id) do
  #   Product
  #   |> join(:left, [p], pc in ProductCoverage, pc.product_id == p.id)
  #   |> join(:left, [p, pc], c in Coverage, pc.coverage_id == c.id)
  #   |> join(:left, [p, pc, c], pcf in ProductCoverageFacility, pcf.product_coverage_id == pc.id)
  #   # |> join(:left, [p, pc, c, pcf], pclt in ProductCoverageLimitThreshold, pclt.product_coverage_id == pc.id)
  #   # |> join(:left, [p, pc, c, pcf, pclt], pcltf in ProductCoverageLimitThresholdFacility, pcltf.product_coverage_limit_threshold_id == pclt.id)
  #   |> where([p, pc, c], p.id == ^id)
  #   |> group_by([p, pc, c], p.id)
  #   |> select([p, pc, c, pcf], %{
  #     id: p.id,
  #     name: p.name,
  #     code: p.code,
  #     coverages: fragment(
  #       "array_agg(json_build_object(
  #       'coverage_id', ?,
  #       'coverage_name', ?,
  #       'product_coverage_id', ?,
  #       'product_coverage_type', ?,
  #       'product_coverage_funding_arrangement', ?,
  #       'facilities', array_agg(json_build_object(
  #           'pcf_id', ?
  #         ))
  #       ))",
  #       c.id,
  #       c.name,
  #       pc.id,
  #       pc.type,
  #       pc.funding_arrangement,
  #       pcf.id
  #     )
  #   })
  #   |> Repo.one()
  #   |> raise
  # end

  # def try_arg1(pcf_id) do
  #   fragment(
  #     "array_agg(json_build_object(
  #       'facility_id', ?
  #     ))",
  #   pcf_id)
  # end

  # def load_product(id) do
  #   Product
  #   |> join(:left, [p], pc in ProductCoverage, pc.product_id == p.id)
  #   |> join(:left, [p, pc], c in Coverage, pc.coverage_id == c.id)
  #   |> join(:left, [p, pc, c], pcf in ProductCoverageFacility, pcf.product_coverage_id == pc.id)
  #   |> join(:left, [p, pc, c, pcf, f], f in Facility, pcf.facility_id == f.id)
  #   # |> join(:left, [p, pc, c, pcf], pclt in ProductCoverageLimitThreshold, pclt.product_coverage_id == pc.id)
  #   # |> join(:left, [p, pc, c, pcf, pclt], pcltf in ProductCoverageLimitThresholdFacility, pcltf.product_coverage_limit_threshold_id == pclt.id)
  #   |> where([p, pc, c], p.id == ^id)
  #   # |> group_by([p, pc, c], p.id)
  #   |> select([p, pc, c, pcf, f], %{
  #     id: p.id,
  #     name: p.name,
  #     code: p.code,
  #     coverages: fragment("string_agg(DISTINCT CONCAT(?,':',?))", pcf.id, f.name)

  #   })
  #   |> Repo.one()
  #   |> raise
  # end

  def count_all_products do
    Product
    |> select([p], count(p.id))
    |> Repo.one
  end

  def get_account_products(id) do
    AccountProduct
    |> join(:left, [ap], a in Account, ap.account_id == a.id)
    |> join(:left, [ap, a], ag in AccountGroup, a.account_group_id == ag.id)
    |> where([ap, a, ag], ap.product_id == ^id)
    |> where([ap, a, ag], a.status == "Active")
    |> select([ap, a, ag], %{
      id: a.id,
      code: ag.code,
      name: ag.name,
      effective_date: a.start_date,
      expiry_date: a.end_date,
    })
    |> Repo.all()
    |> Enum.uniq()
  end

  def get_pb_by_id(id) do
    ProductBenefit
    |> where([pb], pb.id == ^id)
    |> Repo.one()
    |> Repo.preload([
      :product_benefit_limits
    ])
  end

  defp insert_product_benefits(product_id, benefit_ids, user_id) when is_nil(benefit_ids), do: {:ok}
  defp insert_product_benefits(product_id, [], user_id), do: {:ok}
  defp insert_product_benefits(product_id, benefit_ids, user_id) do
    benefit_ids
    |> Enum.map(fn x ->
      params = %{product: product_id, benefit_id: x}

      %ProductBenefit{}
      |> ProductBenefit.changeset(params)
      |> Repo.insert()
    end)

    {:ok}
  end

  def get_all_product_code do
    Product
    |> select([p], fragment("lower(?)", p.code))
    |> Repo.all()
  end

  def delete_product_benefit(id) do
    ProductBenefit
    |> where([pb], pb.id == ^id)
    |> Repo.one()
    |> Repo.delete()
  end

  defp update_product_benefits(product_id, benefit_ids, nil, user_id), do: {:ok}
  defp update_product_benefits(product_id, [], product_benefit_datas, user_id), do: {:ok}
  defp update_product_benefits(product_id, benefit_ids, product_benefit_datas, user_id) do
    #TODO
    benefit_ids = benefit_ids |> Enum.at(0) |> String.split(",")
    product_benefit_datas = product_benefit_datas |> Enum.at(0) |> String.split(",")
    for benefit_id <- benefit_ids do
      datas = Enum.into(product_benefit_datas, [], &(String.split(&1, "|")))
              |> Enum.reject(&(Enum.at(&1, 1) == "Plan Limit Percentage"))
      Enum.map(datas, fn(x) ->
        limit_amount =
          x
          |> Enum.drop(2)
          |> Enum.join()

          if Enum.at(x, 0) == benefit_id do
            result = benefit_checker(product_id, benefit_id)

            if result == true do
              pb = get_product_benefit_data(product_id, benefit_id) |> List.first()
              pbl = pb.product_benefit_limits |> List.first()

              case Enum.at(x, 1) do
                "Sessions" ->
                  params = %{
                    limit_type: "Sessions",
                    product_benefit_id: pbl.product_benefit_id,
                    coverages: pbl.coverages,
                    limit_session: Enum.at(x, 2)
                  }

                "Peso" ->
                  params = %{
                    limit_type: "Peso",
                    product_benefit_id: pbl.product_benefit_id,
                    coverages: pbl.coverages,
                    limit_amount: Enum.at(x, 2)
                  }

                "Tooth" ->
                  params = %{
                    limit_type: "Tooth",
                    product_benefit_id: pbl.product_benefit_id,
                    coverages: pbl.coverages,
                    limit_tooth: Enum.at(x, 2)
                  }

                "Quadrant" ->
                  params = %{
                    limit_type: "Quadrant",
                    product_benefit_id: pbl.product_benefit_id,
                    coverages: pbl.coverages,
                    limit_quadrant: Enum.at(x, 2)
                  }
              end
              {:ok, pbl} =
                pbl
                |> Ecto.Changeset.change(
                  limit_amount: nil,
                  limit_session: nil,
                  limit_tooth: nil,
                  limit_percentage: nil
                )
                |> Repo.update()

              pbl
              |> ProductBenefitLimit.changeset(params)
              |> Repo.update()
          else
            params = %{benefit_id: benefit_id, product_id: product_id}
            changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

            product_benefit =
              changeset
              |> Repo.insert!()
              |> Repo.preload(benefit: :benefit_limits)

              product = get_product!(product_id)
              set_product_coverage(product)

              case Enum.at(x, 1) do
                "Peso" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Peso",
                      limit_percentage: nil,
                      limit_amount: Enum.at(x, 2),
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: nil,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }

                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                "Plan Limit Percentage" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: "Plan Limit Percentage",
                      limit_type: Enum.at(x, 1),
                      limit_percentage: Enum.at(x, 2),
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: nil,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }

                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                "Sessions" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Sessions",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: Enum.at(x, 2),
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: nil,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                "Tooth" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Tooth",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: Enum.at(x, 2),
                      limit_quadrant: nil,
                      limit_classification: nil,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                "Quadrant" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Quadrant",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: Enum.at(x, 2),
                      limit_classification: nil,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                        _ ->
                          {:ok}
              end
            end
          end
      end)
    end
    {:ok}
  end

  defp insert_product_benefits(product_id, [], product_benefit_datas, user_id), do: {:ok}
  defp insert_product_benefits(product_id, benefit_ids, product_benefit_datas, user_id) do
    benefit_ids = benefit_ids |> Enum.at(0) |> String.split(",")
    product_benefit_datas = product_benefit_datas |> Enum.at(0) |> String.split(",")
    for benefit_id <- benefit_ids do
      datas = Enum.into(product_benefit_datas, [], &(String.split(&1, "|")))
      Enum.map(datas, fn(x) ->
        if Enum.at(x, 0) == benefit_id do
          result = benefit_checker(product_id, benefit_id)

          if result == false do
            params = %{benefit_id: benefit_id, product_id: product_id}
            changeset = ProductBenefit.changeset(%ProductBenefit{}, params)

            product_benefit =
              changeset
              |> Repo.insert!()
              |> Repo.preload(benefit: :benefit_limits)

              product = get_product!(product_id)
              set_product_coverage(product)

              case Enum.at(x, 1) do
                "Peso" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Peso",
                      limit_percentage: nil,
                      limit_amount: Enum.at(x, 2),
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: benefit_limit.limit_classification,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }

                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                "Plan Limit Percentage" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: "Plan Limit Percentage",
                      limit_type: Enum.at(x, 1),
                      limit_percentage: Enum.at(x, 2),
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: benefit_limit.limit_classification,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }

                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                  "Sessions" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Sessions",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: Enum.at(x, 2),
                      limit_tooth: nil,
                      limit_quadrant: nil,
                      limit_classification: benefit_limit.limit_classification,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                  "Tooth" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Tooth",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: Enum.at(x, 2),
                      limit_quadrant: nil,
                      limit_classification: benefit_limit.limit_classification,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                  "Quadrant" ->
                  for benefit_limit <- product_benefit.benefit.benefit_limits do
                    params = %{
                      coverages: benefit_limit.coverages,
                      limit_type: "Quadrant",
                      limit_percentage: nil,
                      limit_amount: nil,
                      limit_session: nil,
                      limit_tooth: nil,
                      limit_quadrant: Enum.at(x, 2),
                      limit_classification: benefit_limit.limit_classification,
                      product_benefit_id: product_benefit.id,
                      benefit_limit_id: benefit_limit.id,
                      created_by_id: user_id,
                      updated_by_id: user_id
                    }
                    changeset = ProductBenefitLimit.changeset(%ProductBenefitLimit{}, params)
                    Repo.insert!(changeset)
                  end
                  _ ->
                    {:ok}
              end
          end
        end
      end)
    end
    {:ok}
  end

  def delete_product_coverage_risk_share(id) do
    ProductCoverageDentalRiskShare
    |> where([pcdrs], pcdrs.id == ^id)
    |> Repo.one()
    |> Repo.delete()
  end

  def delete_struct(struct), do: Repo.delete(struct)

  def get_pcdrsf(id), do: Repo.get(ProductCoverageDentalRiskShareFacility, id)

  def delete_product_risk_share(id) do
    ProductRiskShareFacility
    |> where([prsf], prsf.id == ^id)
    |> Repo.one()
    |> Repo.delete()
  end

  def get_all_dental_facility_location_groups() do
    LocationGroup
    |> join(:inner, [lg], flg in FacilityLocationGroup, flg.location_group_id == lg.id)
    |> join(:inner, [lg, flg], f in Facility, flg.facility_id == f.id)
    |> join(:inner, [lg, flg, f], d in Dropdown, f.ftype_id == d.id)
    |> where([lg, flg, f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> select([lg], %{name: lg.name, id: lg.id})
    |> Repo.all()
    |> Enum.uniq()

    rescue
      Elixir.Ecto.MultipleResultsError ->
        nil
      _ ->
        nil
  end

  def get_dental_facilities_by_lg_name(lg_name) do
    LocationGroup
    |> join(:inner, [lg], flg in FacilityLocationGroup, flg.location_group_id == lg.id)
    |> join(:inner, [lg, flg], f in Facility, flg.facility_id == f.id)
    |> join(:inner, [lg, flg, f], d in Dropdown, f.ftype_id == d.id)
    |> where([lg, flg, f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([lg], lg.name == ^lg_name)
    |> distinct(true)
    |> Repo.one()
    |> Repo.preload(facility_location_group: :facility)

    rescue
      Elixir.Ecto.MultipleResultsError ->
        nil
      _ ->
        nil
  end

  def create_and_get_exclusion_pcf(location_group_id, product_coverage_facility_param) do
    {:ok, pcf} =%ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset(product_coverage_facility_param)
      |> Repo.insert()

    result =
      location_group_id
      |> get_exclusion_flg(pcf.facility_id)

    result =
      result
      |> Map.put_new(:product_coverage_facility_id, pcf.id)
  end


  def get_exclusion_flg(location_group_id, id) do
    FacilityLocationGroup
    |> join(:left, [flg], f in Facility, f.id == flg.facility_id)
    |> join(:left, [flg, f], lg in LocationGroup, lg.id == flg.location_group_id)
    |> where([flg, f, lg], f.id == ^id)
    |> where([flg, f, lg], lg.id == ^location_group_id)
    |> distinct(true)
    |> select([flg, f, lg, d], %{
        facility_id: f.id,
        id: flg.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        postal_code: f.postal_code,
        longitude: f.longitude,
        latitude: f.latitude,
        l_name: lg.name})
    |> Repo.one()
  end

  def update_product_coverage_type(product_coverage, params) do
    product_coverage
    |> ProductCoverage.changeset_dental_update(params)
    |> Repo.update()
  end

  def create_and_get_exclusion_pcf(location_group_id, product_coverage_facility_param) do
    # Updates a ProductCoverage record.
    product_coverage_facility_param["product_coverage_id"]
      |> get_product_coverage_by_id()
      |> ProductCoverage.changeset_dental_update(%{type: "exception"})
      |> Repo.update()


    {:ok, pcf} =%ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset(product_coverage_facility_param)
      |> Repo.insert()

    result =
      location_group_id
      |> get_exclusion_flg(pcf.facility_id)

    result =
      result
      |> Map.put_new(:product_coverage_facility_id, pcf.id)
      |> Map.put_new(:type, "exception")
  end

  def get_exclusion_flg(location_group_id, id) do
    FacilityLocationGroup
    |> join(:left, [flg], f in Facility, f.id == flg.facility_id)
    |> join(:left, [flg, f], lg in LocationGroup, lg.id == flg.location_group_id)
    |> where([flg, f, lg], f.id == ^id)
    |> where([flg, f, lg], lg.id == ^location_group_id)
    |> distinct(true)
    |> select([flg, f, lg, d], %{
        facility_id: f.id,
        id: flg.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        postal_code: f.postal_code,
        longitude: f.longitude,
        latitude: f.latitude,
        l_name: lg.name})
    |> Repo.one()
  end

  def create_and_get_inclusion_pcf(product_coverage_facility_param) do
    # Updates a ProductCoverage record.
    product_coverage_facility_param["product_coverage_id"]
      |> get_product_coverage_by_id()
      |> ProductCoverage.changeset_dental_update(%{type: "inclusion"})
      |> Repo.update()

    {:ok, pcf} =%ProductCoverageFacility{}
      |> ProductCoverageFacility.changeset(product_coverage_facility_param)
      |> Repo.insert()

    result = get_inclusion_pcf(pcf.facility_id)

    result =
      result
      |> Map.put_new(:product_coverage_facility_id, pcf.id)
      |> Map.put_new(:type, "inclusion")
  end


  def get_inclusion_pcf(id) do
    f =
      Facility
      |> Repo.get!(id)
      |> Repo.preload([
        [facility_location_groups: :location_group]
      ])

    # flg =
    #   f.facility_location_groups
    #   |> List.first()

    # lg = flg.location_group

    %{
      facility_id: f.id,
      code: f.code,
      name: f.name,
      line_1: f.line_1,
      line_2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      postal_code: f.postal_code,
      longitude: f.longitude,
      latitude: f.latitude
    }

    rescue
      _ ->
        nil
  end

  def get_product_coverage_facility_by_id(product_coverage_id, facility_id) do
    # Searches a ProductCoverageFacility record according to its product coverage id and facility id.

    ProductCoverageFacility
    |> where([pcf], pcf.product_coverage_id == ^product_coverage_id and pcf.facility_id == ^facility_id)
    |> Repo.one!()
  end

  def get_selected_product_coverage_facility(id) do
    ProductCoverageFacility
    |> where([pcf], pcf.product_coverage_id == ^id)
    |> select([pcf], pcf.facility_id)
    |> Repo.all()
  end

  def get_product_coverage_location_group(pc_id, lg_id) do
    ProductCoverageLocationGroup
    # |> where([pclg], pclg.product_coverage_id == ^pc_id and pclg.location_group_id == ^lg_id)
    |> where([pclg], pclg.product_coverage_id == ^pc_id)
    |> Repo.one()
  end

  def insert_or_update_pclg(%{"location_group_id" => _, "product_coverage_id" => nil}), do: nil
  def insert_or_update_pclg(%{"location_group_id" => nil, "product_coverage_id" => _}), do: nil
  def insert_or_update_pclg(params) do
    lg_id = params["location_group_id"]
    pc_id = params["product_coverage_id"]
    pclg = get_product_coverage_location_group(pc_id, lg_id)

    set_product_coverage_location_group(pclg, pc_id, lg_id)
  end

  defp set_product_coverage_location_group(nil, pc_id, lg_id) do
    %ProductCoverageLocationGroup{}
    |> ProductCoverageLocationGroup.changeset(%{
      product_coverage_id: pc_id,
      location_group_id: lg_id
    })
    |> Repo.insert()
  end
  defp set_product_coverage_location_group(pclg, pc_id, lg_id) do
    pclg
    |> ProductCoverageLocationGroup.changeset(%{
      product_coverage_id: pc_id,
      location_group_id: lg_id
    })
    |> Repo.update()
  end

  def get_facility_by_product_id(prod_id) do
    added_facility_ids = get_pcdrsf_facility_ids(prod_id)
    pc =
      prod_id
      |> get_product_coverage()
      |> List.first()

    filter_dental_risk_share_facilities(pc.id, pc.type, added_facility_ids, prod_id)
  end

  def filter_dental_risk_share_facilities(pc_id, nil, [], prod_id), do: []
  def filter_dental_risk_share_facilities(pc_id, nil, added_facility_ids, prod_id), do: []
  def filter_dental_risk_share_facilities(pc_id, "exception", [], prod_id) do
    all_facilities =
      ProductCoverageLocationGroup
      |> join(:inner, [pclg], lg in LocationGroup, pclg.location_group_id == lg.id)
      |> join(:inner, [pclg, lg], flg in FacilityLocationGroup, lg.id == flg.location_group_id)
      |> join(:inner, [pclg, lg, flg], f in Facility, flg.facility_id == f.id)
      |> join(:inner, [pclg, lg, flg, f], d in Dropdown, f.ftype_id == d.id)
      |> where([pclg, lg, flg, f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
      |> where([pclg], pclg.product_coverage_id == ^pc_id)
      |> select([pclg, lg, flg, f], %{
        id: f.id,
        facility_code: f.code,
        facility_name: f.name,
        pc_id: pclg.product_coverage_id
      })
      |> Repo.all()
      |> Enum.uniq()

    exempted_facilities =
      ProductCoverage
      |> join(:inner, [pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
      |> join(:inner, [pc, pcf], f in Facility, pcf.facility_id == f.id)
      |> where([pc, pcf, f], pc.product_id == ^prod_id)
      |> where([pc], pc.type == "exception")
      |> select([pc, pcf, f], %{
        id: f.id,
        facility_code: f.code,
        facility_name: f.name,
        pc_id: pc.id
      })
      |> Repo.all()

    all_facilities -- exempted_facilities
  end
  def filter_dental_risk_share_facilities(pc_id, "inclusion", [], prod_id) do
    included_facilities =
    ProductCoverage
    |> join(:inner, [pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
    |> join(:inner, [pc, pcf], f in Facility, pcf.facility_id == f.id)
    |> where([pc, pcf, f], pc.product_id == ^prod_id)
    |> where([pc], pc.type == "inclusion")
    |> select([pc, pcf, f], %{
      id: f.id,
      facility_code: f.code,
      facility_name: f.name,
      pc_id: pc.id
    })
    |> Repo.all()

    included_facilities
  end
  def filter_dental_risk_share_facilities(pc_id, "exception", added_facility_ids, prod_id) do
    all_facilities =
      ProductCoverageLocationGroup
      |> join(:inner, [pclg], lg in LocationGroup, pclg.location_group_id == lg.id)
      |> join(:inner, [pclg, lg], flg in FacilityLocationGroup, lg.id == flg.location_group_id)
      |> join(:inner, [pclg, lg, flg], f in Facility, flg.facility_id == f.id)
      |> join(:inner, [pclg, lg, flg, f], d in Dropdown, f.ftype_id == d.id)
      |> where([pclg, lg, flg, f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
      |> where([pclg], pclg.product_coverage_id == ^pc_id)
      |> where([pclg, lg, flg, f], f.id not in ^added_facility_ids)
      |> select([pclg, lg, flg, f], %{
        id: f.id,
        facility_code: f.code,
        facility_name: f.name,
        pc_id: pclg.product_coverage_id
      })
      |> Repo.all()
      |> Enum.uniq()

    exempted_facilities =
      ProductCoverage
      |> join(:inner, [pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
      |> join(:inner, [pc, pcf], f in Facility, pcf.facility_id == f.id)
      |> where([pc, pcf, f], pc.product_id == ^prod_id)
      |> where([pc], pc.type == "exception")
      |> select([pc, pcf, f], %{
        id: f.id,
        facility_code: f.code,
        facility_name: f.name,
        pc_id: pc.id
      })
      |> Repo.all()

    all_facilities -- exempted_facilities
  end
  def filter_dental_risk_share_facilities(pc_id, "inclusion", added_facility_ids, prod_id) do
    included_facilities =
      ProductCoverage
      |> join(:inner, [pc], pcf in ProductCoverageFacility, pc.id == pcf.product_coverage_id)
      |> join(:inner, [pc, pcf], f in Facility, pcf.facility_id == f.id)
      |> where([pc, pcf, f], pc.product_id == ^prod_id)
      |> where([pc, pcf, f], f.id not in ^added_facility_ids)
      |> where([pc], pc.type == "inclusion")
      |> select([pc, pcf, f], %{
        id: f.id,
        facility_code: f.code,
        facility_name: f.name,
        pc_id: pc.id
      })
      |> Repo.all()

    included_facilities
  end

  def insert_product_coverage_dental_risk_share(params) do
    %ProductCoverageDentalRiskShare{}
    |> ProductCoverageDentalRiskShare.changeset(params)
    |> Repo.insert()
  end

  def update_pcdrs(pcdrs, params) do
    pcdrs
    |> ProductCoverageDentalRiskShare.changeset(params)
    |> Repo.update()
  end

  def insert_product_coverage_dental_risk_share_facility(params) do
    %ProductCoverageDentalRiskShareFacility{}
    |> ProductCoverageDentalRiskShareFacility.changeset(params)
    |> Repo.insert()
  end

  def get_product_coverage_dental_risk_share_facility(id) do
    facility =
    ProductCoverageDentalRiskShareFacility
    |> Repo.get(id)

    rescue
      Elixir.Ecto.MultipleResultsError ->
        nil
      _ ->
        nil
  end

  def update_product_coverage_dental_risk_share_facility(params) do
    ProductCoverageDentalRiskShareFacility
    |> Repo.get(params["product_coverage_dental_risk_share_facility_id"])
    |> ProductCoverageDentalRiskShareFacility.update_changeset(params)
    |> Repo.update()
  end

  def get_pcdrs_by_id(id) do
    pcdrs =
      ProductCoverageDentalRiskShare
      |> Repo.get(id)

    rescue
      Elixir.Ecto.MultipleResultsError ->
        nil
      _ ->
        nil
  end

  def get_pcdrsf_by_id2(id) do
    pcdrs =
    ProductCoverageDentalRiskShareFacility
      |> Repo.get(id)
  end

  def get_pcdrsf_by_id(id) do
    ProductCoverageDentalRiskShareFacility
    |> Repo.get!(id)
    |> Repo.preload(:facility)
  end

  def get_pcdrsf_facility_ids(product_id) do
    pc_ids =
      ProductCoverage
      |> where([pc], pc.product_id == ^product_id)
      |> select([pc], pc.id)
      |> Repo.all()
    pcrs_ids =
      ProductCoverageDentalRiskShare
      |> where([pcrs], pcrs.product_coverage_id in ^pc_ids)
      |> select([pcrs], pcrs.id)
      |> Repo.all()
    pcrsf_ids =
      ProductCoverageDentalRiskShareFacility
      |> where([pcrsf], pcrsf.product_coverage_dental_risk_share_id in ^pcrs_ids)
      |> select([pcrsf], pcrsf.facility_id)
      |> Repo.all()
  end

  def get_dental_product_coverage_type(product_id) do
    ProductCoverage
    |> where([pc], pc.product_id == ^product_id)
    |> select([pc], pc.type)
    |> Repo.all()
    |> List.first()

    rescue
      Elixir.Ecto.MultipleResultsError ->
        nil
      _ ->
        nil
  end
end

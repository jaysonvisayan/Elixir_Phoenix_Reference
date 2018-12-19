defmodule Innerpeace.PayorLink.Web.Api.V1.ProductView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.Api.ProductContext

  def render("load_all_products.json", %{products: products}) do
    %{product: render_many(products, Innerpeace.PayorLink.Web.Api.V1.ProductView, "product.json", as: :product)}
  end

  def render("show.json", %{product: product}) do
    %{product: render_one(product, Innerpeace.PayorLink.Web.Api.V1.ProductView, "product2.json", as: :product)}
  end

  def render("show_dental.json", %{product: product}) do
    %{product: render_one(product, Innerpeace.PayorLink.Web.Api.V1.ProductView, "product_dental.json", as: :product)}
  end

  def render("product_dental.json", %{product: product}) do
    %{
      # id: product.id,
      code: product.code,
      name: product.name,
      description: product.description,
      dental_plan_limit: product.limit_amount,
      category: product.product_category,
      product_base: product.product_base,
      is_standard: product.standard_product,
      mode_of_payment: product.mode_of_payment,
      type_of_payment: product.type_of_payment_type,
      mode_of_payment_type: get_mode_of_payment_type(product),
      loa_validity: product.loa_validity,
      loa_validity_type: product.loa_validity_type,
      capitation_fee: product.capitation_fee,
      special_handling_type: product.special_handling_type,
      dental_funding_arrangement: product.dental_funding_arrangement,
      member_type: product.member_type,
      type_of_payment: product.type_of_payment_type,
      product_benefit: render_many(
        product.product_benefits,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_benefit.json",
        as: :product_benefit
      ),
      product_coverage: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_coverage.json",
        as: :product_coverage
      ),
      risk_share: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_risk_shares.json",
        as: :product_risk_shares
      )
    }
  end

  def render("product_risk_shares.json", %{product_risk_shares: product_risk_shares}) do
    if is_nil product_risk_shares.product_coverage_dental_risk_share do
      ""
    else
      # if product_risk_shares.type == "exception" do

        prcdrs = product_risk_shares.product_coverage_dental_risk_share
        %{
          asdf_type: prcdrs.asdf_type,
          asdf_amount: prcdrs.asdf_amount,
          asdf_percentage: prcdrs.asdf_percentage,
          asdf_special_handling: prcdrs.asdf_special_handling,
          exempted_facility: render_many(
            product_risk_shares.product_coverage_dental_risk_share.product_coverage_dental_risk_share_facilities,
            Innerpeace.PayorLink.Web.Api.V1.ProductView,
            "product_coverage_dental_risk_share_facility.json",
            as: :product_coverage_dental_risk_share_facility
          )
        }
      # else
      #   prcdrs = product_risk_shares.product_coverage_dental_risk_share
      #   %{
      #     asdf_type: prcdrs.asdf_type,
      #     asdf_amount: prcdrs.asdf_amount,
      #     asdf_special_handling: prcdrs.asdf_special_handling

    end
  end

  def render("product_risk_shares2.json", %{product_coverage: product_coverage}) do
    if is_nil product_coverage.product_coverage_risk_share do
      ""
    else
        prcrs = product_coverage.product_coverage_risk_share
        %{
          coverage: product_coverage.coverage.code,
          af_type: prcrs.af_type,
          af_value: prcrs.af_value,
          af_covered_amount: prcrs.af_covered_amount,
          naf_type: prcrs.naf_type,
          naf_reimbursable: prcrs.naf_reimbursable,
          naf_covered_amount: prcrs.naf_covered_amount,
          naf_value: prcrs.af_value,
          exempted_facility: render_many(
            product_coverage.product_coverage_risk_share.product_coverage_risk_share_facilities,
            Innerpeace.PayorLink.Web.Api.V1.ProductView,
            "product_coverage_risk_share_facility.json",
            as: :product_coverage_risk_share_facility
          )
        }
    end
  end

  def render("product_coverage_dental_risk_share_facility.json", %{product_coverage_dental_risk_share_facility: product_coverage_dental_risk_share_facility}) do

    prcdrs = product_coverage_dental_risk_share_facility
    %{
      code: prcdrs.facility.code,
      sdf_type: prcdrs.sdf_type,
      sdf_amount: prcdrs.sdf_amount,
      sdf_percentage: prcdrs.sdf_percentage,
      sdf_special_handling: prcdrs.sdf_special_handling,
    }
  end

  def render("product_coverage_risk_share_facility.json", %{product_coverage_risk_share_facility: product_coverage_risk_share_facility}) do

    prcrs = product_coverage_risk_share_facility
    %{
      code: prcrs.facility.code,
      type: prcrs.type,
      mount: prcrs.value_amount,
      percentage: prcrs.value_percentage,
    }
  end

  defp get_mode_of_payment_type(product) do
    mop = String.downcase(product.mode_of_payment)
    case mop do
      "capitation" ->
        product.capitation_type
      "per availment" ->
        product.availment_type
      "per_availment" ->
        product.availment_type
      _ ->
        ""
    end
  end

  def render("product2.json", %{product: product}) do
    %{
      id: product.id,
      code: product.code,
      name: product.name,
      description: product.description,
      product_type: product.type,
      product_category: product.product_category,
      limit_type: product.limit_type,
      limit_applicability: product.limit_applicability,
      phic_status: product.phic_status,
      is_standard: product.standard_product,

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

      nem_principal: product.nem_principal,
      nem_dependent: product.nem_dependent,

      sop_principal: product.sop_principal,
      sop_dependent: product.sop_dependent,
      special_handling_type: product.special_handling_type,

      adnb: product.adnb,
      adnnb: product.adnnb,
      opmnb: product.opmnb,
      opmnnb: product.opmnnb,

      exclusions: render_many(
        product.product_exclusions,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_exclusion.json",
        as: :product_exclusion
      ),
      product_benefit: render_many(
        product.product_benefits,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_benefit.json",
        as: :product_benefit
      ),
      product_coverage: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_coverage.json",
        as: :product_coverage
      ),
      rnb: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "rnb.json",
        as: :product_coverage
      ),
      risk_share: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_risk_shares2.json",
        as: :product_coverage
      )
    }
  end

  def render("product.json", %{product: product}) do
    %{
      id: product.id,
      code: product.code,
      name: product.name,
      description: product.description,
      member_type: product.member_type,
      product_type: product.type,
      limit_type: product.limit_type,
      limit_applicability: product.limit_applicability,
      phic_status: product.phic_status,
      product_category: product.product_category,
      is_standard: product.standard_product,

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

      nem_principal: product.nem_principal,
      nem_dependent: product.nem_dependent,

      adnb: product.adnb,
      adnnb: product.adnnb,
      opmnb: product.opmnb,
      opmnnb: product.opmnnb,

      exclusions: render_many(
        product.product_exclusions,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_exclusion.json",
        as: :product_exclusion
      ),
      product_benefit: render_many(
        product.product_benefits,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_benefit.json",
        as: :product_benefit
      ),
      product_coverage: render_many(
        product.product_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_coverage.json",
        as: :product_coverage
      )

    }
  end

  def render("product_exclusion.json", %{product_exclusion: product_exclusion}) do
    disease_count = Enum.count(product_exclusion.exclusion.exclusion_diseases)
    procedure_count = Enum.count(product_exclusion.exclusion.exclusion_procedures)
    %{
      id: product_exclusion.exclusion.id,
      code: product_exclusion.exclusion.code,
      type: product_exclusion.exclusion.coverage,
      name: product_exclusion.exclusion.name,
      disease_count: disease_count,
      procedure_count: procedure_count
    }
  end

  def render("product_benefit.json", %{product_benefit: product_benefit}) do
    %{
      benefit: render_one(product_benefit.benefit, Innerpeace.PayorLink.Web.Api.V1.ProductView, "benefit.json", as: :benefit),

      product_benefit: render_many(product_benefit.product_benefit_limits, Innerpeace.PayorLink.Web.Api.V1.ProductView, "product_benefit_limits.json", as: :product_benefit_limits)
    }
  end

  def render("product_benefit_limits.json", %{product_benefit_limits: product_benefit_limits}) do
    if is_nil(product_benefit_limits) do
      ""
    else
      %{
        coverages: product_benefit_limits.coverages,
        limit_type: product_benefit_limits.limit_type,
        limit_percentage: product_benefit_limits.limit_percentage,
        limit_amount: product_benefit_limits.limit_amount,
        limit_session: product_benefit_limits.limit_session,
        limit_tooth: product_benefit_limits.limit_tooth,
        limit_quadrant: product_benefit_limits.limit_quadrant,
        limit_area: product_benefit_limits.limit_area,
        limit_area_type: product_benefit_limits.limit_area_type
      }
    end
  end

  def render("benefit.json", %{benefit: benefit}) do
    %{
      id: benefit.id,
      code: benefit.code,
      name: benefit.name,
      acu_type: benefit.acu_type,
      acu_coverage: benefit.acu_coverage,
      provider_access: benefit.provider_access,
      peme: benefit.peme,
      maternity_type: benefit.maternity_type,
      coverage: render_many(
        benefit.benefit_coverages,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "benefit_coverage.json",
        as: :benefit_coverage
      ),
      benefit_limit: render_many(
        benefit.benefit_limits,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "benefit_limit.json",
        as: :benefit_limit
      )
      # product_risk_shares: render_many(
      #   product.product_coverage_dental_risk_share,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "product_risk_share.json",
      #   as: :product_risk_shares
      # )
      # procedures: render_many(
      #   benefit.benefit_procedures,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "benefit_procedures.json",
      #   as: :benefit_procedure
      # ),
      # diseases: render_many(
      #   benefit.benefit_diagnoses,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "benefit_diagnoses.json",
      #   as: :benefit_diagnosis
      # ),
      # package: render_many(
      #   benefit.benefit_packages,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "benefit_packages.json",
      #   as: :benefit_package
      # )
    }
  end


  def render("benefit_packages.json", %{benefit_package: benefit_package}) do
    p = benefit_package.package
    %{
      code: p.code,
      name: p.name,
      procedures: render_many(
        p.package_payor_procedure,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "package_procedures.json",
        as: :package_procedure
      )
    }
  end

  def render("package_procedures.json", %{package_procedure: package_procedure}) do
    pp = package_procedure.payor_procedure
    sp = package_procedure.payor_procedure.procedure
    %{
      payor_procedure_code: pp.code,
      payor_procedure_description: pp.description,
      standard_procedure_code: sp.code,
      standard_procedure_description: sp.description
    }
  end

  def render("benefit_procedures.json", %{benefit_procedure: benefit_procedure}) do
    pp = benefit_procedure.procedure
    sp = benefit_procedure.procedure.procedure
    %{
      payor_procedure_description: pp.description,
      payor_procedure_code: pp.code,
      standard_procedure_description: sp.description,
      standard_procedure_code: sp.code
    }
  end

  def render("benefit_diagnoses.json", %{benefit_diagnosis: benefit_diagnosis}) do
    %{
      description: benefit_diagnosis.diagnosis.description,
      code: benefit_diagnosis.diagnosis.code  }
  end

  def render("benefit_coverage.json", %{benefit_coverage: benefit_coverage}) do
    %{
      name: benefit_coverage.coverage.name
  }
  end

  def render("benefit_limit.json", %{benefit_limit: benefit_limit}) do

    %{
      coverages: benefit_limit.coverages,
      limit_type: benefit_limit.limit_type,
      limit_percentage: benefit_limit.limit_percentage,
      limit_amount: benefit_limit.limit_amount,
      limit_session: benefit_limit.limit_session,
      limit_tooth: benefit_limit.limit_tooth,
      limit_quadrant: benefit_limit.limit_quadrant
    }
  end

  def render("product_coverage.json", %{product_coverage: product_coverage}) do
    if product_coverage.product.product_category == "Dental Plan" do
      type = case product_coverage.type do
        "exception" ->
          "Specific Dental Group"
        "inclusion" ->
          "Specific Dental Facility"
        _ ->
          "Not yet filled up"
      end
      else
        type = case product_coverage.type do
          "exception" ->
            "All Affiliated Facility"
          "inclusion" ->
            "Specific Facility"
          _ ->
            "Not yet filled up"
        end
    end
    %{
      coverage: product_coverage.coverage.name,
      type: type,
      funding_arrangement: product_coverage.funding_arrangement,
      location_group: render_many(
        product_coverage.product_coverage_location_groups,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_coverage_location_group.json",
        as: :pclg
      ),
      product_coverage_facility: render_many(
        product_coverage.product_coverage_facilities,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "product_coverage_facility.json",
        as: :product_coverage_facility
      )
      # product_coverage_room_and_board: render_one(
      #   product_coverage.product_coverage_room_and_board,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "product_coverage_room_and_board.json",
      #   as: :product_coverage_room_and_board
      # )
      # product_risk_shares: render_one(
      #   product_coverage.product_coverage_dental_risk_share,
      #   Innerpeace.PayorLink.Web.Api.V1.ProductView,
      #   "product_risk_shares.json",
      #   as: :product_risk_shares
      # )
    }
  end

  def render("product_coverage_location_group.json", %{pclg: pclg}) do
    %{
      name: pclg.location_group.name,
      code: pclg.location_group.code
    }
  end

  def render("product_coverage_facility.json", %{product_coverage_facility: product_coverage_facility}) do
    facility_category_text =
    if is_nil(product_coverage_facility.facility.category) do
      ""
    else
      product_coverage_facility.facility.category.text
    end
    %{
      type: product_coverage_facility.facility.type.text,
      code: product_coverage_facility.facility.code,
      name: product_coverage_facility.facility.name,
      region_category_type: facility_category_text,
      location_group: names(product_coverage_facility.facility.facility_location_groups)
    }
  end

  defp names(facility_location_groups) do
    Enum.into(facility_location_groups, [], &(&1.location_group.name))
  end

  def render("product_coverage_room_and_board.json", %{product_coverage_room_and_board: product_coverage_room_and_board}) do
    pcrnb = product_coverage_room_and_board
    rt_record = ProductContext.load_room(pcrnb.room_type)
    rt = if is_nil(rt_record) do
      ""
    else
      rt_record.type
    end

    %{
      room_and_board: pcrnb.room_and_board,
      room_type: rt,
      room_limit_amount: pcrnb.room_limit_amount,
      room_upgrade: pcrnb.room_upgrade,
      room_upgrade_time: pcrnb.room_upgrade_time
    }
  end

  def render("rnb.json", %{product_coverage: product_coverage}) do
    pcrnb = product_coverage.product_coverage_room_and_board
    if is_nil(pcrnb) do
      ""
    else
      rt_record = ProductContext.load_room(pcrnb.room_type)
      rt = if is_nil(rt_record) do
        ""
      else
        rt_record.type
    end

    %{
      coverage: product_coverage.coverage.code,
      room_and_board: pcrnb.room_and_board,
      room_type: rt,
      room_limit_amount: pcrnb.room_limit_amount,
      room_upgrade: pcrnb.room_upgrade,
      room_upgrade_time: pcrnb.room_upgrade_time
    }
    end
  end

  def render("change_member_product_result.json", %{result: result}) do
    %{
      result: render_many(
        result,
        Innerpeace.PayorLink.Web.Api.V1.ProductView,
        "cop.json",
        as: :cop
      )
    }
  end

  def render("cop.json", %{cop: cop}) do
    old_products =
      cop.changed_member_products
      |> Enum.map(&(
        if &1.type == "Old" do
          &1.product.code
        end
      ))
      |> Enum.filter(&(not is_nil(&1)))

    new_products =
      cop.changed_member_products
      |> Enum.map(&(
        if &1.type == "New" do
          &1.product.code
        end
      ))
      |> Enum.filter(&(not is_nil(&1)))

    %{
      change_of_product_effective_date: cop.change_of_product_effective_date,
      reason: cop.reason,
      member: "#{cop.members.first_name} #{cop.members.middle_name} #{cop.members.last_name}",
      old_products: old_products,
      new_products: new_products
    }
  end

end

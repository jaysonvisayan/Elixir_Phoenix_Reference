defmodule Innerpeace.PayorLink.Web.ProductView do
  use Innerpeace.PayorLink.Web, :view
  # import Ecto.Query
  # import Date
  alias Decimal

  alias Innerpeace.Db.{
    Repo,
    Schemas.Coverage,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageRoomAndBoard,
    Schemas.ProductBenefit,
    Schemas.Room,
    Schemas.User,
    Schemas.ProductRiskShare,
    Schemas.ProductCoverageRiskShare,
    Base.ProductContext
  }

  # displaying many coverages in modal product benefit
  def display_coverages(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.name
    end
    Enum.join(list, ", ")
  end

  def display_limit_coverages_index(product_benefit_limits) do
    list = [] ++ for product_benefit_limit <- product_benefit_limits do
      product_benefit_limit.coverages
    end
    _list =
      list
      |> Enum.sort()
      |> Enum.join(", ")
  end

  def display_coverages_index(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.code
    end
    _list =
      list
      |> Enum.sort()
      |> Enum.join(", ")
  end

  def check_acu_coverage(benefit_coverages) do
    list = [] ++ for benefit_coverage <- benefit_coverages do
      benefit_coverage.coverage.name
    end
    _list =
      list
  end

  def load_coverage(product) do
    coverages = [] ++ for product_benefit <- product.product_benefits do
      for benefit_coverage <- product_benefit.benefit.benefit_coverages do
        benefit_coverage.coverage
      end
    end
    coverages
    |> List.flatten()
    |> Enum.uniq()
  end

  def check_facility(product_facilities, facility_id) do
    list = [] ++ for product_facility <- product_facilities do
      if product_facility.facility != nil do
        product_facility.facility.id
      end
    end
    Enum.member?(list, facility_id)
  end

  def load_acu_facilities(facilities, provider_access) do

    facility_list = [] ++ for facility <- facilities do
      if facility != nil do
        facility
      end
    end

    facility_list_hospital = []
    facility_list_clinic = []
    facility_list_mobile = []

    facility_list_hospital =
      if provider_access =~ "Hospital" do
        [] ++ for facility <- facility_list do
          if facility.type.text  == "HOSPITAL-BASED" do
            facility
          end
        end
      else
        facility_list_hospital
      end

    facility_list_clinic =
      if provider_access =~ "Clinic" do
        [] ++ for facility <- facility_list do
          if facility.type.text  == "CLINIC-BASED" do
            facility
          end
        end
      else
        facility_list_clinic
      end

    facility_list_mobile =
      if provider_access =~ "Mobile" do
        [] ++ for facility <- facility_list do
          if facility.type.text  == "MOBILE" do
            facility
          end
        end
      else
        facility_list_mobile
      end

    facility_total = facility_list_hospital ++ facility_list_clinic ++ facility_list_mobile

    _facility_total =
      facility_total
      |> Enum.uniq()
      |> List.delete(nil)

  end

  def load_coverages(product) do
    coverages = [] ++ for product_benefit <- product.product_benefits do
      for benefit_coverage <- product_benefit.benefit.benefit_coverages do
        benefit_coverage.coverage.id
      end
    end
    coverages
    |> List.flatten()
    |> Enum.uniq()
  end

  def risk_share(product_id, coverage_id) do
    if haha = Repo.get_by(
      ProductRiskShare,
      %{
        product_id: product_id,
        coverage_id: coverage_id
      }
    ) do
      haha
    else
      false
    end
  end

  def coverage_changeset(coverage) do
    ProductCoverageRiskShare.changeset(coverage)
  end

  def pc_rnb_changeset(product_coverage_room_and_board) do
    ProductCoverageRoomAndBoard.changeset(product_coverage_room_and_board)
  end

  def load_inclusion_summary(product, coverage_id) do
    list = [] ++ for product_facility <- product.product_facilities do
      if product_facility.coverage_id == coverage_id do
        product_facility.is_included
      end
    end
    list
    |> List.flatten()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def load_coverages_summary(product) do
    coverages = [] ++ for product_coverage <- product.product_coverages do
        product_coverage.coverage_id
    end
    coverages
    |> List.flatten()
    |> Enum.uniq()
  end

  def load_coverages_summary_rs(product) do
    _coverages = [] ++ for product_risk_share <- product.product_risk_shares do
        product_risk_share.coverage_id
    end
  end

  def load_coverages_id(coverages_id) do
    coverage = Repo.get!(Coverage, coverages_id)
    coverage.name
  end

  def load_product_facility_coverages(product_facility, coverage_id) do
    list = [] ++ for pf <- product_facility do
      if pf.coverage_id == coverage_id do
        if pf.facility == nil do
          'no facility exempted'
        else
          pf.facility.id
        end
      end
    end
    list
    |> Enum.uniq
    |> List.delete(nil)
    |> Enum.join(",")
  end

  def load_product_coverage_facility(product_coverage_facilities) do
    list = [] ++ for pcf <- product_coverage_facilities do
      pcf.facility.id
    end
    list
    |> Enum.join(",")
  end

  def check_active_coverage(product_coverage_id, coverage_id) do
    if product_coverage_id == coverage_id do
      "active"
    end
  end

  def check_exclusion(product_exclusions, exclusion_id) do
    list = [] ++ for product_exclusion <- product_exclusions do
      product_exclusion.exclusion.id
    end
    Enum.member?(list, exclusion_id)
  end

  def check_exclusion_genex(product_exclusions) do
    list = [] ++ for product_exclusion <- product_exclusions do
      if product_exclusion.exclusion.coverage == "General Exclusion" do
        product_exclusion
      end
    end
    list |> Enum.uniq() |> List.delete(nil)
  end

  def check_pre_existing(product_exclusions) do
    list = [] ++ for product_exclusion <- product_exclusions do
      if product_exclusion.exclusion.coverage == "Pre-existing Condition" do
        product_exclusion
      end
    end
    list |> Enum.uniq() |> List.delete(nil)
  end

  def filter_genex(product_exclusions, exclusions) do
    product_exclusion_list = for product_exclusion <- product_exclusions, into: [] do
      if product_exclusion.exclusion.coverage == "General Exclusion" do
        %{
          id: product_exclusion.exclusion.id,
          code: product_exclusion.exclusion.code,
          name: product_exclusion.exclusion.name,
          exclusion_diseases: Enum.count(product_exclusion.exclusion.exclusion_diseases),
          exclusion_procedures: Enum.count(product_exclusion.exclusion.exclusion_procedures)
        }
      end
    end
    product_exclusion_list = product_exclusion_list |> Enum.uniq() |> List.delete(nil)

    exclusions_list = [] ++ for exclusion <- exclusions do
      if exclusion.coverage == "General Exclusion" do
        %{
          id: exclusion.id,
          code: exclusion.code,
          name: exclusion.name,
          exclusion_diseases: Enum.count(exclusion.exclusion_diseases),
          exclusion_procedures: Enum.count(exclusion.exclusion_procedures)
        }
      end
    end
    exclusions_list = exclusions_list |> Enum.uniq() |> List.delete(nil)
    exclusions_list -- product_exclusion_list
  end

  def filter_pre_existing(product_exclusions, exclusions) do
    product_exclusion_list = for product_exclusion <- product_exclusions, into: [] do
      if product_exclusion.exclusion.coverage == "Pre-existing Condition" do
        %{
          id: product_exclusion.exclusion.id,
          code: product_exclusion.exclusion.code,
          name: product_exclusion.exclusion.name,
          exclusion_diseases: Enum.count(product_exclusion.exclusion.exclusion_diseases)
        }
      end
    end
    product_exclusion_list = product_exclusion_list |> Enum.uniq() |> List.delete(nil)

    exclusions_list = [] ++ for exclusion <- exclusions do
      if exclusion.coverage == "Pre-existing Condition" do
        %{
          id: exclusion.id,
          code: exclusion.code,
          name: exclusion.name,
          exclusion_diseases: Enum.count(exclusion.exclusion_diseases)
        }
      end
    end
    exclusions_list = exclusions_list |> Enum.uniq() |> List.delete(nil)
    exclusions_list -- product_exclusion_list
  end

  def filter_facility(_product_risk_shares, facilities) do

    # Temporarily

    #   product_risk_share_facility = [] ++ for product_risk_share <- product_risk_shares do
    #     test1 = [] ++ for product_risk_share_facility <- product_risk_share.product_risk_shares_facilities do
    #       {"#{product_risk_share_facility.facility.code} -
    #{product_risk_share_facility.facility.name}",
    #product_risk_share_facility.facility.id}
    #     end
    #   end
    #   product_risk_share_facility = List.flatten(product_risk_share_facility)

    #   facilities = [] ++ for facility <- facilities do
    #     {"#{facility.code} - #{facility.name}", facility.id}
    #   end

    #   facilities -- product_risk_share_facility

       facilities
       |> Enum.map(&{"#{&1.code} - #{&1.name}", &1.id})
       |> Enum.sort()
  end

  def filter_procedure(procedures) do
    procedures
    |> Enum.map(&{"#{&1.code} - #{&1.description}", &1.id})
    |> Enum.sort()
  end

  def display_limit_amount(benefit_limit) do
    case benefit_limit.limit_type do
      "Plan Limit Percentage" ->
        benefit_limit.limit_percentage
      "Peso" ->
        benefit_limit.limit_amount
      "Sessions" ->
        benefit_limit.limit_session
    end
  end

  def get_all_benefit_limit_peso(product_benefit) do
    total_peso_limit = for product_benefit_limit <- product_benefit.product_benefit_limits do
      if product_benefit_limit.limit_type == "Peso" do
        product_benefit_limit.limit_amount
      end
    end

    total_peso_limit =
      total_peso_limit
      |> Enum.filter(fn(x) -> is_nil(x) == false end)

    recursion_decimal(total_peso_limit)
  end

  def date_computation(exclusion) do
    ## ongoing date_transformation
    from = exclusion.duration_from |> Ecto.Date.to_iso8601() |> Date.from_iso8601!()
    to = exclusion.duration_to |> Ecto.Date.to_iso8601() |> Date.from_iso8601!()

    result = Date.range(from, to)
    duration = Enum.count(result) - 1
    case duration do
      duration when duration <= 31 ->
        "#{duration} days"
      duration when duration >= 31 ->
        result = duration / 31
        "#{:erlang.float_to_binary(result, [decimals: 0])} mth & #{rem(duration, 31)} days"
      duration when duration > 365 ->
        result = duration / 31
        "#{:erlang.float_to_binary(result, [decimals: 0])} mth & #{rem(duration, 31)} days"
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

  def deleting_nil(limits) do
    if Enum.member?(limits, nil) do
      new_limits = List.delete(limits, nil)
      if Enum.member?(new_limits, nil) do
         deleting_nil(new_limits)
      else
        new_limits
      end
    else
      limits
    end
  end

  def grid_and_modal_checker_pb(product_benefits, benefits) do
    # benefits
    # |> Enum.map(&(&1.benefit_limits
    # |> Enum.into([], fn(x) -> if x.limit_type == "Peso", do: x.limit_amount end)
    # |> deleting_nil()
    # |> recursion_decimal()
    # ))
    # |> raise ################################################

    ## for onload of step3 benefit modal
    ## to render details in modal
    for benefit <- benefits, into: [] do
      coverages =
        for benefit_coverage <- benefit.benefit_coverages, into: [], do: %{
          name: benefit_coverage.coverage.code
      }

      limits =
        for benefit_limit <- benefit.benefit_limits, into: [],
          do: if benefit_limit.limit_amount == "Peso" or coverages == [%{name: "ACU"}],
            do: benefit_limit.limit_amount

      if Enum.member?(limits, nil) do
        r = deleting_nil(limits)
        result = recursion_decimal(r)
        %{
          id: benefit.id,
          code: benefit.code,
          name: benefit.name,
          peme: benefit.peme,
          benefit_coverages: Enum.sort(coverages),
          total: result
        }
      else
        result = recursion_decimal(limits)
        %{
          id: benefit.id,
          code: benefit.code,
          name: benefit.name,
          peme: nil,
          benefit_coverages: Enum.sort(coverages),
          total: result
        }
      end
    end

  end

  def display_time(date_time) do
    date_time =
      date_time
      |> DateTime.to_time()
    "#{date_time.hour}:#{date_time.minute}"
  end

  def load_classification(classification) do
    if classification == "Yes" do
      "Standard"
    else
      "Custom"
    end
  end

  #  for the title of accordion
  def get_product_coverage(pcrnb_id) do
    pcrnb =
      ProductCoverageRoomAndBoard
      |> Repo.get!(pcrnb_id)
      |> Repo.preload([product_coverage: :coverage])

    desc = pcrnb.product_coverage.coverage.description
    String.upcase(desc)
  end

  # to get coverage_id from product_coverage_room_and_board backward
  def get_product_coverage_id(pcrnb_id) do
    pcrnb =
      ProductCoverageRoomAndBoard
      |> Repo.get!(pcrnb_id)
      |> Repo.preload([product_coverage: :coverage])

    pcrnb.product_coverage.coverage.id
  end

  # for funding arrangment selected if Fullrisk or ASO
  def funding_checker(product_coverage_id) do
    _product_coverage =
      ProductCoverage
      |> Repo.get(product_coverage_id)
      |> Repo.preload([:product_coverage_room_and_board])
  end

  def acu_executive_checker(product_coverage_rnb) do
    product_coverage_rnb.product_coverage
    |> Repo.preload([:product_benefits])

    ""
    # if is_nil(product_coverage_rnb) == false do
    #     String.upcase("Executive" <> " - " <> "Inpatient")
    # else
    #   ""
    # end
  end

  def check_facility_access(product) do
    result = [] ++ Enum.map(
      product.product_coverages,
      & (
        if is_nil(&1.type) do
          "error"
        else
          if &1.type == "inclusion" and &1.product_coverage_facilities == [] do
            "error"
          end
        end
      ))

    result
    |> Enum.member?("error")
  end

  def convert_rooms(rooms) do
    rooms = for room <- rooms, do: %{type: room.type, id: room.id}
    _rooms =
      rooms
      |> Enum.map(&({&1.type, &1.id}))

  end

  def preload_room_type(pcrnb_room_type) do
    if is_nil(pcrnb_room_type) do
      ""
    else
      room =
        Room
        |> Repo.get(pcrnb_room_type)

      if is_nil(room) do
        ""
      else
        room.type
      end
    end
  end

  def load_pchoed(pchoed, hierarchy_type) do
    result = [] ++ for pchoed_record <- pchoed do
      if pchoed_record.hierarchy_type == hierarchy_type do
        Integer.to_string(pchoed_record.ranking) <> "-" <> pchoed_record.dependent
      end
    end
    _result =
      result
      |> Enum.uniq()
      |> List.delete(nil)
      |> Enum.join(",")
  end

  def load_user(user_id) do
    user =
      User
      |> Repo.get(user_id)
    user.username
  end

  def load_date(date_time) do
    date = DateTime.to_date(date_time)
    month = append_zeros(Integer.to_string(date.month))
    day = append_zeros(Integer.to_string(date.day))
    year = Integer.to_string(date.year)

    _result = month <> "/" <> day <> "/" <> year
  end

  def append_zeros(string) do
    if String.length(string) == 1 do
      _string = "0" <> string
    else
      string
    end
  end

  def member_type_checker(member_type) do
    if member_type == nil do
      ""
    else
      Enum.join(member_type, ", ")
    end

  end

  def product_base_label(product) do
    case product.product_base  do
      "Exclusion-based" ->
        "Coverage"
      "Benefit-based" ->
        "Benefit"
      _ ->
        "Coverage/Benefit"
    end
  end

  def product_base_link(product) do
    if !is_nil(product.product_base) do
      case product.product_base  do
        "Exclusion-based" ->
          "3.2"
        "Benefit-based" ->
          "3"
      end
      else
        "3"
    end
  end

  def product_base_link_edittab(product) do
    if !is_nil(product.product_base) do
      case product.product_base  do
        "Exclusion-based" ->
          "coverage"
        "Benefit-based" ->
          "benefit"
      end
      else
        "benefit"
    end
  end

  def coverage_checkbox_checker(product, coverage_id) do
    coverage_ids_from_pc = for product_coverage <- product.product_coverages do
      product_coverage.coverage.id
    end

    if Enum.member?(coverage_ids_from_pc, coverage_id) do
      'checked=""'
    end
  end

  def checkRiskShareValues(risk_share) do
    af_type = if risk_share.af_type != nil, do: ["true"], else: [nil]
    af_value_percentage = if risk_share.af_value_percentage != nil, do: ["true"], else: [nil]
    af_value_amount = if risk_share.af_value_amount != nil, do: ["true"], else: [nil]
    af_covered_percentage = if risk_share.af_covered_percentage != nil, do: ["true"], else: [nil]
    naf_reimbursable = if risk_share.naf_reimbursable != nil, do: ["true"], else: [nil]
    naf_type = if risk_share.naf_type != nil, do: ["true"], else: [nil]
    naf_value_percentage = if risk_share.naf_value_percentage != nil, do: ["true"], else: [nil]
    naf_value_amount = if risk_share.naf_value_amount != nil, do: ["true"], else: [nil]
    naf_covered_percentage = if risk_share.naf_covered_percentage != nil, do: ["true"], else: [nil]

    list =
      af_type ++ af_value_percentage ++
      af_value_amount ++ af_covered_percentage ++
      naf_reimbursable ++ naf_type ++
      naf_value_percentage ++ naf_value_amount ++
      naf_covered_percentage

    result =
      list
      |> Enum.uniq
      |> Enum.member?("true")

    if result == true, do: "true", else: "false"
  end

  def filter_risk_share(product_risk_share) do
    if is_nil(product_risk_share.naf_reimbursable) do
      if Enum.empty?(product_risk_share.product_coverage_risk_share_facilities) do
        {:all_is_nil}
      else
        {:without_risk_share_default}
      end
    else
      {:default_only}
    end
  end

  def load_rnb_record(rnb) do
    id = if rnb.id != nil, do: rnb.id, else: "nil"
    room_and_board = if rnb.room_and_board != nil, do: rnb.room_and_board, else: "nil"
    room_type = if rnb.room_type != nil, do: rnb.room_type, else: "nil"
    room_limit_amount = if rnb.room_limit_amount != nil, do: Decimal.to_string(rnb.room_limit_amount), else: "nil"
    room_upgrade = if rnb.room_upgrade != nil, do: Integer.to_string(rnb.room_upgrade), else: "nil"
    room_upgrade_time = if rnb.room_upgrade_time != nil, do: rnb.room_upgrade_time, else: "nil"
    product_coverage_id = if rnb.product_coverage.coverage_id != nil, do: rnb.product_coverage.coverage_id, else: "nil"

    "#{id} #{room_and_board} #{room_type} #{room_limit_amount} #{room_upgrade} #{room_upgrade_time} #{product_coverage_id}"
  end

  def render("pcltf.json", %{pcltf: pcltf}) do
    %{
      result: render_many(pcltf, Innerpeace.PayorLink.Web.ProductView, "lt_facility.json", as: :lt_facility)
    }
  end

  def render("lt_facility.json", %{lt_facility: lt_facility}) do
    %{
      id: lt_facility.id,
      facility_id: lt_facility.facility.id,
      code: lt_facility.facility.code,
      name: lt_facility.facility.name,
      limit_threshold: lt_facility.limit_threshold
    }
  end

  def render("load_pcf.json", %{pcf: pcf}) do
    %{
      result: render_many(pcf, Innerpeace.PayorLink.Web.ProductView, "facility.json", as: :facility)
    }
  end

  def render("facility.json", %{facility: facility}) do
    type = if is_nil(facility.type), do: "", else: facility.type.text
    category = if is_nil(facility.category), do: "", else: facility.category.text
    %{
      id: facility.id,
      code: facility.code,
      name: facility.name,
      type: type,
      location_group: facility.facility_location_groups,
      region: facility.region,
      category: category
    }
  end
  def pbl_highest(product) do
    all_pbl = for product_benefit <- product.product_benefits do
      for product_benefit_limit <- product_benefit.product_benefit_limits do
        if product_benefit_limit.limit_type == "Peso" do
          product_benefit_limit.limit_amount
        end
      end
    end

    _per_pbl_total = for add <- all_pbl do
    add = Enum.filter(add, fn(x) -> x != nil end)

    ### this is for acu
      if Enum.empty?(add) do
        recursion_decimal([Decimal.new(0)])
      else
        recursion_decimal(add)
      end
    end
    |> ProductContext.recursion_highest_decimal()
    |> List.first()
    ## #Decimal<19001.50>
  end

  #for_product_index
  def render("load_all_products.json", %{products: products}) do
    %{product: render_many(products, Innerpeace.PayorLink.Web.ProductView, "product.json", as: :product)}
  end

  def render("product.json", %{product: product}) do
    %{
      id: product.id,
      code: product.code,
      name: product.name,
      description: product.description,
      classification: load_classification(product.standard_product),
      created_by: product.created_by.username,
      updated_by: product.updated_by.username,
      date_created: load_date(product.inserted_at),
      date_updated: load_date(product.updated_at),
      step: product.step,
      facility_access: check_facility_access(product)
    }
  end

  # for product_benefit step3
  def render("load_all_benefits.json", %{benefits: benefits}) do
    %{benefits: render_many(benefits, Innerpeace.PayorLink.Web.ProductView, "benefit.json", as: :benefit)}
  end

  def render("benefit.json", %{benefit: benefit}) do
    %{
      id: benefit.id,
      code: benefit.code,
      name: benefit.name,
      peme: benefit.peme,
      benefit_coverages: get_benefit_coverages(benefit),
      total_limit_amount: get_total_limit_amount(benefit)
    }
  end

  def get_total_limit_amount(benefit) do
    benefit.benefit_limits
    |> Enum.into([], &( if not is_nil(&1.limit_amount), do: &1.limit_amount))
    |> deleting_nil()
    |> recursion_decimal()
  end

  def get_benefit_coverages(benefit) do
    benefit.benefit_coverages
    |> Enum.map(&(&1.coverage.code))
    |> Enum.sort()
  end

  def display_location_groups(facility) do
    if Enum.empty?(facility.facility_location_groups) do
      "N/A"
    else
      facility.facility_location_groups
      |> Enum.into([],  &(&1.location_group.name))
      |> Enum.join(",")
    end
  end

  def check_nil_pec_limit(product_exclusion) do
    if is_nil(product_exclusion) do
      " "
    else
      if is_nil(product_exclusion.product_exclusion_limit) do
        %{
          limit_type: " ",
          limit_peso: " ",
          limit_percentage: " ",
          limit_session: " "
        }
      else
        product_exclusion.product_exclusion_limit
      end
    end
  end

  def load_limit_amount(pel) do
    # Load Product Exclusion Limit

    if not is_nil(pel) do
      case pel.limit_type do
        "Peso" ->
          pel.limit_peso
        "Percentage" ->
          pel.limit_percentage
        "Sessions" ->
          pel.limit_sessions
        _ ->
          ""
      end
    end
  end

  def is_medina?(is_medina) do
    if is_medina == true, do: "Yes", else: "No"
  end

  def check_user(nil), do: nil
  def check_user(user), do: user.username
end

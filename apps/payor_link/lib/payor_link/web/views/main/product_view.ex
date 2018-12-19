defmodule Innerpeace.PayorLink.Web.Main.ProductView do
  use Innerpeace.PayorLink.Web, :view

  alias Decimal
  import Ecto.Query

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
    Schemas.ProductCoverageDentalRiskShare,
    Schemas.ProductCoverageDentalRiskShareFacility,
    Schemas.Facility,
    Schemas.ProductCoverageFacility,
    Base.DropdownContext,
    Base.ProductContext
  }

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

  def load_classification(classification) do
    if classification == "Yes" do
      "Standard"
    else
      "Custom"
    end
  end

  # def display_coverages_benefit(benefit) do
  #   list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
  #     benefit_coverage.coverage_name
  #   end
  #   Enum.join(list, ", ")
  # end

  def ruv_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "RUV")
  end

  def acu_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.name
    end
    Enum.member?(list, "ACU")
  end

  def peme_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "PEME")
  end

  def is_benefit_already_used?(benefit) do
    if not Enum.empty?(benefit.product_benefit) do
      "disabled"
    else
      ""
    end
  end

  def convert_date_discontinue(benefit) do
    date = benefit.discontinue_date
    month_text = date.month
    months_map = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    new_converted_date = months_map[month_text]
    new_date= "#{(new_converted_date)} #{(date.day)}, #{(date.year)}"
  end

  def convert_date_delete(benefit) do
    date = benefit.delete_date
    month_text = date.month
    months_map = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    new_converted_date = months_map[month_text]
    new_date= "#{(new_converted_date)} #{(date.day)}, #{(date.year)}"
  end

  def convert_date_disable(benefit) do
    date = benefit.disabled_date
    month_text = date.month
    months_map = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    new_converted_date = months_map[month_text]
    new_date= "#{(new_converted_date)} #{(date.day)}, #{(date.year)}"
  end

  def display_limit_amount(benefit_limit) do
    case benefit_limit.limit_type do
      "Plan Limit Percentage" ->
        benefit_limit.limit_percentage
      "Peso" ->
        benefit_limit.limit_amount
      "Sessions" ->
        benefit_limit.limit_session
      _ ->
        ""
    end
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

  def display_location_groups(facility) do
    if Enum.empty?(facility.facility_location_groups) do
      "N/A"
    else
      facility.facility_location_groups
      |> Enum.into([],  &(&1.location_group.name))
      |> Enum.join(",")
    end
  end

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

  # def load_acu_facilities(facilities, provider_access) do

  #   facility_list = [] ++ for facility <- facilities do
  #     if facility != nil do
  #       facility
  #     end
  #   end

  #   facility_list_hospital = []
  #   facility_list_clinic = []
  #   facility_list_mobile = []

  #   facility_list_hospital =
  #     if provider_access =~ "Hospital" do
  #       [] ++ for facility <- facility_list do
  #         if facility.type.text  == "HOSPITAL-BASED" do
  #           facility
  #         end
  #       end
  #       else
  #       facility_list_hospital
  #     end

  #   facility_list_clinic =
  #     if provider_access =~ "Clinic" do
  #       [] ++ for facility <- facility_list do
  #         if facility.type.text  == "CLINIC-BASED" do
  #           facility
  #         end
  #       end
  #       else
  #       facility_list_clinic
  #     end

  #     facility_list_mobile =
  #       if provider_access =~ "Mobile" do
  #         [] ++ for facility <- facility_list do
  #           if facility.type.text  == "MOBILE" do
  #             facility
  #           end
  #         end
  #         else
  #         facility_list_mobile
  #       end

  #       facility_total = facility_list_hospital ++ facility_list_clinic ++ facility_list_mobile

  #       _facility_total =
  #         facility_total
  #         |> Enum.uniq()
  #         |> List.delete(nil)

  # end

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

        if Enum.member?(limits, nil) or Enum.empty?(limits) do
          r = deleting_nil(limits)
          result = recursion_decimal(r)
          %{
            id: benefit.id,
            code: benefit.code,
            name: benefit.name,
            peme: transform_peme(benefit),
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
  defp transform_peme(benefit), do: if is_nil(benefit.status), do: true, else: false

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

  # def product_base_link(product) do
  #   if !is_nil(product.product_base) do
  #     case product.product_base  do
  #       "Exclusion-based" ->
  #         "3.2"
  #       "Benefit-based" ->
  #         "3"
  #     end
  #     else
  #       "3"
  #   end
  # end

  # def product_base_link_edittab(product) do
  #   if !is_nil(product.product_base) do
  #     case product.product_base  do
  #       "Exclusion-based" ->
  #         "coverage"
  #       "Benefit-based" ->
  #         "benefit"
  #     end
  #     else
  #       "benefit"
  #   end
  # end

  def coverage_checkbox_checker(product, coverage_id) do
    coverage_ids_from_pc = for product_coverage <- product.product_coverages do
      product_coverage.coverage.id
    end

    if Enum.member?(coverage_ids_from_pc, coverage_id) do
      'checked=""'
    end
  end

  # def checkRiskShareValues(risk_share) do
  #   af_type = if risk_share.af_type != nil, do: ["true"], else: [nil]
  #   af_value_percentage = if risk_share.af_value_percentage != nil, do: ["true"], else: [nil]
  #   af_value_amount = if risk_share.af_value_amount != nil, do: ["true"], else: [nil]
  #   af_covered_percentage = if risk_share.af_covered_percentage != nil, do: ["true"], else: [nil]
  #   naf_reimbursable = if risk_share.naf_reimbursable != nil, do: ["true"], else: [nil]
  #   naf_type = if risk_share.naf_type != nil, do: ["true"], else: [nil]
  #   naf_value_percentage = if risk_share.naf_value_percentage != nil, do: ["true"], else: [nil]
  #   naf_value_amount = if risk_share.naf_value_amount != nil, do: ["true"], else: [nil]
  #   naf_covered_percentage = if risk_share.naf_covered_percentage != nil, do: ["true"], else: [nil]

  #   list =
  #     af_type ++ af_value_percentage ++
  #       af_value_amount ++ af_covered_percentage ++
  #         naf_reimbursable ++ naf_type ++
  #           naf_value_percentage ++ naf_value_amount ++
  #             naf_covered_percentage

  #             result =
  #               list
  #               |> Enum.uniq
  #               |> Enum.member?("true")

  #               if result == true, do: "true", else: "false"
  # end

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
        if not is_nil(product_benefit_limit.limit_type) do
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

  ###################################################################################################################################
  def render("load_one_product.json", %{product: product}) do
    %{
      id: product.id,
      name: product.name,
      code: product.code,
      step: product.step,
      product_base: product.product_base,
      product_coverages: render_many(product.product_coverages,
                                     Innerpeace.PayorLink.Web.Main.ProductView,
                                     "product_coverage.json", as: :product_coverage)
    }
  end
  def render("product_coverage.json", %{product_coverage: product_coverage}) do
    %{
      id: product_coverage.id,
      code: product_coverage.coverage.code,
      product_id: product_coverage.product_id,
      coverage_id: product_coverage.coverage_id,
      type: product_coverage.type,
      funding_arrangement: product_coverage.funding_arrangement,
      product_coverage_facilities: render_many(product_coverage.product_coverage_facilities,
                                               Innerpeace.PayorLink.Web.Main.ProductView,
                                               "product_coverage_facility.json", as: :product_coverage_facility),
      product_coverage_limit_threshold: render_one(product_coverage.product_coverage_limit_threshold,
                                                   Innerpeace.PayorLink.Web.Main.ProductView, "product_coverage_limit_threshold.json",
                                                   as: :product_coverage_limit_threshold)
    }
  end
  def render("product_coverage_limit_threshold.json", %{product_coverage_limit_threshold: product_coverage_limit_threshold}) do
    %{
      id: product_coverage_limit_threshold.id,
      limit_threshold: product_coverage_limit_threshold.limit_threshold,
      product_coverage_id: product_coverage_limit_threshold.product_coverage_id,
      product_coverage_limit_threshold_facilities: render_many(product_coverage_limit_threshold.product_coverage_limit_threshold_facilities,
                                               Innerpeace.PayorLink.Web.Main.ProductView,
                                               "pcltf2.json", as: :pcltf2),
    }
  end
  def render("pcltf2.json", %{pcltf2: pcltf2}) do
    %{
      id: pcltf2.id,
      facility_name: pcltf2.facility.name,
      facility_code: pcltf2.facility.code,
      limit_threshold: pcltf2.limit_threshold,
      facility_id: pcltf2.facility_id,
      product_coverage_limit_threshold_id: pcltf2.product_coverage_limit_threshold_id
    }
  end
  def render("product_coverage_facility.json", %{product_coverage_facility: product_coverage_facility}) do
    address = "#{ product_coverage_facility.facility.line_1} #{product_coverage_facility.facility.line_2} #{product_coverage_facility.facility.city} #{product_coverage_facility.facility.province} #{product_coverage_facility.facility.region} #{product_coverage_facility.facility.country}"
    %{
      id: product_coverage_facility.id,
      facility_name: product_coverage_facility.facility.name,
      facility_code: product_coverage_facility.facility.code,
      facility_region: product_coverage_facility.facility.region,
      address: address,
      facility_category: check_facility_category(product_coverage_facility.facility.category),
      facility_type: product_coverage_facility.facility.type.text,
      facility_id: product_coverage_facility.facility_id,
      product_coverage_id: product_coverage_facility.product_coverage_id
    }
  end
  defp check_facility_category(nil), do: ""
  defp check_facility_category(category), do: category.text
  ###################################################################################################################################

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
    |> Enum.into([], &( if &1.limit_type == "Peso", do: &1.limit_amount))
    |> deleting_nil()
    |> recursion_decimal()
  end

  def get_benefit_coverages(benefit) do
    benefit.benefit_coverages
    |> Enum.map(&(&1.coverage.code))
    |> Enum.sort()
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

  def render("all_pcf.json", %{pcfs: pcfs}) do
    %{
      result: render_many(pcfs, Innerpeace.PayorLink.Web.Main.ProductView, "pc_facilities.json", as: :pc_facility)
    }
  end

  def render("pc_facilities.json", %{pc_facility: pc_facility}) do
    type = if is_nil(pc_facility.facility.type.type), do: "", else: pc_facility.facility.type.text
    category = if is_nil(pc_facility.facility.category), do: "", else: pc_facility.facility.category.text
    %{
      code: pc_facility.facility.code,
      name: pc_facility.facility.name,
      type: type,
      location_group: pc_facility.facility.facility_location_groups,
      region: pc_facility.facility.region,
      category: category
    }
  end

  def get_provider_access(product_benefits) do
    product_benefits
    |> Enum.map(&(&1.benefit.provider_access))
    |> Enum.filter(fn(x) -> x != nil end)
  end

  def get_benefit_limit_type(benefit) do
    benefit.benefit_limits
    |> Enum.map(&(&1.limit_type))
    |> List.first()
  end

  def get_pcf_address(product_coverage_facility) do
    "#{ product_coverage_facility.facility.line_1} #{product_coverage_facility.facility.line_2} #{product_coverage_facility.facility.city} #{product_coverage_facility.facility.province} #{product_coverage_facility.facility.region} #{product_coverage_facility.facility.country}"
  end


  def get_benefit_limit_amount(benefit) do
    type = benefit.benefit_limits
           |> Enum.map(&(&1.limit_type))
           |> List.first()

    case type do
      "Peso" ->
        benefit.benefit_limits
        |> Enum.map(&(&1.limit_amount))
        |> List.first()
      "Plan Limit Percentage" ->
        benefit.benefit_limits
        |> Enum.map(&(&1.limit_percentage))
        |> List.first()
      "Sessions" ->
        benefit.benefit_limits
        |> Enum.map(&(&1.limit_session))
        |> List.first()
      "Tooth" ->
        benefit.benefit_limits
        |> Enum.map(&(&1.limit_tooth))
        |> List.first()
      "Quadrant" ->
        benefit.benefit_limits
        |> Enum.map(&(&1.limit_quadrants))
        |> List.first()
      _ ->
        ""
    end
  end

  def get_benefit_limit_type2(product_benefit) do
    product_benefit.product_benefit_limits
    |> Enum.map(&(&1.limit_type))
    |> List.first()
  end

  def get_benefit_limit_amount2(product_benefit) do
    type = product_benefit.product_benefit_limits
           |> Enum.map(&(&1.limit_type))
           |> List.first()
    case type do
      "Peso" ->
        product_benefit.product_benefit_limits
        |> Enum.map(&(&1.limit_amount))
        |> List.first()
        |> getLimit_amount()
      "Plan Limit Percentage" ->
        product_benefit.product_benefit_limits
        |> Enum.map(&(&1.limit_percentage))
        |> List.first()
      "Sessions" ->
        product_benefit.product_benefit_limits
        |> Enum.map(&(&1.limit_session))
        |> List.first()
      "Tooth" ->
        product_benefit.product_benefit_limits
        |> Enum.map(&(&1.limit_tooth))
        |> List.first()
       "Quadrant" ->
        product_benefit.product_benefit_limits
        |> Enum.map(&(&1.limit_quadrant))
        |> List.first()
        |> get_quadrant_amount
      _ ->
        ""
    end
  end

  def get_quadrant_amount(value) do
    if value > 4 or value < 1 do
      value = 4
    else
      value
    end
  end

  def getLimit_amount(value) do
    value = Decimal.to_string(value)
    get_limit_amount(String.contains?(value, "."), value)
  end

  defp get_limit_amount(_, nil), do: 0
  defp get_limit_amount(true, value) do
    value = String.split(value, ".")

    value1 =
      value
      |> Enum.at(0)
      |> String.to_integer
      |> Integer.to_char_list
      |> Enum.reverse
      |> Enum.chunk(3, 3, [])
      |> Enum.join(",")
      |> String.reverse

    "#{value1}.#{Enum.at(value, 1)}"
  end

  defp get_limit_amount(false, value) do
    value
    |> String.to_integer
    |> Integer.to_char_list
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
    |> Kernel.<>(".00")
  end

  def get_sdf_amount(nil), do: "0"
  def get_sdf_amount(sdf_amount) do
    sdf_amount = Decimal.to_string(sdf_amount)
    get_limit_amount(String.contains?(sdf_amount, "."), sdf_amount)
  end

  def count_procedure(benefit_procedures) do
   count = benefit_procedures
    |> Enum.map(&(&1.procedure_id))
    |> Enum.count
  end

  # def filter_product_benefit_dental(benefit, product) do

  #   benefit_ids= [] ++ Enum.map(benefit, fn(x) ->
  #     x.id
  #   end)

  #   product_benefit_ids = [] ++ Enum.map(product.product_benefits, fn(x) ->
  #     x.benefit.id
  #   end)

  #   result = benefit_ids -- product_benefit_ids

  #   benefit_ = [] ++ Enum.map(result, fn(filtered_ids) ->
  #     Enum.map(benefit, fn(x) ->
  #       if filtered_ids == x.id do
  #         x
  #       end
  #     end)
  #   end)

  #   _benefits =
  #       benefit_
  #     |> List.flatten()
  #     |> Enum.uniq()
  #     |> List.delete(nil)
  # end

  def filter_dropdown(ftype_id) do
    ftype_id
    |> DropdownContext.get_dropdown()
  end

  def filter_address(facility) do
    "#{ facility.line_1} #{facility.line_2} #{facility.city} #{facility.province} #{facility.region} #{facility.country}"
  end

  def check_acu_sessions(product_benefit_limit) do
    coverage = product_benefit_limit.coverages
    limit_type = product_benefit_limit.limit_type

    if coverage == "ACU" and limit_type == "Sessions" do
      true
    else
      false
    end
  end

  def get_all_product_coverages(product_coverages) do
    product_coverages
    |> Enum.map(fn(pc) ->
      pc.coverage.code
    end)
    |> Enum.join(",")
  end

  def get_mode_of_payment(product) do
    if is_nil(product.mode_of_payment) do
      "Not Available"
    else
      mode = String.capitalize(product.mode_of_payment)
      case mode do
        "Capitation" ->
          "#{mode}, #{product.capitation_type}"
        "Per_availment" ->
          "Per Availment, #{product.availment_type}"
        "Per availment" ->
          "Per Availment, #{product.availment_type}"
        _ ->
          ""
      end
    end
  end

  def get_loa_validity(product) do
    "#{product.loa_validity} #{product.loa_validity_type}"
  end

  def get_dental_location_group(pc, nil) do
    case pc.type do
      "exception" ->
        if pc.product_coverage_location_groups == [] do
          "N/A"
        else
          "#{List.first(pc.product_coverage_location_groups).location_group.name}"
        end
      "inclusion" ->
        "N/A"
      _ ->
        "N/A"
    end
  end

  def get_dental_location_group(pc, facility) do
    lg = Enum.map(
      facility.facility_location_groups, fn(flg) ->
        flg.location_group.name
      end)
    case pc.type do
    "exception" ->
      "#{List.first(pc.product_coverage_location_groups).location_group.name}"
    "inclusion" ->
      Enum.join(lg, ", ")
    _ ->
      "N/A"
    end
  end

  def get_dental_risk_share_facilities(nil), do: []
  def get_dental_risk_share_facilities(pcdrs), do: pcdrs

  def get_dental_risk_share_type(nil), do: "N/A"
  def get_dental_risk_share_type(pcdrs), do: pcdrs.asdf_type

  def get_dental_risk_share_sh(nil), do: "N/A"
  def get_dental_risk_share_sh(pcdrs), do: pcdrs.asdf_special_handling

  def get_dental_risk_share_value(nil), do: "N/A"
  def get_dental_risk_share_value(pcdrs) do
    if not is_nil(pcdrs.asdf_type) do
      type = String.downcase(pcdrs.asdf_type)
      case type do
        "copayment" ->
          "PHP #{pcdrs.asdf_amount}"
        "copay" ->
          "PHP #{pcdrs.asdf_amount}"
        "coinsurance" ->
          "#{pcdrs.asdf_percentage} %"
        _ ->
          ""
      end
    else
      "N/A"
    end
  end

  def get_dental_risk_share_facility_value(nil), do: "N/A"
  def get_dental_risk_share_facility_value(pcdrsf) do
    if not is_nil(pcdrsf.sdf_type) do
      type = String.downcase(pcdrsf.sdf_type)
      case type do
        "copayment" ->
          "PHP #{pcdrsf.sdf_amount}"
        "copay" ->
          "PHP #{pcdrsf.sdf_amount}"
        "coinsurance" ->
          "#{pcdrsf.sdf_percentage} %"
        _ ->
          ""
      end
    else
      "N/A"
    end
  end

  def get_dental_risk_share_facility_type(nil), do: "N/A"
  def get_dental_risk_share_facility_type(""), do: "N/A"
  def get_dental_risk_share_facility_type(pcdrsf) do
    case pcdrsf.sdf_type do
      "copay" ->
        String.capitalize(pcdrsf.sdf_type)
      "coinsurance" ->
        String.capitalize(pcdrsf.sdf_type)
      _ ->
       ""
    end
  end

  def get_dental_benefit_limit_type(nil), do: "N/A"
  def get_dental_benefit_limit_type(""), do: "N/A"
  def get_dental_benefit_limit_type(pbl), do: pbl.limit_type

  def get_dental_benefit_limit_value(nil), do: "N/A"
  def get_dental_benefit_limit_value(""), do: "N/A"
  def get_dental_benefit_limit_value(pbl) do
    if not is_nil(pbl.limit_type) do
      type = String.downcase(pbl.limit_type)
      case type do
        "peso" ->
          pbl.limit_amount
        "plan limit percentage" ->
          pbl.limit_percentage
        "sessions" ->
          pbl.limit_session
        "tooth" ->
          pbl.limit_tooth
        "quadrant" ->
          pbl.limit_quadrant
        _ ->
          ""
      end
    else
      "N/A"
    end
  end

  def render("all_product_facility_rs.json", %{p_facilities: p_facilities}) when p_facilities == [] do
    %{
      success: false,
      results: []
    }
  end
  def render("all_product_facility_rs.json", %{p_facilities: p_facilities}) do
    %{
      success: true,
      results: render_many(p_facilities, Innerpeace.PayorLink.Web.Main.ProductView, "product_facility_rs.json", as: :p_facility)
    }
  end

  def render("product_facility_rs.json", %{p_facility: p_facility}) do
    %{
      value: p_facility.id,
      name: "#{p_facility.facility_code} #{p_facility.facility_name}"
    }
  end

  def get_pcf(product) do
    for product_coverage <- product.product_coverages do
      for pcf <- product_coverage.product_coverage_facilities do
        %{
          facility_code: pcf.facility.code,
          facility_name: pcf.facility.name,
          facility_address: get_pcf_address(pcf),
          facility_location_group: display_location_groups(pcf.facility)
        }
      end
    end
    |> List.flatten()
  end

  def get_pcf_for_table(product) do
    for product_coverage <- product.product_coverages do
      for pcf <- product_coverage.product_coverage_facilities do
        pcf.id
      end
    end
    |> List.flatten()
  end

  def filter_pcdrs_facility(product_coverage) do
    get_risk_share_facility(product_coverage.id)
  end

  def get_risk_share_facility(product_coverage_id) do
    ProductCoverageDentalRiskShareFacility
    |> join(:inner, [pcdrsf], pcdrs in ProductCoverageDentalRiskShare, pcdrsf.product_coverage_dental_risk_share_id == pcdrs.id)
    |> join(:inner, [pcdrsf, pcdrs], pc in ProductCoverage, pcdrs.product_coverage_id == pc.id)
    |> where([pcdrsf, pcdrs, pc], pc.id == ^product_coverage_id)
    |> distinct(true)
    |> Repo.all()
    |> Repo.preload(:facility)
  end

  def get_product_coverage_facility_id(product_coverage_id) do
    pcf =
      ProductCoverageFacility
      |> where([pcf], pcf.product_coverage_id == ^product_coverage_id)
      |> Repo.all()

    pcf
    |> Enum.map(&(&1.id))
    |> Enum.join(", ")
  end

  def get_product_coverage_type("inclusion"), do: "Specific Dental Facilities"
  def get_product_coverage_type("exception"), do: "Specific Dental Group"
  def get_product_coverage_type(_), do: "Plan Coverage Type is null"

  def check_dental_risk_share_v1(nil), do: true
  def check_dental_risk_share_v1(product), do: validate_rs_v1(product.product_coverages)
  defp validate_rs_v1([]), do: true
  defp validate_rs_v1(pcs), do: validate_rs_v2(Enum.at(pcs, 0))
  defp validate_rs_v2(nil), do: true
  defp validate_rs_v2(pc), do: validate_rs_v3(pc.product_coverage_dental_risk_share)
  defp validate_rs_v3(nil), do: true
  defp validate_rs_v3(pcdrs), do: validate_rs_v4(pcdrs.asdf_type)
  defp validate_rs_v4(nil), do: true
  defp validate_rs_v4(a), do: false

  def check_dental_risk_share_v2(nil), do: true
  def check_dental_risk_share_v2(product), do: validate_drs_v1(product.product_coverages)
  defp validate_drs_v1([]), do: true
  defp validate_drs_v1(pcs), do: validate_drs_v2(Enum.at(pcs, 0))
  defp validate_drs_v2(nil), do: true
  defp validate_drs_v2(pc), do: validate_drs_v3(pc.product_coverage_dental_risk_share)
  defp validate_drs_v3(nil), do: true
  defp validate_drs_v3(pcdrs), do: validate_drs_v4(pcdrs.product_coverage_dental_risk_share_facilities)
  defp validate_drs_v4([]), do: true
  defp validate_drs_v4(_), do: false

  # ProductCoverageDentalRiskShare
  def get_pcdrs_key_value(nil, _key), do: ""
  def get_pcdrs_key_value(pcdrs, key) do
    {_, value} = Map.fetch(pcdrs, key)
    value
  end

  def get_plan_applicability("Principal"), do: "Principal"
  def get_plan_applicability("Dependent"), do: "Dependent"
  def get_plan_applicability("Principal,Dependent"), do: "Principal, Dependent"
  def get_plan_applicability("Principal, Dependent"), do: "Principal, Dependent"
  def get_plan_applicability(nil), do: "N/A"
  def get_plan_applicability(_), do: "N/A"
  def get_plan_applicability(""), do: "N/A"

  def get_facility(nil, _), do: ""
  def get_facility(pcdrsf, key), do: get_facility_v2(get_by_key_value(pcdrsf, :facility), key)
  defp get_facility_v2("", _), do: ""
  defp get_facility_v2(facility, key), do: get_by_key_value(facility, key)

  def get_by_key_value(nil, _), do: ""
  def get_by_key_value(data, key) do
    {_, value} = Map.fetch(data, key)
    value
  end

end

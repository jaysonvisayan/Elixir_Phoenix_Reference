defmodule Innerpeace.PayorLink.Web.Main.BenefitView do
  use Innerpeace.PayorLink.Web, :view

  def display_coverages(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.join(list, ", ")
  end

  def ruv_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "RUV")
  end

  def acu_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "ACU")
  end

  def peme_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "PEME")
  end

  def dental_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "Dental")
  end

  def emergency_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "Emergency")
  end

  def oplab_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "OP Laboratory")
  end

  def opc_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "OP Consult")
  end

  def inpatient_coverage?(benefit) do
    list = [] ++ for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage_name
    end
    Enum.member?(list, "Inpatient")
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
        "#{benefit_limit.limit_percentage} %"
      "Peso" ->
        "#{benefit_limit.limit_amount} PHP"
      "Sessions" ->
        "#{benefit_limit.limit_session} Session/s"
      "Tooth" ->
        "#{benefit_limit.limit_tooth} Tooth"
      "Quadrant" ->
        "#{benefit_limit.limit_quadrant} Quadrant"

      _ ->
        ""
    end
  end

  def convert_date_time(datetime) do
     Date.to_string(datetime)
  end

  def display_category(benefit) do
    loa_facilitated  = if is_nil(benefit.loa_facilitated) or benefit.loa_facilitated == false,
    do: [], else: ["LOA Facilitated"]

    reimbursement  = if is_nil(benefit.reimbursement) or benefit.reimbursement == false,
    do: [], else: ["Reimbursement"]

    category = [] ++ loa_facilitated ++ reimbursement
               |>  Enum.join(", ")
  end

  def display_limit_type(benefit) do
    list = [] ++ for benefit_limit <- benefit.benefit_limit do
      benefit_limit.limit_type
    end
    Enum.join(list, ", ")
  end

  def display_limit(benefit) do
    # limit_type = String.split(display_limit_type(benefit), ",")
    benefit.benefit_limit
    |> Enum.map(fn(limit) ->
      case limit.limit_type do
        "Sessions" ->
          limit.limit_session
        "Peso" ->
          "Php #{limit.limit_amount}"
        "Plan Limit Percentage" ->
          "#{limit.limit_percentage}%"
        "Quadrant" ->
          "#{limit.limit_quadrant}"
        "Tooth" ->
          "#{limit.limit_tooth}"
        "Area" ->
          "N/A"
        _ ->
          "N/A"
      end
    end)
    |> Enum.join(", ")
  end

  defp check_gender(gender) do
    case gender do
       [true, true] ->
         ["M/F"]
      [false, true] ->
        ["F"]
      ["false, false"] ->
        [""]
      [true, false] ->
        ["M"]
      _ ->
        [""]
    end
  end

  defp check_age(age_from, age_to) do
    if age_from == 0 do
      "0" <> "#{ - age_to}"
    else
      "#{age_from - age_to}"
    end
  end

  def is_peme_benefit(coverages) do
    list = [] ++ for benefit_coverage <- coverages do
      benefit_coverage.name
    end
    Enum.member?(list, "PEME")
  end
end

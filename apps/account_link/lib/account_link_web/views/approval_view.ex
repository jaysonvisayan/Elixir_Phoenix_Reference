defmodule AccountLinkWeb.ApprovalView do
  use AccountLinkWeb, :view

  def load_date(date_time) do
    date = DateTime.to_date(date_time)
    month = append_zeros(Integer.to_string(date.month))
    day = append_zeros(Integer.to_string(date.day))
    year = Integer.to_string(date.year)

    _result = month <> "/" <> day <> "/" <> year
  end

  def append_zeros(string) do
    _string =
    if String.length(string) == 1 do
      "0" <> string
    else
      string
    end
  end

  def display_time(date_time) do
    date_time =
      date_time
      |> DateTime.to_time()
    minute = append_zeros(Integer.to_string(date_time.minute))
    "#{date_time.hour}:#{minute}"
  end

  def compute_total_amount(autho_amount) do
    member_covered = autho_amount.member_covered
    payor_covered = autho_amount.payor_covered
    company_covered = autho_amount.company_covered

    if company_covered == Decimal.new(0) do
      total = Decimal.add(member_covered, payor_covered)
    else
      total = Decimal.add(member_covered, payor_covered)
      total = total
              |> Decimal.add(company_covered)
    end
  end
end

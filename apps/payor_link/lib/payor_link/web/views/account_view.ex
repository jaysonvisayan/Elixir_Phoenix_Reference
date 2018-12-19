defmodule Innerpeace.PayorLink.Web.AccountView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.AccountContext
  alias Innerpeace.Db.Base.Api.UtilityContext

  def check_account_products(account_products, product_id) do
    list = [] ++ for account_product <- account_products do
      account_product.product.id
    end
    Enum.member?(list, product_id)
  end

  def display_date(date) do
    "#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}"
  end

  def get_datetime(year, month, day, hour, minute, second) do
    cond do
      year == 0 && month == 0 &&
        day == 0 && hour == 0 &&
          minute == 0 && second == 1 ->
            Integer.to_string(second) <> " second ago"
      year == 0 && month == 0 &&
        day == 0 && hour == 0 && minute == 0 ->
            Integer.to_string(second) <> " seconds ago"
      year == 0 && month == 0 &&
        day == 0 && hour == 0 && minute == 1 ->
          Integer.to_string(minute) <> " minute ago"
      year == 0 && month == 0 &&
        day == 0 && hour == 0 ->
          Integer.to_string(minute) <> " minutes ago"
      year == 0 && month == 0 &&
        day == 1 && hour < DateTime.utc_now.hour ->
          Integer.to_string(hour + 24) <> " hours ago"
      year == 0 && month == 0 &&
        day == 0 && hour == 1 ->
          Integer.to_string(hour) <> " hour ago"
      year == 0 && month == 0 &&
        day == 0 -> Integer.to_string(hour) <> " hours ago"
      year == 0 && month == 0 &&
        day == 1 -> Integer.to_string(day) <> " day ago"
      year == 0 && month == 0 ->
        Integer.to_string(day) <> " days ago"
      year == 0 && month == 1 ->
        Integer.to_string(month) <> " month ago"
      year == 0 -> Integer.to_string(month) <> " months ago"
      year == 1 -> Integer.to_string(year) <> " year ago"
      year > 1 -> Integer.to_string(year) <> " years ago"
    end
  end

  def count_comment(account_id) do
    AccountContext.get_comment_count(account_id)
  end

  def check_financial(account) do
    account = AccountContext.preload_payment_account(account)
    account.payment_account

  end

  def for_extension?(account_status) do
    if account_status != "Active" do
      "disabled"
    end
  end

  def render("show.json", %{account_group: account_group}) do
    %{data: render_one(
        account_group, Innerpeace.PayorLink.Web.AccountView,
        "account_group.json", as: :account_group)}
  end

  def render("account_group.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      code: account_group.code,
      type: account_group.type,
      description: account_group.description,
      segment: account_group.segment,
      security: account_group.security,
      phone_no: account_group.phone_no,
      email: account_group.email,
      remarks: account_group.remarks,
      industry_code: account_group.industry.code,
      account: render_many(
        account_group.account,
        Innerpeace.PayorLink.Web.AccountView,
        "account.json", as: :account),
      account_group_address: render_many(
        account_group.account_group_address,
        Innerpeace.PayorLink.Web.AccountView,
        "account_group_address.json", as: :account_group_address)
    }
  end

  def render("account.json", %{account: account}) do
    %{
      start_date: account.start_date,
      end_date: account.end_date,
      status: account.status,
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      step: account.step
    }
  end

  def render("account_group_address.json", %{account_group_address: account_group_address}) do
    %{
      line_1: account_group_address.line_1,
      line_2: account_group_address.line_2,
      postal_code: account_group_address.postal_code,
      city: account_group_address.city,
      country: account_group_address.country,
      type: account_group_address.type,
      province: account_group_address.province,
      is_check: account_group_address.is_check,
      region: account_group_address.region
    }
  end

  def ap_checker(account_products) do
    ap_list = [] ++ for ap <- account_products do
      if ap.rank != nil do
        Integer.to_string(ap.rank) <> "_" <> ap.id
      end
    end
    Enum.join(ap_list, ",")
  end

  def load_ahoed(ahoed, hierarchy_type) do
    result = [] ++ for ahoed_record <- ahoed do
      if ahoed_record.hierarchy_type == hierarchy_type do
        Integer.to_string(ahoed_record.ranking) <> "-" <> ahoed_record.dependent
      end
    end
    _result =
      result
      |> Enum.uniq()
      |> List.delete(nil)
      |> Enum.join(",")
  end

  def load_ahoed_summary(ahoeds, hierarchy_type) do
    ahoed_records = [] ++ for ahoed <- ahoeds do
      if ahoed.hierarchy_type == hierarchy_type do
        Integer.to_string(ahoed.ranking) <> ". " <> ahoed.dependent
      end
    end

    ahoed_records
    |> Enum.uniq
    |> List.delete(nil)
    |> Enum.sort

  end

  def area_code(area_code) do
    if is_nil(area_code) or area_code == "", do: "", else: area_code
  end

  def local(local) do
    if is_nil(local) or local == "", do: "", else: local
  end

  def valid_product?(account, product) do
    account_coverage_funds =
      Enum.map(
        account.account_group.account_group_coverage_funds,
        &(&1.coverage_id)
      )
    account_coverage_funds = account_coverage_funds |> Enum.uniq()
    aso_product_coverages =
      product.product_coverages
      |> Enum.filter(&(&1.funding_arrangement == "ASO"))
      |> Enum.map(&(&1.coverage_id))
    if Enum.empty?(aso_product_coverages -- account_coverage_funds) do
      peme = Enum.map(account.account_products, fn(x) ->
        x.product.product_category
      end)

      # if Enum.member?(peme, "PEME Product") and product.product_category == "PEME Product" do
      #   "uneligible-peme"
      # else
        ""
      # end
    else
      "uneligible-product"
    end
  end

  def get_fulfillment_display(line) do
    case line do
      "MediLink Number" ->
        "1168 0110 1234 5678"
      "Name of Member" ->
        "Juan Dela Cruz"
      "Account Name" ->
        "ABC Company"
      "Branch Name" ->
        "ABC Company - Cubao"
      "Exclusive Hotline" ->
        "123-4567"
      _ ->
        ""
    end
  end

  def if_is_nil_facility_access(product) do
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

  def if_is_nil_pcrnb(product) do
    product.product_coverages
    |> Enum.filter(&(
     &1.product_coverage_room_and_board != nil
    ))
    |> Enum.map(&(
      if is_nil(&1.product_coverage_room_and_board.room_and_board) do
        "error"
      end
    ))
    |> Enum.member?("error")
  end

  def product_coverages_is_nil(product) do
    product.product_coverages
    |> Enum.count()
    |> do_not_show()
  end

  def do_not_show(count) do
    if count == 0 do
      true
    else
      false
    end
  end

  def financial_tab(nil) do
    %{
      funding_arrangement: "N/A",
      account_tin: "N/A",
      vat_status: "N/A",
      previous_carrier: "N/A",
      attached_point: "N/A",
      mode_of_payment: "N/A",
      payee_name: "N/A"
     }
  end

  def financial_tab(payment_account) do
    %{
      funding_arrangement: payment_account.funding_arrangement,
      account_tin: payment_account.account_tin,
      vat_status: payment_account.vat_status,
      previous_carrier: payment_account.previous_carrier,
      attached_point: payment_account.attached_point,
      mode_of_payment: payment_account.mode_of_payment,
      payee_name: payment_account.payee_name
     }
  end

  def payment_account(nil), do: true
  def payment_account(payment_account) do
    if is_nil(payment_account.payee_name) do
      true
    else
      false
    end
  end

  def sanitize_log_message(value) do
    UtilityContext.sanitize_value(value)
  end
end

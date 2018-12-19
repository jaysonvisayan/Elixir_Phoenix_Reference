defmodule Innerpeace.PayorLink.Web.Main.AcuScheduleView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.AcuScheduleContext
  alias Innerpeace.Db.Base.PackageContext

  def map_accounts(accounts) do
    for a <- accounts do
      {"#{a.account_group.code} | #{a.account_group.name}", a.account_group.code} end
  end

  def map_clusters(clusters) do
    for c <- clusters do
      {"#{c.code} | #{c.name}", c.id}
    end
  end

  def map_facilities(facilities) do
    for f <- facilities do
      {"#{f.code} | #{f.name}", f.id}
    end
  end

  def map_products(asp) do
    Poison.encode!(Enum.into(asp, [], &(&1.product.code)))
  end

  def get_account(ag) do
    ag = Repo.preload(ag, :account)
    account = Enum.find(ag.account, &(&1.status == "Active"))
    account.end_date
  end

  def is_check(member_type) do
    cond do
      member_type == "Principal" ->
        ["checked", ""]
      member_type == "Dependent" ->
        ["", "checked"]
      true ->
        ["checked", "checked"]
    end
  end

  def remove_seconds(time) do
    new_time =
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

  def date_diff(date_from, date_to) do
    date_from =
      date_from
      |> Ecto.Date.to_erl()
      |> Date.from_erl()
      |> elem(1)

    date_to =
      date_to
      |> Ecto.Date.to_erl()
      |> Date.from_erl()
      |> elem(1)

    date_diffs = Date.diff(date_to, date_from)

    if date_diffs != 0 do
       "false"
    else
      "true"
    end
  end

  def is_equal?(guaranteed_heads, members) do
    guaranteed_heads == members
  end

  def render("load_all_acu_schedule_members.json", %{acu_schedule_members: acu_schedule_members}) do
    %{acu_schedule_member: render_many(acu_schedule_members, Innerpeace.PayorLink.Web.AcuScheduleView, "acu_schedule_member.json", as: :acu_schedule_member)}
  end

  def render("acu_schedule_member.json", %{acu_schedule_member: asm}) do
    %{
      id: asm.id,
      card_no: asm.card_no,
      full_name: Enum.join([asm.first_name, asm.middle_name, asm.last_name], " "),
      gender: asm.gender,
      birthdate: asm.birthdate,
      age: member_age(asm.birthdate),
      package: asm.package
    }
  end

  def render("acu_schedule.json", %{acu_schedule: acu_schedule}) do
    %{
      id: acu_schedule.id,
      batch_no: acu_schedule.batch_no,
      account_code: acu_schedule.account_group.code,
      account_name: acu_schedule.account_group.name,
      products: render_many(acu_schedule.acu_schedule_products, Innerpeace.PayorLink.Web.AcuScheduleView,
                            "products.json", as: :product),
      facility: render_one(acu_schedule.facility, Innerpeace.PayorLink.Web.AcuScheduleView, "facility.json", as: :facility),
      no_of_members: acu_schedule.no_of_members,
      no_of_guaranteed: acu_schedule.no_of_guaranteed,
      member_type: acu_schedule.member_type,
      date_from: acu_schedule.date_from,
      date_to: acu_schedule.date_to,
      facility_id: acu_schedule.facility_id
    }
  end

  def render("products.json", %{product: product}) do
    %{
      id: product.product.id,
      code: product.product.code,
      name: product.product.name
    }
  end

  def render("facility.json", %{facility: facility}) do
    %{
      id: facility.id,
      code: facility.code,
      name: facility.name
    }
  end

  def render("account.json", %{account: account}) do
    %{
      start_date: account.start_date,
      end_date: account.end_date
    }
  end

  def render("account_group_clusters.json", %{account_group_clusters: account_group_clusters}) do
    Enum.map(account_group_clusters, fn(agc) ->
      %{
        account_group_code: agc.account_group.code,
        account_group_name: agc.account_group.name,
        account_group_code: agc.account_group.id,
      }
    end)
  end

  def member_age(birthdate) do
    AcuScheduleContext.get_age(birthdate)
  end

  def package(member_id) do
    AcuScheduleContext.get_acu_schedule_member_packages(member_id)
  end

  def get_package_facility(package_id, facility_id) do
    package = PackageContext.get_package_facility_by_package_and_facility(package_id, facility_id)
    if not is_nil(package) do
      package
    end
  end

  def count_selected_members(total, 0), do: total
  def count_selected_members(total, removed) do
    total - removed
  end

  def count_selected_members(members) do
    Enum.count(members, &(is_nil(&1.status)))
  end

  def filter_multiple_package(asms) do
    packages = for asm <- asms do
      if Enum.count(String.split(asm.package, ", ")) > 1 do
        true
      else
        false
      end
    end
    if Enum.member?(packages, true) do
      true
    else
      false
    end
  end

  def check_cluster(nil), do: "N/A"
  def check_cluster(cluster), do: "#{cluster.code} #{cluster.name}"

  def check_account(nil), do: "N/A"
  def check_account(account_group), do: "#{account_group.code}  #{account_group.name}"

  def check_schedule_time(acu_schedule) do
    [tf1, tf2, tf3] = String.split("#{acu_schedule.time_from}", ":")
    [tt1, tt2, tt3] = String.split("#{acu_schedule.time_to}", ":")
    "#{tf1}:#{tf2} - #{tt1}:#{tt2}"
  end

  def check_schedule_date(acu_schedule) do
    "#{format_standard_date(acu_schedule.date_from)} - #{format_standard_date(acu_schedule.date_to)}"
  end

  def check_product(acu_schedule) do
    cond do
      is_nil(acu_schedule.acu_schedule_products) ->
        "N/A"
      Enum.count(acu_schedule.acu_schedule_products) == 1 ->
        get_product(acu_schedule)
      true ->
        acu_schedule
        |> get_product()
        |> Enum.join(", ")
    end
  end

  defp get_product(acu_schedule) do
    Enum.map(acu_schedule.acu_schedule_products, fn(acu_schedule_product) ->
      "#{acu_schedule_product.product.code}  #{acu_schedule_product.product.name}"
    end)
  end

  def format_standard_date(date) do
    date = to_string(date)
    date =
      date
      |> String.split("-")

    year = Enum.at(date, 0)
    month = Enum.at(date, 1)
    day = Enum.at(date, 2)
    month = get_month(month)


    "#{day} #{month} #{year}"
  end

  defp get_month(month) when month == "01", do: "Jan"
  defp get_month(month) when month == "02", do: "Feb"
  defp get_month(month) when month == "03", do: "Mar"
  defp get_month(month) when month == "04", do: "Apr"
  defp get_month(month) when month == "05", do: "May"
  defp get_month(month) when month == "06", do: "Jun"
  defp get_month(month) when month == "07", do: "Jul"
  defp get_month(month) when month == "08", do: "Aug"
  defp get_month(month) when month == "09", do: "Sep"
  defp get_month(month) when month == "10", do: "Oct"
  defp get_month(month) when month == "11", do: "Nov"
  defp get_month(month) when month == "12", do: "Dec"

  def if_draft_edit(nil), do: "clickable-row"
  def if_draft_edit("Draft"), do: "clickable-row"
  def if_draft_edit(_), do: "disabled"

  def if_draft_delete(nil), do: ""
  def if_draft_delete("Draft"), do: ""
  def if_draft_delete(_), do: "disabled"

  def if_draft_export(nil), do: ""
  def if_draft_export("Draft"), do: ""
  def if_draft_export(_), do: true

  def is_draft?(nil), do: false
  def is_draft?("Draft"), do: false
  def is_draft?(_), do: true

  def if_draft_finalize([], _), do: "disabled"
  def if_draft_finalize(_, status) when status == "Completed", do: "disabled"
  def if_draft_finalize(_, _), do: ""

end

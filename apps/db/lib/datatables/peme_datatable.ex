defmodule Innerpeace.Db.Datatables.PemeDatatable do
  @moduledoc """
    Index Table
      Rows:
        Checkbox,
        Evoucher Number,
        Package,
        Issuance Date,
        Registration Date,
        Availment Date,
        Facility,
        Status,
        Cancel Button

  """

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Peme,
    Schemas.Package,
    Schemas.Facility,
    Schemas.AccountGroup
  }

  defp initialize_query do
    # Sets initial query of the table.

    Peme
    |> join(:inner, [p], pc in Package, p.package_id == pc.id)
    |> join(:left, [p, pc], f in Facility, p.facility_id == f.id)
    |> join(:inner, [p, pc, f], ag in AccountGroup, p.account_group_id == ag.id)
  end

  def peme_count(ag) do
    # Returns total count of data without filter and search value.

    initialize_query
    |> where([p, pc, f, ag], ag.id == ^ag.id)
    |> select([p, pc, f, ag], count(p.id))
    |> Repo.one()
  end

  def peme_data(%{
    offset: offset,
    limit: limit,
    search_value: search_value,
    ag: ag,
    locale: locale,
    order: order
  }) do
    # Returns table data according to table's offset and limit.

    initialize_query
    |> where([p, pc, f, ag], ag.id == ^ag.id)
    |> where([p, pc, f, ag],
             ilike(p.evoucher_number, ^"%#{search_value}%") or
             ilike(pc.name, ^"%#{search_value}%") or
             # ilike(fragment("regexp_replace(?, '\s+', ' ', 'g')", pc.name), ^"%#{search_value}%") or
             ilike(pc.name, ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.request_date), ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.registration_date), ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.availment_date), ^"%#{search_value}%") or
             ilike(f.name, ^"%#{search_value}%") or
             ilike(p.status, ^"%#{search_value}%")
    )
    |> select([p, pc, f, ag], p)
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> preload([:package, :facility])
    |> Repo.all()
    |> insert_table_cols([], locale)
  end

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: p.evoucher_number)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: pc.name)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: p.request_date)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: p.registration_date)
  defp order_datatable(query, column, order) when column == "5" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: p.availment_date)
  defp order_datatable(query, column, order) when column == "6" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: f.name)
  defp order_datatable(query, column, order) when column == "7" and order == "asc", do: query |> order_by([p, pc, f, ag], asc: p.status)
  defp order_datatable(query, column, order) when column == "8" and order == "asc", do: query

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: p.evoucher_number)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: pc.name)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: p.request_date)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: p.registration_date)
  defp order_datatable(query, column, order) when column == "5" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: p.availment_date)
  defp order_datatable(query, column, order) when column == "6" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: f.name)
  defp order_datatable(query, column, order) when column == "7" and order == "desc", do: query |> order_by([p, pc, f, ag], desc: p.status)
  defp order_datatable(query, column, order) when column == "8" and order == "desc", do: query

  def peme_filtered_count(
    search_value,
    ag
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    initialize_query
    |> where([p, pc, f, ag], ag.id == ^ag.id)
    |> where([p, pc, f, ag],
             ilike(p.evoucher_number, ^"%#{search_value}%") or
             ilike(pc.name, ^"%#{search_value}%") or
             ilike(pc.name, ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.request_date), ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.registration_date), ^"%#{search_value}%") or
             ilike(fragment("to_char(?, 'Mon dd, yyyy')", p.availment_date), ^"%#{search_value}%") or
             ilike(f.name, ^"%#{search_value}%") or
             ilike(p.status, ^"%#{search_value}%")
    )
    |> select([p, pc, f, ag], count(p.id))
    |> Repo.one()
  end

  defp convert_month([year, month, day]) do
    month =
      month
      |> String.to_integer()
      |> get_month()

    "#{month} #{day}, #{year}"
  end

  defp get_month(month) when month == 1, do: "Jan"
  defp get_month(month) when month == 2, do: "Feb"
  defp get_month(month) when month == 3, do: "Mar"
  defp get_month(month) when month == 4, do: "Apr"
  defp get_month(month) when month == 5, do: "May"
  defp get_month(month) when month == 6, do: "Jun"
  defp get_month(month) when month == 7, do: "Jul"
  defp get_month(month) when month == 8, do: "Aug"
  defp get_month(month) when month == 9, do: "Sep"
  defp get_month(month) when month == 10, do: "Oct"
  defp get_month(month) when month == 11, do: "Nov"
  defp get_month(month) when month == 12, do: "Dec"

  defp convert_date(date) do
    date
    |> Ecto.DateTime.to_date()
    |> Ecto.Date.to_string()
    |> String.split("-")
    |> convert_month()
  end

  defp insert_table_cols([head | tails], tbl, locale) do
    checkbox = generate_peme_checkbox(head)
    link = generate_peme_link(head, locale)
    status = peme_status(head.status)
    registration_date = if is_nil(head.registration_date), do: "N/A", else: convert_date(head.registration_date)
    availment_date = if is_nil(head.availment_date), do: "N/A", else: convert_date(head.availment_date)
    facility_name = if is_nil(head.facility), do: "N/A", else: head.facility.name
    package = package_name(head.package.name)
    issuance_date =
      head.request_date
      |> convert_date()

    tbl =
      tbl ++
        [
          [
            checkbox,
            link,
            package,
            issuance_date,
            registration_date,
            availment_date,
            facility_name,
            status,
            generate_cancel_button(head)
          ]
        ]

    insert_table_cols(tails, tbl, locale)
  end
  defp insert_table_cols([], tbl, locale), do: tbl

  defp package_name(package_name),
    do:
     "<p style='white-space:pre;'> #{package_name}</p>"

  defp generate_peme_checkbox(peme),
    do:
    "<input style='width:20px; height:20px' type='checkbox' class='selection' name='peme[id][]' value='#{peme.id}' />
    <input hidden style='opacity: 0;' id='member_qrcode' value='#{peme.evoucher_qrcode}'/>
    <div hidden style='opacity: 0;' id='print_qrcode_evoucher'>
    </div>"

  defp generate_peme_link(peme, locale),
    do:
      "<a href='/#{locale}/peme/#{peme.id}/show'>#{peme.evoucher_number}</a>"

  defp status_change(id, status) when status == nil,
    do:
      "<p> Pending for Activation </p>"

  defp peme_status(status) do
    case status do
      "Issued" ->
        "<div class='status-tag status-tag--orange'>
        <span>Issued</span>
        </div>"
      "Pending" ->
        "<div class='status-tag status-tag--orange'>
        <span>Pending</span>
        </div>"
      "Registered" ->
        "<div class='status-tag status-tag--green'>
        <span>Registered</span>
        </div>"
      "Cancelled" ->
        "<div class='status-tag status-tag--red'>
        <span>Cancelled</span>
        </div>"
      "Availed" ->
        "<div class='status-tag status-tag--green'>
        <span>Availed</span>
        </div>"
      "Stale" ->
        "<div class='status-tag status-tag--yellow'>
        <span>Stale</span>
        </div>"
    end
  end

  defp generate_cancel_button(peme) do
    if peme.status == "Registered" || peme.status == "Cancelled" do
      "<button class='ui grey right floated small button cancel_evoucher disabled'><i class='remove icon'></i>Cancel E-voucher</button>"
    else
      "<button class='ui grey right floated small button cancel_evoucher' evoucher='#{peme.evoucher_number}' date_from='#{peme.date_from}' date_to='#{peme.date_to}' member_id='#{peme.member_id}' peme_id='#{peme.id}' peme_status='#{peme.status}'><i class='remove icon'></i>Cancel E-voucher</button>"
    end
  end
end

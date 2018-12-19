defmodule Innerpeace.Db.Datatables.ProductDatatable do
  @moduledoc """
    Index Table
      Rows:
        Code,
        Name,
        Description,
        Classification,
        Created by,
        Date Created,
        Updated by,
        Date Updated
  """

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Decimal
  alias Innerpeace.Db.{
    Repo,
    Schemas.Product,
    Schemas.User
  }

  def product_count do
    # Returns total count of data without filter and search value.

    initialize_query
    |> select([p, u, uu], count(p.id))
    |> Repo.one()
  end

  def product_data(
    offset,
    limit,
    search_value,
    order
  ) do
    # Returns table data according to table's offset and limit.

    initialize_query
    |> where(
      [p, u, uu],
      ilike(p.code, ^"%#{search_value}%") or ilike(p.name, ^"%#{search_value}%") or
      ilike(p.description, ^"%#{search_value}%") or ilike(u.username, ^"%#{search_value}%") or
      ilike(uu.username, ^"%#{search_value}%")
    )
    |> select([p, u, uu], %{
      code: p.code,
      name: p.name,
      description: p.description,
      standard_product: p.standard_product,
      classification: p.inserted_at,
      created_by: u.username,
      inserted_at: p.inserted_at,
      updated_by: uu.username,
      updated_at: p.updated_at,
      step: p.step,
      id: p.id
    })
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_cols([])
  end

  def product_filtered_count(
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    initialize_query
    |> where(
      [p, u, uu],
      ilike(p.code, ^"%#{search_value}%") or ilike(p.name, ^"%#{search_value}%") or
      ilike(p.description, ^"%#{search_value}%") or ilike(u.username, ^"%#{search_value}%") or
      ilike(uu.username, ^"%#{search_value}%")
    )
    |> select([p, u, uu], count(p.id))
    |> Repo.one()
  end

  defp initialize_query do
    # Sets initial query of the table.

    Product
    |> join(:left, [p], u in User, u.id == p.created_by_id)
    |> join(:left, [p, u], uu in User, uu.id == p.updated_by_id)
  end

  defp insert_table_cols([head | tails], tbl) do
    step = Decimal.to_float(Decimal.new(head.step))
    link = generate_product_link(head.id, step, head.code, Decimal.to_float(Decimal.new(5)))
    classification = if head.standard_product == "Yes", do: "Standard", else: "Custom"

    tbl =
      tbl ++
        [
          [
            link,
            head.name,
            head.description,
            classification,
            head.created_by,
            load_date(head.inserted_at),
            head.updated_by,
            load_date(head.updated_at)
          ]
        ]

    insert_table_cols(tails, tbl)
  end
  defp insert_table_cols([], tbl), do: tbl

  defp generate_product_link(id, step, code, test) when step < test,
    do:
      "<a href='/web/products/#{id}/setup?step=#{Decimal.to_string(Decimal.round(Decimal.new(step)))}'>#{code} (Draft)</a>"

  defp generate_product_link(id, step, code, test), do: "<a href='/web/products/#{id}/show'>#{code}</a> "

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

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([p, u, uu], asc: p.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, u, uu], asc: p.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, u, uu], asc: u.username)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([p, u, uu], asc: p.standard_product)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([p, u, uu], asc: p.created_by_id)
  defp order_datatable(query, column, order) when column == "5" and order == "asc", do: query |> order_by([p, u, uu], asc: p.inserted_at)
  defp order_datatable(query, column, order) when column == "6" and order == "asc", do: query |> order_by([p, u, uu], asc: p.updated_by_id)
  defp order_datatable(query, column, order) when column == "7" and order == "asc", do: query |> order_by([p, u, uu], asc: p.updated_at)
  defp order_datatable(query, _, order) when order == "asc", do: query |> order_by([p, u, uu], asc: p.code)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([p, u, uu], desc: p.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, u, uu], desc: p.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, u, uu], desc: u.username)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([p, u, uu], desc: p.standard_product)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([p, u, uu], desc: p.created_by_id)
  defp order_datatable(query, column, order) when column == "5" and order == "desc", do: query |> order_by([p, u, uu], desc: p.inserted_at)
  defp order_datatable(query, column, order) when column == "6" and order == "desc", do: query |> order_by([p, u, uu], desc: p.updated_by_id)
  defp order_datatable(query, column, order) when column == "7" and order == "desc", do: query |> order_by([p, u, uu], desc: p.updated_at)
  defp order_datatable(query, _, order) when order == "desc", do: query |> order_by([p, u, uu], desc: p.code)

  defp order_datatable(query, _, _), do: query |> order_by([p, u, uu], asc: p.code)

end

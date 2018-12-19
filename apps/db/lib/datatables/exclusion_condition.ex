defmodule Innerpeace.Db.Datatables.ExclusionCondition do
  @moduledoc """
  Rows:
  Period,
  Type,
  Duration,
  Inner_limit,
  Inner_limit_amount
  """

  import Ecto.Query
  alias Plug.CSRFProtection

  alias Innerpeace.Db.{
    Repo,
    Schemas.Exclusion,
    Schemas.ExclusionCondition
  }

  def count(id) do
    initialize_query(id)
    |> select([ec, e], count(ec.id, :distinct))
    |> Repo.one()
  end

  def get_filtered_count(search_value, id) do
    initialize_query(id)
    |> where([ec, e],
             ilike(ec.diagnosis_type, ^"%#{search_value}%") or
             ilike(ec.inner_limit, ^"%#{search_value}%")
    )
    |> select([ec, e], count(ec.id, :distinct))
    |> Repo.one()
  end

  def insert_exclusion_condition(offset, limit, search_value, order, id, member_type) do
    initialize_query(id)
    |> where([ec, e],
             ilike(ec.diagnosis_type, ^"%#{search_value}%") or
             ilike(ec.inner_limit, ^"%#{search_value}%") and
             ec.member_type == ^member_type
    )
    |> select([ec, e], %{
      # within_grace_period: ec.within_grace_period,
      member_type: ec.member_type,
      type: ec.diagnosis_type,
      duration: ec.duration,
      inner_limit: ec.inner_limit,
      inner_limit_amount: ec.inner_limit_amount
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

  def insert_exclusion_condition(offset, limit, search_value, order, id) do
    initialize_query(id)
    |> where([ec, e],
             ilike(ec.diagnosis_type, ^"%#{search_value}%") or
             ilike(ec.inner_limit, ^"%#{search_value}%")
    )
    |> select([ec, e], %{
      # within_grace_period: ec.within_grace_period,
      member_type: ec.member_type,
      type: ec.diagnosis_type,
      duration: ec.duration,
      inner_limit: ec.inner_limit,
      inner_limit_amount: ec.inner_limit_amount
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

  defp insert_table_cols([head | tails], tbl) do
    duration = duration_month(head.duration)
    tbl =
      tbl ++
        [
          [
            head.member_type,
            head.type,
            duration,
            head.inner_limit,
            head.inner_limit_amount
          ]
        ]
    insert_table_cols(tails, tbl)
  end

  defp duration_month(month), do: "#{month} month/s"
  defp duration_month(nil), do: "N/A"

  defp insert_table_cols([], tbl), do: tbl

  defp order_datatable(query, nil, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([ec, e], asc: ec.member_type)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([ec, e], asc: ec.diagnosis_type)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([ec, e], asc: ec.duration)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([ec, e], asc: ec.inner_limit)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([ec, e], asc: ec.inner_limit_amount)


  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([ec, e], desc: ec.member_type)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([ec, e], desc: ec.diagnosis_type)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([ec, e], desc: ec.duration)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([ec, e], desc: ec.inner_limit)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([ec, e], desc: ec.inner_limit_amount)

  def initialize_query(exclusion_id) do
    # Sets initial query of the table.

    ExclusionCondition
    |> join(:left, [ec], e in Exclusion, ec.exclusion_id == e.id)
    |> where([ec, e], ec.exclusion_id == ^exclusion_id)

  end

end




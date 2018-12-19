defmodule Innerpeace.Db.Datatables.ProcedureDatatable do
  @moduledoc """
    Rows:
      CPT Code,
      CPT Description,
      Payor CPT Code,
      Payor Description
  """

  import Ecto.Query
  alias Innerpeace.Db.{
    Repo,
    Schemas.PayorProcedure,
    Schemas.Procedure
  }

  def procedure_count(ids) do
    # Returns total count of data without filter and search value.

    ids
    |> initialize_query
    |> select([p], count(p.id))
    |> Repo.one()
  end

  def procedure_data(
    ids,
    offset,
    limit,
    search_value,
    order
  ) do
    # Returns table data according to table's offset and limit.

    ids
    |> initialize_query
    |> where([p, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%") or
      ilike(p.code, ^"%#{search_value}%") or
      ilike(p.description, ^"%#{search_value}%")
    )
    |> select([p, pp],
      %{
        id: p.id,
        sp_code: pp.code,
        sp_name: pp.description,
        pp_code: p.code,
        pp_name: p.description,
      }
    )
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_buttons([])
  end

  def procedure_filtered_count(
    ids,
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> initialize_query
    |> where([p, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%") or
      ilike(p.code, ^"%#{search_value}%") or
      ilike(p.description, ^"%#{search_value}%")
    )
    |> select([d], count(d.id))
    |> Repo.one()
  end

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, pp], asc: pp.code)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, pp], asc: pp.description)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([p, pp], asc: p.code)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([p, pp], asc: p.description)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, pp], desc: pp.code)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, pp], desc: pp.description)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([p, pp], desc: p.code)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([p, pp], desc: p.description)

  defp initialize_query(ids) do
    # Sets initial query of the table.

    PayorProcedure
    |> join(:inner, [pp], p in Procedure, pp.procedure_id == p.id)
    |> filter_ids(ids)
  end

  defp filter_ids(procedure, ids) when ids == [""], do: procedure
  defp filter_ids(procedure, ids) when ids != [""] do
    procedure
    |> where([p, pp], p.id not in ^ids)
  end

  defp insert_table_buttons([head | tails], tbl) do
    tbl =
      tbl ++ [[
        "<input type='checkbox' style='width:20px; height:20px' class='procedure_chkbx' pp_id='#{head.id}' sp_code='#{head.sp_code}' sp_name='#{head.sp_name}' pp_code='#{head.pp_code}' pp_name='#{head.pp_name}' />",
        "<span class='green'>#{head.sp_code}</span>",
        "#{head.sp_name}",
        "#{head.pp_code}",
        "#{head.pp_name}"
      ]]

    insert_table_buttons(tails, tbl)
  end
  defp insert_table_buttons([], tbl), do: tbl

end

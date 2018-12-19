defmodule Innerpeace.Db.Datatables.DiagnosisDatatable do
  @moduledoc """
    Rows:
      Code,
      Description,
      Type
  """

  import Ecto.Query
  alias Innerpeace.Db.{
    Repo,
    Schemas.Diagnosis
  }

  def diagnosis_count(ids, type) do
    # Returns total count of data without filter and search value.

    ids
    |> initialize_query(type)
    |> select([d], count(d.id))
    |> Repo.one()
  end

  def diagnosis_data(
    ids,
    params
    # type,
    # offset,
    # limit,
    # search_value
  ) do
    # Returns table data according to table's offset and limit.

    type = params["type"]
    offset = params["start"]
    limit = params["length"]
    search_value = params["search"]["value"]
    is_all_selected = params["is_all_selected"]
    order = params["order"]["0"]

    ids
    |> initialize_query(type)
    |> where([d],
      ilike(d.code, ^"%#{search_value}%") or
      ilike(d.group_description, ^"%#{search_value}%") or
      ilike(d.description, ^"%#{search_value}%") or
      ilike(d.type, ^"%#{search_value}%")
    )
    |> select([d],
      %{
        id: d.id,
        code: d.code,
        name: d.group_description,
        description: d.description,
        type: d.type
      }
    )
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_buttons([], is_all_selected)
  end

  def diagnosis_filtered_count(
    ids,
    type,
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> initialize_query(type)
    |> where([d],
      ilike(d.code, ^"%#{search_value}%") or
      ilike(d.group_description, ^"%#{search_value}%") or
      ilike(d.description, ^"%#{search_value}%") or
      ilike(d.type, ^"%#{search_value}%")
    )
    |> select([d], count(d.id))
    |> Repo.one()
  end

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([d], asc: d.code)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([d], asc: d.group_description)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([d], asc: d.type)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([d], desc: d.code)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([d], desc: d.group_description)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([d], desc: d.type)

  defp initialize_query(ids, type) do
    # Sets initial query of the table.

    Diagnosis
    |> filter_ids(ids)
  end

  defp filter_ids(diagnosis, ids) when ids == [""], do: diagnosis
  defp filter_ids(diagnosis, ids) when ids != [""] do
    diagnosis
    |> where([d], d.code not in ^ids)
  end

  defp insert_table_buttons([head | tails], tbl, is_all_selected) do
    input_status = if is_all_selected == "true", do: "checked", else: ""
    tbl =
      tbl ++ [[
        "<input type='checkbox' style='width:20px; height:20px' role='checkbox2' class='diagnosis_chkbx' id='#{head.id}' diagnosis_id='#{head.id}' code='#{head.code}' description='#{head.description}' diagnosis_type='#{head.type}' diagnosis_name='#{head.name}' #{input_status} /><label type='text' for='#{head.id}' style='font-family: 'SExtralight'; font-size:20px;'></label>",
        "<span class='green'>#{head.code}</span>",
        "<strong>#{head.name}</strong><br><small class='thin dim'>#{head.description}</small>",
        head.type
      ]]

    insert_table_buttons(tails, tbl, is_all_selected)
  end
  defp insert_table_buttons([], tbl, is_all_selected), do: tbl

  def diagnosis_all_data(
    ids,
    params
  ) do
    # Returns table data according to table's offset and limit.

    type = params["type"]
    offset = params["start"]
    limit = params["length"]
    search_value = params["search"]["value"]

    ids
    |> initialize_query(type)
    |> select([d],
      %{
        id: d.id,
        code: d.code,
        name: d.group_description,
        description: d.description,
        type: d.type
      }
    )
    |> Repo.all()
  end

  defp insert_table_buttons2([head | tails], tbl) do
    tbl =
      tbl ++ [[
        "<span class='green selected_diagnosis_id'>#{ head.code }</span>",
        "<strong>#{ head.name }</strong><br><small class='thin dim'>#{ head.description }</small>",
        head.type,
        "<a href='#!' class='remove_diagnosis'><i class='green trash icon'></i></a><input type='hidden' name='benefit[diagnosis_ids][]' value='#{ head.id }'>"
      ]]

    insert_table_buttons2(tails, tbl)
  end
  defp insert_table_buttons2([], tbl), do: tbl
end

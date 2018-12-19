defmodule Innerpeace.Db.Datatables.LocationGroupDatatable do
  @moduledoc false


  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.LocationGroup,
    Schemas.Facility,
    Schemas.FacilityLocationGroup
  }

  def get_location_group_filtered_count(search_value) do
    LocationGroup
    |> where([lg],
      ilike(lg.code, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%") or
      ilike(lg.description, ^"%#{search_value}%")
    )
    |> select([lg], count(lg.id, :distinct))
    |> Repo.one()
  end

  def get_location_group_count() do
    LocationGroup
    |> select([lg], count(lg.id, :distinct))
    |> Repo.one()
  end

  def get_location_group(
    offset,
    limit,
    search_value,
    order
  ) do

    LocationGroup
    |> where([lg],
      ilike(lg.code, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%") or
      ilike(lg.description, ^"%#{search_value}%")
    )
    |> select([lg],
      %{
        id: lg.id,
        code: lg.code,
        name: lg.name,
        description: lg.description,
        status: lg.status
      }
    )
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols([])
  end

  defp insert_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            generate_location_group_link(head.id, head.code, head.status),
            head.name,
            head.description
          ]
        ]
    insert_table_cols(tails, tbl)
  end
  defp insert_table_cols([], tbl), do: tbl

  defp generate_location_group_link(id, code, status) do
    if status == "Draft" do
      "<a href='/web/facility_groups/#{id}/edit_draft'>#{code}(Draft)</a>"
    else
      "<a href='/web/facility_groups/#{id}/show'>#{code}</a>"
    end
  end

  # Ascending
  defp order_datatable(query, nil, _), do: query |> order_by([lg], asc: lg.code)
  defp order_datatable(query, _, nil), do: query |> order_by([lg], asc: lg.code)
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([lg], asc: lg.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([lg], asc: lg.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([lg], asc: lg.description)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([lg], desc: lg.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([lg], desc: lg.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([lg], desc: lg.description)

  def get_location_group_view_facility_filtered_count(search_value, id) do
    Facility
    |> join(:inner, [f], flp in FacilityLocationGroup, flp.facility_id == f.id)
    |> where([f, flp],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%")
    )
    |> where([f, flp], flp.location_group_id == ^id)
    |> where([f, flp], f.status == "Affiliated")
    |> select([f, flp], count(f.id, :distinct))
    |> Repo.one()
  end

  def get_location_group_view_facility_count(id) do
    Facility
    |> join(:inner, [f], flp in FacilityLocationGroup, flp.facility_id == f.id)
    |> where([f, flp], flp.location_group_id == ^id)
    |> where([f, flp], f.status == "Affiliated")
    |> select([f, flp], count(f.id, :distinct))
    |> Repo.one()
  end

  def get_location_group_view_facility(
    offset,
    limit,
    search_value,
    order,
    id
    ) do
    Facility
    |> join(:inner, [f], flp in FacilityLocationGroup, flp.facility_id == f.id)
    |> where([f, flp],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%")
    )
    |> where([f, flp], flp.location_group_id == ^id)
    |> where([f, flp], f.status == "Affiliated")
    |> select([f, flp],
      %{
        id: f.id,
        code: f.code,
        name: f.name,
        region: f.region
      }
    )
    |> view_facility_order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> view_facility_insert_table_cols([])
  end

  defp view_facility_insert_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            head.code,
            head.name,
            head.region
          ]
        ]
    view_facility_insert_table_cols(tails, tbl)
  end
  defp view_facility_insert_table_cols([], tbl), do: tbl

  # Ascending
  defp view_facility_order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([lg], asc: lg.code)
  defp view_facility_order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([lg], asc: lg.name)
  defp view_facility_order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([lg], asc: lg.description)

  # Descending
  defp view_facility_order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([lg], desc: lg.code)
  defp view_facility_order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([lg], desc: lg.name)
  defp view_facility_order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([lg], desc: lg.description)


  ############################ start: add facility modal function ##############################
  def get_location_group_add_facility_filtered_count(facility_ids, search_value) do
    Facility
    |> where([f],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%")
    )
    |> where([f], f.id not in ^facility_ids)
    |> where([f], f.status == "Affiliated")
    |> select([f], count(f.id, :distinct))
    |> Repo.one()
  end

  def get_location_group_add_facility_count(facility_ids) do
    Facility
    |> where([f], f.id not in ^facility_ids)
    |> where([f], f.status == "Affiliated")
    |> select([f], count(f.id, :distinct))
    |> Repo.one()
  end

  def get_location_group_add_facility(
    facility_ids,
    offset,
    limit,
    search_value,
    order
  ) do
    Facility
    |> where([f],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%")
    )
    |> where([f], f.id not in ^facility_ids)
    |> where([f], f.status == "Affiliated")
    |> select([f],
      %{
        id: f.id,
        code: f.code,
        name: f.name,
        region: f.region
      }
    )
    |> add_facility_order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> add_facility_insert_table_cols([])
  end

  defp add_facility_insert_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            head.id,
            head.code,
            head.name,
            head.region
          ]
        ]
    add_facility_insert_table_cols(tails, tbl)
  end
  defp add_facility_insert_table_cols([], tbl), do: tbl

  # Ascending
  defp add_facility_order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([lg], asc: lg.code)
  defp add_facility_order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([lg], asc: lg.name)
  defp add_facility_order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([lg], asc: lg.region)

  # Descending
  defp add_facility_order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([lg], desc: lg.code)
  defp add_facility_order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([lg], desc: lg.name)
  defp add_facility_order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([lg], desc: lg.region)

end

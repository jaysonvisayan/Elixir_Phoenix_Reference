defmodule Innerpeace.Db.Datatables.ExclusionFacilityDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Facility,
    FacilityLocationGroup,
    LocationGroup,
    Dropdown
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  def get_exclusion_facility(offset, limit, params, location_group_id) do
    FacilityLocationGroup
    |> join(:left, [flg], f in Facility, f.id == flg.facility_id)
    |> join(:left, [flg, f], lg in LocationGroup, lg.id == flg.location_group_id)
    |> where([flg, f, lg], lg.id == ^location_group_id)
    |> where([flg, f, lg],
      ilike(f.code, ^"%#{params}%") or
      ilike(f.name, ^"%#{params}%") or
      ilike(f.line_1, ^"%#{params}%") or
      ilike(f.line_2, ^"%#{params}%") or
      ilike(f.city, ^"%#{params}%") or
      ilike(f.province, ^"%#{params}%") or
      ilike(f.region, ^"%#{params}%") or
      ilike(f.country, ^"%#{params}%") or
      ilike(f.postal_code, ^"%#{params}%") or
      ilike(f.longitude, ^"%#{params}%") or
      ilike(f.latitude, ^"%#{params}%") or
      ilike(lg.name, ^"%#{params}%"))
    |> order_by([flg, f, lg], f.code)
    |> select([flg, f, lg], %{
        id: flg.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        postal_code: f.postal_code,
        longitude: f.longitude,
        latitude: f.latitude,
        l_name: lg.name
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_ef_cols([])
  end

  def get_ef_count(params, location_group_id) do
    FacilityLocationGroup
    |> join(:left, [flg], f in Facility, f.id == flg.facility_id)
    |> join(:left, [flg, f], lg in LocationGroup, lg.id == flg.location_group_id)
    |> where([flg, f, lg],
      ilike(f.code, ^"%#{params}%") or
      ilike(f.name, ^"%#{params}%") or
      ilike(f.line_1, ^"%#{params}%") or
      ilike(f.line_2, ^"%#{params}%") or
      ilike(f.city, ^"%#{params}%") or
      ilike(f.province, ^"%#{params}%") or
      ilike(f.region, ^"%#{params}%") or
      ilike(f.country, ^"%#{params}%") or
      ilike(f.postal_code, ^"%#{params}%") or
      ilike(f.longitude, ^"%#{params}%") or
      ilike(f.latitude, ^"%#{params}%") or
      ilike(lg.name, ^"%#{params}%"))
    |> select([flg, f, lg], count(f.id))
    |> Repo.one()
  end

  defp convert_to_tbl_ef_cols([head | tails], tbl) do
    tbl =
      tbl ++ [[
        "todo",
        head.code,
        head.name,
        "#{head.line_1}, #{head.line_2}, #{head.city}, #{head.province}, #{head.region}, #{head.country}, #{head.postal_code}",
        head.l_name
      ]]

    convert_to_tbl_ef_cols(tails, tbl)
  end
  defp convert_to_tbl_ef_cols([], tbl), do: tbl

  # FACILITY DATATABLE EXEMPTION FACILITIES

  def facility_count(ids, nil), do: 0
  def facility_count(ids, ""), do: 0
  def facility_count(ids, location_group_id) do
    # Returns total count of data without filter and search value.

    ids
    |> initialize_query
    |> where([flg, f, lg, d], lg.id == ^location_group_id)
    |> where([flg, f, lg, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> select([flg, f, lg, d], count(f.id))
    |> Repo.one()
  end

  def get_all_exclusion_facility_data(ids, location_group_id) do
    ids
    |> initialize_query
    |> where([flg, f, lg, d], lg.id == ^location_group_id)
    |> where([flg, f, lg, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> select([flg, f, lg, d], f.id)
    |> Repo.all()
  end

  def get_all_inclusion_facility_data(ids) do
    ids
    |> inclusion_initialize_query
    |> where([f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> select([f, d], f.id)
    |> Repo.all()
  end

  def facility_data(
    ids,
    location_group_id,
    offset,
    limit,
    search_value,
    order
  ) do
    # Returns table data according to table's offset and limit.

    ids
    |> initialize_query
    |> where([flg, f, lg, d], lg.id == ^location_group_id)
    |> where([flg, f, lg, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([flg, f, lg, d],
        ilike(f.code, ^"%#{search_value}%") or
        ilike(f.name, ^"%#{search_value}%") or
        ilike(f.line_1, ^"%#{search_value}%") or
        ilike(f.line_2, ^"%#{search_value}%") or
        ilike(f.city, ^"%#{search_value}%") or
        ilike(f.province, ^"%#{search_value}%") or
        ilike(f.region, ^"%#{search_value}%") or
        ilike(f.country, ^"%#{search_value}%") or
        ilike(f.postal_code, ^"%#{search_value}%") or
        ilike(f.longitude, ^"%#{search_value}%") or
        ilike(f.latitude, ^"%#{search_value}%") or
        ilike(lg.name, ^"%#{search_value}%"))
    |> select([flg, f, lg, d], %{
        facility_id: f.id,
        id: flg.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        postal_code: f.postal_code,
        longitude: f.longitude,
        latitude: f.latitude,
        l_name: lg.name})
    |> inclusion_order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_buttons([])
  end

  defp inclusion_order_datatable(query, nil, _), do: query
  defp inclusion_order_datatable(query, _, nil), do: query

  # Ascending
  defp inclusion_order_datatable(query, column, order) when column == "0" and order == "asc", do: query
  defp inclusion_order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([flg, f, lg, d], asc: f.code)
  defp inclusion_order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([flg, f, lg, d], asc: f.name)
  defp inclusion_order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([flg, f, lg, d], asc: f.line_1)
  defp inclusion_order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([flg, f, lg, d], asc: lg.name)

  # Descending
  defp inclusion_order_datatable(query, column, order) when column == "0" and order == "desc", do: query
  defp inclusion_order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([flg, f, lg, d], desc: f.code)
  defp inclusion_order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([flg, f, lg, d], desc: f.name)
  defp inclusion_order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([flg, f, lg, d], desc: f.line_1)
  defp inclusion_order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([flg, f, lg, d], desc: lg.name)

  def facility_filtered_count(
    ids,
    location_group_id,
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> initialize_query
    |> where([flg, f, lg, d], lg.id == ^location_group_id)
    |> where([flg, f, lg, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([flg, f, lg, d],
        ilike(f.code, ^"%#{search_value}%") or
        ilike(f.name, ^"%#{search_value}%") or
        ilike(f.line_1, ^"%#{search_value}%") or
        ilike(f.line_2, ^"%#{search_value}%") or
        ilike(f.city, ^"%#{search_value}%") or
        ilike(f.province, ^"%#{search_value}%") or
        ilike(f.region, ^"%#{search_value}%") or
        ilike(f.country, ^"%#{search_value}%") or
        ilike(f.postal_code, ^"%#{search_value}%") or
        ilike(f.longitude, ^"%#{search_value}%") or
        ilike(f.latitude, ^"%#{search_value}%") or
        ilike(lg.name, ^"%#{search_value}%"))
    |> select([flg, f, lg, d], count(f.id))
    |> Repo.one()
  end

  defp initialize_query(ids) do
    # Sets initial query of the table.

    FacilityLocationGroup
    |> join(:left, [flg], f in Facility, f.id == flg.facility_id)
    |> join(:left, [flg, f], lg in LocationGroup, lg.id == flg.location_group_id)
    |> join(:left, [flg, f, lg], d in Dropdown, d.id == f.ftype_id)
    |> distinct(true)
    |> filter_ids(ids)
  end

  defp filter_ids(facilities, ids) when ids == [""], do: facilities
  defp filter_ids(facilities, ids) when ids != [""] do
    facilities
    |> where([flg, f, lg, d], f.id not in ^ids)
  end

  defp insert_table_buttons([head | tails], tbl) do

    tbl =
    tbl ++ [[
      "<input id='#{head.facility_id}' value='#{head.id}' type='checkbox' class='facility_chkbx' role='checkbox' />
        <label type='text' for='#{head.facility_id}' style='font-family: 'SExtralight'; font-size:14px;'>
      </label>",
      head.code,
      head.name,
      "#{head.line_1}, #{head.line_2}, #{head.city}, #{head.province}, #{head.region}, #{head.country}, #{head.postal_code}",
      head.l_name
    ]]

    insert_table_buttons(tails, tbl)

  end
  defp insert_table_buttons([], tbl), do: tbl

  # FACILITY DATATABLE ALL DENTAL FACILITY

  def a_facility_count(ids) do
    # Returns total count of data without filter and search value.

    ids
    |> inclusion_initialize_query
    |> where([f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> select([f, d], count(f.id))
    |> Repo.one()
  end

  def a_get_all_facility_data(ids) do
    ids
    |> inclusion_initialize_query
    |> select([flg, f, lg, d], f.id)
    |> Repo.all()
  end

  defp inclusion_initialize_query(ids) do
    # Sets initial query of the table.

    Facility
    |> join(:left, [f], d in Dropdown, d.id == f.ftype_id)
    |> distinct(true)
    |> filter_ids_inclusion(ids)
  end

  defp filter_ids_inclusion(facilities, ids) when ids == [""], do: facilities
  defp filter_ids_inclusion(facilities, ids) when ids != [""] do
    facilities
    |> where([f, d], f.id not in ^ids)
  end

  def a_facility_data(
    ids,
    offset,
    limit,
    search_value,
    order
  ) do

    # Returns table data according to table's offset and limit.

    ids
    |> inclusion_initialize_query
    |> where([f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([f, d],
        ilike(f.code, ^"%#{search_value}%") or
        ilike(f.name, ^"%#{search_value}%") or
        ilike(f.line_1, ^"%#{search_value}%") or
        ilike(f.line_2, ^"%#{search_value}%") or
        ilike(f.city, ^"%#{search_value}%") or
        ilike(f.province, ^"%#{search_value}%") or
        ilike(f.region, ^"%#{search_value}%") or
        ilike(f.country, ^"%#{search_value}%") or
        ilike(f.postal_code, ^"%#{search_value}%") or
        ilike(f.longitude, ^"%#{search_value}%") or
        ilike(f.latitude, ^"%#{search_value}%"))
    |> select([f, d], %{
        facility_id: f.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        postal_code: f.postal_code,
        longitude: f.longitude,
        latitude: f.latitude
        })
    |> exclusion_order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> a_insert_table_buttons([])
  end

  defp exclusion_order_datatable(query, nil, _), do: query
  defp exclusion_order_datatable(query, _, nil), do: query

  # Ascending
  defp exclusion_order_datatable(query, column, order) when column == "0" and order == "asc", do: query
  defp exclusion_order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([f, d], asc: f.code)
  defp exclusion_order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([f, d], asc: f.name)
  defp exclusion_order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([f, d], asc: f.line_1)
  defp exclusion_order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([f, d], asc: f.name)

  # Descending
  defp exclusion_order_datatable(query, column, order) when column == "0" and order == "desc", do: query
  defp exclusion_order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([f, d], desc: f.code)
  defp exclusion_order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([f, d], desc: f.name)
  defp exclusion_order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([f, d], desc: f.line_1)
  defp exclusion_order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([f, d], desc: f.name)

  defp exclusion_order_datatable(query, _column, _order), do: query

  def a_facility_filtered_count(
    ids,
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> inclusion_initialize_query
    |> where([f, d], d.text == "DENTAL PROVIDER" or d.text == "DENTAL CLINIC")
    |> where([f, d],
        ilike(f.code, ^"%#{search_value}%") or
        ilike(f.name, ^"%#{search_value}%") or
        ilike(f.line_1, ^"%#{search_value}%") or
        ilike(f.line_2, ^"%#{search_value}%") or
        ilike(f.city, ^"%#{search_value}%") or
        ilike(f.province, ^"%#{search_value}%") or
        ilike(f.region, ^"%#{search_value}%") or
        ilike(f.country, ^"%#{search_value}%") or
        ilike(f.postal_code, ^"%#{search_value}%") or
        ilike(f.longitude, ^"%#{search_value}%") or
        ilike(f.latitude, ^"%#{search_value}%"))
    |> select([f, d], count(f.id))
    |> Repo.one()
  end

  defp a_insert_table_buttons([head | tails], tbl) do

    tbl =
    tbl ++ [[
      "<input id='#{head.facility_id}' value='#{head.facility_id}' type='checkbox' class='facility_chkbx' role='checkbox' />
        <label type='text' for='#{head.facility_id}' style='font-family: 'SExtralight'; font-size:14px;'>
      </label>",
      head.code,
      head.name,
      "#{head.line_1}, #{head.line_2}, #{head.city}, #{head.province}, #{head.region}, #{head.country}, #{head.postal_code}",
      head.name
    ]]

    a_insert_table_buttons(tails, tbl)

  end
  defp a_insert_table_buttons([], tbl), do: tbl


end

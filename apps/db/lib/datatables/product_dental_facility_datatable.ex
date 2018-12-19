defmodule Innerpeace.Db.Datatables.ProductDentalFacilityDatatable do
  @moduledoc ""

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.ProductCoverageLocationGroup,
    Schemas.LocationGroup,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.Dropdown
  }

  def facility_count(product_id) do
    initialize_query
    |> where([p, pc, pclg, pcf, f, d, lg], pc.product_id == ^product_id)
    |> where([p, pc, pclg, pcf, f, d, lg],
      ilike(f.code, ^"%%") or
      ilike(f.name, ^"%%") or
      ilike(f.line_1, ^"%%") or
      ilike(f.line_2, ^"%%") or
      ilike(f.city, ^"%%") or
      ilike(f.province, ^"%%") or
      ilike(f.region, ^"%%") or
      ilike(f.country, ^"%%") or
      ilike(lg.name, ^"%%")
    )
    |> select([p, pc, pclg, pcf, f, d, lg], %{
      id: f.id,
      code: f.code,
      name: f.name,
      line_1: f.line_1,
      line_2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      l_name: lg.name,
      pc_type: pc.type
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  def facility_data(params) do

    initialize_query
    |> where([p, pc, pclg, pcf, f, d, lg], pc.product_id == ^params.product_id)
    |> where([p, pc, pclg, pcf, f, d, lg],
      ilike(f.code, ^"%#{params.search_value}%") or
      ilike(f.name, ^"%#{params.search_value}%") or
      ilike(f.line_1, ^"%#{params.search_value}%") or
      ilike(f.line_2, ^"%#{params.search_value}%") or
      ilike(f.city, ^"%#{params.search_value}%") or
      ilike(f.province, ^"%#{params.search_value}%") or
      ilike(f.region, ^"%#{params.search_value}%") or
      ilike(f.country, ^"%#{params.search_value}%") or
      ilike(lg.name, ^"%#{params.search_value}%")
    )
    |> select([p, pc, pclg, pcf, f, d, lg], %{
        id: f.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        l_name: lg.name,
        pc_type: pc.type,
        product_id: p.id,
        pc_id: pc.id,
        pcf_id: pcf.id,
        ftype: d.text
      })
    |> order_datatable(
      params.order["column"],
      params.order["dir"]
    )
    |> offset(^params.offset)
    |> limit(^params.limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols([], params.step)
  end

  def facility_filtered_count(
    search_value,
    product_id
  ) do

    initialize_query
    |> where([p, pc, pclg, pcf, f, d, lg], pc.product_id == ^product_id)
    |> where([p, pc, pclg, pcf, f, d, lg],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.line_1, ^"%#{search_value}%") or
      ilike(f.line_2, ^"%#{search_value}%") or
      ilike(f.city, ^"%#{search_value}%") or
      ilike(f.province, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(f.country, ^"%#{search_value}%") or
      ilike(lg.name, ^"%#{search_value}%")
    )
    |> select([p, pc, pclg, pcf, f, d, lg], %{
      id: f.id,
      code: f.code,
      name: f.name,
      line_1: f.line_1,
      line_2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      l_name: lg.name,
      pc_type: pc.type
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  defp initialize_query do
    Product
    |> join(:left, [p], pc in ProductCoverage, pc.product_id == p.id)
    |> join(:left, [p, pc], pclg in ProductCoverageLocationGroup, pclg.product_coverage_id == pc.id)
    |> join(:left, [p, pc, pclg], pcf in ProductCoverageFacility, pcf.product_coverage_id == pc.id)
    |> join(:left, [p, pc, pclg, pcf], f in Facility, f.id == pcf.facility_id)
    |> join(:left, [p, pc, pclg, pcf, f], d in Dropdown, f.ftype_id == d.id)
    |> join(:left, [p, pc, pclg, pcf, f, d], lg in LocationGroup, lg.id == pclg.location_group_id)
  end

  def get_pcf_address(head) do
    "#{head.line_1} #{head.line_2} #{head.city} #{head.province} #{head.region} #{head.country}"
  end

  defp insert_table_cols([head | tails], tbl, step) do
    case step do
      2 ->
        address = get_pcf_address(head)
        tbl = insert_table_cols_facility(head.pc_type, head, tbl)
        insert_table_cols(tails, tbl, step)
      4 ->
        address = get_pcf_address(head)
        tbl = insert_table_cols_v2(head.pc_type, head, tbl)
        insert_table_cols(tails, tbl, step)
    end

  end
  defp insert_table_cols([], tbl, step), do: tbl

  defp insert_table_cols_facility(_, head, tbl) do
    if is_nil(head.id) do
      []
    else
      address = get_pcf_address(head)

      tbl =
      tbl ++
        [
          [
            is_nil?(head.code),
            is_nil?(head.name),
            is_nil?(address),
            is_nil?(head.ftype),
            generate_remove_button(head)
          ]
        ]
    end
  end

  defp insert_table_cols_facility("exception", head, tbl) do
    if is_nil(head.id) do
      []
    else
      address = get_pcf_address(head)

      tbl =
      tbl ++
        [
          [
            is_nil?(head.code),
            is_nil?(head.name),
            is_nil?(address),
            is_nil?(head.l_name),
            generate_remove_button(head)
          ]
        ]
    end
  end

  defp generate_remove_button(head),
  do:
    "<a href='#!' pc_type='#{head.pc_type}' product_id='#{head.product_id}' product_coverage_facility_id='#{head.pcf_id}' class='remove_facility'> Remove </a>
     <input type='hidden' name='product[dentl][facility_ids][]' value='#{head.id}'>
     <span class='selected_facility_id hidden'>#{head.id}</span>"

  defp insert_table_cols_v2("exception", head, tbl) do
    address = get_pcf_address(head)

    tbl =
      tbl ++
        [
          [
            is_nil?(head.code),
            is_nil?(head.name),
            is_nil?(address),
            is_nil?(head.l_name)
          ]
        ]
  end
  defp insert_table_cols_v2(_, head, tbl) do
    address = get_pcf_address(head)

    tbl =
      tbl ++
        [
          [
            is_nil?(head.code),
            is_nil?(head.name),
            is_nil?(address)
          ]
        ]
  end

  defp is_nil?(nil), do: "N/A"
  defp is_nil?(""), do: "N/A"
  defp is_nil?(value), do: value

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], asc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], asc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], asc: f.line_1)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], asc: lg.name)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], asc: f.code)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], desc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], desc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], desc: f.line_1)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], desc: lg.name)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([p, pc, pclg, pcf, f, d, lg], desc: f.code)
end

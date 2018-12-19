defmodule Innerpeace.Db.Datatables.ProductDentalFacilityInclusionDatatable do
  @moduledoc ""

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
  }

  def facility_count(product_id) do
    initialize_query
    |> where([p, pc, pcf, f], pc.product_id == ^product_id)
    |> where([p, pc, pcf, f],
      ilike(f.code, ^"%%") or
      ilike(f.name, ^"%%") or
      ilike(f.line_1, ^"%%") or
      ilike(f.line_2, ^"%%") or
      ilike(f.city, ^"%%") or
      ilike(f.province, ^"%%") or
      ilike(f.region, ^"%%") or
      ilike(f.country, ^"%%")
    )
    |> select([p, pc, pcf, f], %{
      id: f.id,
      code: f.code,
      name: f.name,
      line_1: f.line_1,
      line_2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      pc_type: pc.type
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  def facility_data(param) do
    initialize_query
    |> where([p, pc, pcf, f], pc.product_id == ^param.product_id)
    |> where([p, pc, pcf, f],
      ilike(f.code, ^"%#{param.search_value}%") or
      ilike(f.name, ^"%#{param.search_value}%") or
      ilike(f.line_1, ^"%#{param.search_value}%") or
      ilike(f.line_2, ^"%#{param.search_value}%") or
      ilike(f.city, ^"%#{param.search_value}%") or
      ilike(f.province, ^"%#{param.search_value}%") or
      ilike(f.region, ^"%#{param.search_value}%") or
      ilike(f.country, ^"%#{param.search_value}%")
    )
    |> select([p, pc, pcf, f], %{
        id: f.id,
        code: f.code,
        name: f.name,
        line_1: f.line_1,
        line_2: f.line_2,
        city: f.city,
        province: f.province,
        region: f.region,
        country: f.country,
        pc_type: pc.type
      })
    |> order_datatable(
      param.order["column"],
      param.order["dir"]
    )
    |> offset(^param.offset)
    |> limit(^param.limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols([])
  end

  def facility_filtered_count(
    search_value,
    product_id
  ) do

    initialize_query
    |> where([p, pc, pcf, f], pc.product_id == ^product_id)
    |> where([p, pc, pcf, f],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(f.line_1, ^"%#{search_value}%") or
      ilike(f.line_2, ^"%#{search_value}%") or
      ilike(f.city, ^"%#{search_value}%") or
      ilike(f.province, ^"%#{search_value}%") or
      ilike(f.region, ^"%#{search_value}%") or
      ilike(f.country, ^"%#{search_value}%")
    )
    |> select([p, pc, pcf, f], %{
      id: f.id,
      code: f.code,
      name: f.name,
      line_1: f.line_1,
      line_2: f.line_2,
      city: f.city,
      province: f.province,
      region: f.region,
      country: f.country,
      pc_type: pc.type
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  defp initialize_query do
    Product
    |> join(:left, [p], pc in ProductCoverage, pc.product_id == p.id)
    |> join(:left, [p, pc], pcf in ProductCoverageFacility, pcf.product_coverage_id == pc.id)
    |> join(:left, [p, pc, pcf], f in Facility, f.id == pcf.facility_id)
  end

  def get_pcf_address(head) do
    "#{head.line_1} #{head.line_2} #{head.city} #{head.province} #{head.region} #{head.country}"
  end

  defp insert_table_cols([head | tails], tbl) do
    address = get_pcf_address(head)

    tbl = insert_table_cols_v2(head.pc_type, head, tbl)

    insert_table_cols(tails, tbl)
  end
  defp insert_table_cols([], tbl), do: tbl

  # defp insert_table_cols_v2("exception", head, tbl) do
  #   address = get_pcf_address(head)

  #   tbl =
  #     tbl ++
  #       [
  #         [
  #           is_nil?(head.code),
  #           is_nil?(head.name),
  #           is_nil?(address),
  #           is_nil?(head.l_name)
  #         ]
  #       ]
  # end
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
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([p, pc, pcf, f], asc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, pc, pcf, f], asc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, pc, pcf, f], asc: f.line_1)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([p, pc, pcf, f], desc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, pc, pcf, f], desc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, pc, pcf, f], desc: f.line_1)

end

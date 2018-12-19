defmodule Innerpeace.Db.Datatables.ProductDentalRiskShareDatatable do
  @moduledoc ""

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Schemas.Product,
    Schemas.ProductCoverage,
    Schemas.ProductCoverageFacility,
    Schemas.ProductCoverageDentalRiskShare,
    Schemas.ProductCoverageDentalRiskShareFacility
  }

  def risk_share_count(nil), do: 0
  def risk_share_count(product_id) do
    initialize_query
    |> where([pcdrsf, pcdrs, pc, f], pc.product_id == ^product_id)
    |> where([pcdrsf, pcdrs, pc, f],
      ilike(f.code, ^"%%") or
      ilike(f.name, ^"%%") or
      ilike(pcdrsf.sdf_type, ^"%%") or
      ilike(fragment("text(?)", pcdrsf.sdf_amount), ^"%%") or
      ilike(pcdrsf.sdf_special_handling, ^"%%")
    )
    |> select([pcdrsf, pcdrs, pc, f], %{
        id: f.id,
        code: f.code,
        name: f.name,
        type: pcdrsf.sdf_type,
        amount: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        fragment("text(?)", pcdrsf.sdf_amount),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_amount)),
        special_handling: pcdrsf.sdf_special_handling
      })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  def risk_share_data(_, _, _, _, nil), do: []
  def risk_share_data(
    offset,
    limit,
    search_value,
    order,
    product_id
  ) do

    initialize_query
    |> where([pcdrsf, pcdrs, pc, f], pc.product_id == ^product_id)
    |> where([pcdrsf, pcdrs, pc, f],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(pcdrsf.sdf_type, ^"%#{search_value}%") or
      ilike(fragment("text(?)", pcdrsf.sdf_amount), ^"%#{search_value}%") or
      ilike(pcdrsf.sdf_special_handling, ^"%#{search_value}%")
    )
    |> select([pcdrsf, pcdrs, pc, f], %{
        id: f.id,
        code: f.code,
        name: f.name,
        type: pcdrsf.sdf_type,
        amount: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        fragment("text(?)", pcdrsf.sdf_amount),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_amount)),
        special_handling: pcdrsf.sdf_special_handling
      })
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

  def risk_share_filtered_count(_, nil), do: 0
  def risk_share_filtered_count(
    search_value,
    product_id
  ) do

    initialize_query
    |> where([pcdrsf, pcdrs, pc, f], pc.product_id == ^product_id)
    |> where([pcdrsf, pcdrs, pc, f],
      ilike(f.code, ^"%#{search_value}%") or
      ilike(f.name, ^"%#{search_value}%") or
      ilike(pcdrsf.sdf_type, ^"%#{search_value}%") or
      ilike(fragment("text(?)", pcdrsf.sdf_amount), ^"%#{search_value}%") or
      ilike(pcdrsf.sdf_special_handling, ^"%#{search_value}%")
    )
    |> select([pcdrsf, pcdrs, pc, f], %{
      id: f.id,
      code: f.code,
      name: f.name,
      type: pcdrsf.sdf_type,
      amount: fragment(
      "CASE WHEN ? IS NULL THEN
        CASE WHEN ? IS NULL THEN '' ELSE ? END
      ELSE ? END",
      fragment("text(?)", pcdrsf.sdf_amount),
      fragment("text(?)", pcdrsf.sdf_percentage),
      fragment("text(?)", pcdrsf.sdf_percentage),
      fragment("text(?)", pcdrsf.sdf_amount)),
      special_handling: pcdrsf.sdf_special_handling
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  defp initialize_query do
    # ProductCoverage
    # |> join(:left, [pc], pcdrs in ProductCoverageDentalRiskShare, pcdrs.product_coverage_id == pc.id)
    # |> join(:left, [pc, pcdrs], pcdrsf in ProductCoverageDentalRiskShareFacility, pcdrsf.product_coverage_dental_risk_share_id == pcdrs.id)
    # |> join(:left, [pc, pcdrs, pcdrsf], f in Facility, f.id == pcdrsf.facility_id)

    ProductCoverageDentalRiskShareFacility
    |> join(:left, [pcdrsf], pcdrs in ProductCoverageDentalRiskShare, pcdrsf.product_coverage_dental_risk_share_id == pcdrs.id)
    |> join(:left, [pcdrsf, pcdrs], pc in ProductCoverage, pcdrs.product_coverage_id == pc.id)
    |> join(:left, [pcdrsf, pcdrs, pc], f in Facility, pcdrsf.facility_id == f.id)
  end


  def get_amount(_, nil), do: 0
  def get_amount(true, value) do
    [head | rest] = String.split(value, ".")

    value =
      head
      |> String.to_integer
      |> Integer.to_char_list
      |> Enum.reverse
      |> Enum.chunk(3, 3, [])
      |> Enum.join(",")
      |> String.reverse

    "#{value}.#{rest}"
  end

  def get_amount(false, nil), do: 0
  def get_amount(false, ""), do: 0
  def get_amount(false, value) do
    value
    |> String.to_integer
    |> Integer.to_char_list
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
  end

  defp insert_table_cols([head | tails], tbl) do
    amount = get_amount(String.contains?(head.amount, "."), head.amount)
    tbl =
      tbl ++
        [
          [
            is_nil?(head.code),
            is_nil?(head.name),
            is_nil?(head.type),
            is_nil?(amount),
            is_nil?(head.special_handling)
          ]
        ]

    insert_table_cols(tails, tbl)
  end

  defp insert_table_cols([], tbl), do: tbl

  defp is_nil?(value) when value == "copay", do: "Copay"
  defp is_nil?(value) when value == "coinsurance", do: "Coinsurance"
  defp is_nil?(nil), do: "N/A"
  defp is_nil?(""), do: "N/A"
  defp is_nil?(value), do: value

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([pcdrsf, pcdrs, pc, f], asc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([pcdrsf, pcdrs, pc, f], asc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([pcdrsf, pcdrs, pc, f], asc: pcdrsf.sdf_type)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([pcdrsf, pcdrs, pc, f], asc: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        fragment("text(?)", pcdrsf.sdf_amount),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_amount)))
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([pcdrsf, pcdrs, pc, f], asc: pcdrsf.sdf_special_handling)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([pcdrsf, pcdrs, pc, f], desc: f.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([pcdrsf, pcdrs, pc, f], desc: f.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([pcdrsf, pcdrs, pc, f], desc: pcdrsf.sdf_type)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([pcdrsf, pcdrs, pc, f], desc: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        fragment("text(?)", pcdrsf.sdf_amount),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_percentage),
        fragment("text(?)", pcdrsf.sdf_amount)))
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([pcdrsf, pcdrs, pc, f], desc: pcdrsf.sdf_special_handling)

end

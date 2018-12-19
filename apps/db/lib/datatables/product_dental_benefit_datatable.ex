defmodule Innerpeace.Db.Datatables.ProductDentalBenefitDatatable do
  @moduledoc ""

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Benefit,
    Schemas.BenefitLimit,
    Schemas.BenefitProcedure,
    Schemas.ProductBenefit,
    Schemas.ProductBenefitLimit
  }

  def benefit_count(product_id) do
    initialize_query
    |> where([pb, b, bl, pbl, bp], pb.product_id == ^product_id)
    |> where([pb, b, bl, pbl, bp],
      ilike(b.code, "%%") or
      ilike(fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ), ^"%%") or
      ilike(fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ), ^"%%") or
    fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%%"))
    |> group_by([pb, b, bl, pbl, bp], b.code)
    |> group_by([pb, b, bl, pbl, bp], b.name)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], b.id)
    |> select([pb, b, bl, pbl, bp], %{
      code: b.code,
      name: b.name,
      limit_type: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ),
      limit_amount: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ),
      id: b.id,
      cdt: count(bp.id)
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  def benefit_data(
    offset,
    limit,
    search_value,
    order,
    product_id
  ) do

    search_value_v2 = search_value_v2("#{search_value}")

    initialize_query
    |> where([pb, b, bl, pbl, bp],
      ilike(b.code, ^"%#{search_value}%") or
      ilike(fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ), ^"%#{search_value}%") or
      ilike(
        fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ),  ^"%#{search_value_v2}%") or
      fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%#{search_value}%"))
    |> where([pb, b, bl, pbl, bp], pb.product_id == ^product_id)
    |> group_by([pb, b, bl, pbl, bp], b.code)
    |> group_by([pb, b, bl, pbl, bp], b.name)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], b.id)
    |> select([pb, b, bl, pbl, bp], %{
      code: b.code,
      name: b.name,
      limit_type: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ),
      limit_amount: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ),
      id: b.id,
      cdt: count(bp.id)
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

  def benefit_filtered_count(
    search_value,
    product_id
  ) do

    search_value_v2 = search_value_v2("#{search_value}")

    initialize_query
    |> where([pb, b, bl, pbl, bp], pb.product_id == ^product_id)
    |> where([pb, b, bl, pbl, bp],
      ilike(b.code, ^"%#{search_value}%") or
      ilike(fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ), ^"%#{search_value}%") or
      ilike(
        fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ),  ^"%#{search_value_v2}%") or
    fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%#{search_value}%"))
    |> group_by([pb, b, bl, pbl, bp], b.code)
    |> group_by([pb, b, bl, pbl, bp], b.name)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], bl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_type)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_amount)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_percentage)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_session)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_tooth)
    |> group_by([pb, b, bl, pbl, bp], pbl.limit_quadrant)
    |> group_by([pb, b, bl, pbl, bp], b.id)
    |> select([pb, b, bl, pbl, bp], %{
      code: b.code,
      name: b.name,
      limit_type: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN '' ELSE ? END
        ELSE ? END",
        pbl.limit_type,
        bl.limit_type,
        bl.limit_type,
        pbl.limit_type
      ),
      limit_amount: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN
                  CASE WHEN ? IS NULL THEN
                    CASE WHEN ? IS NULL THEN
                      CASE WHEN ? IS NULL THEN
                        CASE WHEN ? IS NULL THEN
                          CASE WHEN ? IS NULL THEN '' ELSE ? END
                        ELSE ? END
                      ELSE ? END
                    ELSE ? END
                  ELSE ? END
                ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", pbl.limit_amount),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", pbl.limit_quadrant),
        fragment("text(?)", pbl.limit_tooth),
        fragment("text(?)", pbl.limit_session),
        fragment("text(?)", pbl.limit_percentage),
        fragment("text(?)", pbl.limit_amount)
      ),
      id: b.id,
      cdt: count(bp.id)
    })
    |> distinct(true)
    |> Repo.all()
    |> Enum.count()
  end

  defp initialize_query do
    ProductBenefit
    |> join(:inner, [pb], b in Benefit, b.id == pb.benefit_id)
    |> join(:inner, [pb, b], bl in BenefitLimit, bl.benefit_id == b.id)
    |> join(:inner, [pb, b, bl], pbl in ProductBenefitLimit, pbl.product_benefit_id == pb.id)
    |> join(:inner, [pb, b, bl, pbl], bp in BenefitProcedure, bp.benefit_id == b.id)
  end

  defp get_limit_amount(_, nil), do: 0
  defp get_limit_amount(true, value) do
    value = String.split(value, ".")

    value1 =
      value
      |> Enum.at(0)
      |> String.to_integer
      |> Integer.to_char_list
      |> Enum.reverse
      |> Enum.chunk(3, 3, [])
      |> Enum.join(",")
      |> String.reverse

    "#{value1}.#{Enum.at(value, 1)}"
  end

  defp get_limit_amount(false, value) do
    value
    |> String.to_integer
    |> Integer.to_char_list
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
  end

  defp insert_table_cols([head | tails], tbl) do
    link = generate_benefit_link(head.id, head.code)

    limit_amount = get_limit_amount(String.contains?(head.limit_amount, "."), head.limit_amount)

    tbl =
      tbl ++
        [
          [
            is_nil?(link),
            is_nil?(head.name),
            is_nil?(head.cdt),
            is_nil?(head.limit_type),
            is_nil?(limit_amount)
          ]
        ]

    insert_table_cols(tails, tbl)
  end
  defp insert_table_cols([], tbl), do: tbl

  defp is_nil?(nil), do: "N/A"
  defp is_nil?(""), do: "N/A"
  defp is_nil?(value), do: value

  defp generate_benefit_link(nil, _), do: "N/A"
  defp generate_benefit_link(_, nil), do: "N/A"
  defp generate_benefit_link(id, code), do: "<a href='/web/products/benefit/#{id}'>#{code}</a> "

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([pb, b, bl, pbl, bp], asc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([pb, b, bl, pbl, bp], asc: b.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([pb, b, bl, pbl, bp], asc: count(bp.id))
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([pb, b, bl, pbl, bp], asc: bl.limit_type)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([pb, b, bl, pbl, bp], asc: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN '' ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount)))

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([pb, b, bl, pbl, bp], desc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([pb, b, bl, pbl, bp], desc: b.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([pb, b, bl, pbl, bp], desc: count(bp.id))
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([pb, b, bl, pbl, bp], desc: bl.limit_type)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([pb, b, bl, pbl, bp], desc: fragment(
        "CASE WHEN ? IS NULL THEN
          CASE WHEN ? IS NULL THEN
            CASE WHEN ? IS NULL THEN
              CASE WHEN ? IS NULL THEN
                CASE WHEN ? IS NULL THEN '' ELSE ? END
              ELSE ? END
            ELSE ? END
          ELSE ? END
        ELSE ? END",
        fragment("text(?)", bl.limit_amount),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_quadrant),
        fragment("text(?)", bl.limit_tooth),
        fragment("text(?)", bl.limit_session),
        fragment("text(?)", bl.limit_percentage),
        fragment("text(?)", bl.limit_amount)))

  defp search_value_v2(""), do: ""
  defp search_value_v2(val), do: String.replace(val, ",", "")

end

defmodule Innerpeace.Db.Datatables.DentalBenefitDatatable do
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
    Schemas.Benefit,
    Schemas.BenefitLimit,
    Schemas.BenefitProcedure,
    Schemas.BenefitCoverage,
    Schemas.Coverage,
  }

  def procedure_count(ids) do
    # Returns total count of data without filter and search value.

    ids
    |> initialize_query
    |> where([b, bc, c, bl, bp],
      ilike(b.code, ^"%%") or
      ilike(b.name, ^"%%") or
      ilike(bl.limit_type, ^"%%") or
      ilike(
        fragment("to_char(?, 'FM9999999999999')", bl.limit_amount),
        ^"%%"
      ) or
      ilike(fragment("text(?)", bl.limit_percentage), ^"%%") or
      ilike(fragment("text(?)", bl.limit_session), ^"%%") or
      ilike(fragment("text(?)", bl.limit_tooth), ^"%%") or
      ilike(fragment("text(?)", bl.limit_quadrant), ^"%%") or
      fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%%")
    )
    |> select([b, bc, c, bl, bp],
      %{
        benefit_id: b.id,
        benefit_code: b.code,
        benefit_name: b.name,
        bl_count: count(bp.id),
        bl_limit_type: bl.limit_type,
        limit_amount: fragment(
          "CASE
            WHEN ? = 'Sessions' THEN ?
            WHEN ? = 'Peso' THEN ?
            WHEN ? = 'Plan Limit Percentage' THEN ?
            WHEN ? = 'Quadrant' THEN ?
            WHEN ? = 'Tooth' THEN ?
            ELSE ?
          END",

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_session),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_amount),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_percentage),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_quadrant),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_tooth),

            fragment("text(?)", 0)

        )
      }
    )
    |> group_by([b, bc, c, bl, bp], [b.id, bl.limit_type, bl.limit_session, bl.limit_amount,
                                    bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
                                    ])
    |> Repo.all()
    |> Enum.count()
  end

  def get_all_dental_benefit_data(ids, benefits_ids) do
    ids
    |> initialize_query
    |> where([b, bc, c, bl, bp],
      ilike(b.code, ^"%%") or
      ilike(b.name, ^"%%") or
      ilike(bl.limit_type, ^"%%") or
      ilike(
        fragment("to_char(?, 'FM9999999999999')", bl.limit_amount),
        ^"%%"
      ) or
      ilike(fragment("text(?)", bl.limit_percentage), ^"%%") or
      ilike(fragment("text(?)", bl.limit_session), ^"%%") or
      ilike(fragment("text(?)", bl.limit_tooth), ^"%%") or
      ilike(fragment("text(?)", bl.limit_quadrant), ^"%%") or
      fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%%")
    )
    |> select([b, bc, c, bl, bp],
      %{
        benefit_id: b.id,
        benefit_code: b.code,
        benefit_name: b.name,
        bl_count: count(bp.id),
        bl_limit_type: bl.limit_type,
        limit_amount: fragment(
          "CASE
            WHEN ? = 'Sessions' THEN ?
            WHEN ? = 'Peso' THEN ?
            WHEN ? = 'Plan Limit Percentage' THEN ?
            WHEN ? = 'Quadrant' THEN ?
            WHEN ? = 'Tooth' THEN ?
            ELSE ?
          END",

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_session),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_amount),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_percentage),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_quadrant),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_tooth),

            fragment("text(?)", 0)

        )
      }
    )
    |> group_by([b, bc, c, bl, bp], [b.id, bl.limit_type, bl.limit_session, bl.limit_amount,
                                    bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
                                    ])
    |> Repo.all()
    |> Enum.count()
  end

  def get_all_dental_benefit_with_procedure(ids) do
    benefits =
      ids
      |> initialize_query
      |> Repo.all()
      |> Repo.preload([
        :benefit_limits,
        :benefit_procedures
      ])

    Enum.map(benefits, fn(benefit) ->
      procedures =
        benefit.benefit_procedures
        |> Enum.map(fn(x) ->
          x.procedure_id
        end)

       %{
        id: benefit.id,
        procedure_ids: procedures
      }
    end)
  end

  def get_all_selected_dental_benefit(ids) do
    benefits =
      ids
      |> initialize_selected_query
      |> Repo.all()
      |> Repo.preload([
        :benefit_limits,
        benefit_procedures: :procedure
      ])


    Enum.map(benefits, fn(benefit) ->
      procedures =
        benefit.benefit_procedures
        |> Enum.map(fn(x) ->
          %{
            id: x.procedure_id,
            code: x.procedure.code,
            description: x.procedure.description
          }
        end)

      type = List.first(benefit.benefit_limits).limit_type

      case type do
        "Peso" ->
          amount = List.first(benefit.benefit_limits).limit_amount
        "Plan Limit Percentage" ->
          amount = List.first(benefit.benefit_limits).limit_percentage
        "Sessions" ->
          amount = List.first(benefit.benefit_limits).limit_session
        "Tooth" ->
          amount = List.first(benefit.benefit_limits).limit_tooth
        "Quadrant" ->
          amount = List.first(benefit.benefit_limits).limit_quadrant
        _ ->
          ""
      end

       %{
        id: benefit.id,
        b_code: benefit.code,
        b_name: benefit.name,
        bp_id: Enum.count(benefit.benefit_procedures),
        bl_limit_amount: amount,
        bl_limit_type: type,
        procedure_ids: procedures
      }
    end)
  end

  defp initialize_selected_query(ids) do
    # Sets initial query of the table.

    Benefit
    |> join(:inner, [b], bc in BenefitCoverage, b.id == bc.benefit_id)
    |> join(:inner, [b, bc], c in Coverage, bc.coverage_id == c.id)
    |> join(:inner, [b, bc, c], bl in BenefitLimit, bl.benefit_id == b.id)
    |> where([b, bc, c, bl], c.code == "DENTL")
    |> where([b, bc, c, bl], b.step == 0)
    |> distinct(true)
    |> filter_selected_ids(ids)
  end

  defp filter_selected_ids(benefit, ids) when ids == [""], do: benefit
  defp filter_selected_ids(benefit, ids) when ids != [""] do
    benefit
    |> where([b, bc, c, bl], b.id in ^ids)
  end

  def procedure_data(
    ids,
    benefit_ids,
    offset,
    limit,
    search_value,
    order
  ) do

    query = case order["column"] do
      "1" ->
        query_benefit_data(search_value, offset, limit, "b.code", order["dir"])
      "2" ->
        query_benefit_data(search_value, offset, limit, "b.name", order["dir"])
      "3" ->
        query_benefit_data(search_value, offset, limit, "cdt_count", order["dir"])
      "4" ->
        query_benefit_data(search_value, offset, limit, "bl.limit_type", order["dir"])
      "5" ->
        query_benefit_data(search_value, offset, limit, "limit_amount", order["dir"])
    end

    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

     result.rows
      |> insert_table_buttons([], ids, benefit_ids)
  end

  def query_benefit_data(search_value, offset, limit, column, direction) do
    "select b.id, b.code, b.name, count(bp.id) as cdt_count, bl.limit_type,
      ( CASE
        WHEN bl.limit_type = 'Sessions' THEN bl.limit_session
        WHEN bl.limit_type = 'Plan Limit Percentage' THEN bl.limit_percentage
        WHEN bl.limit_type = 'Peso' THEN bl.limit_amount
        WHEN bl.limit_type = 'Quadrant' THEN bl.limit_quadrant
        WHEN bl.limit_type = 'Tooth' THEN bl.limit_tooth
        ELSE 0
        END
      ) as limit_amount
    from benefits b
    Inner Join coverage_benefits bc on bc.benefit_id = b.id
    Inner Join coverages c on bc.coverage_id = c.id
    Inner Join benefit_limits bl on bl.benefit_id = b.id
    Inner join benefit_procedures bp on bp.benefit_id = b.id
    where (c.code = 'DENTL' and b.step = 0 and bl.limit_type != 'Area')
    AND (((((((((b.code ILIKE '%#{search_value}%')
    OR (b.name ILIKE '%#{search_value}%'))
    OR (bl.limit_type ILIKE '%#{search_value}%'))
    OR (to_char(bl.limit_amount, 'FM9999999999999') ILIKE '%#{search_value}%'))
    OR (text(bl.limit_percentage) ILIKE '%#{search_value}%'))
    OR (text(bl.limit_session) ILIKE '%#{search_value}%'))
    OR (text(bl.limit_tooth) ILIKE '%#{search_value}%'))
    OR (text(bl.limit_quadrant) ILIKE '%#{search_value}%'))
    OR TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = b.id)) ILIKE '%#{search_value}%')
    group by b.id, bl.limit_type, bl.limit_session, bl.limit_amount, bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
    order by #{column} #{direction}
    offset #{offset}
    limit #{limit}"
  end

  #def procedure_data(
  #  ids,
  #  benefit_ids,
  #  offset,
  #  limit,
  #  search_value,
  #  order
 # #) do
 #   query = "select b.id, b.code, b.name, count(bp.id) as cdt_count, bl.limit_type,
 #       ( CASE
 #         WHEN bl.limit_type = 'Sessions' THEN bl.limit_session
 #         WHEN bl.limit_type = 'Plan Limit Percentage' THEN bl.limit_percentage
 #         WHEN bl.limit_type = 'Peso' THEN bl.limit_amount
 #         WHEN bl.limit_type = 'Quadrant' THEN bl.limit_quadrant
 #         WHEN bl.limit_type = 'Tooth' THEN bl.limit_tooth
 #         ELSE 0
 #         END
 #       ) as limit_amount
 #     from benefits b
 #     Inner Join coverage_benefits bc on bc.benefit_id = b.id
 #     Inner Join coverages c on bc.coverage_id = c.id
 #     Inner Join benefit_limits bl on bl.benefit_id = b.id
 #     Inner join benefit_procedures bp on bp.benefit_id = b.id
 #     where (c.code = 'DENTL' and b.step = 0 and bl.limit_type != 'Area')
 #     AND (((((((((b.code ILIKE '%#{search_value}%')
 #     OR (b.name ILIKE '%#{search_value}%'))
 #     OR (bl.limit_type ILIKE '%#{search_value}%'))
 #     OR (to_char(bl.limit_amount, 'FM9999999999999') ILIKE '%#{search_value}%'))
 #     OR (text(bl.limit_percentage) ILIKE '%#{search_value}%'))
 #     OR (text(bl.limit_session) ILIKE '%#{search_value}%'))
 #     OR (text(bl.limit_tooth) ILIKE '%#{search_value}%'))
 #     OR (text(bl.limit_quadrant) ILIKE '%#{search_value}%'))
 #     OR TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = b.id)) ILIKE '%#{search_value}%')
 #     group by b.id, bl.limit_type, bl.limit_session, bl.limit_amount, bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
 #     order by cdt_count desc
 #     offset #{offset}
 #     limit #{limit}"
#
 #   {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)
#
 #    result.rows
 #     |> insert_table_buttons([], ids, benefit_ids)
#
    # Returns table data according to table's offset and limit.
    #ids
    #|> initialize_query
    #|> where([b, bc, c, bl, bp],
    #  ilike(b.code, ^"%#{search_value}%") or
    #  ilike(b.name, ^"%#{search_value}%") or
    #  ilike(bl.limit_type, ^"%#{search_value}%") or
    #   ilike(
    #    fragment("to_char(?, 'FM9999999999999')", bl.limit_amount),
    #    ^"%#{search_value}%"
    #  ) or
    #  ilike(fragment("text(?)", bl.limit_percentage), ^"%#{search_value}%") or
    #  ilike(fragment("text(?)", bl.limit_session), ^"%#{search_value}%") or
    #  ilike(fragment("text(?)", bl.limit_tooth), ^"%#{search_value}%") or
    #  ilike(fragment("text(?)", bl.limit_quadrant), ^"%#{search_value}%") or
    #  fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%#{search_value}%")
    #)
    #|> select([b, bc, c, bl, bp],
    #  %{
    #    benefit_id: b.id,
    #    benefit_code: b.code,
    #    benefit_name: b.name,
    #    bl_count: count(bp.id),
    #    bl_limit_type: bl.limit_type,
    #    limit_amount: fragment(
    #      "CASE
    #        WHEN ? = 'Sessions' THEN ?
    #        WHEN ? = 'Peso' THEN ?
    #        WHEN ? = 'Plan Limit Percentage' THEN ?
    #        WHEN ? = 'Quadrant' THEN ?
    #        WHEN ? = 'Tooth' THEN ?
    #        ELSE ?
    #      END",
    #
    #        fragment("text(?)", bl.limit_type),
    #        fragment("text(?)", bl.limit_session),
    #
    #        fragment("text(?)", bl.limit_type),
    #        fragment("text(?)", bl.limit_amount),
    #
    #        fragment("text(?)", bl.limit_type),
    #        fragment("text(?)", bl.limit_percentage),
    #
    #        fragment("text(?)", bl.limit_type),
    #        fragment("text(?)", bl.limit_quadrant),
    #
    #        fragment("text(?)", bl.limit_type),
    #        fragment("text(?)", bl.limit_tooth),
    #
    #        fragment("text(?)", 0)
    #
    #    )
    #  }
    #)
    #|> order_datatable(
    #  order["column"],
    #  order["dir"]
    #)
    #|> group_by([b, bc, c, bl, bp], [b.id, bl.limit_type, bl.limit_session, bl.limit_amount,
    #                                bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
    #                                ])
    #|> offset(^offset)
    #|> limit(^limit)
    #|> Repo.all()
    #|> insert_table_buttons([], ids, benefit_ids)
  # end

  def procedure_filtered_count(
    ids,
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    ids
    |> initialize_query
    |> where([b, bc, c, bl, bp],
      ilike(b.code, ^"%#{search_value}%") or
      ilike(b.name, ^"%#{search_value}%") or
      ilike(bl.limit_type, ^"%#{search_value}%") or
      ilike(
        fragment("to_char(?, 'FM9999999999999')", bl.limit_amount),
        ^"%#{search_value}%"
      ) or
      ilike(fragment("text(?)", bl.limit_percentage), ^"%#{search_value}%") or
      ilike(fragment("text(?)", bl.limit_session), ^"%#{search_value}%") or
      ilike(fragment("text(?)", bl.limit_tooth), ^"%#{search_value}%") or
      ilike(fragment("text(?)", bl.limit_quadrant), ^"%#{search_value}%") or
      fragment("TEXT((SELECT COUNT(*) FROM benefit_procedures WHERE benefit_id = ?)) ILIKE ?", b.id,  ^"%#{search_value}%")
    )
    |> select([b, bc, c, bl, bp],
      %{
        benefit_id: b.id,
        benefit_code: b.code,
        benefit_name: b.name,
        bl_count: count(bp.id),
        bl_limit_type: bl.limit_type,
        limit_amount: fragment(
          "CASE
            WHEN ? = 'Sessions' THEN ?
            WHEN ? = 'Peso' THEN ?
            WHEN ? = 'Plan Limit Percentage' THEN ?
            WHEN ? = 'Quadrant' THEN ?
            WHEN ? = 'Tooth' THEN ?
            ELSE ?
          END",

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_session),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_amount),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_percentage),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_quadrant),

            fragment("text(?)", bl.limit_type),
            fragment("text(?)", bl.limit_tooth),

            fragment("text(?)", 0)

        )
      }
    )
    |> group_by([b, bc, c, bl, bp], [b.id, bl.limit_type, bl.limit_session, bl.limit_amount,
                                    bl.limit_percentage, bl.limit_quadrant, bl.limit_tooth
                                    ])
    |> Repo.all()
    |> Enum.count()

  end

  defp initialize_query(ids) do
    # Sets initial query of the table.

    Benefit
    |> join(:inner, [b], bc in BenefitCoverage, b.id == bc.benefit_id)
    |> join(:inner, [b, bc], c in Coverage, bc.coverage_id == c.id)
    |> join(:inner, [b, bc, c], bl in BenefitLimit, bl.benefit_id == b.id)
    |> join(:inner, [b, bc, c, bl], bp in BenefitProcedure, bp.benefit_id == b.id)
    |> where([b, bc, c, bl, bp], c.code == "DENTL")
    |> where([b, bc, c, bl, bp], b.step == 0)
    |> where([b, bc, c, bl, bp], bl.limit_type != "Area")


    # |> distinct(true)
    #|> filter_ids(ids)
  end

  defp filter_ids(procedure, ids) when ids == [""], do: procedure
  defp filter_ids(procedure, ids) when ids != [""] do
    procedure
    |> where([b, bc, c, bl, bp], b.id not in ^ids)
  end

  defp insert_table_buttons([head | tails], tbl, benefit_ids, selected_benefit_ids) do

    if benefit_ids != [""] do
      procedure_ids =
        benefit_ids
        |> Enum.map(fn(x) ->
          benefit =
            Benefit
            |> where([b], b.id == ^x)
            |> Repo.one()
            |> Repo.preload([
              :benefit_limits,
              :benefit_procedures
            ])

            if is_nil(benefit) do
              []
            else
              Enum.map(benefit.benefit_procedures, fn(x) ->
                x.procedure_id
              end)
            end
        end)
        |> List.flatten()
    else
      procedure_ids = []
    end


    benefit = Benefit
              |> where([b], b.id == ^Ecto.UUID.cast!(Enum.at(head, 0)))
              |> Repo.one()
              |> Repo.preload([
                :benefit_limits,
                :benefit_procedures
              ])

    disabled =
      benefit.benefit_procedures
        |> Enum.map(fn(x) ->
            x.procedure_id
        end)
        |> Enum.any?(fn(x) -> x in procedure_ids end)

     head_procedures =
      benefit.benefit_procedures
      |> Enum.map(fn(x) ->
        x.procedure_id
      end)

      head = %{
        id: Ecto.UUID.cast!(Enum.at(head, 0)),
        b_code: Enum.at(head, 1),
        b_name: Enum.at(head, 2),
        bp_id: Enum.at(head, 3),
        bl_limit_amount: Enum.at(head, 5),
        bl_limit_type: Enum.at(head, 4)
      }

      if Enum.member?(selected_benefit_ids, head.id) do
        tbl =
        tbl ++ [[
          "<input id='#{head.id}' value='#{head.id}' type='checkbox' role='checkbox'
          #{if disabled, do: "role='disabled_checkbox'", else: "role='checkbox'"} class='procedure_chkbx'
          checked='true' pp_id='#{head.id}' b_code='#{head.b_code}' b_name='#{head.b_name}' bp_id='#{head.bp_id}'
          bl_limit_type='#{head.bl_limit_type}' bl_limit_amount='#{head.bl_limit_amount}' #{if disabled, do: "disabled"}
          procedure_ids='#{head_procedures}'/> <label type='text' for='#{head.id}' style='font-family: 'SExtralight'; font-size:14px;'></label>",
          "<span #{if disabled, do: "class='black'", else: "class='green'"} >#{head.b_code}</span>",
          "#{head.b_name}",
          "#{head.bp_id}",
          "#{head.bl_limit_type}",
          "#{head.bl_limit_amount}",
          "#{head.id}"
        ]]

      insert_table_buttons(tails, tbl, benefit_ids, selected_benefit_ids)
      else
        tbl =
        tbl ++ [[
          "<input id='#{head.id}' value='#{head.id}' type='checkbox'
          #{if disabled, do: "role='disabled_checkbox'", else: "role='checkbox'"} class='procedure_chkbx'
          pp_id='#{head.id}' b_code='#{head.b_code}' b_name='#{head.b_name}' bp_id='#{head.bp_id}'
          bl_limit_type='#{head.bl_limit_type}' bl_limit_amount='#{head.bl_limit_amount}' #{if disabled, do: "disabled"}
          procedure_ids='#{head_procedures}'/> <label type='text' for='#{head.id}' style='font-family: 'SExtralight'; font-size:14px;'></label>",
          "<span #{if disabled, do: "class='black'", else: "class='green'"}>#{head.b_code}</span>",
          "#{head.b_name}",
          "#{head.bp_id}",
          "#{head.bl_limit_type}",
          "#{head.bl_limit_amount}",
          "#{head.id}"
        ]]

       insert_table_buttons(tails, tbl, benefit_ids, selected_benefit_ids)
      end
  end
  defp insert_table_buttons([], tbl, benefit_ids, selected_benefit_ids), do: tbl

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: b.code)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: b.name)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: count(bp.id))
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: bl.limit_type)
  defp order_datatable(query, column, order) when column == "5" and order == "asc", do: query |> order_by([b, bc, c, bl, bp], asc: fragment(
    "CASE
      WHEN ? = 'Sessions' THEN ?
      WHEN ? = 'Peso' THEN ?
      WHEN ? = 'Plan Limit Percentage' THEN ?
      WHEN ? = 'Quadrant' THEN ?
      WHEN ? = 'Tooth' THEN ?
      ELSE ?
    END",

      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_session),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_amount),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_percentage),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_quadrant),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_tooth),
      fragment("text(?)", 0)
  ))
  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: b.code)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: b.name)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: count(bp.id))
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: bl.limit_type)
  defp order_datatable(query, column, order) when column == "5" and order == "desc", do: query |> order_by([b, bc, c, bl, bp], desc: fragment(
    "CASE
      WHEN ? = 'Sessions' THEN ?
      WHEN ? = 'Peso' THEN ?
      WHEN ? = 'Plan Limit Percentage' THEN ?
      WHEN ? = 'Quadrant' THEN ?
      WHEN ? = 'Tooth' THEN ?
      ELSE ?
    END",

      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_session),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_amount),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_percentage),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_quadrant),
      fragment("text(?)", bl.limit_type),
      fragment("text(?)", bl.limit_tooth),
      fragment("text(?)", 0)
  ))
end

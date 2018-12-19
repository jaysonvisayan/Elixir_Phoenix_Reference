defmodule Innerpeace.Db.Datatables.ExclusionProcedure do
  @moduledoc """
  Rows:
  Code,
  Description
  """

  import Ecto.Query
  alias Plug.CSRFProtection

  alias Innerpeace.Db.{
    Repo,
    Schemas.Diagnosis,
    Schemas.Exclusion,
    Schemas.ExclusionProcedure,
    Schemas.DiagnosisCoverage,
    Schemas.Coverage,
    Schemas.PayorProcedure,
  }

  def insert_exclusion_procedure(offset, limit, search_value, order, id) do
    initialize_query(id)
    |> where([pp, ep, e], ep.exclusion_id == ^id)
    |> where([pp, ep, e],
             ilike(pp.code, ^"%#{search_value}%") or
             ilike(pp.description, ^"%#{search_value}%")
    )
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    # |> group_by([pp, ep, e], [d.id])
    # |> distinct([d], d.code)
    |> select([pp, ep, e], %{
      id: pp.id,
      code: pp.code,
      description: pp.description
    })
    |> Repo.all()
    |> insert_table_cols([])
  end

  def procedure_count(id) do
    initialize_query(id)
    |> select([pp, ep, e], count(pp.code, :distinct))
    |> Repo.one()
  end

  def filtered_count(search_value, id) do
    PayorProcedure
    |> join(:left, [pp], ep in ExclusionProcedure, pp.id == ep.procedure_id)
    |> join(:left, [pp, ep], e in Exclusion, ep.exclusion_id == e.id)
    |> where([pp, ep, e], e.id == ^id)
    |> where([pp, ep, e],
             ilike(pp.code, ^"%#{search_value}%") or
             ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([pp, ep, e], count(pp.code, :distinct))
    |> Repo.one()
  end

  defp insert_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            head.code,
            head.description
          ]
        ]
    insert_table_cols(tails, tbl)
  end

  defp insert_table_cols([], tbl), do: tbl

  defp generate_link(diagnosis, coverages) do
    "<a class='show-diagnosis pointer' code='#{diagnosis.code}' description='#{diagnosis.description}' group_code='#{diagnosis.group_code}' group_description='#{diagnosis.group_description}' group_name='#{diagnosis.group_name}' chapter='#{diagnosis.chapter}' type='#{diagnosis.type}' congenital='#{diagnosis.congenital}' exclusion='#{diagnosis.exclusion_type}' coverages='#{coverages}' id='show_diagnosis_modal' diagnosisId='#{diagnosis.id}'>#{diagnosis.code}</a>"

    # "<a target='_blank' href='/diseases'>#{diagnosis.code}</a>"
  end

  defp order_datatable(query, nil, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([d, ed, e, dc, c], asc: d.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([d, ed, e, dc, c], asc: d.description)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([d, ed, e, dc, c], desc: d.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([d, ed, e, dc, c], desc: d.description)

  def initialize_query(exclusion_id) do
    # Sets initial query of the table.

    # ExclusionDisease
    PayorProcedure
    |> join(:left, [pp], ep in ExclusionProcedure, pp.id == ep.procedure_id)
    |> join(:left, [pp, ep], e in Exclusion, ep.exclusion_id == e.id)
    |> where([pp, ep, e], e.id == ^exclusion_id)
  end
end

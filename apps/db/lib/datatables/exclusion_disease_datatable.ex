defmodule Innerpeace.Db.Datatables.ExclusionDiseaseDatatable do
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
    Schemas.ExclusionDisease,
    Schemas.DiagnosisCoverage,
    Schemas.Coverage
  }

  def insert_diagnosis_exclusion(offset, limit, search_value, order, id) do
    initialize_query(id)
    |> where([d, ed, e, dc, c], ed.exclusion_id == ^id)

    |> where([d, ed, e, dc, c],
             ilike(d.code, ^"%#{search_value}%") or
             ilike(d.description, ^"%#{search_value}%")
    )
    |> order_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> group_by([d, ed, e, dc, c], [d.id])
    # |> distinct([d], d.code)
    |> select([d, ed, e, dc, c], %{
      id: d.id,
      code: d.code,
      description: d.description,
      group_code: d.group_code,
      group_description: d.group_description,
      group_name: d.group_name,
      chapter: d.chapter,
      type: d.type,
      congenital: d.congenital,
      exclusion_type: d.exclusion_type,
      coverages: fragment("string_agg(DISTINCT CONCAT(?), ', ')", c.name)
      })
    |> Repo.all()
    |> insert_table_cols([])
  end

  def disease_count(id) do
    initialize_query(id)
    |> select([d, ed, e, dc, c], count(d.code, :distinct))
    |> Repo.one()
  end

  def get_disease_filtered_count(search_value, id) do
    Diagnosis
    |> join(:left, [d], ed in ExclusionDisease, d.id == ed.disease_id)
    |> join(:left, [d, ed], e in Exclusion, ed.exclusion_id == e.id)
    |> where([d, ed, e], e.id == ^id)
    |> where([d, ed, e],
             ilike(d.code, ^"%#{search_value}%") or
             ilike(d.description, ^"%#{search_value}%")
    )
    |> select([d, ed, e, dc, c], count(d.code, :distinct))
    |> Repo.one()
  end

  defp insert_table_cols([head | tails], tbl) do

    coverages =
      DiagnosisCoverage
      |> where([dc], dc.diagnosis_id == ^head.id)
      |> join(:left, [dc], c in Coverage, dc.coverage_id == c.id)
      |> select([dc, c], c.name)
      |> Repo.all()
      |> Enum.sort()
      |> Enum.join(",")

    tbl =
      tbl ++
        [
          [
            generate_link(head, coverages),
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
    Diagnosis
    |> join(:left, [d], ed in ExclusionDisease, d.id == ed.disease_id)
    |> join(:left, [d, ed], e in Exclusion, ed.exclusion_id == e.id)
    |> join(:left, [d, ed, e], dc in DiagnosisCoverage, d.id == dc.diagnosis_id)
    |> join(:left, [d, ed, e, dc], c in Coverage, dc.coverage_id == c.id)
    |> where([d, ed, e, dc, c], e.id == ^exclusion_id)
  end
end
defmodule Innerpeace.Db.Datatables.BenefitDatatable do
  @moduledoc """
    Index Table
      Rows:
        Code,
        Name,
        Created by,
        Date Created,
        Updated by,
        Date Updated,
        Coverages
  """

  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Benefit,
    Schemas.BenefitPackage,
    Schemas.BenefitProcedure,
    Schemas.BenefitDiagnosis,
    Schemas.Diagnosis,
    Schemas.PayorProcedure,
    Schemas.PackagePayorProcedure,
    Schemas.BenefitCoverage,
    Schemas.Coverage,
    Schemas.Procedure,
    Schemas.User
  }

  def benefit_count do
    # Returns total count of data without filter and search value.

    initialize_query
    |> select([b, cb, c, u, uu], count(b.id, :distinct))
    |> Repo.one()
  end

  def benefit_data(
    offset,
    limit,
    search_value,
    order
  ) do
    # Returns table data according to table's offset and limit.

    initialize_query
    |> where([b, cb, c, u, uu],
      ilike(b.code, ^"%#{search_value}%") or
      ilike(b.name, ^"%#{search_value}%") or
      ilike(c.name, ^"%#{search_value}%") or
      ilike(u.username, ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.updated_at), ^"%#{search_value}%") or
      ilike(uu.username, ^"%#{search_value}%")
    )
    |> select([b, cb, c, u, uu], %{
      code: b.code,
      name: b.name,
      created_by: u.username,
      inserted_at: b.inserted_at,
      updated_by: uu.username,
      updated_at: b.updated_at,
      step: b.step,
      id: b.id,
      coverages: c.name
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
    search_value
  ) do
    # Returns count of data filtered according to search value, type, and added id.

    initialize_query
    |> where([b, cb, c, u, uu],
      ilike(b.code, ^"%#{search_value}%") or
      ilike(b.name, ^"%#{search_value}%") or
      ilike(c.name, ^"%#{search_value}%") or
      ilike(u.username, ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.inserted_at), ^"%#{search_value}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", b.updated_at), ^"%#{search_value}%") or
      ilike(uu.username, ^"%#{search_value}%")
    )
    |> select([b, cb, c, u, uu], count(b.id, :distinct))
    |> Repo.one()
  end

  defp initialize_query do
    # Sets initial query of the table.

    Benefit
    |> join(:left, [b], cb in BenefitCoverage, b.id == cb.benefit_id)
    |> join(:left, [b, cb], c in Coverage, cb.coverage_id == c.id)
    |> join(:left, [b, cb, c], u in User, b.created_by_id == u.id)
    |> join(:left, [b, cb, c, u], uu in User, b.updated_by_id == uu.id)
  end

  defp insert_table_cols([head | tails], tbl) do

    coverages =
      BenefitCoverage
      |> where([bc], bc.benefit_id == ^head.id)
      |> join(:left, [bc], c in Coverage, bc.coverage_id == c.id)
      |> select([bc, c], c.name)
      |> Repo.all()
      |> Enum.join(", ")

    link = generate_benefit_link(head.id, head.step, head.code, head.coverages)

    tbl =
      tbl ++
        [
          [
            link,
            head.name,
            head.created_by,
            NaiveDateTime.to_date(head.inserted_at),
            head.updated_by,
            NaiveDateTime.to_date(head.updated_at),
            coverages
          ]
        ]

    insert_table_cols(tails, tbl)
  end

  defp insert_table_cols([], tbl), do: tbl

  defp generate_benefit_link(id, step, code, coverages) when step == 1,
    do:
      "<a href='#' data-csrf='#{CSRFProtection.get_csrf_token()}' data-method='post' data-to='/web/benefits/new?id=#{
        id
      }'>#{code} (Draft)</a>"

  defp generate_benefit_link(id, step, code, coverages) when coverages == "Dental", do: "<a href='/web/benefits/#{code}/view'>#{code}</a>"

  # Change link for vue js show page
  # defp generate_benefit_link(id, step, code, coverages),  do: "<a href='/web/benefits/#{id}'>#{code}</a>"
  defp generate_benefit_link(id, step, code, coverages),  do: "<a href='/web/benefits/#{code}/show'>#{code}</a>"

  defp order_datatable(query, nil, _), do: query
  defp order_datatable(query, _, nil), do: query

  # Ascending
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: b.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: u.username)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: b.inserted_at)
  defp order_datatable(query, column, order) when column == "4" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: uu.username)
  defp order_datatable(query, column, order) when column == "5" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: b.updated_at)
  defp order_datatable(query, column, order) when column == "6" and order == "asc", do: query |> order_by([b, cb, c, u, uu], asc: c.name)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: b.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: b.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: u.username)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: b.inserted_at)
  defp order_datatable(query, column, order) when column == "4" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: uu.username)
  defp order_datatable(query, column, order) when column == "5" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: b.updated_at)
  defp order_datatable(query, column, order) when column == "6" and order == "desc", do: query |> order_by([b, cb, c, u, uu], desc: c.name)

  def get_benefit_procedure_count(benefit_id) do
    BenefitProcedure
    |> join(:left, [bp], pp in PayorProcedure, pp.id == bp.procedure_id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> select([bp, pp], count(pp.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_procedure_filtered_count(search_value, benefit_id) do
    BenefitProcedure
    |> join(:left, [bp], pp in PayorProcedure, pp.id == bp.procedure_id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, pp], count(pp.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_procedure(
    offset,
    limit,
    search_value,
    order,
    benefit_id
  ) do

    BenefitProcedure
    |> join(:left, [bp], pp in PayorProcedure, pp.id == bp.procedure_id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, pp], %{id: pp.id, code: pp.code, description: pp.description})
    |> order_bp_datatable2(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols_procedure([])
  end

  defp insert_table_cols_procedure([head | tails], tbl) do
    link = generate_benefit_diagnosis_link(head.id, head.code)
    tbl =
      tbl ++
        [
          [
            link,
            head.description
          ]
        ]
    insert_table_cols_procedure(tails, tbl)
  end
  defp insert_table_cols_procedure([], tbl), do: tbl
  defp generate_benefit_diagnosis_link(id, code), do: "<a class='' href='#'>#{code}</a>"
  # Ascending
  defp order_bp_datatable2(query, nil, _), do: query |> order_by([bp, pp], asc: pp.code)
  defp order_bp_datatable2(query, _, nil), do: query |> order_by([bp, pp], asc: pp.code)

  defp order_bp_datatable2(query, column, order) when column == "0" and order == "asc", do: query |> order_by([bp, pp], asc: pp.code)
  defp order_bp_datatable2(query, column, order) when column == "1" and order == "asc", do: query |> order_by([bp, pp], asc: pp.description)

  # Descending
  defp order_bp_datatable2(query, column, order) when column == "0" and order == "desc", do: query |> order_by([bp, pp], desc: pp.code)
  defp order_bp_datatable2(query, column, order) when column == "1" and order == "desc", do: query |> order_by([bp, pp], desc: pp.description)

  def get_benefit_diagnosis_count(benefit_id) do
    BenefitDiagnosis
    |> join(:left, [bd], d in Diagnosis, bd.diagnosis_id == d.id)
    |> where([bd, d], bd.benefit_id == ^benefit_id)
    |> select([bd, d], count(bd.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_diagnosis_filtered_count(search_value, benefit_id) do
    BenefitDiagnosis
    |> join(:left, [bd], d in Diagnosis, bd.diagnosis_id == d.id)
    |> where([bd, d], bd.benefit_id == ^benefit_id)
    |> where([bd, d],
      ilike(d.code, ^"%#{search_value}%") or
      ilike(d.description, ^"%#{search_value}%")
    )
    |> select([bd, d], count(bd.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_diagnosis(
    offset,
    limit,
    search_value,
    order,
    benefit_id
  ) do

    BenefitDiagnosis
    |> join(:left, [bd], d in Diagnosis, bd.diagnosis_id == d.id)
    |> where([bd, d], bd.benefit_id == ^benefit_id)
    |> where([bd, d],
      ilike(d.code, ^"%#{search_value}%") or
      ilike(d.description, ^"%#{search_value}%")
    )
    |> select([bd, d], %{id: d.id, code: d.code, description: d.description})
    |> order_benefitdiagnosis_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols_diagnosis([])
  end

  defp insert_table_cols_diagnosis([], tbl), do: tbl
  defp insert_table_cols_diagnosis([head | tails], tbl) do
    link = generate_benefit_diagnosis_link(head.id, head.code)
    tbl =
      tbl ++
        [
          [
            link,
            head.description
          ]
        ]
    insert_table_cols_diagnosis(tails, tbl)
  end

  defp generate_benefit_diagnosis_link(id, code), do: "<a class='show-diagnosis-details' href='#'>#{code}</a>"
  # Ascending
  defp order_benefitdiagnosis_datatable(query, nil, _), do: query |> order_by([bd, d], asc: d.code)
  defp order_benefitdiagnosis_datatable(query, _, nil), do: query |> order_by([bd, d], asc: d.code)

  defp order_benefitdiagnosis_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([bd, d], asc: d.code)
  defp order_benefitdiagnosis_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([bd, d], asc: d.description)

  # Descending
  defp order_benefitdiagnosis_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([bd, d], desc: d.code)
  defp order_benefitdiagnosis_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([bd, d], desc: d.description)

  def get_benefit_dental_procedure_count(benefit_id) do
    BenefitPackage
    |> join(:inner, [bp], ppp in PackagePayorProcedure, bp.package_id == ppp.package_id)
    |> join(:inner, [bp, ppp], pp in PayorProcedure, ppp.payor_procedure_id == pp.id)
    |> where([bp, ppp, pp], bp.benefit_id == ^benefit_id)
    |> select([bp, ppp, pp], count(pp.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_dental_procedure_filtered_count(search_value, benefit_id) do
    BenefitPackage
    |> join(:inner, [bp], ppp in PackagePayorProcedure, bp.package_id == ppp.package_id)
    |> join(:inner, [bp, ppp], pp in PayorProcedure, ppp.payor_procedure_id == pp.id)
    |> where([bp, ppp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, ppp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, ppp, p], count(p.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_dental_procedure(
    offset,
    limit,
    search_value,
    order,
    benefit_id
  ) do

    BenefitPackage
    |> join(:inner, [bp], ppp in PackagePayorProcedure, bp.package_id == ppp.package_id)
    |> join(:inner, [bp, ppp], pp in PayorProcedure, ppp.payor_procedure_id == pp.id)
    |> where([bp, ppp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, ppp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, ppp, pp], %{id: pp.id, code: pp.code, description: pp.description})
    |> order_bp_datatable_dental(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols_dental_procedure([])
  end

  defp insert_table_cols_dental_procedure([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            head.code,
            head.description
          ]
        ]
    insert_table_cols_dental_procedure(tails, tbl)
  end
  defp insert_table_cols_dental_procedure([], tbl), do: tbl

  # Ascending
  defp order_bp_datatable_dental(query, nil, _), do: query |> order_by([bp, ppp, pp], asc: pp.code)
  defp order_bp_datatable_dental(query, _, nil), do: query |> order_by([bp, ppp, pp], asc: pp.code)

  defp order_bp_datatable_dental(query, column, order) when column == "0" and order == "asc", do: query |> order_by([bp, ppp, pp], asc: pp.code)
  defp order_bp_datatable_dental(query, column, order) when column == "1" and order == "asc", do: query |> order_by([bp, ppp, pp], asc: pp.description)

  # Descending
  defp order_bp_datatable_dental(query, column, order) when column == "0" and order == "desc", do: query |> order_by([bp, ppp, pp], desc: pp.code)
  defp order_bp_datatable_dental(query, column, order) when column == "1" and order == "desc", do: query |> order_by([bp, ppp, pp], desc: pp.description)

  def get_dental_benefit_procedure_count(benefit_id) do
    BenefitProcedure
    |> join(:inner, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> select([bp, pp], count(pp.id, :distinct))
    |> Repo.one()
  end

  def get_dental_benefit_procedure(
    offset,
    limit,
    search_value,
    order,
    benefit_id
  ) do

    BenefitProcedure
    |> join(:inner, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, pp], %{id: pp.id, code: pp.code, description: pp.description})
    |> order_dental_benefit_procedure(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_table_cols_dental_benefit_procedure([])
  end

  defp insert_table_cols_dental_benefit_procedure([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            head.code,
            head.description
          ]
        ]

    insert_table_cols_dental_benefit_procedure(tails, tbl)
  end

  defp insert_table_cols_dental_benefit_procedure([], tbl), do: tbl

  #if is_nil
  defp order_dental_benefit_procedure(query, nil, _), do: query |> order_by([bp, pp], asc: pp.code)
  defp order_dental_benefit_procedure(query, _, nil), do: query |> order_by([bp, pp], asc: pp.code)

  #Ascending
  defp order_dental_benefit_procedure(query, column, order) when column == "0" and order == "asc", do: query |> order_by([bp, pp], asc: pp.code)
  defp order_dental_benefit_procedure(query, column, order) when column == "1" and order == "asc", do: query |> order_by([bp, pp], asc: pp.description)

  #Descending
  defp order_dental_benefit_procedure(query, column, order) when column == "0" and order == "desc", do: query |> order_by([bp, pp], desc: pp.code)
  defp order_dental_benefit_procedure(query, column, order) when column == "1" and order == "desc", do: query |> order_by([bp, pp], desc: pp.description)

  def get_dental_benefit_procedure_filtered_count(search_value, benefit_id) do
    BenefitProcedure
    |> join(:inner, [bp], pp in PayorProcedure, bp.procedure_id == pp.id)
    |> where([bp, pp], bp.benefit_id == ^benefit_id)
    |> where([bp, pp],
      ilike(pp.code, ^"%#{search_value}%") or
      ilike(pp.description, ^"%#{search_value}%")
    )
    |> select([bp, pp], count(pp.id, :distinct))
    |> Repo.one()
  end

end

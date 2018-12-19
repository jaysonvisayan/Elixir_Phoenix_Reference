defmodule Innerpeace.Db.Datatables.BenefitDatatableV2 do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Benefit,
    BenefitLimit,
    BenefitPackage,
    Package,
    BenefitCoverage,
    Coverage,
    User
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  def get_benefits(offset, limit, params) do
    initialize_query()
    |> where([b, cb, c, u, uu],
        ilike(b.code, ^"%#{params}%") or
        ilike(b.name, ^"%#{params}%") or
        ilike(c.name, ^"%#{params}%") or
        ilike(u.username, ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", b.inserted_at), ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", b.updated_at), ^"%#{params}%") or
        ilike(uu.username, ^"%#{params}%")
      )
    |> select([b, cb, c, u, uu], %{
        code: b.code,
        name: b.name,
        created_by: u.username,
        inserted_at: b.inserted_at,
        updated_by: uu.username,
        updated_at: b.updated_at,
        step: b.step,
        id: b.id
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_benefit_cols([])
  end

  def get_benefits_count(params) do
    initialize_query()
    |> where([b, cb, c, u, uu],
        ilike(b.code, ^"%#{params}%") or
        ilike(b.name, ^"%#{params}%") or
        ilike(c.name, ^"%#{params}%") or
        ilike(u.username, ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", b.inserted_at), ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", b.updated_at), ^"%#{params}%") or
        ilike(uu.username, ^"%#{params}%")
      )
    |> select([b, cb, c, u, uu], count(b.id))
    |> Repo.one()
  end

  defp convert_to_tbl_benefit_cols([head | tails], tbl) do
    link = generate_benefit_link(head.id, head.step, head.code)

    coverages =
      BenefitCoverage
      |> where([bc], bc.benefit_id == ^head.id)
      |> join(:left, [bc], c in Coverage, bc.coverage_id == c.id)
      |> select([bc, c], c.name)
      |> Repo.all()
      |> Enum.join(", ")

    tbl =
      tbl ++
        [
          [
            link,
            head.name,
            head.created_by,
            UtilityContext.convert_date_format(head.inserted_at),
            head.updated_by,
            UtilityContext.convert_date_format(head.updated_at),
            coverages
          ]
        ]

    convert_to_tbl_benefit_cols(tails, tbl)
  end

  defp convert_to_tbl_benefit_cols([], tbl), do: tbl

  defp generate_benefit_link(id, step, code) when step >= 1,
    do:
      "<a href='/benefits/#{id}/setup?step=#{step}'>#{code} (Draft)</a>"

  defp generate_benefit_link(id, step, code),
    do: "<a href='/benefits/#{id}'>#{code}</a> "

  defp initialize_query do
    # Sets initial query of the table.

    Benefit
    |> join(:left, [b], cb in BenefitCoverage, b.id == cb.benefit_id)
    |> join(:left, [b, cb], c in Coverage, cb.coverage_id == c.id)
    |> join(:left, [b, cb, c], u in User, b.created_by_id == u.id)
    |> join(:left, [b, cb, c, u], uu in User, b.updated_by_id == uu.id)
  end

  def get_benefit_package_count(benefit_id) do
    BenefitPackage
    |> where([bp], bp.benefit_id == ^benefit_id)
    |> select([bp], count(bp.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_package_filtered_count(search_value, benefit_id) do
    Package
    |> join(:inner, [p], bp in BenefitPackage, p.id == bp.package_id)
    |> where([p, bp], bp.benefit_id == ^benefit_id)
    |> where([p, bp],
      ilike(p.code, ^"%#{search_value}%") or
      ilike(p.name, ^"%#{search_value}%") or
      ilike(fragment("CONCAT(?, ' - ', ?)", bp.age_from, bp.age_to), ^"%#{search_value}%") or
      ilike(fragment("CONCAT((CASE WHEN ? = true THEN 'M' ELSE NULL END), '/', (CASE WHEN ? = true THEN 'F' ELSE NULL END))",bp.male, bp.female), ^"%#{search_value}%")
    )
    |> select([p], count(p.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_package(offset, limit, search_value, order, benefit_id) do
    Package
    |> join(:inner, [p], bp in BenefitPackage, p.id == bp.package_id)
    |> where([p, bp], bp.benefit_id == ^benefit_id)
    |> where([p, bp],
      ilike(p.code, ^"%#{search_value}%") or
      ilike(p.name, ^"%#{search_value}%") or
      ilike(fragment("CONCAT(?, ' - ', ?)", bp.age_from, bp.age_to), ^"%#{search_value}%") or
      ilike(fragment("CONCAT((CASE WHEN ? = true THEN 'M' ELSE NULL END), '/', (CASE WHEN ? = true THEN 'F' ELSE NULL END))",bp.male, bp.female), ^"%#{search_value}%")
    )
    |> select([p, bp],
      %{
        id: p.id,
        code: p.code,
        name: p.name,
        male: bp.male,
        female: bp.female,
        age_from: bp.age_from,
        age_to: bp.age_to
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
            generate_benefit_package_link(head.id, head.code),
            head.name,
            check_gender(head.male, head.female),
            check_age(head.age_from, head.age_to)
          ]
        ]
    insert_table_cols(tails, tbl)
  end

  defp check_age(age_from, age_to) do
    if is_nil(age_from) or is_nil(age_to) do
      "Na"
    else
      "#{age_from} - #{age_to}"
    end
  end

  defp insert_table_cols([], tbl), do: tbl

  defp generate_benefit_package_link(id, code) do
      "<a href='/packages/#{id}/summary'>#{code}</a>"
  end
  # Ascending
  defp order_datatable(query, nil, _), do: query |> order_by([p], asc: p.code)
  defp order_datatable(query, _, nil), do: query |> order_by([p], asc: p.code)
  defp order_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([p, bp], asc: p.code)
  defp order_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([p, bp], asc: p.name)
  defp order_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([p, bp], asc: bp.age_from)
  defp order_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([p, bp], asc: bp.male)

  # Descending
  defp order_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([p, bp], desc: p.code)
  defp order_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([p, bp], desc: p.name)
  defp order_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([p, bp], desc: bp.age_from)
  defp order_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([p, bp], desc: bp.male)

  defp check_gender(male, female) do
    gender = [male, female]
    case gender do
       [true, true] ->
         ["M/F"]
      [false, true] ->
        ["F"]
      ["false, false"] ->
        [""]
      [true, false] ->
        ["M"]
      _ ->
        ["Na"]
    end
  end

  def get_benefit_limit_count(benefit_id) do
    BenefitLimit
    |> where([bl], bl.benefit_id == ^benefit_id)
    |> select([bl], count(bl.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_limit_filtered_count(search_value, benefit_id) do
    BenefitLimit
    |> where([bl], bl.benefit_id == ^benefit_id)
    |> where([bl],
      ilike(bl.coverages, ^"%#{search_value}%") or
      ilike(bl.limit_type, ^"%#{search_value}%") or
      ilike(fragment("CONCAT('Php.',CAST (? as text))", bl.limit_amount), ^"%#{search_value}%") or
      ilike(fragment("CAST (? as text)", bl.limit_session), ^"%#{search_value}%") or
      ilike(fragment("CONCAT(CAST (? as text),'%')", bl.limit_percentage), ^"%#{search_value}%") or
      ilike(bl.limit_classification, ^"%#{search_value}%")
    )
    |> select([bl], count(bl.id, :distinct))
    |> Repo.one()
  end

  def get_benefit_limit(offset, limit, search_value, order, benefit_id) do
    BenefitLimit
    |> where([bl], bl.benefit_id == ^benefit_id)
    |> where([bl],
      ilike(bl.coverages, ^"%#{search_value}%") or
      ilike(bl.limit_type, ^"%#{search_value}%") or
      ilike(fragment("CONCAT('Php.',CAST (? as text))", bl.limit_amount), ^"%#{search_value}%") or
      ilike(fragment("CAST (? as text)", bl.limit_session), ^"%#{search_value}%") or
      ilike(fragment("CONCAT(CAST (? as text),'%')", bl.limit_percentage), ^"%#{search_value}%") or
      ilike(bl.limit_classification, ^"%#{search_value}%")
    )
    |> select([bl],
      %{
        id: bl.id,
        coverages: bl.coverages,
        limit_type: bl.limit_type,
        limit_session: bl.limit_session,
        limit_amount: bl.limit_amount,
        limit_percentage: bl.limit_percentage,
        limit_classification: bl.limit_classification
      }
    )
    |> order_limit_datatable(
      order["column"],
      order["dir"]
    )
    |> offset(^offset)
    |> limit(^limit)
    |> distinct(true)
    |> Repo.all()
    |> insert_bl_table_cols([])
  end

  defp insert_bl_table_cols([head | tails], tbl) do
    tbl =
      tbl ++
        [
          [
            check_coverages(head.coverages),
            head.limit_type,
            check_limit(head)
            # head.limit_classification
        ]
    ]
    insert_bl_table_cols(tails, tbl)
  end

  defp check_coverages(nil), do: ""
  defp check_coverages(coverages) do
    coverages
    |> String.split(", ")
    |> Enum.map(fn(coverage) ->
      case coverage do
        "MTRNTY" ->
           "Maternity"
        "OPT" ->
          "Optical"
        "MED" ->
          "Medicine"
        "OPMED" ->
          "OP Medicine"
        "CNCR" ->
          "Cancer"
        "OP" ->
          "Out Patient"
        "IP" ->
          "Inpatient"
        "OPL" ->
          "OP Laboratory"
        "OPC" ->
          "OP Consult"
        "EMRGNCY" ->
          "Emergency"
        "POS" ->
          "Point of Service"
        "GRPLIFE" ->
          "Group Life"
        "LOD" ->
          "List of Doctors"
        "LIFE" ->
          "Life ADD&D"
        _ ->
          coverage
      end
    end)
    |> Enum.join(", ")
  end

  defp check_limit(nil), do: ""
  defp check_limit(head) do
    case head.limit_type do
      "Plan Limit Percentage" ->
        check_limit_percentage(head.limit_percentage)
      "Peso" ->
        check_limit_amount("#{head.limit_amount}")
      "Sessions" ->
            head.limit_session
      "Tooth" ->
        "#{head.limit_tooth} Tooth"
      "Quadrant" ->
        "#{head.limit_quadrant} Quadrant"

      _ ->
        ""
    end
  end

  defp get_amount(_, nil), do: 0
  defp get_amount(true, value) do
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

  defp get_amount(false, nil), do: 0
  defp get_amount(false, ""), do: 0
  defp get_amount(false, value) do
    value
    |> String.to_integer
    |> Integer.to_char_list
    |> Enum.reverse
    |> Enum.chunk(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
  end

  defp check_limit_amount(nil), do: nil
  defp check_limit_amount(limit_amount) do
    amount = get_amount(String.contains?(limit_amount, "."), limit_amount)
  end

  defp check_limit_percentage(nil), do: nil
  defp check_limit_percentage(limit_percentage), do: "#{limit_percentage}%"

  defp insert_bl_table_cols([], tbl), do: tbl

  # Ascending
  defp order_limit_datatable(query, nil, _), do: query |> order_by([bl], asc: bl.coverages)
  defp order_limit_datatable(query, _, nil), do: query |> order_by([bl], asc: bl.coverages)
  defp order_limit_datatable(query, column, order) when column == "0" and order == "asc", do: query |> order_by([bl], asc: bl.coverages)
  defp order_limit_datatable(query, column, order) when column == "1" and order == "asc", do: query |> order_by([bl], asc: bl.limit_type)
  defp order_limit_datatable(query, column, order) when column == "2" and order == "asc", do: query |> order_by([bl], [asc: bl.limit_session, asc: bl.limit_percentage, asc: bl.limit_amount])
  defp order_limit_datatable(query, column, order) when column == "3" and order == "asc", do: query |> order_by([bl], asc: bl.limit_classification)

  # Descending
  defp order_limit_datatable(query, column, order) when column == "0" and order == "desc", do: query |> order_by([bl], desc: bl.coverages)
  defp order_limit_datatable(query, column, order) when column == "1" and order == "desc", do: query |> order_by([bl], desc: bl.limit_type)
  defp order_limit_datatable(query, column, order) when column == "2" and order == "desc", do: query |> order_by([bl], [desc: bl.limit_session, desc: bl.limit_percentage, desc: bl.limit_amount])
  defp order_limit_datatable(query, column, order) when column == "3" and order == "desc", do: query |> order_by([bl], desc: bl.limit_classification)
end

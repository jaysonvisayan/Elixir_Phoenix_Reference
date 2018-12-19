defmodule Innerpeace.Db.Datatables.PackageDatatable do

  @moduledoc """
    View Package Table
      Rows:
        Code,
        Name
  """
  import Ecto.Query
  alias Plug.CSRFProtection
  alias Innerpeace.Db.{
    Repo,
    Schemas.Package,
    Schemas.Benefit,
    Schemas.BenefitPackage
  }

  def view_package_count(benefit_id) do
    intialize_query
    |> where([p, bp, b], b.id == ^benefit_id)
    |> select([p, bp, b], count(b.id))
    |> Repo.one()
  end

  def view_package_data(offset, benefit_id, limit, search_value) do

    intialize_query
    |> where([p, bp, b], b.id == ^benefit_id)
    |> where([p, bp, b], ilike(p.code, ^"%#{search_value}%") or ilike(p.name, ^"%#{search_value}%"))
    |> select([p, bp, b], %{
        id: p.id,
        code: p.code,
        name: p.name
    })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> insert_table_cols([])
  end

  def view_package_filtered_count(search_value, benefit_id) do
    intialize_query
    |> where([p, bp, b],
        ilike(p.code, ^"%#{search_value}%") or
        ilike(p.name, ^"%#{search_value}%")
    )
    |> where([p, bp, b], b.id == ^benefit_id)
    |> select([p, bp, b], count(b.id))
    |> Repo.one()
  end

  defp insert_table_cols([head | tails], tbl) do
    link = generate_package_link(head.id, head.code)

    tbl =
        tbl ++
            [
                [
                  link,
                  head.code,
                  head.name
                ]
            ]

    insert_table_cols(tails, tbl)
   end

  defp insert_table_cols([], tbl), do: tbl

  defp generate_package_link(id, code), do: "<a href='/packages/#{id}/summary'>#{code}</a>"

  defp intialize_query do
    Package
    |> join(:inner, [p], bp in BenefitPackage, p.id == bp.package_id)
    |> join(:inner, [p, bp], b in Benefit, bp.benefit_id == b.id)
  end

end

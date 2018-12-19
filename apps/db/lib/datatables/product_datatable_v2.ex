defmodule Innerpeace.Db.Datatables.ProductDatatableV2 do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Product,
    User
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  def list_all_products do
    Product
    |> select([p], %{
        id: p.id, code: p.code, name: p.name,
        description: p.description, standard_product: p.standard_product,
        inserted_at: p.inserted_at,
        updated_at: p.updated_at, step: p.step
      })
    |> offset(0)
    |> limit(10)
    |> Repo.all()
  end

  def get_products(offset, limit, params) do
    Product
    |> join(:left, [p], u in User, u.id == p.created_by_id)
    |> join(:left, [p, u], uu in User, uu.id == p.updated_by_id)
    |> where([p, u, uu],
        ilike(u.username, ^"%#{params}%") or
        ilike(uu.username, ^"%#{params}%") or
        ilike(p.code, ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", p.inserted_at), ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", p.updated_at), ^"%#{params}%") or
        ilike(p.name, ^"%#{params}%"))
    |> order_by([p, u, uu], p.code)
    |> select([p, u, uu], %{
        id: p.id, code: p.code, name: p.name,
        description: p.description, standard_product: p.standard_product,
        created_by: u.username, updated_by: u.username, inserted_at: p.inserted_at,
        updated_at: p.updated_at, step: p.step
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_product_cols([])
  end

  def get_products_count(params) do
    Product
    |> join(:left, [p], u in User, u.id == p.created_by_id)
    |> join(:left, [p, u], uu in User, uu.id == p.updated_by_id)
    |> where([p, u, uu],
        ilike(u.username, ^"%#{params}%") or
        ilike(uu.username, ^"%#{params}%") or
        ilike(p.code, ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", p.inserted_at), ^"%#{params}%") or
        ilike(fragment("to_char(?, 'Mon DD, YYYY')", p.updated_at), ^"%#{params}%") or
        ilike(p.name, ^"%#{params}%"))
    |> select([p, u, uu], count(p.id))
    |> Repo.one()
  end

  defp convert_to_tbl_product_cols([head | tails], tbl) do
    link = generate_product_link(head.id, head.step, head.code)
    classification = if head.standard_product == "Yes", do: "Standard", else: "Custom"

    tbl =
      tbl ++
        [
          [
            link,
            head.name,
            head.description,
            classification,
            head.created_by,
            UtilityContext.convert_date_format(head.inserted_at),
            head.updated_by,
            UtilityContext.convert_date_format(head.updated_at)
          ]
        ]

    convert_to_tbl_product_cols(tails, tbl)
  end

  defp convert_to_tbl_product_cols([], tbl), do: tbl

  defp generate_product_link(id, step, code) when step < "5",
    do:
      "<a href='/products/#{id}/setup?step=#{step}'>#{code} (Draft)</a>"

  defp generate_product_link(id, step, code), do: "<a href='/products/#{id}'>#{code}</a> "

end

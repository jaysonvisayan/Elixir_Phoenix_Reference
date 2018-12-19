defmodule Innerpeace.Db.Datatables.FacilityDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Facility
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  def list_all_facility do
    Facility
    |> select([f], %{
        id: f.id, code: f.code, name: f.name,
        affiliation_date: f.affiliation_date, disaffiliation_date: f.disaffiliation_date,
        step: f.step, status: f.status
      })
    |> offset(0)
    |> limit(10)
    |> Repo.all()
  end

  def get_facilities(offset, limit, params) do
    Facility
    |> where([f],
      ilike(f.code, ^"%#{params}%") or
      ilike(f.name, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", f.affiliation_date), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", f.disaffiliation_date), ^"%#{params}%") or
      ilike(f.status, ^"%#{params}%"))
    |> order_by([f], f.code)
    |> select([f], %{
        id: f.id, code: f.code, name: f.name,
        affiliation_date: f.affiliation_date, disaffiliation_date: f.disaffiliation_date,
        step: f.step, status: f.status
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_facility_cols([])
  end

  def get_facilities_count(params) do
    Facility
    |> where([f],
      ilike(f.code, ^"%#{params}%") or
      ilike(f.name, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", f.affiliation_date), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", f.disaffiliation_date), ^"%#{params}%") or
      ilike(f.status, ^"%#{params}%"))
    |> select([a], count(a.id))
    |> Repo.one()
  end

  defp convert_to_tbl_facility_cols([head | tails], tbl) do
    tbl =
      tbl ++ [[
        Enum.join([head.name, head.id, head.step], "|"),
        head.code,
        UtilityContext.convert_date_format(head.affiliation_date),
        UtilityContext.convert_date_format(head.disaffiliation_date),
        head.status
      ]]

    convert_to_tbl_facility_cols(tails, tbl)
  end

  defp convert_to_tbl_facility_cols([], tbl), do: tbl

end

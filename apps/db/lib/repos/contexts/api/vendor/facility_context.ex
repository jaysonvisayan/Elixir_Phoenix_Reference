defmodule Innerpeace.Db.Base.Api.Vendor.FacilityContext do
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset

  @moduledoc false

  alias Innerpeace.Db.Base.Api.FacilityContext, as: MainApiFacilityContext
  alias Innerpeace.Db.Base.FacilityContext, as: MainWebFacilityContext

  def search_facility(params) do
    MainApiFacilityContext.search_facility(params)
  end

  def search_facility_by_location(params) do
    MainApiFacilityContext.search_facility_by_location(params)
  end

  def search_all_facility do
    MainApiFacilityContext.search_all_facility() |> Enum.map(fn(x) ->
      Enum.map(x.practitioner_facilities, fn(y) ->
        filter_pf(y, x)
      end)
    end)
    |> Enum.uniq()
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1)))
  end
  defp filter_pf(y, x), do: if y.practitioner_id != "", do: x

end

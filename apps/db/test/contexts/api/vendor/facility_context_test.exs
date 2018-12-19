defmodule Innerpeace.Db.Base.Api.Vendor.FacilityContextTest do
  @moduledoc false

  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.Api.Vendor.FacilityContext

  setup do
    facility =
      insert(
        :facility,
        code: "cmc",
        name: "CALAMBA MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23"
      )
    {:ok, %{facility: facility}}
  end

  test "search_facility/1 returns all facilities based on name or code" do
    params = %{
      "facility" => "calamba"
    }
    result = FacilityContext.search_facility(params)
    assert List.first(result).code == "cmc"
  end

end

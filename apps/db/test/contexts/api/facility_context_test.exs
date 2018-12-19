defmodule Innerpeace.Db.Base.Api.FacilityContextTest do
  use Innerpeace.Db.SchemaCase

  # alias Innerpeace.Db.Base.Api.{
  #   FacilityContext
  # }

  alias Innerpeace.Db.{
    Repo,
    Schemas.Facility,
    Base.Api.FacilityContext
  }

  test "get_facility_code_vendor_code/1, get facility code by vendor code with valid parameter" do
    facility = insert(:facility, vendor_code: "123")

    result = FacilityContext.get_facility_code_by_vendor_code("123")
    assert facility.code == result
  end

  test "get_facility_code_vendor_code/1, get facility code by vendor code with invalid parameter" do
    facility = insert(:facility, vendor_code: "123")

    result = FacilityContext.get_facility_code_by_vendor_code("456")
    refute facility.code == result
  end

  test "search_all_facility, load all facility with no parameter" do

    search_query = ""
    query = "%#{search_query}%"
    f_query = (
      from f in Facility,
      where: (ilike(f.name, ^query)
          or ilike(f.code, ^query)),
      select: f
    )

    f =
      f_query
      |> Repo.all
      |> Repo.preload([
        :type,
        :category,
        :vat_status,
        :prescription_clause,
        :payment_mode,
        :releasing_mode,
        [facility_files: :file],
        [
          facility_service_fees: [
            :coverage,
            :service_type
          ]
        ]
      ])

    facility = FacilityContext.search_all_facility()
    assert f == facility
  end

  test "get_facility_by_code/1 success" do
    insert(:facility, code: "code-101")
    refute is_nil(FacilityContext.get_facility_by_code("code-101"))
  end

  test "get_facility_by_code/1 failed" do
    assert is_nil(FacilityContext.get_facility_by_code("code-101"))
  end

end

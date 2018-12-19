defmodule Innerpeace.Db.Schemas.FileTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.File

  test "changeset with valud attributes" do
    params = %{
      name: "example_name"
    }
    changeset = File.changeset(%File{}, params)
    assert changeset.valid?
  end

  test "changeset_kyc_upload with valud attributes" do
    params = %{
      link: "www.medilink.com.ph",
      link_type: "sample_type",
      kyc_bank_id: "488412e1-1668-42b7-86d2-bd57f46678b6",
      name: "test123"
    }
    changeset = File.changeset_kyc_upload(%File{}, params)
    assert changeset.valid?
  end

end


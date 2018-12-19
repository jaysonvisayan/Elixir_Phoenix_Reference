defmodule Innerpeace.Db.Schemas.CoverageTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Coverage

   test "changeset with valid attributes" do
     params = %{
       code: "CODE",
       name: "some content",
       description: "some content",
       status: "some content",
       type: "some content"
     }

     changeset = Coverage.changeset(%Coverage{}, params)
     assert changeset.valid?
   end
end

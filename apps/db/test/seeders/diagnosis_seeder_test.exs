defmodule Innerpeace.Db.DiagnosisSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.DiagnosisSeeder
  @code "A00.0"
  @description "CHOLERA: Cholera due to Vibrio cholerae 01, biovar cholerae"
  @group_description "CHOLERA"
  @congenital "N"
  @exclusion_type "Exclusion"

  test "seed diagnosis with new data" do
    [a1] = DiagnosisSeeder.seed(data())
    assert a1.code == @code
  end

  test "seed user with existing data" do
    insert(:industry, code: @code)
    data = [
      %{
        code: "A00.0",
        description: "CHOLERA: Cholera due to Vibrio cholerae 01, biovar cholerae",
        group_description: "CHOLERA",
        type: "Dreaded",
        congenital: "N",
        exclusion_type: "Pre-existing condition"
      }
    ]
    [a1] = DiagnosisSeeder.seed(data)
    assert a1.code == "A00.0"
  end

  defp data do
    [
      %{
        code: @code,
        description: @description,
        group_description: @group_description,
        type: "Dreaded",
        congenital: @congenital,
        exclusion_type: @exclusion_type
      }
    ]
  end

end

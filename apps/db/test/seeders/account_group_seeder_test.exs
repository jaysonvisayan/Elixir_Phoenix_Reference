defmodule Innerpeace.Db.AccountGroupSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.AccountGroupSeeder

  test "test account group with new data" do
    industry = insert(:industry)
    [ag1] = AccountGroupSeeder.seed(data(industry))
    assert ag1.code == "CODE101"

  end

  test "test account group with existing data" do
    industry = insert(:industry)
    data = [
      %{
        name: "Account101",
        code: "CODE101",
        type: "Payor",
        description: "Test Description",
        segment: "Test Segment",
        security: "Test Security",
        phone_no: "",
        email: "f@medilink.com.ph",
        remarks: "d",
        #photo
        mode_of_payment: "",
        payee_name: "",
        account_no: "",
        account_name: "",
        branch: "",
        industry_id: industry.id,
        original_effective_date: Ecto.Date.cast!("2017-08-01")

      }
    ]
    [ag1] = AccountGroupSeeder.seed(data)
    assert ag1.code == "CODE101"

  end


  defp data(industry) do
    [
      %{
        name: "Account101",
        code: "CODE101",
        type: "Payor",
        description: "Test Description",
        segment: "Test Segment",
        security: "Test Security",
        phone_no: "",
        email: "f@medilink.com.ph",
        remarks: "d",
        #photo
        mode_of_payment: "",
        payee_name: "",
        account_no: "",
        account_name: "",
        branch: "",
        industry_id: industry.id,
        original_effective_date: Ecto.Date.cast!("2017-08-01")

      }
    ]

  end


end

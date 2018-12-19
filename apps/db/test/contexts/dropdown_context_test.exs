defmodule Innerpeace.Db.Base.DropdownContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.Dropdown

   # get_all_facility_type start
  test "return all facility types" do
    facility_type = insert(:dropdown, type: "Facility Type", text: "Hospital", value: "Hospital")
    assert get_all_facility_type() == [facility_type]
  end
  # get_all_facility_type end

  # get_all_facility_category start
  test "return all facility category" do
    insert(:dropdown, type: "Facility Category", text: "Tertiary", value: "Tertiaty")
    insert(:dropdown, type: "Facility Type", text: "Hospital", value: "Hospital")
    assert length(get_all_facility_category()) == 1
  end
  # get_all_facility_category end

  # get_all_vat_status start
  test "return all vat status" do
    insert(:dropdown, type: "Facility Category", text: "Tertiary", value: "Tertiaty")
    insert(:dropdown, type: "Facility Type", text: "Hospital", value: "Hospital")
    assert length(get_all_vat_status()) == 0
  end
  # get_all_vat_status end

  # get_all_prescription_clause start
  test "return all prescription clause" do
    prescription_clause = insert(:dropdown, type: "Prescription Clause", text: "Daily", value: "Daily")
    assert get_all_prescription_clause() == [prescription_clause]
  end
  # get_all_prescription_clause end

  # get_all_payment_mode start
  test "return all payment mode" do
    payment_mode = insert(:dropdown, type: "Payment Mode", text: "Daily", value: "Daily")
    assert get_all_payment_mode() == [payment_mode]
  end
  # get_all_payment_mode end

  # get_all_releasing_mode start
  test "return all releasing mode" do
    releasing_mode = insert(:dropdown, type: "Releasing Mode", text: "ADA", value: "ADA")
    assert get_all_releasing_mode() == [releasing_mode]
  end
  # get_all_releaseing_mode end

  test "get_dropdown_by_name! returns the dropdown with given name" do
    dropdown = insert(:dropdown, text: "Sample Text")
    assert get_dropdown_by_name(dropdown.text) == dropdown
  end

  test "get_dropdown * returns the dropdown with given id" do
    dropdown = insert(:dropdown, text: "Sample Text")
    assert get_dropdown(dropdown.id) == dropdown
  end

  test "create_dropdown * with valid data creates a dropdown" do
    insert(:dropdown, text: "20% VAT-able")
    params = %{
      type: "VAT Status",
      text: "20% VAT-able",
      value: "20% VAT-able"
    }
    assert {:ok, %Dropdown{}} = create_dropdown(params)
  end

  test "create_dropdown with invalid data returns error changeset" do
    params = %{
      type: ""
    }
     assert {:error, %Ecto.Changeset{}} = create_dropdown(params)
  end

  test "update_dropdown * with valid data updates the dropdown text" do
   dropdown = insert(:dropdown, text: "20% VAT-able")
    params = %{
      text: "30% VAT-able"
    }
    assert {:ok, %Dropdown{} = dropdown} = update_dropdown(dropdown.id, params)
    assert dropdown.text == "30% VAT-able"
  end

  test "update_dropdown with invalid data returns error changeset" do
    dropdown = insert(:dropdown)
    params = %{
      type: ""
    }
    assert {:error, %Ecto.Changeset{}} = update_dropdown(dropdown.id, params)
  end

  test "insert_or_update_dropdown * validates dropdown" do
    dropdown = insert(:dropdown, text: "20% VAT-able")
    get_dropdowns = get_dropdown_by_name(dropdown.text)

    if is_nil(get_dropdowns) do
      params = %{
      type: "VAT Status",
      text: "20% VAT-able",
      value: "20% VAT-able"
      }
      assert {:ok, %Dropdown{}} = create_dropdown(params)
    else
      params = %{
      text: "30% VAT-able"
      }
      assert {:ok, %Dropdown{} = dropdown} = update_dropdown(dropdown.id, params)
      assert dropdown.text == "30% VAT-able"
    end
  end
end

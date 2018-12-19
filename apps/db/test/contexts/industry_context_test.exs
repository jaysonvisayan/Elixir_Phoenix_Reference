defmodule Innerpeace.Db.Base.IndustryContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.Industry
  alias Innerpeace.Db.Base.IndustryContext

  @invalid_attrs %{}

  test "lists all industry" do
    industry = insert(:industry, code: "test")
    assert IndustryContext.get_all_industry() == [industry]
  end

  test "get_industry returns the industry with given id" do
    industry = insert(:industry, code: "test")
    assert IndustryContext.get_industry(industry.id) == industry
  end

  test "create_industry with valid data creates an industry" do
    params = %{
      code: "TEST"
    }
    assert {:ok, %Industry{} = industry} = IndustryContext.create_industry(params)
    assert industry.code == "TEST"
  end

  test "create_industry with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = IndustryContext.create_industry(@invalid_attrs)
  end

  test "update_industry with valid data updates the industry" do
    industry = insert(:industry)
    params = %{
      code: "TEST",
    }
    assert {:ok, industry} = IndustryContext.update_industry(industry.id, params)
    assert %Industry{} = industry
    assert industry.code == "TEST"
  end

  test "update_industry with invalid data returns error changeset" do
    industry = insert(:industry)
    assert {:error, %Ecto.Changeset{}} = IndustryContext.update_industry(industry.id, @invalid_attrs)
    assert industry == IndustryContext.get_industry(industry.id)
  end

  test "delete_industry deletes the industry" do
    industry = insert(:industry)
    assert {:ok, %Industry{}} = IndustryContext.delete_industry(industry.id)
    assert_raise Ecto.NoResultsError, fn -> IndustryContext.get_industry(industry.id) end
  end

  test "get_industry_by_code! returns the industry with given code" do
    industry = insert(:industry, code: "test")
    assert IndustryContext.get_industry_by_code(industry.code) == industry
  end

  test "insert_or_update_industry * validates industry" do
    industry = insert(:industry, code: "test")
    get_industry = IndustryContext.get_industry_by_code(industry.code)

    if is_nil(get_industry) do
      params = %{
        code: "TEST"
      }
      assert {:ok, %Industry{} = industry} = IndustryContext.create_industry(params)
      assert industry.code == "TEST"
    else
      params = %{
       code: "TEST",
      }
      assert {:ok, industry} = IndustryContext.update_industry(industry.id, params)
      assert %Industry{} = industry
      assert industry.code == "TEST"
    end
  end
end

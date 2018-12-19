defmodule Innerpeace.Db.Base.ProcedureCategoryContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.ProcedureCategory
  alias Innerpeace.Db.Base.ProcedureCategoryContext

  @invalid_attrs %{}

  test "lists all procedure_category" do
    procedure_category = insert(:procedure_category, name: "test")
    assert ProcedureCategoryContext.get_all_procedure_category() == [procedure_category]
  end

  test "get_procedure_category returns the procedure_category with given id" do
    procedure_category = insert(:procedure_category, name: "test")
    assert ProcedureCategoryContext.get_procedure_category(procedure_category.id) == procedure_category
  end

  test "create_procedure_category with valid data creates an procedure_category" do
    params = %{
      name: "test",
      code: "code"
    }
    assert {:ok, %ProcedureCategory{} = procedure_category} = ProcedureCategoryContext.create_procedure_category(params)
    assert procedure_category.name == "test"
  end

  test "create_procedure_category with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = ProcedureCategoryContext.create_procedure_category(@invalid_attrs)
  end

  test "update_procedure_category with valid data updates the procedure_category" do
    procedure_category = insert(:procedure_category)
    params = %{
      name: "test1",
      code: "test_code"
    }
    assert {:ok, procedure_category} = ProcedureCategoryContext.update_procedure_category(procedure_category.id, params)
    assert %ProcedureCategory{} = procedure_category
    assert procedure_category.name == "test1"
  end

  test "update_procedure_category with invalid data returns error changeset" do
    procedure_category = insert(:procedure_category)
    assert {:error, %Ecto.Changeset{}} = ProcedureCategoryContext.update_procedure_category(procedure_category.id, @invalid_attrs)
    assert procedure_category == ProcedureCategoryContext.get_procedure_category(procedure_category.id)
  end

  test "delete_procedure_category deletes the procedure_category" do
    procedure_category = insert(:procedure_category)
    assert {:ok, %ProcedureCategory{}} = ProcedureCategoryContext.delete_procedure_category(procedure_category.id)
    assert_raise Ecto.NoResultsError, fn -> ProcedureCategoryContext.get_procedure_category(procedure_category.id) end
  end
end

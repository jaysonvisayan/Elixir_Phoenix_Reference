defmodule Innerpeace.Db.Base.ApplicationContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.Application
  alias Innerpeace.Db.Base.ApplicationContext

  @invalid_attrs %{}

  test "lists all applications" do
    application = :application |> insert(name: "test") |> Repo.preload(:roles)
    assert ApplicationContext.get_all_applications() == [application]
  end

  test "get_application returns the application with given id" do
    application = insert(:application, name: "test")
    assert ApplicationContext.get_application(application.id) == application
  end

  test "create_application with valid data creates an application" do
    params = %{
      name: "test"
    }
    assert {:ok, %Application{} = application} =
      ApplicationContext.create_application(params)
    assert application.name == "test"
  end

  test "create_application with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} =
      ApplicationContext.create_application(@invalid_attrs)
  end

  test "update_application with valid data updates the application" do
    application = insert(:application)
    params = %{
      name: "test1",
    }
    assert {:ok, application} =
      ApplicationContext.update_application(application.id, params)
    assert %Application{} = application
    assert application.name == "test1"
  end

  test "update_application with invalid data returns error changeset" do
    application = insert(:application)
    assert {:error, %Ecto.Changeset{}} =
      ApplicationContext.update_application(application.id, @invalid_attrs)
    assert application == ApplicationContext.get_application(application.id)
  end

  test "delete_application deletes the application" do
    application = insert(:application)
    assert {:ok, %Application{}} =
      ApplicationContext.delete_application(application.id)
    assert_raise Ecto.NoResultsError, fn ->
      ApplicationContext.get_application(application.id) end
  end

  test "get_application_by_name! returns the application with given name" do
    application = insert(:application, name: "PayorLink")
    assert ApplicationContext.get_application_by_name(application.name) ==
      application
  end

  test "insert_or_update_application * validates application" do
    application = insert(:application, name: "test")
    get_app = ApplicationContext.get_application_by_name(application.name)

    if is_nil(get_app) do
       params = %{
          name: "test"
        }
        assert {:ok, %Application{}} =
          ApplicationContext.create_application(params)
    else
       params = %{
        name: "test1",
      }
      assert {:ok, application} =
        ApplicationContext.update_application(application.id, params)
      assert %Application{} = application
    end
  end
end

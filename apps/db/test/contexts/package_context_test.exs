defmodule Innerpeace.Db.Base.PackageContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.{
    Db.Repo,
    Db.Base.PackageContext,
    Db.Schemas.Package,
    # Db.Schemas.PayorProcedure,
    Db.Schemas.PackagePayorProcedure
    # Db.Schemas.Procedure
  }

  @invalid_attrs %{}

  test "get_package_payor_procedures* test" do
    package = insert(:package)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure_id: procedure.id)
    package_payor_procedure = insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    left =
      package.id
      |> get_package_payor_procedures
      |> Repo.preload([:package, payor_procedure: [:procedure]])

    right =
      package_payor_procedure
      |> Repo.preload([:package, payor_procedure: [:procedure]])
      |> List.wrap

    assert left == right
  end

  test "get_package_payor_procedure* test" do
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, procedure_id: procedure.id)
    package = insert(:package)
    package_payor_procedure = insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    left =
      package_payor_procedure.id
      |> get_package_payor_procedure
      |> Repo.preload([:package, :payor_procedure])
    right =
      package_payor_procedure

    assert left == right
  end

  test "get_all_packagess*" do
    payor_procedure = insert(:payor_procedure, is_active: true)
    package = insert(:package)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)

    left =
      PackageContext.get_all_packages

    right =
      package
      |> Repo.preload([package_payor_procedure: [payor_procedure: [:procedure]]])
      |> List.wrap

    assert left == right
  end

  test "list_all_package_payor_procedures* test" do
    package = insert(:package)
    payor = insert(:payor)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, payor_id: payor.id, procedure_id: procedure.id)
    package_payor_procedure = insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    left =
      PackageContext.list_all_package_payor_procedures
      |> Repo.preload([:package, payor_procedure: [:procedure]])

    right =
      package_payor_procedure
      |> Repo.preload([:package, payor_procedure: [:procedure]])
      |> List.wrap

    assert left == right
  end

  test "list_all_packages*" do
    payor_procedure = insert(:payor_procedure, is_active: true)
    package = insert(:package)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)

    left =
      PackageContext.list_all_packages

    right =
      package
      |> List.wrap

    assert left == right
  end

  test "insert_package_payor_procedures/2 sets payor_procedures with valid attributes for package" do
    package = insert(:package)
    payor_procedure = insert(:payor_procedure)
    params = %{
      "payor_procedure_id" => payor_procedure.id,
      "male" => true,
      "female" => true,
      "age_from" => "10",
      "age_to" => "15"
    }
    assert {:ok, %PackagePayorProcedure{}} = PackageContext.insert_package_payor_procedures(package.id, params)
  end

  test "get_package* test" do
    payor_procedure = insert(:payor_procedure, is_active: true)
    package = insert(:package)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    left =
      package.id
      |> get_package
      |> Repo.preload([:package_log, :package_facility, package_payor_procedure: [payor_procedure: [:procedure]]])
    right =
      package
      |> Repo.preload([:package_log, :package_facility, package_payor_procedure: [payor_procedure: [:procedure]]])

    assert left == right
  end

  test "create_package with valid data creates a package" do
    params = %{
      code: "TEST",
      name: "NAME"
    }
    assert {:ok, %Package{} = package} = PackageContext.create_package(params)
    assert package.code == "TEST"
  end

  test "create_package with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = PackageContext.create_package(@invalid_attrs)
  end

  test "update_package with valid data updates the package" do
    package = insert(:package)
    params = %{
      code: "TEST",
      name: "NAME"
    }
    assert {:ok, package} = PackageContext.update_package(package, params)
    assert %Package{} = package
    assert package.code == "TEST"
  end

  test "update_package with invalid data returns error changeset" do
    package = insert(:package)
    assert {:error, %Ecto.Changeset{}} = PackageContext.update_package(package, @invalid_attrs)
  end

  test "update_a_package with valid data updates the package" do
    package = insert(:package)
    params = %{
      code: "TEST",
      name: "NAME"
    }
    assert {:ok, package} = PackageContext.update_a_package(package.id, params)
    assert %Package{} = package
    assert package.code == "TEST"
  end

  test "update_a_package with invalid data returns error changeset" do
    package = insert(:package)
    assert {:error, %Ecto.Changeset{}} = PackageContext.update_a_package(package.id, @invalid_attrs)
  end

  test "update_a_package_step with valid data updates the package step" do
    package = insert(:package, step: 1)
    params = %{
      step: 2
    }
    assert {:ok, package} = PackageContext.update_package_step(package, params)
    assert %Package{} = package
    assert package.step == 2
  end

  test "update_a_package_step with invalid data returns error changeset" do
    package = insert(:package)
    assert {:error, %Ecto.Changeset{}} = PackageContext.update_package_step(package, @invalid_attrs)
  end

  test "delete package* deletes the package" do
    package = insert(:package)
    assert {:ok, %Package{}} = PackageContext.delete_package(package.id)
  end

  test "delete a package payor procedure* delete a package payor procedure" do
    package_payor_procedure = insert(:package_payor_procedure)
    assert {:ok, %PackagePayorProcedure{}} = PackageContext.delete_a_package_payor_procedure(package_payor_procedure.id)
    assert_raise Ecto.NoResultsError, fn -> PackageContext.get_package_payor_procedure(package_payor_procedure.id) end
  end

  test "change_package* returns a package changeset" do
    package = insert(:package, name: "name")
    assert %Ecto.Changeset{} = change_package(package)
  end

  test "change_package_payor_procedure* returns a package_payor_procedure changeset" do
    package_payor_procedure = insert(:package_payor_procedure)
    assert %Ecto.Changeset{} = change_package_payor_procedure(package_payor_procedure)
  end

  test "get_account_count* test" do
    payor_procedure = insert(:payor_procedure)
    package = insert(:package)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)

    assert get_package_payor_procedure_count(package.id) == 1
  end

end


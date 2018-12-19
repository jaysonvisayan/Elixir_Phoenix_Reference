defmodule Innerpeace.Db.Base.ProcedureContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Procedure,
    PayorProcedure
  }
  alias Innerpeace.Db.Base.{
    ProcedureContext
  }

  test "list_procedures returns all procedures" do
    procedure = insert(:procedure)
    assert ProcedureContext.get_all_procedures() == [procedure]
  end

  test "get_procedure/1 returns the procedure with the given id" do
    procedure = insert(:procedure)
    assert ProcedureContext.get_procedure(procedure.id) == procedure |> Repo.preload(:procedure_logs)
  end

  test "get_payor_procedure/1 returns the procedure with the given id" do
    procedure = insert(:procedure)
    payor = insert(:payor)
    payor_procedure =
      :payor_procedure
      |> insert(procedure_id: procedure.id, payor_id: payor.id)
      |> Repo.preload([:package_payor_procedures, :exclusion_procedures, facility_payor_procedures:
                       [facility: [:category, :type]]])
    assert ProcedureContext.get_payor_procedure!(payor_procedure.id) == payor_procedure
  end

  test "create_procedure/1 with valid data creates a procedure" do
    procedure_category = insert(:procedure_category)
    procedure_params = %{
      code: "CPT-101",
      description: "Insect Bite",
      type: "Diagnostic",
      procedure_category_id: procedure_category.id
    }
    assert {:ok, %Procedure{} = procedure} = ProcedureContext.create_procedure(procedure_params)
    assert procedure.code == "CPT-101"
    assert procedure.description == "Insect Bite"
    assert procedure.type == "Diagnostic"
  end

  test "create_procedure/1 with invalid data returns error changeset" do
    procedure_params = %{
      code: nil,
      description: nil,
      type: nil
    }
    assert {:error, %Ecto.Changeset{}} = ProcedureContext.create_procedure(procedure_params)
  end

  test "update_coverage/2 with valid data updates the coverage" do
    procedure_category = insert(:procedure_category)
    procedure_params = %{
      code: "CPT-101_updated",
      description: "Insect Bite_updated",
      type: "Diagnostic_updated",
      procedure_category_id: procedure_category.id
    }

    procedure = insert(:procedure)
    assert {:ok, procedure} = ProcedureContext.update_procedure(procedure.id, procedure_params)
    assert procedure.code == "CPT-101_updated"
    assert procedure.description == "Insect Bite_updated"
    assert procedure.type == "Diagnostic_updated"
  end

  test "update_procedure/1 with invalid data returns error changeset" do
    procedure_params = %{
      code: nil,
      description: nil,
      type: nil
    }
    procedure = :procedure |> insert() |> Repo.preload(:procedure_logs)
    assert {:error, %Ecto.Changeset{}} = ProcedureContext.update_procedure(procedure.id, procedure_params)
    assert procedure == ProcedureContext.get_procedure(procedure.id)
  end

  test "delete_procedure/1 deletes the procedure" do
    procedure = insert(:procedure)
    assert {:ok, %Procedure{}} = ProcedureContext.delete_procedure(procedure.id)
    assert_raise Ecto.NoResultsError, fn -> ProcedureContext.get_procedure(procedure.id) end
  end

  test "download_procedures with valid data" do
    insert(:procedure)
    insert(:payor_procedure)
    params = %{code: "Procedures"}
    _procedures =
      Procedure
      |> join(:inner, [p], pp in PayorProcedure, p.id == pp.procedure_id)
      |> select([p, pp], [p.code, p.description, pp.code, pp.description, pp.exclusion_type])
      |> order_by([p], asc: p.code)
      |> Repo.all
    _procedure2 = ProcedureContext.get_all_procedures
    procedures3 = ProcedureContext.download_procedures(params)
    _csv_content = [['Standard CPT Code', 'Standard CPT Description', 'Payor CPT Code',
                     'Payor CPT Description', 'Exclusion Type']] ++ procedures3
                  |> CSV.encode
                  |> Enum.to_list
                  |> to_string
    assert _csv_content = ProcedureContext.download_procedures(params)
  end

  test "deactivate Payor CPT to a Standard CPT" do
    insert(:procedure_category)
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure)
    params = %{
      "code" => "Payor CPT Code",
      "description" => "Payor CPT Description",
      "is_active" => false,
      "deactivation_date" => Ecto.Date.utc(),
      "procedure_id" => procedure.id
    }

    payor_cpt =
    ProcedureContext.get_payor_procedure!(payor_procedure.id)

    deactivated_payor_cpt =
      payor_cpt
      |> PayorProcedure.changeset(params)
    assert deactivated_payor_cpt.changes.code == "Payor CPT Code"
    assert deactivated_payor_cpt.changes.description == "Payor CPT Description"
    assert deactivated_payor_cpt.changes.is_active == false
    assert deactivated_payor_cpt.changes.deactivation_date == Ecto.Date.utc()
    assert deactivated_payor_cpt.changes.procedure_id == procedure.id

  end

  test "create logs when Payor CPT is mapped to a Standard CPT" do
    user = insert(:user, %{username: "admin", email: "admin@admin.com"})
    :procedure |> insert() |> Repo.preload(:procedure_logs)
    payor = insert(:payor)
    procedure = insert(:procedure)
    insert(:payor_procedure, payor_id: payor.id, procedure_id: procedure.id)
    params = %{
      "code" => "Payor CPT Code",
      "description" => "Payor CPT Description",
      "procedure_id" => procedure.id
    }
    cpt = ProcedureContext.get_procedure(procedure.id)
    cpt_log = ProcedureContext.create_mapped_procedure_log(user, cpt, params)
    assert {:ok , %PayorProcedure{}} = ProcedureContext.create_payor_procedure(params)
    assert cpt_log.user_id == user.id
    assert cpt_log.procedure_id == procedure.id
    assert cpt_log.message == "<b>#{user.username}</b> mapped <b>Payor CPT Code</b> '#{params["code"]}' to <b>Standard CPT Code</b> '#{procedure.code}' and <b>Payor CPT Description</b> '#{params["description"]}' to <b>Standard CPT Description</b> '#{procedure.description}'."
  end

  test "create logs when Payor CPT is deactivated to a Standard CPT" do
    user = insert(:user, %{username: "admin", email: "admin@admin.com"})
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure)
    _params = %{
      "code" => "Payor CPT Code",
      "description" => "Payor CPT Description",
      "is_active" => false,
      "deactivation_date" => Ecto.Date.utc(),
      "procedure_id" => procedure.id
    }

    payor_cpt = ProcedureContext.get_payor_procedure!(payor_procedure.id)
    cpt_log = ProcedureContext.create_deactivated_procedure_log(user, payor_cpt)
    assert cpt_log.user_id == user.id
    assert cpt_log.procedure_id == payor_cpt.procedure_id
    assert cpt_log.message == "<b>#{user.username}</b> deactivated <b>Payor CPT Code</b> '#{payor_procedure.code}' and <b>Payor CPT Description</b> '#{payor_procedure.description}'."
  end

  test "create logs when Payor CPT is updated" do
    user = insert(:user, %{username: "admin", email: "admin@admin.com"})
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure)
    params = %{
      "code" => "Payor CPT Code",
      "description" => "Payor CPT Description",
      "procedure_id" => procedure.id
    }
    payor_cpt = ProcedureContext.get_payor_procedure!(payor_procedure.id)
    changeset = PayorProcedure.changeset(payor_cpt, params)
    cpt_log = ProcedureContext.create_updated_procedure_log(user, changeset)
    changes = ProcedureContext.procedure_changes_to_string(changeset)

    assert cpt_log.user_id == user.id
    assert cpt_log.procedure_id == payor_cpt.procedure_id
    assert cpt_log.message == "#{user.username} updated #{changes}."
  end

  test "get_procedure_by_code with given code" do
    procedure = insert(:procedure, code: "test")
    assert ProcedureContext.get_procedure_by_code(procedure.code) == procedure |> Repo.preload(:procedure_logs)
  end

  test "get_all_payor_procedure_query for load datatable" do
    payor = insert(:payor, %{name: "Maxicare"})
    procedure = insert(:procedure)
    payor_procedure = insert(:payor_procedure, payor: payor, procedure: procedure, code: "code", description: "descript")
    payor_procedure_query = ProcedureContext.get_all_procedure_query("", 0)
    assert payor_procedure_query |> Repo.preload([:payor, [procedure: :procedure_category]]) == [payor_procedure]
  end

end

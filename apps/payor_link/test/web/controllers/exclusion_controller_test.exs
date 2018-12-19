defmodule Innerpeace.PayorLink.Web.ExclusionControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    # user = insert(:user)
    user = fixture(:user_permission, %{keyword: "manage_exclusions", module: "Exclusions"})
    conn = authenticated(conn, user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "General Exclusion"
    )
    # conn = sign_in(conn, user)
    {:ok, %{conn: conn, exclusion: exclusion}}
  end

  test "lists all entries on index", %{conn: conn, exclusion: exclusion} do
    conn = get conn, exclusion_path(conn, :index)
    assert html_response(conn, 200) =~ "Exclusions"
    assert html_response(conn, 200) =~ exclusion.name
  end

  test "renders form for creating new exclusion", %{conn: conn} do
    conn = get conn, exclusion_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Exclusion"
  end

  test "creates exclusion with valid attributes", %{conn: conn} do
    params = %{
      "name" => "exclusion name",
      "coverage" => "General Exclusion",
      "code" => "exclusion code",
       }
    conn = post conn, exclusion_path(conn, :create_basic), exclusion: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == exclusion_path(conn, :setup, id, step: "2")
  end

  test "does not create exclusion with invalid attributes", %{conn: conn} do
    params = %{
      "coverage" => "General Exclusion",
      "name" => "some name"
       }
    conn = post conn, exclusion_path(conn, :create_basic), exclusion: params
    assert html_response(conn, 200) =~ "Exclusion Code"
  end

  test "creates pre-existing condition with valid attributes", %{conn: conn} do
    params = %{
      "name" => "Exclusion Name",
      "coverage" => "Pre-existing Condition",
      "code" => "Exclusion Code",
      "duration_from" => "2017-02-12",
      "duration_to" => "2017-02-22"
      }
    conn = post conn, exclusion_path(conn, :create_basic), exclusion: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == exclusion_path(conn, :setup, id, step: "2")
  end

  test "does not create pre-existing condition with invalid attributes", %{conn: conn} do
    params = %{
      "coverage" => "General Exclusion",
      "code" => "some code"
    }
    conn = post conn, exclusion_path(conn, :create_basic), exclusion: params
    assert html_response(conn, 200) =~ "Code"
  end

  test "renders form for editing step 1 of the given exclusion", %{conn: conn, exclusion: exclusion} do
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "1")
    assert html_response(conn, 200) =~ exclusion.name
  end

  test "updates step 1 of the given exclusion with exclusion coverage", %{conn: conn, exclusion: exclusion} do
    params = %{
      "name" => "updated plan",
      "code" => "updated code",
      "coverage" => "General Exclusion",
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "1", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "2")
  end

  test "does not update step 1 of the given exclusion with invalid attributes", %{conn: conn, exclusion: exclusion} do
    params = %{
      "name" => "",
      "coverage" => "General Exclusion",
      "code" => "test code"
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "1", exclusion: params)
    assert html_response(conn, 200) =~ "error"
  end

  test "updates step 1 of the given exclusion with pre-existing condition category", %{conn: conn, exclusion: exclusion} do
    params = %{
      "name" => "updated plan",
      "code" => "updated code",
      "coverage" => "Pre-existing Condition",
      "duration_from" => "2017-02-12",
      "duration_to" => "2017-02-22"
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "1", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "2")
  end

  test "does not update step 1 of the given pre-existing condition with invalid attributes", %{conn: conn, exclusion: exclusion} do
    params = %{
      "name" => "",
      "coverage" => "General Exclusion",
      "code" => "test code"
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "1", exclusion: params)
    assert html_response(conn, 200) =~ "error"
  end

  test "renders form for step 2 of the given general exclusion", %{conn: conn, exclusion: exclusion} do
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "2")
    assert html_response(conn, 200) =~ "Disease Code"
    assert html_response(conn, 200) =~ "Disease Description"
    assert html_response(conn, 200) =~ "Disease Type"
    assert html_response(conn, 200) =~ "Disease Chapter"
    assert html_response(conn, 200) =~ "Disease Group"
  end

  test "renders form for step 2 of the given pre-existing condition", %{conn: conn} do
    user = insert(:user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code2",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "Pre-existing Condition"
    )
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "2")
    assert html_response(conn, 200) =~ "Disease Type"
    assert html_response(conn, 200) =~ "Duration"
    assert html_response(conn, 200) =~ "Covered After Duration"
  end

  test "step 2 adds exclusion diseases with valid attributes of the given general exclusion", %{conn: conn, exclusion: exclusion} do
    disease = insert(:diagnosis)
    params = %{
      "disease_ids_main" => disease.id,
      "disease_id" => disease.id
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "2", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "2")
  end

  test "step 2 adds exclusion diseases with valid attributes of the given pre-existing condition", %{conn: conn} do
    user = insert(:user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code2",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "Pre-existing Condition"
    )
    insert(:exclusion_duration)
    params = %{
      "disease_type" => "Dreaded",
      "duration" => 50,
      "percentage" => 50
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "2", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "2")
  end

  test "renders form for step 3 of the given general exclusion", %{conn: conn, exclusion: exclusion} do
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "3")
    assert html_response(conn, 200) =~ "CPT Code"
    assert html_response(conn, 200) =~ "CPT Description"
    assert html_response(conn, 200) =~ "Procedure Section"
  end

  test "renders form for step 3 of the given pre-existing condition", %{conn: conn} do
    user = insert(:user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code2",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "Pre-existing Condition"
    )
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "3")
    assert html_response(conn, 200) =~ "Disease Code"
    assert html_response(conn, 200) =~ "Disease Description"
    assert html_response(conn, 200) =~ "Disease Type"
    assert html_response(conn, 200) =~ "Disease Chapter"
    assert html_response(conn, 200) =~ "Disease Group"
  end

  test "step 3 adds exclusion procedures with valid attributes of the given general exclusion", %{conn: conn, exclusion: exclusion} do
    procedure = insert(:payor_procedure)
    params = %{
      "procedure_ids_main" => procedure.id,
      "procedure_id" => procedure.id
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "3", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "3")
  end

  test "step 3 adds exclusion procedures with valid attributes of the given pre-existing condition", %{conn: conn} do
    user = insert(:user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code2",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "Pre-existing Condition"
    )
    disease = insert(:diagnosis)
    params = %{
      "disease_ids_main" => disease.id,
      "disease_id" => disease.id
    }
    conn = post conn, exclusion_path(conn, :update_setup, exclusion, step: "3", exclusion: params)
    assert redirected_to(conn) == exclusion_path(conn, :setup, exclusion, step: "3")
  end

  test "renders form for step 4 of the given general exclusion", %{conn: conn, exclusion: exclusion} do
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "4")
    assert html_response(conn, 200) =~ "Summary"
    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ "Condition"
    assert html_response(conn, 200) =~ "Disease"
    assert html_response(conn, 200) =~ "Procedure"
  end

  test "renders form for step 4 of the given general pre-existing condition", %{conn: conn} do
    user = insert(:user)
    exclusion = insert(:exclusion,
      name: "test exclusion",
      code: "test code2",
      created_by_id: user.id,
      updated_by_id: user.id,
      coverage: "Pre-existing Condition"
    )
    conn = get conn, exclusion_path(conn, :setup, exclusion, step: "4")
    assert html_response(conn, 200) =~ "Summary"
    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ "Condition"
    assert html_response(conn, 200) =~ "Duration"
    assert html_response(conn, 200) =~ "Disease"
  end

end

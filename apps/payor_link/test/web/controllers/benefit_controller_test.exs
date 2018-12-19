defmodule Innerpeace.PayorLink.Web.BenefitControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  #use Innerpeace.PayorLink.Web.UserCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    # user = insert(:user)
    user = fixture(:user_permission, %{keyword: "manage_benefits", module: "Benefits"})
    benefit = insert(:benefit, %{
      name: "test benefit",
      created_by_id: user.id,
      updated_by_id: user.id,
      provider_access: "Hospital"
    })
    conn = authenticated(conn, user)

    {:ok, %{conn: conn, benefit: benefit}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, benefit_path(conn, :index)
    assert html_response(conn, 200) =~ "Benefits"
  end

  test "renders form for creating new benefit", %{conn: conn} do
    conn = get conn, benefit_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Benefit"
  end

  test "creates health benefit with valid attributes", %{conn: conn} do
    coverage = insert(:coverage)
    params = %{
      "name" => "test benefit",
      "category" => "Health",
      "code" => "some code",
      "coverage_ids" => [coverage.id]
    }
    conn = post conn, benefit_path(conn, :create_basic), benefit: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == benefit_path(conn, :setup, id, step: "2")
  end

  test "does not create health benefit with invalid attributes", %{conn: conn} do
    coverage = insert(:coverage)
    params = %{
      "category" => "Health",
      "code" => "some code",
      "coverage_ids" => [coverage.id]
    }
    conn = post conn, benefit_path(conn, :create_basic), benefit: params
    assert html_response(conn, 200) =~ "Code"
  end

  test "creates riders benefit with valid attributes", %{conn: conn} do
    coverage = insert(:coverage)
    params = %{
      "name" => "test benefit",
      "category" => "Riders",
      "code" => "some code",
      "coverage_id" => coverage.id
    }
    conn = post conn, benefit_path(conn, :create_basic), benefit: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == benefit_path(conn, :setup, id, step: "2")
  end

  test "does not create riders benefit with invalid attributes", %{conn: conn} do
    params = %{
      "category" => "Health",
      "code" => "some code"
    }
    conn = post conn, benefit_path(conn, :create_basic), benefit: params
    assert html_response(conn, 200) =~ "Code"
  end

  test "renders form for editing step 1 of the given benefit", %{conn: conn, benefit: benefit} do
    conn = get conn, benefit_path(conn, :setup, benefit, step: "1")
    assert html_response(conn, 200) =~ benefit.name
  end

  test "updates step 1 of the given benefit with health category", %{conn: conn, benefit: benefit} do
    coverage = insert(:coverage)
    params = %{
      "name" => "updated plan",
      "category" => "Health",
      "coverage_ids" => [coverage.id]
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "1", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "2")
  end

  test "does not update step 1 of the given health benefit with invalid attributes", %{conn: conn, benefit: benefit} do
    params = %{
      "name" => "",
      "category" => "Health"
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "1", benefit: params)
    assert html_response(conn, 200) =~ benefit.code
  end

  test "updates step 1 of the given health benefit with riders category", %{conn: conn, benefit: benefit} do
    coverage = insert(:coverage)
    params = %{
      "name" => "updated plan",
      "category" => "Riders",
      "coverage_id" => coverage.id
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "1", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "2")
  end

  test "does not update step 1 of the given riders benefit with invalid attributes", %{conn: conn, benefit: benefit} do
    params = %{
      "name" => "",
      "category" => "Health"
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "1", benefit: params)
    assert html_response(conn, 200) =~ benefit.code
  end

  # test "renders form for step 2 of the given benefit w/ ACU coverage", %{conn: conn, benefit: benefit} do
  #   coverage = insert(:coverage, name: "ACU")
  #   insert(:benefit_coverage, benefit: benefit, coverage: coverage)
  #   conn = get conn, benefit_path(conn, :setup, benefit, step: "2")
  #   assert html_response(conn, 200) =~ "Gender"
  #   assert html_response(conn, 200) =~ "Age"
  # end

  test "renders form for step 2 of the given benefit w/o ACU coverage", %{conn: conn, benefit: benefit} do
    conn = get conn, benefit_path(conn, :setup, benefit, step: "2")
    assert html_response(conn, 200) =~ "Code"
    assert html_response(conn, 200) =~ "Description"
    refute html_response(conn, 200) =~ "Gender"
    refute html_response(conn, 200) =~ "Age"
  end

  test "step 2 adds benefit procedures with valid attributes", %{conn: conn, benefit: benefit} do
    procedure = insert(:payor_procedure)
    params = %{
      "procedure_ids_main" => procedure.id,
      "procedure_id" => procedure.id
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "2", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "2")
  end

  test "renders form for step 3 of the given benefit", %{conn: conn, benefit: benefit} do
    conn = get conn, benefit_path(conn, :setup, benefit, step: "3")
    assert html_response(conn, 200) =~ "Code"
    assert html_response(conn, 200) =~ "Description"
    assert html_response(conn, 200) =~ "ICD Type"
  end

  test "step 3 adds benefit diagnosis with valid attributes", %{conn: conn, benefit: benefit} do
    diagnosis = insert(:diagnosis)
    params = %{
      "diagnosis_ids_main" => diagnosis.id,
      "diagnosis_ids" => [diagnosis.id],
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "3", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "3")
  end

  test "renders form for step 5 of the given benefit", %{conn: conn, benefit: benefit} do
    conn = get conn, benefit_path(conn, :setup, benefit, step: "5")
    assert html_response(conn, 200) =~ "Coverage"
    assert html_response(conn, 200) =~ "Limit Type"
    assert html_response(conn, 200) =~ "Limit Amount"
  end

  test "step 5 adds benefit limits with valid attributes", %{conn: conn, benefit: benefit} do
    params = %{
      "coverages" => ["IP"],
      "limit_type" => "Peso",
      "amount" => "5000"
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "5", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "5")
  end

  test "step 5 does not add benefit limits with invalid attributes", %{conn: conn, benefit: benefit} do
    params = %{
      "coverages" => ["ACU"],
      "limit_type" => nil,
      "amount" => "5000"
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "5", benefit: params)
    assert html_response(conn, 200) =~ "Coverage"
  end

  test "step 4 updates benefit limit", %{conn: conn, benefit: benefit} do
    benefit_limit = insert(:benefit_limit, %{benefit: benefit})
    params = %{
      "coverages" => "OPL,OPC",
      "benefit_limit_id" => benefit_limit.id,
      "limit_type" => "Peso"
    }
    conn = post conn, benefit_path(conn, :update_setup, benefit, step: "4.1", benefit: params)
    assert redirected_to(conn) == benefit_path(conn, :setup, benefit, step: "5")
  end

  test "renders form for step 6 of the given benefit", %{conn: conn, benefit: benefit} do
    coverage = insert(:coverage, name: "ACU")
    procedure = insert(:payor_procedure)
    insert(:benefit_procedure, %{
      benefit: benefit,
      procedure: procedure
    })
    insert(:benefit_coverage, %{
      benefit: benefit,
      coverage: coverage
    })
    insert(:benefit_limit, %{
      benefit: benefit,
      coverages: "OP, IP",
      limit_type: "Peso"
    })
    insert(:benefit_diagnosis, %{
      benefit: benefit,
    })
    conn = get conn, benefit_path(conn, :setup, benefit, step: "6")
    assert html_response(conn, 200) =~ benefit.name
    assert html_response(conn, 200) =~ "ACU"
    assert html_response(conn, 200) =~ "OP, IP"
  end

end


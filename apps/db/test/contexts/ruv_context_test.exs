defmodule Innerpeace.Db.Base.RUVContextTest do
  use Innerpeace.Db.SchemaCase

  alias Ecto.UUID
  alias Innerpeace.Db.{
    Base.RUVContext,
    Schemas.RUV
  }

  test "get_ruvs with return" do
    insert(:ruv)
    insert(:ruv)
    insert(:ruv)

    result = RUVContext.get_ruvs()

    assert Enum.count(result) == 3
  end

  test "get_ruvs with no return" do
    result = RUVContext.get_ruvs()

    assert Enum.count(result) == 0
  end

  test "create_ruv with valid params" do
    user = insert(:user)
    params = %{
      "code" => "test code",
      "description" => "test description",
      "type" => "Unit",
      "value" => 20,
      "effectivity_date" => Ecto.Date.cast!("2017-10-18")
    }

    {_, result} = RUVContext.create_ruv(user.id, params)
    assert result.code == "test code"
  end

  test "create_ruv with invalid params" do
    user = insert(:user)
    params = %{
      "code" => "test code",
      "type" => "Unit",
      "value" => 20,
      "effectivity_date" => Ecto.Date.cast!("2017-10-18")
    }

    {_, result} = RUVContext.create_ruv(user.id, params)
    assert result.valid? == false
  end

  test "get_ruv_codes with return" do
    insert(:ruv, code: "test code 1")
    insert(:ruv, code: "test code 2")

    result = RUVContext.get_ruv_codes()
    assert Enum.count(result) == 2
  end

  test "get_ruv_codes with no return" do
    result = RUVContext.get_ruv_codes()
    assert Enum.count(result) == 0
  end

  test "get_ruv_by_id with valid id" do
    ruv = insert(:ruv, code: "test code")

    result = RUVContext.get_ruv_by_id(ruv.id)

    assert result.code == "test code"
  end

  test "get_ruv_by_id with invalid id" do
    {_, id} = UUID.load(UUID.bingenerate())

    result = RUVContext.get_ruv_by_id(id)
    assert result == nil
  end

  test "update_ruv with valid params" do
    user = insert(:user)
    ruv = insert(:ruv, created_by_id: user.id)
    params = %{
      "code" => "test code",
      "description" => "test description",
      "type" => "Unit",
      "value" => 20,
      "effectivity_date" => Ecto.Date.cast!("2017-10-18")
    }

    {status, _} = RUVContext.update_ruv(user.id, ruv.id, params)
    assert status == :ok
  end

  test "update_ruv with invalid params" do
    user = insert(:user)
    ruv = insert(:ruv, created_by_id: user.id)
    params = %{
      "code" => "test code",
      "description" => "test description",
      "value" => 20,
      "effectivity_date" => Ecto.Date.cast!("2017-10-18")
    }

    {status, _} = RUVContext.update_ruv(user.id, ruv.id, params)
    assert status == :error
  end

  test "delete_ruv with valid id" do
    ruv = insert(:ruv)

    {cnt, _} = RUVContext.delete_ruv(ruv.id)
    assert cnt == 1
  end

  test "delete_ruv with invalid id" do
    {_, id} = UUID.load(UUID.bingenerate())

    {cnt, _} = RUVContext.delete_ruv(id)
    assert cnt == 0
  end

  test "create_ruv_log with changes" do
    user = insert(:user, username: "test user")
    ruv = insert(:ruv,
                 code: "test code",
                 description: "test description",
                 type: "Rate",
                 value: 12.50,
                 effectivity_date: Ecto.Date.cast!("2017-10-18"),
                 created_by_id: user.id,
                 updated_by_id: user.id)

    params = %{
      "description" => "test description update"
    }

    changeset = RUV.changeset(ruv, params)

    {_, result} = RUVContext.create_ruv_log(user, changeset)
    assert result.message == "test user edited RUV Description from test description to test description update."
  end

  test "create_ruv_log without changes" do
    user = insert(:user, username: "test user")
    ruv = insert(:ruv,
                 code: "test code",
                 description: "test description",
                 type: "Rate",
                 value: 12.50,
                 effectivity_date: Ecto.Date.cast!("2017-10-18"),
                 created_by_id: user.id,
                 updated_by_id: user.id)

    params = %{
      "description" => "test description"
    }

    changeset = RUV.changeset(ruv, params)

    result = RUVContext.create_ruv_log(user, changeset)
    assert result == nil
  end

  test "changes_to_string with changes" do
    user = insert(:user, username: "test user")
    ruv = insert(:ruv,
                 code: "test code",
                 description: "test description",
                 type: "Rate",
                 value: 12.50,
                 effectivity_date: Ecto.Date.cast!("2017-10-18"),
                 created_by_id: user.id,
                 updated_by_id: user.id)

    params = %{
      "description" => "test description update"
    }

    changeset = RUV.changeset(ruv, params)

    result = RUVContext.changes_to_string(changeset)
    assert result == "RUV Description from test description to test description update"
  end

  test "changes_to_string without changes" do
    user = insert(:user, username: "test user")
    ruv = insert(:ruv,
                 code: "test code",
                 description: "test description",
                 type: "Rate",
                 value: 12.50,
                 effectivity_date: Ecto.Date.cast!("2017-10-18"),
                 created_by_id: user.id,
                 updated_by_id: user.id)

    params = %{
      "description" => "test description"
    }

    changeset = RUV.changeset(ruv, params)

    result = RUVContext.changes_to_string(changeset)
    assert result == ""
  end

  test "insert_log with valid params" do
    ruv = insert(:ruv)
    user = insert(:user)

    params = %{
      user_id: user.id,
      ruv_id: ruv.id,
      message: "test message"
    }

    {_, result} = RUVContext.insert_log(params)
    assert result.message == "test message"
  end

  test "insert_log with invalid params" do
    ruv = insert(:ruv)
    user = insert(:user)

    params = %{
      user_id: user.id,
      ruv_id: ruv.id,
    }

    {_, result} = RUVContext.insert_log(params)
    assert result.valid? == false
  end

  test "get_logs_by_ruv_id with valid ruv id" do
    ruv = insert(:ruv)
    user = insert(:user)
    insert(:ruv_log, user: user, ruv: ruv)

    result = RUVContext.get_logs_by_ruv_id(ruv.id)
    assert Enum.count(result) == 1
  end

  test "get_logs_by_ruv_id with invalid ruv id" do
    {_, id} = UUID.load(UUID.bingenerate())
    ruv = insert(:ruv)
    user = insert(:user)
    insert(:ruv_log, user: user, ruv: ruv)

    result = RUVContext.get_logs_by_ruv_id(id)
    assert Enum.count(result) == 0
  end
end

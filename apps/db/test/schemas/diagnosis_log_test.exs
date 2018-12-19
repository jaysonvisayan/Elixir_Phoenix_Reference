defmodule Innerpeace.Db.Schemas.DiagnosisLogTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.DiagnosisLog

  test "changeset with valid attributes" do
    params = %{
      message: "test message",
      diagnosis_id: Ecto.UUID.bingenerate,
      user_id: Ecto.UUID.bingenerate,
    }

    result = DiagnosisLog.changeset(%DiagnosisLog{}, params)
    assert result.valid? == true
  end

  test "changeset with invalid attributes" do
    params = %{
      message: "test message",
      diagnosis_id: Ecto.UUID.bingenerate,
    }

    result = DiagnosisLog.changeset(%DiagnosisLog{}, params)
    assert result.valid? == false
  end
end

defmodule Innerpeace.Db.Schemas.BenefitTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Benefit

  test "changeset health with valid attributes" do
    params = %{
      name: "some content",
      code: "some code",
      category: "Health",
      limit_type: "Nomenclature",
      coverage_ids: [Ecto.UUID.generate()]
    }

    changeset = Benefit.changeset_health(%Benefit{}, params)
    assert changeset.valid?
  end

  test "changeset health with invalid attributes" do
    changeset = Benefit.changeset_health(%Benefit{}, %{})
    refute changeset.valid?
  end

  test "changeset riders with valid attributes" do
    params = %{
      name: "some content",
      code: "some code",
      category: "Riders",
      limit_type: "Nomenclature",
      coverage_id: Ecto.UUID.generate()
    }
    changeset = Benefit.changeset_riders(%Benefit{}, params)
    assert changeset.valid?
  end

  test "changeset riders with invalid attributes" do
    changeset = Benefit.changeset_riders(%Benefit{}, %{})
    refute changeset.valid?
  end

  test "changeset edit health with valid attributes" do
    params = %{
      name: "new name",
      code: "new code",
      updated_by_id: Ecto.UUID.generate(),
      coverage_ids: [Ecto.UUID.generate()]
    }
    changeset = Benefit.changeset_edit_health(%Benefit{}, params)
    assert changeset.valid?
  end

  test "changeset edit health with invalid attributes" do
    params = %{
      code: "new code"
    }
    changeset = Benefit.changeset_edit_health(%Benefit{}, params)
    refute changeset.valid?
  end

  test "changeset edit riders with valid attributes" do
    params = %{
      name: "new name",
      code: "new code"
    }
    changeset = Benefit.changeset_edit_riders(%Benefit{}, params)
    assert changeset.valid?
  end

  test "changeset edit riders with invalid attributes" do
    params = %{
      code: "new code"
    }
    changeset = Benefit.changeset_edit_riders(%Benefit{}, params)
    refute changeset.valid?
  end

  test "changeset step with valid attributes" do
    params = %{
      step: 5,
      updated_by_id: Ecto.UUID.generate()
    }
    changeset = Benefit.changeset_step(%Benefit{}, params)
    assert changeset.valid?
  end

  test "changeset step with invalid attributes" do
    params = %{
      updated_by_id: Ecto.UUID.generate()
    }
    changeset = Benefit.changeset_step(%Benefit{}, params)
    refute changeset.valid?
  end

end


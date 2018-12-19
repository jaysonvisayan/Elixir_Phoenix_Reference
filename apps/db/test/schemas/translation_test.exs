defmodule Innerpeace.Db.Schemas.TranslationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Translation

  test "changeset with valid attributes" do
    params = %{
      base_value: "hello",
      translated_value: "kumusta",
      language: "en"
    }

    changeset = Translation.changeset(%Translation{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      base_value: "hello",
      translated_value: "kumusta",
      language: ""
    }

    changeset = Translation.changeset(%Translation{}, params)
    refute changeset.valid?
  end

end

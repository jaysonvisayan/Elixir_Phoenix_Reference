defmodule Innerpeace.Db.Schemas.AuthorizationPractitioner do
  use Innerpeace.Db.Schema

  schema "authorization_practitioners" do
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :practitioner_id,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :authorization_id,
      :practitioner_id,
      :created_by_id,
      :updated_by_id
    ])
  end
end

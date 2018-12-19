defmodule Innerpeace.Db.Schemas.PractitionerLog do
  use Innerpeace.Db.Schema

  schema "practitioner_logs" do
    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :practitioner_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :practitioner_id,
      :user_id,
      :message
    ])
  end

end

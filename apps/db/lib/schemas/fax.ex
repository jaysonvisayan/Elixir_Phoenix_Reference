defmodule Innerpeace.Db.Schemas.Fax do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  @derive {Poison.Encoder, only: [:number]}
  schema "fax" do
    field :number, :string
    field :prefix, :string

    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:number, :prefix, :contact_id])
    |> validate_required([:number, :contact_id])
  end
end

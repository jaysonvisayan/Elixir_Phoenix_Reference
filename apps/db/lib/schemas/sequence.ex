defmodule Innerpeace.Db.Schemas.Sequence do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  schema "sequences" do
    field :type, :string
    field :number, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
        :type,
        :number
      ])
    |> validate_required([
        :type,
        :number
      ])
  end

end

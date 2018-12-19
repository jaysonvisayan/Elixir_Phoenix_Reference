defmodule Innerpeace.Db.Schemas.ProcedureCategory do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "procedure_categories" do
    field :name, :string
    field :code, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :code])
    |> validate_required([:name, :code])
  end

end

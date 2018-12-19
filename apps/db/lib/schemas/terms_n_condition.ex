defmodule Innerpeace.Db.Schemas.TermsNCondition do
  use Innerpeace.Db.Schema

  schema "terms_n_conditions" do
    field :version, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:version])
    |> validate_required([:version])
  end
end

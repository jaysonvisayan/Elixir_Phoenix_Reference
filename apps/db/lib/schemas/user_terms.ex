defmodule Innerpeace.Db.Schemas.UserTerm do
  use Innerpeace.Db.Schema

  schema "user_terms" do
    belongs_to :user, Innerpeace.Db.Schemas.User
    belongs_to :terms_n_condition, Innerpeace.Db.Schemas.TermsNCondition

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :terms_n_condition_id])
    |> validate_required([:user_id, :terms_n_condition_id])
  end
end

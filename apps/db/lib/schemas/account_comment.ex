defmodule Innerpeace.Db.Schemas.AccountComment do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "account_comments" do
    field :comment, :string
    belongs_to :account, Innerpeace.Db.Schemas.Account
    belongs_to :user, Innerpeace.Db.Schemas.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :comment,
      :account_id,
      :user_id
    ])
    |> validate_required([
      :comment,
      :account_id,
      :user_id
     ])
    |> validate_length(:comment, min: 1, message: "Atleast 1 character")
  end

end

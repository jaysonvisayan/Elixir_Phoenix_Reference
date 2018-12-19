defmodule Innerpeace.Db.Schemas.UserPassword do
  use Innerpeace.Db.Schema

  schema "user_passwords" do
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :hashed_password, :string
    field :password, :string, virtual: true

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :password,
      :user_id
    ])
    |> validate_required([:password, :user_id])
    |> hash_password()
  end

  #private methhods
  defp hash_password(%{valid?: false} = changeset), do: changeset
  defp hash_password(%{valid?: true} = changeset) do
    hashedpw = Comeonin.Bcrypt.hashpwsalt(Ecto.Changeset.get_field(changeset, :password))
    Ecto.Changeset.put_change(changeset, :hashed_password, hashedpw)
  end
end

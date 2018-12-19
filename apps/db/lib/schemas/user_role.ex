defmodule Innerpeace.Db.Schemas.UserRole do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :role_id
  ]}

  schema "user_roles" do
    belongs_to :user, Innerpeace.Db.Schemas.User
    belongs_to :role, Innerpeace.Db.Schemas.Role

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :role_id])
    |> unique_constraint(:role_id,  name: :user_roles_user_id_role_id_index, message: "Role is already added within a selected User!")
  end

end

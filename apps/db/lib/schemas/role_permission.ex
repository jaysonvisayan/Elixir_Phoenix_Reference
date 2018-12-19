defmodule Innerpeace.Db.Schemas.RolePermission do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "role_permissions" do
    field :account_permissions, :string, virtual: true
    belongs_to :role, Innerpeace.Db.Schemas.Role
    belongs_to :permission, Innerpeace.Db.Schemas.Permission

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role_id, :permission_id])
    |> assoc_constraint(:permission)
    |> assoc_constraint(:role)
  end

  def virtual_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_permissions])
  end

end

defmodule Innerpeace.Db.Schemas.Application do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "applications" do
    field :name, :string

    has_many :role_applications, Innerpeace.Db.Schemas.RoleApplication
    many_to_many :roles, Innerpeace.Db.Schemas.Role, join_through: "role_applications"
    has_many :permissions, Innerpeace.Db.Schemas.Permission

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :applications_name_index, message: "Name is already exist!")
  end
end

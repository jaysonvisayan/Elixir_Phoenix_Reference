defmodule Innerpeace.Db.Schemas.Permission do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "permissions" do
    field :name, :string
    field :description, :string
    field :status, :string
    field :module, :string
    field :keyword, :string

    belongs_to :application, Innerpeace.Db.Schemas.Application
    has_many :role_permissions, Innerpeace.Db.Schemas.RolePermission

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description, :status, :module, :keyword, :application_id])
    |> validate_required([:name, :description, :status, :module, :keyword, :application_id])
  end


  def payor_modules(query) do
      from p in query,
      where: like(p.keyword, ^"%manage%")
  end
end

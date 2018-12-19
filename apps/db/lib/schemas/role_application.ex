defmodule Innerpeace.Db.Schemas.RoleApplication do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "role_applications" do
    belongs_to :application, Innerpeace.Db.Schemas.Application
    belongs_to :role, Innerpeace.Db.Schemas.Role

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role_id, :application_id])
    |> assoc_constraint(:role)
    |> assoc_constraint(:application)
  end
end

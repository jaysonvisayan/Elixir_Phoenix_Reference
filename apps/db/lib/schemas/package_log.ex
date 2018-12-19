defmodule Innerpeace.Db.Schemas.PackageLog do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "package_logs" do
    belongs_to :package, Innerpeace.Db.Schemas.Package
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :package_id,
      :user_id,
      :message
    ])
  end
end

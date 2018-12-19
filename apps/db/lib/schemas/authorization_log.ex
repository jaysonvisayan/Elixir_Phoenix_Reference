defmodule Innerpeace.Db.Schemas.AuthorizationLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "authorization_logs" do
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :authorization_id,
      :user_id,
      :message
    ])
  end

end

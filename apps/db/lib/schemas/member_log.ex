defmodule Innerpeace.Db.Schemas.MemberLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "member_logs" do
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :member_id,
      :message
    ])
  end

end

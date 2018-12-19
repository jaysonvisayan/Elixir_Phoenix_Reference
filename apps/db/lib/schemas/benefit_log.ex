defmodule Innerpeace.Db.Schemas.BenefitLog do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "benefit_logs" do
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
       :benefit_id,
       :user_id,
       :message
    ])
  end
end

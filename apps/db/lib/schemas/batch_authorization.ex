defmodule Innerpeace.Db.Schemas.BatchAuthorization do
  use Innerpeace.Db.Schema

  schema "batch_authorizations" do
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :batch, Innerpeace.Db.Schemas.Batch
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    field :assessed_amount, :decimal
    field :reason, :string
    field :status, :string
    field :availment_date, Ecto.Date
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :batch_id,
      :created_by_id,
      :updated_by_id,
      :assessed_amount,
      :reason,
      :status,
      :availment_date
    ])
    |> validate_required([
      :authorization_id,
      :batch_id,
      :created_by_id,
      :updated_by_id
    ])
  end
end

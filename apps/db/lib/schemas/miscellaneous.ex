defmodule Innerpeace.Db.Schemas.Miscellaneous do
  @moduledoc false
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :code
  ]}

  schema "miscellaneous" do
    field :code, :string
    field :description, :string
    field :price, :decimal
    field :step, :string

    # Relationship
    belongs_to :created_by,
      Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by,
      Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :description,
      :price,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :code,
      :description,
      :price,
      :step,
      :created_by_id,
      :updated_by_id
    ])
  end

  def changeset_create(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :description,
      :price,
      :step,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :code,
      :description,
      :price,
      :step,
      :created_by_id,
      :updated_by_id
    ])
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :description,
      :price,
      :updated_by_id
    ])
    |> validate_required([
      :description,
      :price,
      :updated_by_id
    ])
  end

end

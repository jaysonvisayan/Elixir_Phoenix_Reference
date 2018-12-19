defmodule Innerpeace.Db.Schemas.ProductLog do
  use Innerpeace.Db.Schema

  schema "product_logs" do
    belongs_to :product, Innerpeace.Db.Schemas.Product
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :product_id,
      :user_id,
      :message
    ])
  end

end

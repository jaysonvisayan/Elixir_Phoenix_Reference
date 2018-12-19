defmodule Innerpeace.Db.Schemas.Comment do
  use Innerpeace.Db.Schema

  schema "comments" do
    field :comment, :string
    belongs_to :batch, Innerpeace.Db.Schemas.Batch
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :comment,
      :batch_id,
      :created_by_id,
      :updated_by_id
    ])
#    |> validate_required([
#      :comment,
#      :batch_id
#     ])
    |> validate_length(:comment, min: 1, message: "Atleast 1 character")
  end

end

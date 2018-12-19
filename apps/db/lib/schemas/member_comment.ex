defmodule Innerpeace.Db.Schemas.MemberComment do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  schema "member_comments" do
    field :comment, :string
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :comment,
      :member_id,
      :created_by_id,
      :updated_by_id
    ])
    # |> validate_required([
    #   :comment,
    #   :account_id,
    #   :user_id
    # ])
    |> validate_length(:comment, min: 1, message: "Atleast 1 character")
  end

end

defmodule Innerpeace.Db.Schemas.MemberSkippingHierarchy do
  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  schema "member_skipping_hierarchy" do
    belongs_to :member, Innerpeace.Db.Schemas.Member
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :relationship, :string
    field :suffix, :string
    field :gender, :string
    field :birthdate, Ecto.Date
    field :reason, :string
    field :status, :string
    field :code, :string
    field :disapproval_reason, :string
    field :supporting_document, Innerpeace.FileUploader.Type
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :first_name,
      :middle_name,
      :last_name,
      :relationship,
      :suffix,
      :gender,
      :birthdate,
      :reason,
      :created_by_id
    ])
    |> validate_required([
      :member_id,
      :first_name,
      :last_name,
      :relationship,
      :gender,
      :birthdate,
      :reason
    ])
    |> validate_inclusion(:relationship, [
      "Parent",
      "Spouse",
      "Child",
      "Sibling"
    ])
    |> validate_inclusion(:gender, ["Male", "Female"])
  end

  def changeset_document(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:supporting_document])
  end

  def changeset_approve(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status,
      :updated_by_id,
      :disapproval_reason
    ])
    |> validate_required([
      :status
    ])
  end

end


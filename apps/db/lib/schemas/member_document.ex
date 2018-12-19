defmodule Innerpeace.Db.Schemas.MemberDocument do
  use Innerpeace.Db.Schema
  @moduledoc """
    Schema and changesets for MemberDocument
  """
  schema "member_documents" do
    field :filename, :string
    field :content_type, :string
    field :link, :string
    field :purpose, :string
    field :uploaded_from, :string
    field :date_uploaded, Ecto.Date
    field :uploaded_by, :string
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :member, Innerpeace.Db.Schemas.Member

    timestamps()
  end

  @doc """
  builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :content_type,
      :link,
      :purpose,
      :uploaded_from,
      :date_uploaded,
      :uploaded_by,
      :authorization_id,
      :member_id
    ])
    |> validate_required([
      :filename,
      :content_type,
      :link,
      :purpose,
      :uploaded_from,
      :date_uploaded,
      :uploaded_by,
      :member_id
    ])
  end

end

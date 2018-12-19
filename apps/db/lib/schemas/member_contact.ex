defmodule Innerpeace.Db.Schemas.MemberContact do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "member_contacts" do
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :contact_id])
    |> validate_required([:member_id, :contact_id])
  end
end

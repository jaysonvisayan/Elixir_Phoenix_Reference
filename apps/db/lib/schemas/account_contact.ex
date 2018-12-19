defmodule Innerpeace.Db.Schemas.AccountGroupContact do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "account_group_contacts" do
    field :status, :string
    field :type, :string
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :contact, Innerpeace.Db.Schemas.Contact
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_group_id, :contact_id])
    |> validate_required([:account_group_id, :contact_id])
  end
end

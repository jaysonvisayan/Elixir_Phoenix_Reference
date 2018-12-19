defmodule Innerpeace.Db.Schemas.Bank do
  use Innerpeace.Db.Schema

  schema "banks" do
    field :account_name, :string
    field :account_no, :string
    field :status, :string
    field :branch, :string

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    has_one :practitioner, Innerpeace.Db.Schemas.Practitioner, on_delete: :delete_all
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_name, :account_no, :account_group_id, :status, :branch])
    |> validate_required([:account_group_id])
  end

  def changeset_practitioner(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_name, :account_no, :practitioner_id])
    |> validate_required([:account_name, :account_no, :practitioner_id])
  end
end

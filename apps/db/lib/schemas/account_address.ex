defmodule Innerpeace.Db.Schemas.AccountGroupAddress do
  @moduledoc """
    Schema and changesets for AccountGroupAddress
  """
  use Innerpeace.Db.Schema

  schema "account_group_address" do
    field :line_1, :string
    field :line_2, :string
    field :city, :string
    field :province, :string
    field :country, :string
    field :region, :string
    field :postal_code, :string
    field :type, :string
    field :is_check, :boolean, default: true

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    has_many :account_logs, Innerpeace.Db.Schemas.AccountLog, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_group_id,
      :line_1,
      :line_2,
      :postal_code,
      :city,
      :country,
      :type,
      :province,
      :is_check,
      :region
    ])
    |> validate_required([
      :account_group_id,
      :line_1,
      :line_2,
      :postal_code,
      :city,
      :type,
      :province,
      :region
    ])
    |> assoc_constraint(:account_group)
  end

  def changeset_api_billing(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_group_id,
      :line_1,
      :line_2,
      :postal_code,
      :city,
      :country,
      :type,
      :province,
      :is_check,
      :region
    ])
    |> validate_required([
      :account_group_id
    ])
    |> assoc_constraint(:account_group)
  end

end

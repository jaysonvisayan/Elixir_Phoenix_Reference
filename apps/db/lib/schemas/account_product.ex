defmodule Innerpeace.Db.Schemas.AccountProduct do
  @moduledoc """
    Schema and changesets for AccountProduct
  """
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :name,
    :description,
    :type,
    :limit_applicability,
    :limit_type,
    :limit_amount,
    :status,
    :standard_product
  ]}
  schema "account_products" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :limit_applicability, :string
    field :limit_type, :string
    field :limit_amount, :decimal
    field :status, :string
    field :standard_product, :string
    field :rank, :integer

    belongs_to :account, Innerpeace.Db.Schemas.Account
    belongs_to :product, Innerpeace.Db.Schemas.Product
    has_many :account_product_benefits, Innerpeace.Db.Schemas.AccountProductBenefit, on_delete: :delete_all
    has_many :member_products, Innerpeace.Db.Schemas.MemberProduct, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :type,
      :limit_applicability,
      :limit_type,
      :limit_amount,
      :standard_product,
      :status,
      :account_id,
      :product_id,
      :rank
    ])
    |> validate_required([
      :name,
      :description,
      :type,
      # :limit_applicability,
      # :limit_type,
      # :limit_amount,
      :account_id,
      :product_id
    ])
  end

  def changeset_update_tier(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :rank
    ])
    |> validate_required([
      :rank
    ])
  end

  def changeset_constraints(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_id,
      :product_id,
    ])
    |> validate_required([
      :account_id,
      :product_id
    ])
  end
end

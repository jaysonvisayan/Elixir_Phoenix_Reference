defmodule Innerpeace.Db.Schemas.MemberProduct do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :account_product_id
  ]}

  schema "member_products" do
    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :account_product, Innerpeace.Db.Schemas.AccountProduct
    has_many :authorization_diagnosis, Innerpeace.Db.Schemas.AuthorizationDiagnosis
    has_many :authorization_procedure_diagnoses, Innerpeace.Db.Schemas.AuthorizationProcedureDiagnosis

    field :tier, :integer
    field :loa_payor_pays, :decimal

    #Added field for Batch Change of Product
    field :is_archived, :boolean, default: false
    field :is_acu_consumed, :boolean, default: false

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:tier, :member_id, :account_product_id])
    |> unique_constraint(:account_product_id,  name: :member_products_member_id_account_product_id_index, message: "Product is already added!")

  end

  def changeset_tier(struct, params \\ %{}) do
    struct
    |> cast(params, [:tier])
  end

  def changeset_loa_payor_pays(struct, params \\ %{}) do
    struct
    |> cast(params, [:loa_payor_pays])
  end

  def changeset_is_archived(struct, params \\ %{}) do
    struct
    |> cast(params, [:tier, :is_archived])
  end

end

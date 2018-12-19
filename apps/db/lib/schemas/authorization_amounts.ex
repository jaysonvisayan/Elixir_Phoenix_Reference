defmodule Innerpeace.Db.Schemas.AuthorizationAmount do
  use Innerpeace.Db.Schema

  # Initial Limit: P10,000
  # Debit: P1000 (fee)
  # Remaining Limit: P9,000
  schema "authorization_amounts" do
    field :coordinator_fee, :decimal
    field :consultation_fee, :decimal
    field :copayment, :decimal
    field :coinsurance_percentage, :integer
    field :covered_after_percentage, :integer
    field :pre_existing_percentage, :integer
    field :payor_covered, :decimal
    field :member_covered, :decimal
    field :company_covered, :decimal
    field :room_rate, :decimal
    field :total_amount, :decimal
    field :vat_amount, :decimal
    field :special_approval_amount, :decimal
    field :approved_datetime, Ecto.DateTime
    field :senior_discount, :decimal
    field :pwd_discount, :decimal
     #Relationships
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :approved_by, Innerpeace.Db.Schemas.User, foreign_key: :approved_by_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :coordinator_fee,
        :consultation_fee,
        :copayment,
        :coinsurance_percentage,
        :covered_after_percentage,
        :pre_existing_percentage,
        :payor_covered,
        :member_covered,
        :company_covered,
        :room_rate,
        :total_amount,
        :authorization_id,
        :created_by_id,
        :updated_by_id,
        :approved_by_id,
        :vat_amount,
        :special_approval_amount,
        :approved_datetime
      ])
      |> validate_required([
        :payor_covered,
        :total_amount,
        :authorization_id,
        :created_by_id,
        :updated_by_id
      ])
    end

    def approver_changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :approved_by_id,
        :approved_datetime
      ])
    end

    def senior_and_pwd_changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :senior_discount,
        :pwd_discount
      ])
    end

   def special_approval_amount_changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :special_approval_amount
      ])
    end


    def changeset_update_amount(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :payor_covered,
        :member_covered,
        :company_covered,
        :updated_by_id,
        :approved_by_id,
        :vat_amount,
        :special_approval_amount,
        :total_amount,
        :approved_datetime
      ])
      |> validate_required([
        :payor_covered,
        :member_covered,
        :authorization_id
      ])
    end

    #for insert utilization
    def utilization_changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :authorization_id,
        :pre_existing_percentage,
        :payor_covered,
        :member_covered,
        :company_covered,
        :total_amount,
        :vat_amount,
        :special_approval_amount
      ])
      |> validate_required([
        :payor_covered,
        :member_covered,
        :company_covered,
        :total_amount,
        :vat_amount
      ])
    end
  end
end

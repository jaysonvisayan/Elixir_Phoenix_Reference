defmodule Innerpeace.Db.Schemas.Embedded.PEME do
    use Innerpeace.Db.Schema
  
    embedded_schema do
      field :authorization_id
      field :user_id
      field :member_id
      field :product_id
      field :facility_id
      field :coverage_id
      field :room_id
      field :benefit_package_id
      field :admission_date
      field :discharge_date
      field :package_rate
      field :room_rate
      field :room_hierarchy
      field :payor_pays
      field :member_pays
      field :total_amount
      field :internal_remarks
      field :valid_until
      field :member_product_id
      field :product_benefit_id
      field :origin
      field :acu_schedule_id
    end
  
    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :authorization_id,
        :user_id,
        :member_id,
        :product_id,
        :facility_id,
        :coverage_id,
        :room_id,
        :benefit_package_id,
        :admission_date,
        :discharge_date,
        :package_rate,
        :room_rate,
        :room_hierarchy,
        :payor_pays,
        :member_pays,
        :total_amount,
        :internal_remarks,
        :valid_until,
        :member_product_id,
        :product_benefit_id,
        :origin,
        :acu_schedule_id
      ])
      |> validate_required([
        :member_id,
        :facility_id,
        :coverage_id,
        :benefit_package_id
      ])
    end
  end
  
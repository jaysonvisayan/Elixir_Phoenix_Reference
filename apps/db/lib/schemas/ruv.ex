defmodule Innerpeace.Db.Schemas.RUV do
  @moduledoc """
    Schema and changesets for  RUV
  """

  use Innerpeace.Db.Schema

  schema "ruvs" do
    field :code, :string
    field :description, :string
    field :type, :string
    field :value, :decimal
    field :effectivity_date, Ecto.Date

    belongs_to :created_by, Innerpeace.Db.Schemas.User,
      foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User,
      foreign_key: :updated_by_id

    has_many :benefit_ruvs, Innerpeace.Db.Schemas.BenefitRUV
    has_many :facility_ruvs, Innerpeace.Db.Schemas.FacilityRUV
    has_many :ruv_logs, Innerpeace.Db.Schemas.RUVLog, on_delete: :delete_all
    has_one :case_rates, Innerpeace.Db.Schemas.CaseRate, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :description,
      :type,
      :value,
      :effectivity_date,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :code,
      :description,
      :type,
      :value,
      :effectivity_date,
      :created_by_id,
      :updated_by_id
    ])
  end
end

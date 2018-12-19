defmodule Innerpeace.Db.Schemas.AcuSchedule do
  @moduledoc """
    Schema and changesets for ACU Schedule
  """
  @derive {Poison.Encoder, only: [
    :batch_no,
    :no_of_members,
    :no_of_guaranteed,
    :member_type,
    :date_from,
    :date_to,
    :time_from,
    :time_to
  ]}


  use Innerpeace.Db.Schema

  schema "acu_schedules" do
    field :batch_no, :integer
    field :no_of_members, :integer
    field :no_of_guaranteed, :integer
    field :no_of_selected_members, :integer
    field :member_type, :string
    field :date_from, Ecto.Date
    field :date_to, Ecto.Date
    field :time_from, Ecto.Time
    field :time_to, Ecto.Time
    field :status, :string
    field :guaranteed_amount, :decimal

    belongs_to :cluster, Innerpeace.Db.Schemas.Cluster
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :batch, Innerpeace.Db.Schemas.Batch

    belongs_to :created_by, Innerpeace.Db.Schemas.User,
      foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User,
      foreign_key: :updated_by_id

    has_many :acu_schedule_products, Innerpeace.Db.Schemas.AcuScheduleProduct
    has_many :acu_schedule_members, Innerpeace.Db.Schemas.AcuScheduleMember
    has_many :acu_schedule_packages, Innerpeace.Db.Schemas.AcuSchedulePackage

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_no,
      :batch_id,
      :no_of_members,
      :no_of_selected_members,
      :no_of_guaranteed,
      :guaranteed_amount,
      :member_type,
      :date_from,
      :date_to,
      :account_group_id,
      :facility_id,
      :cluster_id,
      :time_from,
      :time_to,
      :created_by_id,
      :updated_by_id,
      :status
    ])
    |> validate_required([
      :batch_no,
      :no_of_members,
      :member_type,
      :date_from,
      :date_to,
      :account_group_id,
      :facility_id,
      :time_from,
      :time_to,
      :created_by_id,
      :updated_by_id
    ])
  end

  def new_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_no,
      :no_of_members,
      :no_of_selected_members,
      :no_of_guaranteed,
      :member_type,
      :date_from,
      :date_to,
      :account_group_id,
      :facility_id,
      :cluster_id,
      :time_from,
      :time_to,
      :created_by_id,
      :updated_by_id,
      :status,
      :guaranteed_amount,
      :inserted_at,
      :updated_at
    ])
    |> validate_required([
      :batch_no,
      :no_of_members,
      :member_type,
      :account_group_id,
      :facility_id,
      :created_by_id,
      :updated_by_id,
      :guaranteed_amount
    ])
  end
end

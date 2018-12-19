defmodule Innerpeace.Db.Schemas.Benefit do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [:code]}

  @timestamps_opts [usec: false]
  schema "benefits" do
    field :name, :string
    field :code, :string
    field :category, :string
    #field :limit_type, :string
    field :coverage_ids, {:array, :string}, virtual: :true
    field :coverage_id, :string, virtual: :true
    field :step, :integer
    field :maternity_type, :string
    field :acu_type, :string
    field :acu_coverage, :string
    field :provider_access, :string
    field :peme, :boolean
    field :loa_facilitated, :boolean
    field :reimbursement, :boolean
    field :condition, :string
    field :covered_enrollees, :string
    field :classification, :string
    field :type, :string
    field :waiting_period, :string
    field :discontinue_date, Ecto.Date
    field :remarks, :string
    field :disabled_date, Ecto.Date
    field :status, :string
    field :delete_date, Ecto.Date
    field :all_diagnosis, :boolean, default: false
    field :all_procedure, :boolean, default: false
    field :frequency, :string
    field :risk_share_type, :string
    field :risk_share_value, :decimal
    field :member_pays_handling, {:array, :string}

    belongs_to :created_by, Innerpeace.Db.Schemas.User,
      foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User,
      foreign_key: :updated_by_id
    has_many :benefit_diagnoses, Innerpeace.Db.Schemas.BenefitDiagnosis,
      on_delete: :delete_all
    has_many :benefit_procedures, Innerpeace.Db.Schemas.BenefitProcedure,
      on_delete: :delete_all
    has_many :benefit_coverages, Innerpeace.Db.Schemas.BenefitCoverage,
      on_delete: :delete_all
    has_many :benefit_limits, Innerpeace.Db.Schemas.BenefitLimit,
      on_delete: :delete_all
    has_many :product_benefits, Innerpeace.Db.Schemas.ProductBenefit,
      on_delete: :delete_all
    has_many :benefit_ruvs, Innerpeace.Db.Schemas.BenefitRUV,
      on_delete: :delete_all
    has_many :benefit_packages, Innerpeace.Db.Schemas.BenefitPackage,
      on_delete: :delete_all
    has_many :benefit_pharmacies, Innerpeace.Db.Schemas.BenefitPharmacy,
      on_delete: :delete_all
    has_many :benefit_miscellaneous, Innerpeace.Db.Schemas.BenefitMiscellaneous,
    on_delete: :delete_all
    has_many :benefit_logs, Innerpeace.Db.Schemas.BenefitLog,
    on_delete: :delete_all


    many_to_many :coverage, Innerpeace.Db.Schemas.Coverage, join_through: "benefit_coverages"
    timestamps()
  end

  def changeset_health(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :category,
      :coverage_ids,
      :created_by_id,
      :updated_by_id,
      :step,
      :type,
      :condition,
      :all_diagnosis,
      :all_procedure,
      :classification,
      :loa_facilitated,
      :reimbursement,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :name,
      :code,
      :category,
      :coverage_ids
    ])
    |> unique_constraint(:code, message: "Code already exists")
    |> validate_inclusion(:category, ["Health"])
    |> validate_inclusion(:condition, ["ANY", "ALL"])
  end

  def new_changeset_health(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :category,
      :coverage_ids,
      :created_by_id,
      :updated_by_id,
      :type,
      :step,
      :condition,
      :all_diagnosis,
      :all_procedure,
      :loa_facilitated,
      :reimbursement,
      :classification,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :category,
      :coverage_ids
    ])
    |> unique_constraint(:code, message: "Code already exists")
    |> validate_inclusion(:category, ["Health"])
    |> validate_inclusion(:condition, ["ANY", "ALL"])
  end

  def changeset_riders(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :category,
      :coverage_id,
      :created_by_id,
      :updated_by_id,
      :maternity_type,
      :acu_type,
      :acu_coverage,
      :provider_access,
      :type,
      :peme,
      :step,
      :condition,
      :covered_enrollees,
      :waiting_period,
      :loa_facilitated,
      :all_diagnosis,
      :all_procedure,
      :reimbursement,
      :classification,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
      # :discontinue_date,
      # :remarks
    ])
    |> validate_required([
      :name,
      :code,
      :category
    ])
    |> unique_constraint(:code, message: "Code already exists")
    |> validate_inclusion(:category, ["Riders"])
    |> validate_inclusion(:condition, ["ANY", "ALL"])
  end

  def changeset_edit_health(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :type,
      :code,
      :updated_by_id,
      :coverage_ids,
      :condition,
      :all_diagnosis,
      :all_procedure,
      :loa_facilitated,
      :reimbursement,
      :classification
    ])
    |> validate_required([
      :name,
      :code,
    ])
    |> unique_constraint(:code)
  end

  def changeset_edit_riders(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :code,
      :coverage_id,
      :updated_by_id,
      :maternity_type,
      :acu_type,
      :acu_coverage,
      :provider_access,
      :peme,
      :type,
      :condition,
      :covered_enrollees,
      :waiting_period,
      :loa_facilitated,
      :reimbursement,
      :classification
      # :discontinue_date,
      # :remarks
    ])
    |> validate_required([
      :name,
      :code,
    ])
    |> unique_constraint(:code)
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id
    ])
    |> validate_required([
      :step,
      :updated_by_id
    ])
  end

  def changeset_discontinue_benefit(struct, params \\ %{})do
    struct
    |> cast(params, [
      :discontinue_date,
      :status,
      :remarks
    ])
 |> validate_required([
      :discontinue_date,
      :status
    ])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :step
    ])
    |> unique_constraint(:name, message: "Benefit Name already exist!")
    |> validate_required([
      :code,
      :name
    ])
  end

  def changeset_disabling_benefit(struct, params \\ %{})do
    struct
    |> cast(params, [
      :disabled_date,
      :remarks,
      :status
    ])
    |> validate_required([
      :disabled_date,
      :status
    ])
  end

  def changset_change_status(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :status
    ])
    |> validate_required([
      :status
    ])
  end

  def changeset_delete_benefit(struct, params \\ %{})do
    struct
    |> cast(params, [
      :delete_date,
      :remarks,
      :status
    ])
  end

  def new_changeset_riders(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :name,
      :code,
      :category,
      :created_by_id,
      :updated_by_id,
      :acu_type,
      :acu_coverage,
      :provider_access,
      :maternity_type,
      :covered_enrollees,
      :waiting_period,
      :classification,
      :loa_facilitated,
      :reimbursement,
      :step,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :created_by_id,
      :updated_by_id
    ])
    |> unique_constraint(:code)
  end

  def changeset_acu_policy(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :name,
      :code,
      :category,
      :created_by_id,
      :updated_by_id,
      :acu_type,
      :acu_coverage,
      :provider_access,
      :maternity_type,
      :covered_enrollees,
      :waiting_period,
      :classification,
      :step,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :created_by_id,
      :updated_by_id
    ])
    |> unique_constraint(:code)
  end

  def changeset_acu_update_policy(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :name,
      :code,
      :category,
      :created_by_id,
      :updated_by_id,
      :acu_type,
      :acu_coverage,
      :provider_access,
      :maternity_type,
      :covered_enrollees,
      :waiting_period,
      :classification,
      :step,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :name
    ])
    |> unique_constraint(:code)
  end

  def changeset_sap_dental(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :name,
      :code,
      :category,
      :loa_facilitated,
      :reimbursement,
      :frequency,
      :created_by_id,
      :updated_by_id,
      :step,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :name
    ])
    |> unique_constraint(:code)
  end

  def changeset_dental(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :name,
      :code,
      :category,
      :loa_facilitated,
      :reimbursement,
      :frequency,
      :created_by_id,
      :updated_by_id,
      :step,
      :risk_share_type,
      :risk_share_value,
      :member_pays_handling
    ])
    |> validate_required([
      :code,
      :name,
      :created_by_id,
      :updated_by_id
    ])
    |> unique_constraint(:code)
  end
end

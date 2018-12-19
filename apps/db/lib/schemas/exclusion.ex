defmodule Innerpeace.Db.Schemas.Exclusion do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :coverage,
    :code,
    :name,
    :duration_from,
    :duration_to,
    :id,
    :exclusion_diseases,
    :exclusion_procedures,
    :exclusion_durations
  ]}

  @timestamps_opts [usec: false]
  schema "exclusions" do
    field :coverage, :string
    field :code, :string
    field :name, :string
    field :condition, :string
    field :step, :integer
    field :limit_type, :string
    field :limit_amount, :decimal
    field :limit_percentage, :integer
    field :limit_session, :integer

    field :is_applicability_dependent, :boolean, default: false
    field :is_applicability_principal, :boolean, default: false

    field :policy, {:array, :string}
    field :classification_type, :string
    field :type, :string

    has_many :exclusion_diseases, Innerpeace.Db.Schemas.ExclusionDisease, on_delete: :delete_all
    has_many :exclusion_procedures, Innerpeace.Db.Schemas.ExclusionProcedure, on_delete: :delete_all
    has_many :exclusion_durations, Innerpeace.Db.Schemas.ExclusionDuration, on_delete: :delete_all
    has_many :exclusion_conditions, Innerpeace.Db.Schemas.ExclusionCondition, on_delete: :delete_all

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset_exclusion(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :coverage,
      :created_by_id,
      :updated_by_id,
      :condition
    ])
    |> validate_required([
      :name,
      :coverage,
      :code,
    ])
    |> unique_constraint(:code, message: "Exclusion code already exist!")
  end

  def changeset_pre_existing(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :coverage,
      :created_by_id,
      :updated_by_id,
      :condition,
      :limit_amount,
      :limit_type,
      :limit_percentage,
      :limit_session
    ])
    |> validate_required([
      :code,
      :name,
      :coverage
    ])
    |> validate_inclusion(:coverage, ["Pre-existing Condition"])
    |> validate_inclusion(:limit_type, [
      "Peso",
      "Percentage",
      "Sessions"
    ])
    |> unique_constraint(:code, message: "Exclusion code already exist!")
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

    def changeset_edit_exclusion(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :coverage,
      :created_by_id,
      :updated_by_id,
      :condition
    ])
    |> validate_required([
      :name,
      :code,
      :coverage
    ])
    |> unique_constraint(:code, message: "Exclusion code already exist!")
  end

  def changeset_edit_pre_existing(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :coverage,
      :created_by_id,
      :updated_by_id,
      :condition,
      :limit_type,
      :limit_amount,
      :limit_percentage,
      :limit_session
    ])
    |> validate_required([
      :code,
      :name,
      :coverage
    ])
    |> validate_inclusion(:limit_type, [
      "Peso",
      "Percentage",
      "Sessions"
    ])
    |> unique_constraint(:code, message: "Exclusion code already exist!")
  end

  def changeset_pre_ex_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :is_applicability_dependent,
      :is_applicability_principal,
      :created_by_id,
      :updated_by_id,
      :step,
      :coverage
    ])
  end

  def changeset_exclusion_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :type,
      :classification_type,
      :policy,
      :created_by_id,
      :updated_by_id,
      :coverage,
      :step
    ])
  end

end

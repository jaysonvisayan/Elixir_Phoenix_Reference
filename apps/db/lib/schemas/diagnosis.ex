defmodule Innerpeace.Db.Schemas.Diagnosis do
  @moduledoc """
    Schema and changesets for diagnosis
  """

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :code,
    :name,
    :classification,
    :type,
    :description,
    :id,
    :congenital,
    :group_name,
    :group_code,
    :chapter,
    :diagnosis_coverages
  ]}

  schema "diagnoses" do
    field :code, :string
    field :name, :string
    field :classification, :string
    field :type, :string
    field :group_description, :string
    field :description, :string
    field :congenital, :string
    field :exclusion_type, :string
    field :group_name, :string
    field :group_code, :string
    field :chapter, :string

    has_many :benefit_diagnoses, Innerpeace.Db.Schemas.BenefitDiagnosis
    many_to_many :benefits, Innerpeace.Db.Schemas.Benefit, join_through: "benefit_diagnoses"

    has_many :exclusion_diseases, Innerpeace.Db.Schemas.ExclusionDisease
    many_to_many :exclusions, Innerpeace.Db.Schemas.Exclusion, join_through: "exclusion_diseases"

    has_many :diagnosis_coverages, Innerpeace.Db.Schemas.DiagnosisCoverage
    has_many :diagnosis_logs, Innerpeace.Db.Schemas.DiagnosisLog,
      on_delete: :delete_all

    has_many :case_rates, Innerpeace.Db.Schemas.CaseRate, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :classification,
      :type,
      :group_description,
      :description,
      :congenital,
      :exclusion_type,
      :group_name,
      :group_code,
      :chapter
    ])
    |> validate_required([
      :code,
      :type,
      :group_description,
      :description,
      :congenital,
    ])
  end

  def changeset_exclusion_type(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusion_type
    ])
    |> validate_required([
      :exclusion_type
    ])
  end

  def changeset_exclusion_type_nil(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusion_type
    ])
  end

end

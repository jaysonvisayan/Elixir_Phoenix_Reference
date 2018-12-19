defmodule Innerpeace.Db.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # General
      add :name, :string
      add :description, :string
      add :limit_applicability, :string
      add :type, :string
      add :limit_type, :string
      add :limit_amount, :decimal
      add :phic_status, :string
      add :standard_product, :string

      # Conditions
      # ------------------------ Age Eligibility
      add :principal_min_age, :integer
      add :principal_min_type, :string
      add :principal_max_age, :integer
      add :principal_max_type, :string

      add :adult_dependent_min_age, :integer
      add :adult_dependent_min_type, :string
      add :adult_dependent_max_age, :integer
      add :adult_dependent_max_type, :string

      add :minor_dependent_min_age, :integer
      add :minor_dependent_min_type, :string
      add :minor_dependent_max_age, :integer
      add :minor_dependent_max_type, :string

      add :overage_dependent_min_age, :integer
      add :overage_dependent_min_type, :string
      add :overage_dependent_max_age, :integer
      add :overage_dependent_max_type, :string

      # ------------------------- Deductions
      # adnb = Annual Deduction - Network Benefits
      # adnnb = Annual Deduction - Non-Network Benefits
      add :adnb, :decimal
      add :adnnb, :decimal

      # opmnb = Out of Pocket Maximum - Network Benefits
      # opmnnb = Out of Pocket Maximum - Network Benefits
      add :opmnb, :decimal
      add :opmnnb, :decimal

      # ------------------------- Room and Board
      add :room_and_board, :string
      add :room_type, :string
      add :room_limit_amount, :decimal
      add :room_upgrade, :integer
      add :room_upgrade_time, :string

      add :coverage_id, :string

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer
      add :include_all_facilities, :boolean

      add :payor_id, references(:payors, type: :binary_id)

      timestamps()
    end
  end
end

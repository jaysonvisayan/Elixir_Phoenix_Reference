defmodule Innerpeace.Db.Schemas.Package do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder, only: [:id, :code, :name]}
  @timestamps_opts [usec: false]
  schema "packages" do
    field :code, :string
    field :name, :string
    field :step, :integer

    has_many :package_payor_procedure, Innerpeace.Db.Schemas.PackagePayorProcedure, on_delete: :delete_all
    has_many :package_facility, Innerpeace.Db.Schemas.PackageFacility, on_delete: :delete_all
    has_many :package_log, Innerpeace.Db.Schemas.PackageLog, on_delete: :delete_all
    has_many :benefit_packages, Innerpeace.Db.Schemas.BenefitPackage, on_delete: :delete_all
    has_many :acu_schedule_packages, Innerpeace.Db.Schemas.BenefitPackage, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :step
    ])
    |> unique_constraint(:code, message: "Package Code already exist!")
    |> validate_required([
      :code,
      :name
    ])
  end

  def update_general_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name
    ])
    |> validate_length(:name, min: 4, message: "Atleast 4 characters")
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [:step])
    |> validate_required([
      :step
    ])
  end

end

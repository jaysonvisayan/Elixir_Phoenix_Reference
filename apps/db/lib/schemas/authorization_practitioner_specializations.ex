defmodule Innerpeace.Db.Schemas.AuthorizationPractitionerSpecialization do
  use Innerpeace.Db.Schema

  schema "authorization_practitioner_specializations" do

    field :role, :string
    belongs_to :authorization, Innerpeace.Db.Schemas.Authorization
    belongs_to :practitioner_specialization, Innerpeace.Db.Schemas.PractitionerSpecialization
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id
    has_many :authorization_procedure_diagnosis, Innerpeace.Db.Schemas.AuthorizationProcedureDiagnosis, on_delete: :delete_all

    has_many :practitioner_days_of_visits, Innerpeace.Db.Schemas.PractitionerDaysOfVisit

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :authorization_id,
      :practitioner_specialization_id,
      :created_by_id,
      :updated_by_id,
      :role
    ])
    |> validate_required([
      :authorization_id,
      :practitioner_specialization_id
    ])
  end
end

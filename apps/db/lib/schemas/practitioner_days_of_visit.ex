defmodule Innerpeace.Db.Schemas.PractitionerDaysOfVisit do
  use Innerpeace.Db.Schema

  schema "practitioner_days_of_visits" do
    field :role, :string
    field :date_from, :date
    field :date_to, :date

    belongs_to :authorization_practitioner_specializations, Innerpeace.Db.Schemas.AuthorizationPractitionerSpecialization

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role,
                     :date_from,
                     :date_to,
                     :authorization_practitioner_specialization_id
    ])
    |> validate_required([
      :role
    ])
  end
end

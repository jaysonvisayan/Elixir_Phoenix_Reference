defmodule Innerpeace.Db.Schemas.PrescriptionClause do
  use Innerpeace.Db.Schema

  schema "prescription_clauses" do
    field :desc, :string

    has_many :facilities, Innerpeace.Db.Schemas.Facility

    timestamps()
  end
end

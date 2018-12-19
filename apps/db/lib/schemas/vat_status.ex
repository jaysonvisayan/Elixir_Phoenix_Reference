defmodule Innerpeace.Db.Schemas.VatStatus do
  use Innerpeace.Db.Schema

  schema "vat_statuses" do
    field :desc, :string
    has_many :facilities, Innerpeace.Db.Schemas.Facility
    timestamps()
  end
end

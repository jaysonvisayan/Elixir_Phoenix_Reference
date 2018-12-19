defmodule Innerpeace.Db.Schemas.ModeOfPayment do
  use Innerpeace.Db.Schema

  schema "mode_of_payments" do
    field :desc, :string
    has_many :facilities, Innerpeace.Db.Schemas.Facility
    timestamps()
  end
end

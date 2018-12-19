defmodule Innerpeace.Db.Schemas.ModeOfRelease do
  use Innerpeace.Db.Schema

  schema "mode_of_releases" do
    field :desc, :string
    has_many :facilities, Innerpeace.Db.Schemas.Facility
    timestamps()
  end
end

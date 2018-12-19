defmodule Innerpeace.Db.Schemas.PractitionerAccountContact do
  use Innerpeace.Db.Schema

  schema "practitioner_account_contacts" do
    field :type, :string
    belongs_to :practitioner_account, Innerpeace.Db.Schemas.PractitionerAccount
    belongs_to :contact, Innerpeace.Db.Schemas.Contact

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:practitioner_account_id, :contact_id])
    |> validate_required([:practitioner_account_id, :contact_id])
  end
end



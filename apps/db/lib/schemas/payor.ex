defmodule Innerpeace.Db.Schemas.Payor do
  use Innerpeace.Db.Schema

  schema "payors" do
    field :name, :string
    field :legal_name, :string
    field :tax_number, :integer
    field :type, :string
    field :status, :string
    field :code, :string

    has_many :products, Innerpeace.Db.Schemas.Product
    has_many :payor_procedures, Innerpeace.Db.Schemas.PayorProcedure
    #has_many :agent, Innerpeace.Agent
    #has_many :practitioner_payors, Innerpeace.PractitionerPayor
    many_to_many :contacts, Innerpeace.Db.Schemas.Contact, join_through: "payor_contacts"
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :legal_name,
      :tax_number,
      :type,
      :status,
      :code
    ])
  end
end

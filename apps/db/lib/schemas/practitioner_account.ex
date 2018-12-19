defmodule Innerpeace.Db.Schemas.PractitionerAccount do
  use Innerpeace.Db.Schema

  schema "practitioner_accounts" do
    field :step, :integer

    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    has_one :practitioner_account_contact, Innerpeace.Db.Schemas.PractitionerAccountContact
    has_many :practitioner_schedules, Innerpeace.Db.Schemas.PractitionerSchedule
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :practitioner_id,
      :account_group_id,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :practitioner_id,
      :account_group_id
    ])
    |> unique_constraint(:account_group_id, name: :practitioner_accounts_practitioner_id_account_group_id_index, message: "Account already selected")
  end

  def changeset_step(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :step,
      :updated_by_id
    ])
  end
end

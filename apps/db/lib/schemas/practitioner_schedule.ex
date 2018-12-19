defmodule Innerpeace.Db.Schemas.PractitionerSchedule do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :day,
    :room,
    :time_to,
    :time_from
  ]}

  schema "practitioner_schedules" do
    field :day, :string
    field :room, :string
    field :time_from, Ecto.Time
    field :time_to, Ecto.Time

    belongs_to :practitioner_account, Innerpeace.Db.Schemas.PractitionerAccount
    belongs_to :practitioner_facility, Innerpeace.Db.Schemas.PractitionerFacility

    timestamps()
  end

  def changeset_pa(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :day,
      :room,
      :time_from,
      :time_to,
      :practitioner_account_id
    ])
    |> validate_required([
      :day,
      :room,
      :time_from,
      :time_to,
      :practitioner_account_id
    ])
  end

  def changeset_pf(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :day,
      :room,
      :time_from,
      :time_to,
      :practitioner_facility_id
    ])
    |> validate_required([
      :day,
      :room,
      :time_from,
      :time_to,
      :practitioner_facility_id
    ])
  end
end

defmodule Innerpeace.Db.Schemas.UserReportingTo do
  use Innerpeace.Db.Schema

  schema "user_reporting_to" do
    belongs_to :user, Innerpeace.Db.Schemas.User
    belongs_to :lead, Innerpeace.Db.Schemas.User, foreign_key: :lead_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :lead_id])
  end

end


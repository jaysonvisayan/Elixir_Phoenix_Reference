defmodule Innerpeace.Db.Schemas.ProcedureLog do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :inserted_at,
    :message
  ]}
  schema "procedure_logs" do
    belongs_to :procedure, Innerpeace.Db.Schemas.Procedure
    belongs_to :payor_procedure, Innerpeace.Db.Schemas.PayorProcedure
    belongs_to :user, Innerpeace.Db.Schemas.User
    field :message, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :payor_procedure_id,
      :procedure_id,
      :user_id,
      :message
    ])
    |> validate_required([
      :user_id,
      :message
    ])
  end

end

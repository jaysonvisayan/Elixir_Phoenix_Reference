defmodule Innerpeace.Db.Schemas.UserAccessActivationLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "user_access_activation_logs" do
    field :code, :string
    field :employee_name, :string
    field :remarks, :string
    field :status, :string

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :user_access_activation_file, Innerpeace.Db.Schemas.UserAccessActivationFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
        :code,
        :user_access_activation_file_id,
        :employee_name,
        :status,
        :created_by_id,
        :remarks
      ])
    |> validate_required([
        :code,
        :user_access_activation_file_id,
        :employee_name,
        :status,
        :created_by_id,
        :remarks
      ])
  end
end

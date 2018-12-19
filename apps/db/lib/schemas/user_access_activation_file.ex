defmodule Innerpeace.Db.Schemas.UserAccessActivationFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "user_access_activation_files" do
    field :filename, :string
    field :batch_no, :string

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    has_many :user_access_activation_logs, Innerpeace.Db.Schemas.UserAccessActivationLog, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_no,
      :filename,
      :created_by_id
    ])
    |> validate_required([
      :batch_no,
      :filename,
      :created_by_id
    ])
  end
end

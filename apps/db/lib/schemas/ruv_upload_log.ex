defmodule Innerpeace.Db.Schemas.RUVUploadLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "ruv_upload_logs" do
    field :filename, :string
    field :ruv_code, :string
    field :ruv_description, :string
    field :ruv_type, :string
    field :value, :decimal
    field :effectivity_date, Ecto.Date
    field :status, :string
    field :remarks, :string

    belongs_to :ruv, Innerpeace.Db.Schemas.RUV
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :ruv_upload_file, Innerpeace.Db.Schemas.RUVUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :ruv_code,
      :ruv_description,
      :ruv_type,
      :value,
      :effectivity_date,
      :status,
      :remarks,
      :created_by_id,
      :ruv_id,
      :ruv_upload_file_id,
    ])
    |> validate_required([
      :filename,
      :status,
      :created_by_id,
      :ruv_upload_file_id
    ])
  end

end

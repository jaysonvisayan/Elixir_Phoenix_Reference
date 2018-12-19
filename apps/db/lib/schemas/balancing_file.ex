defmodule Innerpeace.Db.Schemas.BalancingFile do

  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  schema "balancing_files" do
    field :file, Innerpeace.BalancingFileUploader.Type
    field :name, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
  end

  def changeset_file(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:file])
  end

end

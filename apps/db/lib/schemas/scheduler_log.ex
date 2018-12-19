defmodule Innerpeace.Db.Schemas.SchedulerLog do
  use Innerpeace.Db.Schema

  schema "scheduler_logs" do
    field :message, :string
    field :name, :string
    field :total, :integer

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :message,
      :name,
      :total
    ])
    |> validate_required([
      :message,
      :name
    ])
  end
end

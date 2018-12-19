defmodule Innerpeace.Db.Repo.Migrations.AddRuvRateInRoomTable do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :ruv_rate, :string
    end
  end
end

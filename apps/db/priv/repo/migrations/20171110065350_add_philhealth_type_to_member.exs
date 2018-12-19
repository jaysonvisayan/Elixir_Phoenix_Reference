defmodule Innerpeace.Db.Repo.Migrations.AddPhilhealthTypeToMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :philhealth_type, :string
    end
  end

end


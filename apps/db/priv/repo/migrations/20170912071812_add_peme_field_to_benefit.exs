defmodule Innerpeace.Db.Repo.Migrations.AddPemeFieldToBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :peme, :boolean
  	end
  end
end

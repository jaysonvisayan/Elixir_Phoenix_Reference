defmodule Innerpeace.Db.Repo.Migrations.CreateCommonPassword do
  use Ecto.Migration

  def up do
    create table(:common_passwords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :password, :string

      timestamps()
    end
  end

  def down do
    drop table(:common_passwords)
  end
end

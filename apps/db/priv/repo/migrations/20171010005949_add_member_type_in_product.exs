defmodule Innerpeace.Db.Repo.Migrations.AddMemberTypeInProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :member_type, {:array, :string}
    end
  end
end

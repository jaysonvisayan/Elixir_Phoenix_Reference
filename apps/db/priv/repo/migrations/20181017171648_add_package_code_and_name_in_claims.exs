defmodule Innerpeace.Db.Repo.Migrations.AddPackageCodeAndNameInClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      add :package_code, {:array, :string}
      add :package_name, {:array, :string}
    end
  end
end

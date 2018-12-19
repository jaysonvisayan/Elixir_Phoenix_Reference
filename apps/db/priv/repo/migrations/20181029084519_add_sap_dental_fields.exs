defmodule Innerpeace.Db.Repo.Migrations.AddSapDentalFields do
  use Ecto.Migration

  def up do
    alter table(:benefits) do
      add :frequency, :string
    end

    alter table(:procedures) do
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :delete_all)
    end
    create index(:procedures, :coverage_id)

    alter table(:benefit_limits) do
      add :limit_area_type, {:array, :string}
      add :limit_area, {:array, :string}
    end
  end

  def down do
    alter table(:benefits) do
      remove :frequency
    end

    execute "ALTER TABLE procedures DROP CONSTRAINT procedures_coverage_id_fkey"
    alter table(:procedures) do
      remove :coverage_id
    end

    alter table(:benefit_limits) do
      remove :limit_area_type
      remove :limit_area
    end
  end

end

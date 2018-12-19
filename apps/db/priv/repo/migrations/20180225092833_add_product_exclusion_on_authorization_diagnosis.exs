defmodule Innerpeace.Db.Repo.Migrations.AddProductExclusionOnAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      add :product_exclusion_id, references(:product_exclusions, type: :binary_id)
    end
  end
end

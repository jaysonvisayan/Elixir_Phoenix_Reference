defmodule Innerpeace.Db.Repo.Migrations.AddRemarksAndDuiscontinueDateToBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :discontinue_date, :date
      add :remarks, :string
    end
  end
end

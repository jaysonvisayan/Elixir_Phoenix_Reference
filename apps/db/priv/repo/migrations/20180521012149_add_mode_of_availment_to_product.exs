defmodule Innerpeace.Db.Repo.Migrations.AddModeOfAvailmentToProduct do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:products) do
      add :loa_facilitated, :boolean
      add :reimbursement, :boolean
    end
  end
end

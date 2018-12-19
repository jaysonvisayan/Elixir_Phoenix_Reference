defmodule Innerpeace.Db.Repo.Migrations.AddReasonInMemberSkippingHierarchy do
  use Ecto.Migration

  def change do
    alter table(:member_skipping_hierarchy) do
      add :disapproval_reason, :string
    end
  end
end

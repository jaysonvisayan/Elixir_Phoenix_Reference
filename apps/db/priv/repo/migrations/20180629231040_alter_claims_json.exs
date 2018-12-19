defmodule Innerpeace.Db.Repo.Migrations.AlterClaimsJson do
  use Ecto.Migration

  def change do
     alter table(:claims) do
       remove (:package)
       remove (:diagnosis)
       remove (:physician)
       remove (:procedure)

       add :package, {:array, :map}, default: []
       add :diagnosis, {:array, :map}, default: []
       add :physician, {:array, :map}, default: []
       add :procedure, {:array, :map}, default: []
     end
  end
end

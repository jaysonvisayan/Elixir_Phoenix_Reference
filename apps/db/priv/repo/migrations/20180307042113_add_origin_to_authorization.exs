defmodule Innerpeace.Db.Repo.Migrations.AddOriginToAuthorization do
  use Ecto.Migration

  def change do
  	alter table(:authorizations) do
  	 add :origin, :string
  	end
  end
end

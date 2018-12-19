defmodule Innerpeace.Db.Repo.Migrations.AddControlNumberToAuthorization do
  use Ecto.Migration

  def change do
  	alter table(:authorizations) do
  	 add :control_number, :string
  	end
  end
end

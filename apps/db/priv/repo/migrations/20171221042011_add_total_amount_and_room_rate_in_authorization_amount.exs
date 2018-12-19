defmodule Innerpeace.Db.Repo.Migrations.AddTotalAmountAndRoomRateInAuthorizationAmount do
  use Ecto.Migration

  def change do
    alter table(:authorization_amounts) do
      add :room_rate, :decimal
      add :total_amount, :decimal
    end
  end
end

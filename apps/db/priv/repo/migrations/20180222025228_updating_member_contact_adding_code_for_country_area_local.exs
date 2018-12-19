defmodule Innerpeace.Db.Repo.Migrations.UpdatingMemberContactAddingCodeForCountryAreaLocal do
  use Ecto.Migration

  @moduledoc """
    mcc = mobile_country_code
    mcc2 = mobile2_country_code
    tcc = tel_country_code
    tac = tel_area_code
    tlc = tel_local_code
    fcc = fax_country_code
    fac = fax_area_code
    flc = fax_local_code
  """

  def up do
    alter table(:members) do
      add :mcc, :string
      add :mcc2, :string
      add :tcc, :string
      add :tac, :string
      add :tlc, :string
      add :fcc, :string
      add :fac, :string
      add :flc, :string
    end
  end

  def down do
    alter table(:members) do
      remove(:mcc)
      remove(:mcc2)
      remove(:tcc)
      remove(:tac)
      remove(:tlc)
      remove(:fcc)
      remove(:fac)
      remove(:flc)
    end
  end

end

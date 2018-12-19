defmodule Innerpeace.Db.Base.BankContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Bank
  }

  #Create Seeder
  def insert_or_update_bank(bank_params) do
    bank = get_bank_by_name_and_no(bank_params.account_name, bank_params.account_no)
    if is_nil(bank) do
      create_bank(bank_params)
    else
      update_bank(bank, bank_params)
    end

  end

  #end of Create Seeder

  def get_bank_by_name_and_no(account_name, account_no) do
    Bank
    |> Repo.get_by(account_name: account_name, account_no: account_no)
  end

  def get_bank_by_name(account_name) do
    Bank
    |> Repo.get_by(account_name: account_name)
  end

  def create_bank(attrs \\ %{}) do
    %Bank{}
    |> Bank.changeset(attrs)
    |> Repo.insert()
  end

  def update_bank(%Bank{} = bank, attrs) do
    bank
    |> Bank.changeset(attrs)
    |> Repo.update()
  end

  def get_all_banks do
    Bank
    |> Repo.all()
  end

end

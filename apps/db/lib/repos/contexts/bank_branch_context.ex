defmodule Innerpeace.Db.Base.BankBranchContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.BankBranch
  }

  #Create Seeder
  def insert_or_update_bank_branch(bank_branch_params) do
    bank_branch = get_bank_branch_by_id(bank_branch_params.bank_id)
    if is_nil(bank_branch) do
      create_bank_branch(bank_branch_params)
    else
      update_bank_branch(bank_branch, bank_branch_params)
    end

  end

  #end of Create Seeder

  def get_bank_branch_by_id(bank_id) do
    BankBranch
    |> Repo.get_by(bank_id: bank_id)
  end

  def create_bank_branch(attrs \\ %{}) do
    %BankBranch{}
    |> BankBranch.changeset(attrs)
    |> Repo.insert()
  end

  def update_bank_branch(%BankBranch{} = bank_branch, attrs) do
    bank_branch
    |> BankBranch.changeset(attrs)
    |> Repo.update()
  end

end

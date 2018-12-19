defmodule Innerpeace.Db.Base.AccountGroupContext do
  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.{
    Db.Repo,
    # Db.Schemas.Account,
    # Db.Schemas.AccountComment,
    Db.Schemas.AccountGroup,
    # Db.Schemas.AccountGroupApproval,
    # Db.Schemas.AccountGroupAddress,
    # Db.Schemas.AccountGroupApproval,
    # Db.Schemas.AccountGroupContact,
    # Db.Schemas.AccountLog,
    # Db.Schemas.AccountProduct,
    # Db.Schemas.AccountProductBenefit,
    # Db.Schemas.Bank,
    # Db.Schemas.Contact,
    # Db.Schemas.Fax,
    # Db.Schemas.PaymentAccount,
    # Db.Schemas.Phone,
  }

  #Create Seeder
  def insert_or_update_account_group(account_group_params) do
    account_group = get_account_group_by_code(account_group_params.code)
    if is_nil(account_group) do
      create_an_account_group(account_group_params)
    else
      update_an_account_group(account_group, account_group_params)
    end

  end

  #end of Create Seeder

  def get_account_group_by_code(code) do
    AccountGroup
    |> Repo.get_by(code: code)
  end

  def create_an_account_group(attrs \\ %{}) do
    %AccountGroup{}
    |> AccountGroup.changeset(attrs)
    |> Repo.insert()
  end

  def update_an_account_group(%AccountGroup{} = account_group, attrs) do
    account_group
    |> AccountGroup.changeset(attrs)
    |> Repo.update()
  end

end

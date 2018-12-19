defmodule Innerpeace.Db.Base.EmailContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Email
  }

  def delete_email(id) do
    Email
    |> where([c], c.contact_id == ^id)
    |> Repo.delete_all()
  end

  def create_email(params) do
    %Email{}
    |> Email.changeset(params)
    |> Repo.insert()
  end

  def create_email_kyc_step2(params) do
    %Email{}
    |> Email.changeset_kyc_web_step2(params)
    |> Repo.insert()
  end

  def delete_email_kyc_step2(kyc_id) do
    Email
    |> where([c], c.kyc_bank_id == ^kyc_id)
    |> Repo.delete_all()
  end

  def get_email_kyc_step2(kyc_id) do
    Email
    |> where([e], e.kyc_bank_id == ^kyc_id)
    |> Repo.all()
  end

  def get_email_by_address(address) do
    Email
    |> where([e], e.address == ^address)
    |> Repo.all()
  end

end

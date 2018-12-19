defmodule Innerpeace.Db.Base.PhoneContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Phone
  }

  def delete_phone(id) do
    Phone
    |> where([p], p.contact_id == ^id)
    |> Repo.delete_all()
  end

  def insert_or_update_phone(params) do
    phone = get_phone_by_contact(params)
    if is_nil(phone) do
      create_phone(params)
    else
      update_phone(phone.id, params)
    end
  end

  def get_phone_by_contact(contact) do
    Phone
    |> Repo.get_by(contact)
  end

  def create_phone(params) do
    %Phone{}
    |> Phone.changeset(params)
    |> Repo.insert()
  end

  def update_phone(id, phone_param) do
    id
    |> get_one_phone()
    |> Phone.changeset(phone_param)
    |> Repo.update
  end

  def get_one_phone(id) do
    Phone
    |> Repo.get!(id)
  end

  def create_phone_kyc_step2(params) do
    %Phone{}
    |> Phone.changeset_kyc_web_step2(params)
    |> Repo.insert()
  end

    def delete_phone_kyc_step2(kyc_id) do
    Phone
    |> where([p], p.kyc_bank_id == ^kyc_id)
    |> Repo.delete_all()
  end

end

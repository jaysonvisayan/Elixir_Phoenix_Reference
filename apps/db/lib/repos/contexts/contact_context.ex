defmodule Innerpeace.Db.Base.ContactContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Repo,
    Schemas.Contact
  }

  def get_contact!(id) do
    Contact
    |> Repo.get!(id)
    |> Repo.preload([
      :phones,
      :fax,
      :emails,
      :account_logs
    ])
  end

  def create_fcontact(params) do
    %Contact{}
    |> Contact.facility_contact_changeset(params)
    |> Repo.insert()
  end

  def create_pfcontact(params) do
    %Contact{}
    |> Contact.pfcontact_changeset(params)
    |> Repo.insert()
  end

  def update_fcontact(%Contact{} = contact, params) do
    contact
    |> Contact.facility_contact_changeset(params)
    |> Repo.update()
  end

  def update_pfcontact(contact, params) do
    contact
    |> Contact.pfcontact_changeset(params)
    |> Repo.update()
  end

  def delete_contact(id) do
    Contact
    |> where([c], c.id == ^id)
    |> Repo.delete_all()
  end

  #Seeds for Account Group Address

  def insert_or_update_contact(params) do
    contact = get_contact_by_last_name_and_type(params.last_name, params.type)
    if is_nil(contact) do
      create_one_contact(params)
    else
      update_one_contact(contact.id, params)
    end
  end

  def get_contact_by_last_name_and_type(last_name, type) do
    Contact
    |> Repo.get_by(last_name: last_name, type: type)
  end

  def create_one_contact(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  def update_one_contact(id, contact_param) do
    id
    |> get_one_contact()
    |> Contact.changeset(contact_param)
    |> Repo.update
  end

  def get_one_contact(id) do
    Contact
    |> Repo.get!(id)
  end

  #End of Seeds for Account Group Address

end

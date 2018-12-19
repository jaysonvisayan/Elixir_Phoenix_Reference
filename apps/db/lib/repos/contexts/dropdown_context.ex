defmodule Innerpeace.Db.Base.DropdownContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Dropdown
  }

   def insert_or_update_dropdown(dropdown_params) do
    dropdown = get_dropdown_by_name(dropdown_params.text)
      if is_nil(dropdown) do
        create_dropdown(dropdown_params)
      else
        update_dropdown(dropdown.id, dropdown_params)
      end
  end

  def get_dropdown_by_name(text) do
    Dropdown
    |> Repo.get_by(text: text)
  end

  def update_dropdown(id, dropdown_params) do
    id
    |> get_dropdown()
    |> Dropdown.changeset(dropdown_params)
    |> Repo.update()
  end

  def create_dropdown(dropdown_params) do
    %Dropdown{}
    |> Dropdown.changeset(dropdown_params)
    |> Repo.insert
   end

  def get_dropdown(id) do
    Dropdown
    |> Repo.get!(id)
  end

  def get_all_facility_type do
    Dropdown
    |> where([d], d.type == ^"Facility Type")
    |> Repo.all
  end

  def get_all_facility_category do
    Dropdown
    |> where([d], d.type == ^"Facility Category")
    |> Repo.all
  end

  def get_all_vat_status do
    Dropdown
    |> where([d], d.type == ^"VAT Status")
    |> Repo.all
  end

  def get_all_prescription_clause do
    Dropdown
    |> where([d], d.type == ^"Prescription Clause")
    |> Repo.all
  end

  def get_all_payment_mode do
    Dropdown
    |> where([d], d.type == ^"Payment Mode")
    |> Repo.all
  end

  def get_all_releasing_mode do
    Dropdown
    |> where([d], d.type == ^"Releasing Mode")
    |> Repo.all
  end

  def get_all_practitioner_status do
    Dropdown
    |> where([d], d.type == ^"Practitioner Status")
    |> Repo.all
  end

  def get_practitioner_status(value) do
    Dropdown
    |> where([d], d.value == ^value and d.type == "Practitioner Status")
    |> Repo.one
  end

  def get_practitioner_status_by_id(id) do
    Dropdown
    |> where([d], d.id == ^id)
    |> select([d], d.value)
    |> Repo.one
  end

  def get_all_special_approval do
    Dropdown
    |> where([d], d.type == ^"Special Approval")
    |> Repo.all
  end

  def get_all_cp_clearance do
    Dropdown
    |> where([d], d.type == ^"CP Clearance")
    |> Repo.all
  end

  def get_cp_clearance(value) do
    Dropdown
    |> where([d], d.value == ^value and d.type == "CP Clearance")
    |> Repo.one
  end

  def get_cp_clearance_by_id(id) do
    Dropdown
    |> where([d], d.id == ^id)
    |> select([d], d.value)
    |> Repo.one
  end

  def get_all_mode_of_payment do
    Dropdown
    |> where([d], d.type == "Mode of Payment")
    |> Repo.all()
  end

  def get_all_facility_service_fee_types do
    Dropdown
    |> where([d], d.type == "Facility Service Fee")
    |> Repo.all()
  end

  def get_dropdown_value(id) do
    Dropdown
    |> where([d], d.id == ^id)
    |> Repo.one()
  end

  def get_dropdown_occupation do
    Dropdown
    |> where([d], d.type == "Occupation")
    |> Repo.all
  end

end

defmodule Innerpeace.PayorLink.Web.PractitionerView do
  use Innerpeace.PayorLink.Web, :view

  def check_telephone(contacts) do
    telephone  = for contact <- contacts do
      if contact.type == "telephone" do
        _array = [] ++ contact
      end
    end
    Enum.filter(telephone, fn(x) -> is_nil(x) == false end)
  end

  def check_fax(contacts) do
    fax  = for contact <- contacts do
      if contact.type == "fax" do
        _array = [] ++ contact
      end
    end
    Enum.filter(fax, fn(x) -> is_nil(x) == false end)
  end

  def check_mobile(contacts) do
    mobile  = for contact <- contacts do
      if contact.type == "mobile" do
        _array = [] ++ contact
      end
    end
    Enum.filter(mobile, fn(x) -> is_nil(x) == false end)
  end

  def filter_accounts(practitioner_accounts, accounts) do
    test = for practitioner_account <- practitioner_accounts, into: [] do
      {practitioner_account.account_group.name, practitioner_account.account_group.id}
    end
    accounts -- test
  end

  def check_email(contacts) do
    email  = for contact <- contacts do
        _array = [] ++ contact
    end
    Enum.filter(email, fn(x) -> is_nil(x) == false end)
  end

  def check_cf_fee(pf, ps_id) do
    if not Enum.empty?(pf.practitioner_facility_consultation_fees) do
      pfcf_record =
        for pfcf <- pf.practitioner_facility_consultation_fees do
          if pfcf.practitioner_specialization_id == ps_id do
            pfcf
          end
        end
        |> Enum.uniq
        |> List.delete(nil)
        |> List.first

      if is_nil(pfcf_record) or is_nil(pfcf_record.fee), do: "", else: pfcf_record.fee
    else
      ""
    end
  end

  def loadSubSpecializationIds(practitioner, specializations) do
    selected =
      Enum.filter(practitioner.practitioner_specializations, &(&1.type == "Primary"))
      |> Enum.map(&({&1.specialization.name, &1.specialization.id}))
    specializations -- selected
  end

  def render("load_all_specializations.json", %{specializations: specializations}) do
    %{specialization: render_many(specializations, Innerpeace.PayorLink.Web.PractitionerView, "specialization.json", as: :specialization)}
  end

  def render("specialization.json", %{specialization: specialization}) do
    %{
      id: specialization.id,
      name: specialization.name
    }
  end

  def render("practitioner_specializations.json", %{practitioner_specializations: practitioner_specializations}) do
    %{specialization: render_many(practitioner_specializations, Innerpeace.PayorLink.Web.PractitionerView, "practitioner_specialization.json", as: :practitioner_specialization)}
  end

  def render("practitioner_specialization.json", %{practitioner_specialization: practitioner_specialization}) do
    %{
      id: practitioner_specialization.specialization.id,
      name: practitioner_specialization.specialization.name
    }
  end

  def render("specialization_practitioners.json", %{specialization_practitioners: specialization_practitioners}) do
    %{practitioner: render_many(specialization_practitioners, Innerpeace.PayorLink.Web.PractitionerView, "specialization_practitioner.json", as: :specialization_practitioner)}
  end

  def render("specialization_practitioner.json", %{specialization_practitioner: specialization_practitioner}) do
    %{
      id: specialization_practitioner.practitioner.id,
      name: "#{specialization_practitioner.practitioner.code} | #{specialization_practitioner.practitioner.first_name} #{specialization_practitioner.practitioner.last_name}"
    }
  end

  def check_pf_contacts(pf) do
    cond do
      is_nil(pf.practitioner_facility_contacts) ->
        true
      is_nil(pf.practitioner_facility_contacts.contact) ->
        true
      is_nil(pf.practitioner_facility_contacts.contact.phones) ->
        true
      Enum.empty?(pf.practitioner_facility_contacts.contact.phones) ->
        true
      true ->
        false
    end
  end
end

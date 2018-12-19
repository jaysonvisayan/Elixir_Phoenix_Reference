defmodule MemberLinkWeb.Api.V1.ProfileView do
  use MemberLinkWeb, :view

  def render("show.json", %{member: member}) do
    render_one(member, MemberLinkWeb.Api.V1.ProfileView, "member.json", as: :member)
  end

  def render("dependents.json", %{member: member}) do
    render_many(member, MemberLinkWeb.Api.V1.ProfileView, "dependents.json", as: :dependent)
  end

  def render("dependent.json", %{member: member}) do
    render_one(member, MemberLinkWeb.Api.V1.ProfileView, "dependents.json", as: :dependent)
  end

  def render("member.json", %{member: member}) do
    %{
      id: member.id,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      gender: member.gender,
      age: get_age(member.birthdate, Date.utc_today),
      type: member.type,
      mobile: member.user.mobile,
      email: member.user.email,
      card_number: member.card_no,
      birthday: member.birthdate,
      extension: member.suffix,
      company: render_one(member.account_group, MemberLinkWeb.Api.V1.ProfileView, "company.json", as: :account_group),
      photo: render_one(member, MemberLinkWeb.Api.V1.ProfileView, "photo.json", as: :photo),
      uploads: render_many(member.files, MemberLinkWeb.Api.V1.ProfileView, "uploads.json", as: :upload)
    }
  end

  def render("dependents.json", %{dependent: member}) do
    %{
      id: member.id,
      salutation: member.salutation,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      gender: member.gender,
      age: get_age(member.birthdate, Date.utc_today),
      mobile: member.mobile,
      email: member.email
    }
  end

  def render("company.json", %{account_group: account_group}) do
    %{
      code: account_group.code,
      name: account_group.name
    }
  end

  def render("emergency_contact.json", %{contact: _contact}) do
    %{
      "message": "Successfully Submitted Info",
      "code": 200
    }
  end

  def render("update_emergency_contact.json", %{contact: _contact}) do
    %{
      "message": "Successfully Updated Info",
      "code": 200
    }
  end

  def render("update_contact_details.json", %{user: _user}) do
    %{
      "message": "Contact details successfully updated",
      "code": 200
    }
  end

  def render("member_emergency_contact.json", %{emergency_contact: member}) do
    %{
      contact_person: render_one(member.emergency_contact, MemberLinkWeb.Api.V1.ProfileView, "contact_person.json", as: :contact),
      info: render_one(member, MemberLinkWeb.Api.V1.ProfileView, "info.json", as: :info),
      hospital: render_one(member, MemberLinkWeb.Api.V1.ProfileView, "emergency_hospital.json", as: :member)
    }
  end

  def render("emergency_hospital.json", %{member: member}) do
    %{
    name: member.emergency_contact.hospital_name,
    phone: member.emergency_contact.hospital_telephone,
    hmo: "Maxicare",
    card_number: member.card_no,
    policy_number: member.policy_no,
    customer_care_number: member.emergency_contact.customer_care_number
    }
  end
  def render("info.json", %{info: info}) do
    %{
      blood_type: info.blood_type,
      allergies: info.allergies,
      medication: info.medication
    }
  end

  def render("contact_person.json", %{contact: contact}) do
    %{
      name: contact.ecp_name,
      relationship: contact.ecp_relationship,
      phones: %{
          phone_1: contact.ecp_phone,
          phone_2: contact.ecp_phone2
      },
      email: contact.ecp_email
    }
  end

  def render("phones.json", %{phones: phone}) do
    %{
      phone: phone.number
    }
  end

  def render("emails.json", %{emails: email}) do
    %{
      email: email.address
    }
  end

  defp get_age(birth_date, date_today) do
    birth_year = birth_date.year
    birth_month = birth_date.month
    birth_day = birth_date.day
    date_year = date_today.year
    date_month = date_today.month
    date_day = date_today.day
    age = date_year - birth_year
    if birth_month >= date_month && birth_day > date_day do
      age - 1
    else
      age
    end
  end

  def render("uploads.json", %{upload: upload}) do
    link =
      case Application.get_env(:member_link, :env) do
        :dev ->
          "localhost:4001"
        :prod ->
          "http://memberlink-ip-staging.medilink.com.ph"
        _ ->
          nil
      end

    if is_nil(upload.link_type) do
      image_extension = Enum.at(String.split(upload.image_type.file_name, "."), 1)
      %{
        name: upload.name,
        link: "#{link}/uploads/images/#{upload.id}/original.#{image_extension}"
      }
    else
      %{
        name: upload.name,
        link: "#{link}/uploads/files/#{upload.id}/#{upload.link_type.file_name}"
      }
    end
  end

  def render("photo.json", %{photo: upload}) do
    link =
      case Application.get_env(:member_link, :env) do
        :dev ->
          "localhost:4001"
        :prod ->
          "http://memberlink-ip-staging.medilink.com.ph"
        _ ->
          nil
      end

    if not is_nil(upload.photo) do
      image_extension = Enum.at(String.split(upload.photo.file_name, "."), 1)
      %{
        #link: upload.image_type
        link: "#{link}/uploads/images/#{upload.id}/original.#{image_extension}"
      }
    else
      nil
    end
  end

  def render("show_photo.json", %{photo: upload}) do
    link =
      case Application.get_env(:member_link, :env) do
        :dev ->
          "localhost:4001"
        :prod ->
          "http://memberlink-ip-staging.medilink.com.ph"
        _ ->
          nil
      end
    %{
      photo:
      if not is_nil(upload.photo) do
        image_extension = Enum.at(String.split(upload.photo.file_name, "."), 1)
        %{
          #link: upload.image_type
          link: "#{link}/uploads/images/#{upload.id}/original.#{image_extension}"
        }
      else
        nil
      end
    }
  end

  def render("request_cor.json", %{prof_cor: prof_cor}) do
    %{
      message: "Your personal information correction request has been sent",
      status: 200
    }
  end
end

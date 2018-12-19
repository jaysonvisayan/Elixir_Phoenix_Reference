defmodule MemberLinkWeb.Api.V1.KycView do
  use MemberLinkWeb, :view

  def render("kyc.json", %{kyc: _kyc}) do
    %{
      "message": "Successfully Submitted Info",
      "code": 200
    }
  end

  def render("get_kyc.json", %{kyc: kyc}) do
    %{
      personal: %{
        country: kyc.country,
        city: kyc.city,
        citizenship: kyc.citizenship,
        civil_status: kyc.civil_status,
        mother_maiden: Enum.join(["#{kyc.mm_last_name},", kyc.mm_first_name, kyc.mm_middle_name], " "),
        tin: kyc.tin,
        sss_number: kyc.sss_number,
        unified_id_number: kyc.unified_id_number,
        identification_card: kyc.id_card
      },
      professional: %{
        educational_attainment: kyc.educational_attainment,
        company: %{
          name: kyc.company_name,
          position_title: kyc.position_title ,
          occupation: kyc.occupation,
          nature_of_work: kyc.nature_of_work,
          source_of_fund: kyc.source_of_fund
        }
      },
      contact: %{
        phones: render_many(kyc.phone, MemberLinkWeb.Api.V1.KycView, "phones.json", as: :phone),
        emails: render_many(kyc.email, MemberLinkWeb.Api.V1.KycView, "emails.json", as: :email),
        address: render_many(kyc.address, MemberLinkWeb.Api.V1.KycView, "addresses.json", as: :address)
      },
      uploads: render_many(kyc.file, MemberLinkWeb.Api.V1.KycView, "uploads.json", as: :upload)
    }
  end

  def render("phones.json", %{phone: phone}) do
    %{
      number: phone.number,
      type: phone.type
    }
  end

  def render("emails.json", %{email: email}) do
    %{
      email: email.address
    }
  end

  def render("addresses.json", %{address: address}) do
    %{
      street: address.street,
      district: address.district,
      country: address.country,
      city: address.city,
      postal_code: address.postal_code
    }
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
        #link: upload.image_type
        link: "#{link}/uploads/images/#{upload.id}/original.#{image_extension}"
      }
    else
      file_extension = Enum.at(String.split(upload.link_type.file_name, "."), 1)
      %{
        name: upload.name,
        #link: upload.link_type
        link: "#{link}/uploads/files/#{upload.id}/#{upload.link_type.file_name}"
      }
    end
  end
end

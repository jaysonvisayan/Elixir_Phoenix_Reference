defmodule MemberLinkWeb.KycView do
  use MemberLinkWeb, :view

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> MemberLinkWeb.LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/payor_link/assets/static", "")
  end

  def get_file(files, type) do
    files
    |> Enum.into([], &(if &1.name == type, do: &1))
    |> Enum.reject(&(is_nil(&1)))
    |> Enum.uniq()
    |> List.first()
  end

  def to_ellipsis(str) do
    if String.length(str) > 20 do
      str = String.slice(str, 0..20)
      Enum.join([str, "..."])
    else
      str
    end
  end

  def file_url_for(file, id) do
    if is_nil(file) do
      "None"
    else
      "/uploads/files/#{id}/#{file.file_name}"
    end
  end

  def image_url_for(file, id) do
    if is_nil(file) do
      "None"
    else
      "/uploads/images/#{id}/standard.png"
    end
  end

  def filter_skip(kyc) do
    Enum.all?([
      not is_nil(kyc.country_of_birth),
      not is_nil(kyc.city_of_birth),
      not is_nil(kyc.citizenship),
      not is_nil(kyc.civil_status),
      not is_nil(kyc.mm_first_name),
      not is_nil(kyc.mm_middle_name),
      not is_nil(kyc.mm_last_name),
      not is_nil(kyc.educational_attainment),
      not is_nil(kyc.company_name),
      not is_nil(kyc.position_title),
      not is_nil(kyc.occupation),
      not is_nil(kyc.nature_of_work),
      not is_nil(kyc.source_of_fund)
    ])
  end

  def kyc_occupations(dropdowns) do
  Enum.map(dropdowns, &({&1.text, &1.id}))
  end

end

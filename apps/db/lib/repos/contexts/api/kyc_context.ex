defmodule Innerpeace.Db.Base.Api.KycContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.{
    Schemas.KycBank,
    Schemas.Member,
    Schemas.Phone,
    Schemas.Email,
    Schemas.Address,
    Base.MemberContext,
    Parsers.MemberLinkParser
  }
 alias Innerpeace.Db.Schemas.File, as: CardFile
 alias Innerpeace.Db.Repo

  def create_kyc_bank(user, params) do
    with member = %Member{} <- MemberContext.get_member(user.member_id),
         {:ok, "validated"}  <- validate_kyc_bank(member.id, params),
         {:ok, "phones"} <- validate_phones(params),
         {:ok, "emails"} <- validate_emails(params),
         {:ok, address} <- validate_address(params),
         {:ok, "uploads"} <- validate_uploads(params["uploads"])
    do
         {:ok, kyc_bank} = insert_or_update_kyc_bank(member.id, params)
         create_or_update_phones(kyc_bank.id, params)
         create_or_update_emails(kyc_bank.id, params)
         create_or_update_address(kyc_bank.id, params)
         MemberLinkParser.upload_a_file_kyc(kyc_bank.id, params["uploads"])
          {:ok, "kyc_bank"}
    else
      {:error_number, message} ->
        {:error_number, message}
      {:error, "phones"} ->
        {:error_phones}
      {:error, "emails"} ->
        {:error_emails}
      nil ->
        {:member_not_found}
      {:error_upload_params} ->
        {:error_upload_params}
      {:error_base_64} ->
        {:error_base_64}
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:server_error}
    end
  end

  def insert_or_update_kyc_bank(member_id, params) do
    member = Member
             |> Repo.get!(member_id)
             |> Repo.preload(:kyc_bank)
    data =
      %{
        country: params["personal"]["country"],
        city: params["personal"]["city"],
        citizenship: params["personal"]["citizenship"],
        civil_status: params["personal"]["civil_status"],
        #mother_maiden: params["personal"]["mother_maiden"],
        mm_first_name: params["personal"]["mother_first_name"],
        mm_middle_name: params["personal"]["mother_middle_name"],
        mm_last_name: params["personal"]["mother_last_name"],
        tin: params["personal"]["tin"],
        sss_number: params["personal"]["sss_number"],
        unified_id_number: params["personal"]["unified_id_number"],
        educational_attainment: params["professional"]["educational_attainment"],
        position_title: params["professional"]["company"]["position_title"],
        occupation: params["professional"]["company"]["occupation"],
        source_of_fund: params["professional"]["company"]["source_of_fund"],
        company_name: params["professional"]["company"]["name"],
        nature_of_work: params["professional"]["company"]["nature_of_work"],
        member_id: member_id,
        id_card: params["personal"]["identification_card"]
      }

    if is_nil(member.kyc_bank) do
      %KycBank{}
      |> KycBank.changeset(data)
      |> Repo.insert()
    else
      KycBank
      |> Repo.get_by(member_id: member.id)
      |> KycBank.changeset(data)
      |> Repo.update()
    end
  end

  def create_or_update_phones(kyc_bank_id, params) do
    kyc_bank = KycBank
               |> Repo.get!(kyc_bank_id)
               |> Repo.preload(:phone)
    if not is_nil(kyc_bank.phone) do
      Phone
      |> where([p], p.kyc_bank_id == ^kyc_bank.id)
      |> Repo.delete_all()
    end
    for phone <- params["contact"]["phones"] do
      data =
        %{
          number: phone["number"],
          type: phone["type"],
          kyc_bank_id: kyc_bank_id
        }
      %Phone{}
      |> Phone.changeset_kyc(data)
      |> Repo.insert()
    end
      {:ok, "phones"}
  end

  def create_or_update_emails(kyc_bank_id, params) do
    kyc_bank = KycBank
               |> Repo.get!(kyc_bank_id)
               |> Repo.preload(:email)
    if not is_nil(kyc_bank.email) do
      Email
      |> where([e], e.kyc_bank_id == ^kyc_bank.id)
      |> Repo.delete_all()
    end
    for email <- params["contact"]["emails"] do
      data =
        %{
          address: email["email"],
          type: "email",
          kyc_bank_id: kyc_bank_id
        }

      %Email{}
      |> Email.changeset_kyc(data)
      |> Repo.insert()
    end
      {:ok, "emails"}
  end

  def create_or_update_address(kyc_bank_id, params) do
    kyc_bank = KycBank
             |> Repo.get!(kyc_bank_id)
             |> Repo.preload(:address)

    if not is_nil(kyc_bank.address) do
      Address
      |> where([a], a.kyc_bank_id == ^kyc_bank.id)
      |> Repo.delete_all()
    end
    data =
      %{
        street: params["contact"]["street"],
        district: params["contact"]["district"],
        postal_code: params["contact"]["postal_code"],
        city: params["contact"]["city"],
        country: params["contact"]["country"],
        kyc_bank_id: kyc_bank_id
      }
    %Address{}
    |> Address.changeset_kyc(data)
    |> Repo.insert()
  end

  # def create_uploads(kyc_bank_id,params) do
  #   for upload <- params["uploads"] do
  #     data =
  #       %{
  #         link: upload["link"],
  #         link_type: upload["type"],
  #         kyc_bank_id: kyc_bank_id
  #       }
  #     File.changeset_kyc_upload(%File{},data)
  #     |> Repo.insert()
  #   end
  #     {:ok, "uploads"}
  # end

   def validate_kyc_bank(member_id, params) do
    data =
      %{
        country: params["personal"]["country"],
        city: params["personal"]["city"],
        citizenship: params["personal"]["citizenship"],
        civil_status: params["personal"]["civil_status"],
        #mother_maiden: params["personal"]["mother_maiden"],
        mm_first_name: params["personal"]["mother_first_name"],
        mm_middle_name: params["personal"]["mother_middle_name"],
        mm_last_name: params["personal"]["mother_last_name"],
        tin: params["personal"]["tin"],
        sss_number: params["personal"]["sss_number"],
        unified_id_number: params["personal"]["unified_id_number"],
        educational_attainment: params["professional"]["educational_attainment"],
        position_title: params["professional"]["company"]["position_title"],
        occupation: params["professional"]["company"]["occupation"],
        source_of_fund: params["professional"]["company"]["source_of_fund"],
        company_name: params["professional"]["company"]["name"],
        nature_of_work: params["professional"]["company"]["nature_of_work"],
        member_id: member_id,
        id_card: params["personal"]["identification_card"]
      }
    changeset = KycBank.changeset(%KycBank{}, data)
    if changeset.errors == [] do
      if Regex.match?(~r/^[0-9]*$/, data.tin) == false do
        {:error_number, "Invalid Tin"}
      else
        if Regex.match?(~r/^[0-9]*$/, data.sss_number) == false do
          {:error_number, "Invalid SSS Number"}
        else
          if Regex.match?(~r/^[0-9]*$/, data.unified_id_number) == false do
            {:error_number, "Invalid Unified ID Number"}
          else
            {:ok, "validated"}
          end
        end
      end
    else
      {:error, changeset}
    end
  end

  def validate_phones(params) do
    result = for phone <- params["contact"]["phones"] do
      data =
        %{
          number: phone["number"],
          type: phone["type"],
          kyc_bank_id: Ecto.UUID.generate()
        }
      p = Phone.changeset_kyc(%Phone{}, data)
      if p.errors == [] do
        if phone["type"] == "mobile" do
          if Regex.match?(~r/^[0-9]*$/, phone["number"]) == true do
            "ok"
          else
            "error"
          end
        end
        if phone["type"] == "telephone" do
          if Regex.match?(~r/^(\()?\d{2}(\))?(-|\s)?\d{3}(-|\s)\d{4}$/, phone["number"]) == true do
            "ok"
          else
            "error"
          end
        end
      else
        "error"
      end
    end
    if Enum.member?(result, "error") do
      {:error, "phones"}
    else
      {:ok, "phones"}
    end
  end

  def validate_emails(params) do
    result = for email <- params["contact"]["emails"] do
      data =
        %{
          address: email["email"],
          type: "email",
          kyc_bank_id: Ecto.UUID.generate()
        }
      e = Email.changeset_kyc(%Email{}, data)
      if e.errors == [] do
        "ok"
      else
        "error"
      end
    end
    if Enum.member?(result, "error") do
      {:error, "emails"}
    else
      {:ok, "emails"}
    end
  end

  def validate_address(params) do
    data =
      %{
        street: params["contact"]["street"],
        district: params["contact"]["district"],
        postal_code: params["contact"]["postal_code"],
        city: params["contact"]["city"],
        country: params["contact"]["country"],
        kyc_bank_id: Ecto.UUID.generate()
      }
    changeset = Address.changeset_kyc(%Address{}, data)
    if changeset.errors == [] do
      {:ok, "address"}
    else
      {:error, changeset}
    end
  end

  def validate_uploads(datas) do
    if datas == [] or is_nil(datas) do
      {:error_upload_params}
    else
      data = for data <- datas do
        with {:ok, "upload"} <- validate_upload(data),
             {:ok, data} <- Base.decode64(data["base_64_encoded"])
        do
          "ok"
        else
          {:error, "upload"} ->
            "error_upload"
          :error ->
            "error_base_64"
        end
      end
      cond do
        Enum.member?(data, "error_upload") ->
          {:error_upload_params}
        Enum.member?(data, "error_base_64") ->
          {:error_base_64}
        true ->
          {:ok, "uploads"}
      end
    end
  end

  def validate_upload_profile(data) do
    if is_nil(data) do
      {:error_upload_params}
    else
      data =
        with {:ok, "upload"} <- validate_upload(data),
             {:ok, data} <- Base.decode64(data["base_64_encoded"])
        do
          "ok"
        else
          {:error, "upload"} ->
            "error_upload"
          :error ->
            "error_base_64"
        end
      cond do
        data == "error_upload" ->
          {:error_upload_params}
        data == "error_base_64" ->
          {:error_base_64}
        true ->
          {:ok, "uploads"}
      end
    end
  end

  def validate_upload(params) do
    types = %{
      base_64_encoded: :string,
      type: :string,
      extension: :string,
      link: :string,
      name: :string
    }

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))
      |> Ecto.Changeset.validate_required([
        :base_64_encoded,
        :type,
        :extension,
        :link,
        :name
      ], message: "is required")

    if changeset.valid? and (params["type"] == "file" or params["type"] == "image") do
      {:ok, "upload"}
    else
      {:error, "upload"}
    end
  end

  def get_kyc_bank_info(member_id) do
    kyc_bank = KycBank
               |> where([k], k.member_id == ^member_id)
               |> Repo.one()
               |> Repo.preload([:phone, :email, :address, :file])
    if is_nil(kyc_bank) do
      {:no_results_found}
    else
      {:ok, kyc_bank}
    end
  end
end

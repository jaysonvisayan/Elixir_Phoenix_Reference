defmodule Innerpeace.Db.Parsers.MemberLinkParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.File, as: CardFile
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.KycBank
  alias Innerpeace.Db.Schemas.Member
  alias Innerpeace.Db.Schemas.ProfileCorrection
  alias Innerpeace.Db.Base.MemberContext
  alias Innerpeace.Db.Base.Api.ProfileCorrectionContext
  import Ecto.Query

  #for kyc/bank
  def upload_a_file_kyc(kyc_bank_id, params) do
    for param <- params do
      if param["type"] == "file" do
        {:ok, file} = insert_file_kyc(kyc_bank_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/files/')
          :dev ->
            Path.expand('./uploads/files/')
          :prod ->
            Path.expand('./uploads/files/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/files'))
        File.write!(pathsample <> "/KYC_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_file_kyc(param, file)
        File.rm_rf(pathsample <> "/KYC_#{file.link}.#{param["extension"]}")
      end
      if param["type"]  == "image" do
        {:ok, file} = insert_file_kyc(kyc_bank_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/images/')
          :dev ->
            Path.expand('./uploads/images/')
          :prod ->
            Path.expand('./uploads/images/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/images'))
        File.write!(pathsample <> "/KYC_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_image_kyc(param, file)
        File.rm_rf(pathsample <> "/KYC_#{file.link}.#{param["extension"]}")
      end
    end
  end

  def insert_file_kyc(kyc_bank_id, params) do
    kyc_bank = KycBank
               |> Repo.get!(kyc_bank_id)
               |> Repo.preload(:file)
    data =
      %{
        name: params["name"],
        link: params["link"],
        kyc_bank_id: kyc_bank_id
      }

    file = CardFile
           |> Repo.get_by(data)

    if is_nil(file) do
      %CardFile{}
      |> CardFile.changeset_kyc_upload(data)
      |> Repo.insert()
    else
      file =
        file
        |> Repo.delete()

      %CardFile{}
      |> CardFile.changeset_kyc_upload(data)
      |> Repo.insert()
    end
  end

  def update_file_kyc(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
      :dev ->
        Path.expand('./uploads/files/')
      :prod ->
        Path.expand('./uploads/files/')
      _ ->
        nil
    end

    file_path = "KYC_#{file.link}.#{params["extension"]}"
    file_params = %{"link_type" => %Plug.Upload{
      content_type: "application/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }}

    file
    |> CardFile.changeset_kyc_file(file_params)
    |> Repo.update()
  end

  def update_image_kyc(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "KYC_#{file.link}.#{params["extension"]}"
    file_upload = %Plug.Upload{
      content_type: "image/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    file_params = %{
      "image_type" => file_upload
    }

    file
    |> CardFile.changeset_kyc_image(file_params)
    |> Repo.update()
  end

  #End KYC

  #Start OPLab

  def upload_a_file_op_lab(op_lab_id, params) do
    for param <- params do
      if param["type"] == "file" do
        {:ok, file} = insert_file_op_lab(op_lab_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/files/')
          :dev ->
            Path.expand('./uploads/files/')
          :prod ->
            Path.expand('./uploads/files/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/files'))
        File.write!(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_file_op_lab(param, file)
        File.rm_rf(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}")
      end
      if param["type"]  == "image" do
        {:ok, file} = insert_file_op_lab(op_lab_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/images/')
          :dev ->
            Path.expand('./uploads/images/')
          :prod ->
            Path.expand('./uploads/images/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/images'))
        File.write!(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_image_op_lab(param, file)
        File.rm_rf(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}")
      end
    end
  end

  def insert_file_op_lab(op_lab_id, params) do
    data =
      %{
        link: params["link"],
        authorization_id: op_lab_id
      }

    file = CardFile
           |> Repo.get_by(data)

    if is_nil(file) do
      %CardFile{}
      |> CardFile.changeset_authorization_upload(data)
      |> Repo.insert()
    else
      file =
        file
        |> Repo.delete()

      %CardFile{}
      |> CardFile.changeset_authorization_upload(data)
      |> Repo.insert()
    end
  end

  def update_file_op_lab(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
      :dev ->
        Path.expand('./uploads/files/')
      :prod ->
        Path.expand('./uploads/files/')
      _ ->
        nil
    end

    file_path = "OPLab_#{file.link}.#{params["extension"]}"
    file_params = %{"link_type" => %Plug.Upload{
      content_type: "application/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }}

    file
    |> CardFile.changeset_authorization_file(file_params)
    |> Repo.update()
  end

  def update_image_op_lab(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "OPLab_#{file.link}.#{params["extension"]}"
    file_upload = %Plug.Upload{
      content_type: "image/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    file_params = %{
      "image_type" => file_upload
    }

    file
    |> CardFile.changeset_kyc_image(file_params)
    |> Repo.update()
  end
  #End OPLab

  # Start of Update profile

  def upload_a_file_profile(member_id, params) do
    for param <- params do
      if param["type"] == "file" do
        {:ok, file} = insert_file_profile(member_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/files/')
          :dev ->
            Path.expand('./uploads/files/')
          :prod ->
            Path.expand('./uploads/files/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/files'))
        File.write!(pathsample <> "/Profile_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_file_profile(param, file)
        File.rm_rf(pathsample <> "/Profile_#{file.link}.#{param["extension"]}")
      end
      if param["type"]  == "image" do
        {:ok, file} = insert_file_profile(member_id, param)
        pathsample = case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/images/')
          :dev ->
            Path.expand('./uploads/images/')
          :prod ->
            Path.expand('./uploads/images/')
          _ ->
            nil
        end
        File.mkdir_p!(Path.expand('./uploads/images'))
        File.write!(pathsample <> "/Profile_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_image_profile(param, file)
        File.rm_rf(pathsample <> "/Profile_#{file.link}.#{param["extension"]}")
      end
    end
  end

  def insert_file_profile(member_id, params) do
    data =
      %{
        link: params["link"],
        member_id: member_id
      }

    file = CardFile
           |> Repo.get_by(data)

    if is_nil(file) do
      %CardFile{}
      |> CardFile.changeset_profile_upload(data)
      |> Repo.insert()
    else
      file =
        file
        |> Repo.delete()

      %CardFile{}
      |> CardFile.changeset_profile_upload(data)
      |> Repo.insert()
    end
  end

  def update_file_profile(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
      :dev ->
        Path.expand('./uploads/files/')
      :prod ->
        Path.expand('./uploads/files/')
      _ ->
        nil
    end

    file_path = "OPLab_#{file.link}.#{params["extension"]}"
    file_params = %{"link_type" => %Plug.Upload{
      content_type: "application/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }}

    file
    |> CardFile.changeset_profile_file(file_params)
    |> Repo.update()
  end

  def update_image_profile(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "OPLab_#{file.link}.#{params["extension"]}"
    file_upload = %Plug.Upload{
      content_type: "image/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    file_params = %{
      "image_type" => file_upload
    }

    file
    |> CardFile.changeset_profile_image(file_params)
    |> Repo.update()
  end

  # End Update Profile

  def upload_an_image_profile(member_id, params) do
    member = MemberContext.get_member(member_id)
    pathsample = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end
    File.mkdir_p!(Path.expand('./uploads/images'))
    File.write!(pathsample <> "/#{params["name"]}_#{params["link"]}.#{params["extension"]}", Base.decode64!(params["base_64_encoded"]))
    {:ok, member} = update_member_profile_photo(params, member)
    File.rm_rf(pathsample <> "/#{params["name"]}_#{params["link"]}.#{params["extension"]}")
    member
  end

  def update_member_profile_photo(params, member) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "#{params["name"]}_#{params["link"]}.#{params["extension"]}"
    file_upload = %Plug.Upload{
      content_type: "image/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    file_params = %{
      "photo" => file_upload
    }

    {:ok, member} = MemberContext.update_member_photo(member, file_params)
  end

  def upload_an_id_card_profile(prof_cor_id, params) do
    prof_cor = ProfileCorrectionContext.get_profile_correction(prof_cor_id)
    pathsample = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end
    File.mkdir_p!(Path.expand('./uploads/images'))
    File.write!(pathsample <> "/#{params["name"]}_#{params["link"]}.#{params["extension"]}", Base.decode64!(params["base_64_encoded"]))
    {:ok, prof_cor} = update_profile_id_card(params, prof_cor)
    File.rm_rf(pathsample <> "/#{params["name"]}_#{params["link"]}.#{params["extension"]}")
    {:ok, prof_cor}
  end

  def update_profile_id_card(params, prof_cor) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/images/')
      :dev ->
        Path.expand('./uploads/images/')
      :prod ->
        Path.expand('./uploads/images/')
      _ ->
        nil
    end

    file_path = "#{params["name"]}_#{params["link"]}.#{params["extension"]}"
    file_upload = %Plug.Upload{
      content_type: "image/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    file_params = %{
      "id_card" => file_upload
    }

    {:ok, prof_cor} = ProfileCorrectionContext.update_id_card(prof_cor, file_params)
  end

  # def upload_an_id_profile(member_id, params) do
  #   member = for param <- params do
  #     if param["type"] == "file" do
  #       {:ok, file} = insert_id_member(member_id, param)
  #       pathsample = case Application.get_env(:db, :env) do
  #         :test ->
  #           Path.expand('./../../uploads/files/')
  #         :dev ->
  #           Path.expand('./uploads/files/')
  #         :prod ->
  #           Path.expand('./uploads/files/')
  #         _ ->
  #           nil
  #       end
  #       File.mkdir_p!(Path.expand('./uploads/files'))
  #       File.write!(pathsample <> "/#{param["name"]}_#{param["link"]}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
  #       update_file_id_member(param, file)
  #       File.rm_rf(pathsample <> "/#{param["name"]}_#{param["link"]}.#{param["extension"]}")
  #     end
  #     if param["type"]  == "image" do
  #       {:ok, file} = insert_id_member(member_id, param)
  #       pathsample = case Application.get_env(:db, :env) do
  #         :test ->
  #           Path.expand('./../../uploads/images/')
  #         :dev ->
  #           Path.expand('./uploads/images/')
  #         :prod ->
  #           Path.expand('./uploads/images/')
  #         _ ->
  #           nil
  #       end
  #       File.mkdir_p!(Path.expand('./uploads/images'))
  #       File.write!(pathsample <> "/#{param["name"]}_#{param["link"]}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
  #       update_image_id_member(param, file)
  #       File.rm_rf(pathsample <> "/#{param["name"]}_#{param["link"]}.#{param["extension"]}")
  #     end
  #     member = MemberContext.get_member(file.member_id)
  #   end
  #   member = member
  #            |> Enum.uniq()
  #            |> List.first()
  # end

  # def insert_id_member(member_id, params) do
  #   member = Member
  #              |> Repo.get!(member_id)
  #              |> Repo.preload(:files)
  #   data =
  #     %{
  #       name: params["name"],
  #       link: params["link"],
  #       member_id: member_id
  #     }

  #   file = CardFile
  #          |> Repo.get_by(%{member_id: data.member_id, name: data.name})

  #   if is_nil(file) do
  #     %CardFile{}
  #     |> CardFile.changeset_profile_id(data)
  #     |> Repo.insert()
  #   else
  #     file =
  #       file
  #       |> Repo.delete()

  #     %CardFile{}
  #     |> CardFile.changeset_profile_id(data)
  #     |> Repo.insert()
  #   end
  # end

  # def update_file_id_member(params, file) do
  #   path = case Application.get_env(:db, :env) do
  #     :test ->
  #       Path.expand('./../../uploads/files/')
  #     :dev ->
  #       Path.expand('./uploads/files/')
  #     :prod ->
  #       Path.expand('./uploads/files/')
  #     _ ->
  #       nil
  #   end

  #   file_path = "#{params["name"]}_#{params["link"]}.#{params["extension"]}"
  #   file_params = %{"link_type" => %Plug.Upload{
  #     content_type: "application/#{params["extension"]}",
  #     path: "#{path}/#{file_path}",
  #     filename: "#{file_path}"
  #   }}

  #   file
  #   |> CardFile.changeset_kyc_file(file_params)
  #   |> Repo.update()
  # end

  # def update_image_id_member(params, file) do
  #   path = case Application.get_env(:db, :env) do
  #     :test ->
  #       Path.expand('./../../uploads/images/')
  #     :dev ->
  #       Path.expand('./uploads/images/')
  #     :prod ->
  #       Path.expand('./uploads/images/')
  #     _ ->
  #       nil
  #   end

  #   file_path = "#{params["name"]}_#{params["link"]}.#{params["extension"]}"
  #   file_upload = %Plug.Upload{
  #     content_type: "image/#{params["extension"]}",
  #     path: "#{path}/#{file_path}",
  #     filename: "#{file_path}"
  #   }

  #   file_params = %{
  #     "image_type" => file_upload
  #   }

  #   file
  #   |> CardFile.changeset_kyc_image(file_params)
  #   |> Repo.update()
  # end

end

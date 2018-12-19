defmodule Innerpeace.Db.Parsers.KycUploadParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.File, as: CardFile
  alias Innerpeace.Db.Repo

  def upload_a_file(kyc_bank_id, params) do
    for param <- params do
      if param["type"] == "file" do
        {:ok, file} = insert_file(kyc_bank_id, param)
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
        File.write!(pathsample <> "/KYC_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_file(param, file)
        File.rm_rf(pathsample <> "/KYC_#{file.link}.#{param["extension"]}")
      end
      if param["type"]  == "image" do
        {:ok, file} = insert_file(kyc_bank_id, param)
        # pathsample =
        case Application.get_env(:db, :env) do
          :test ->
            Path.expand('./../../uploads/files/')
          :dev ->
            Path.expand('./uploads/files/')
          :prod ->
            Path.expand('./uploads/files/')
          _ ->
            nil
        end
        pathsample = Path.expand("./uploads/images")
        File.write!(pathsample <> "/KYC_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_image(param, file)
        File.rm_rf(pathsample <> "/KYC_#{file.link}.#{param["extension"]}")
      end
    end
  end

  def insert_file(kyc_bank_id, params) do
    data =
      %{
        link: params["link"],
        kyc_bank_id: kyc_bank_id
      }
    %CardFile{}
    |> CardFile.changeset_authorization_upload(data)
    |> Repo.insert()
  end

  def update_file(params, file) do
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
    |> CardFile.changeset_authorization_file(file_params)
    |> Repo.update()
  end

  def update_image(params, file) do
    path = case Application.get_env(:db, :env) do
      :test ->
        Path.expand('./../../uploads/files/')
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
    |> CardFile.changeset_authorization_image(file_params)
    |> Repo.update()
  end
end

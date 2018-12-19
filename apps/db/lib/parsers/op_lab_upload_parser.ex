defmodule Innerpeace.Db.Parsers.OpLabUploadParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.File, as: CardFile
  alias Innerpeace.Db.Repo

  def upload_a_file(op_lab_id, params) do
    for param <- params do
      if param["type"] == "file" do
        {:ok, file} = insert_file(op_lab_id, param)
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
        File.write!(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_file(param, file)
        File.rm_rf(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}")
      end
      if param["type"]  == "image" do
        {:ok, file} = insert_file(op_lab_id, param)
    # unused variable
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
        File.write!(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
        update_image(param, file)
        File.rm_rf(pathsample <> "/OPLab_#{file.link}.#{param["extension"]}")
      end
    end
  end

  def insert_file(op_lab_id, params) do
    data =
      %{
        link: params["link"],
        authorization_id: op_lab_id
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

    file_path = "OPLab_#{file.link}.#{params["extension"]}"
    haha = %Plug.Upload{
      content_type: "application/#{params["extension"]}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }
    file_params = %{"link_type" => haha}

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
end

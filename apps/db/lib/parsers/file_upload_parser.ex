defmodule Innerpeace.Db.Parsers.FileUploadParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.File, as: UploadFile
  alias Innerpeace.Db.Repo

  alias AccountLinkWeb.LayoutView
  import Ecto.Query

  # FOR EVOUCHER UPLOAD PHOTO

  def convert_base64_img(%{
    "filename" => filename,
    "extension" => extension,
    "photo" => base64_encoded
  })
  do
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

    [_base, base64_encoded] = String.split(base64_encoded, ",")

    File.mkdir_p!(Path.expand('./uploads/images'))
    File.write!(pathsample <> "/evoucher_#{filename}.#{extension}", Base.decode64!(base64_encoded))

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

    file_path = "evoucher_#{filename}.#{extension}"
    file_upload = %Plug.Upload{
      content_type: "image/#{extension}",
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }

    {:ok, %{"photo" => file_upload}}

  end

  def delete_local_img(file_name, extension) do
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

    File.rm_rf(pathsample <> "/evoucher_#{file_name}.#{extension}")
  end

end

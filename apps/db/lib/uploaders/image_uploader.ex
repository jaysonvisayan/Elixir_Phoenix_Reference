defmodule Innerpeace.ImageUploader do
  use Arc.Definition
  use Arc.Ecto.Definition

  @acl :public_read

  def __storage do
    case Application.get_env(:db, :arc_storage) do
      :s3 -> Arc.Storage.S3
      _ -> Arc.Storage.Local
    end
  end

  def s3_object_headers(version, {file, scope}) do
    [content_type: Plug.MIME.path(file.file_name)] # for "image.png", would produce: "image/png"
  end

  @versions [:original, :standard, :thumb]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    Enum.member?(@extension_whitelist, file_extension)
  end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    {:convert, "-thumbnail 100x100^ -gravity center -extent 100x100 -format png", :png}
  end

  def transform(:standard, _) do
    {:convert, "-thumbnail 300x300^ -gravity center -extent 300x300 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(version, _) do
    version
  end

  def storage_dir(_, {file, user}) do
    "uploads/images/#{user.id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(:thumb) do
    "https://placehold.it/100x100"
  end

  def default_url(:standard) do
    "apps/payor_link/assets/static/images/canvas.png"
  end

  def default_url(:original) do
    "/images/file-upload.png"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end

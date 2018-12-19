defmodule Innerpeace.Db.Parsers.MemberUploadParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.MemberSkippingHierarchy, as: SkippingHierarchy
  alias Innerpeace.Db.Repo

  def upload_a_file(member_skip, param) do
    if true do
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
      File.write!(pathsample <> "/#{param["name"]}", Base.decode64!(param["base_64_encoded"]))
      file_params = %{
        "supporting_document" => %Plug.Upload{
          content_type: "application/#{param["extension"]}",
          path: "#{pathsample}/#{param["name"]}",
          filename: "#{param["name"]}"
        }
      }
      member_skip
      |> SkippingHierarchy.changeset_document(file_params)
      |> Repo.update()
      File.rm_rf(pathsample <> "/#{param["name"]}")
    end
    # if param["extension"] == "jpg" or
    #    param["extension"] == "png" do
    #    pathsample = case Application.get_env(:db, :env) do
    #      :test ->
    #        Path.expand('./../../uploads/files/')
    #      :dev ->
    #        Path.expand('./uploads/files/')
    #      :prod ->
    #        Path.expand('./uploads/files/')
    #      _->
    #        nil
    #    end
    #    pathsample = Path.expand("./uploads/images")
    #    File.write!(pathsample<>"/KYC_#{file.link}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
    #    update_image(param, file)
    #    File.rm_rf(pathsample<>"/KYC_#{file.link}.#{param["extension"]}")
    #  end
  end

end

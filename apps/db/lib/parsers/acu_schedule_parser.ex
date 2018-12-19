defmodule Innerpeace.Db.Parsers.AcuScheduleParser do
  @moduledoc ""
  alias Innerpeace.Db.Schemas.{
    AcuScheduleMember,
    Batch,
    AcuSchedule,
    BatchFile
  }
  alias Innerpeace.Db.Schemas.File, as: UploadFile
  alias Innerpeace.Db.Parsers.MemberParser
  alias Innerpeace.Db.Repo
  import Ecto.Query

  #FOR BATCH SOA
  def upload_a_file_batch(batch_id, param, user) do
    with {:ok, file} <- insert_file_batch(batch_id, param),
         {:ok, base64} <- validate_base64(param["base_64_encoded"]),
         {:ok, batch_file} <- update_file_batch(param, file, batch_id, user)
    do
      url = get_url(Application.get_env(:db, :env))
      File.mkdir_p!(Path.expand('./uploads/files'))
      File.write!("#{url}/#{file.name}", base64)
      File.rm_rf("#{url}/BATCH_SOA_#{file.name}")
      {:ok}
    else
      {:invalid, message} ->
        {:invalid, message}
      _ ->
        {:invalid, "Error uploading batch!"}
    end
  end

  defp validate_base64(nil), do: ""
  defp validate_base64(base64) do
    {:ok, Base.decode64!(base64)}
  rescue
    _ ->
      {:invalid, "Invalid base_64_encoded"}
  end

  defp get_url(:test), do: Path.expand('./../../uploads/files/')
  defp get_url(:dev), do: Path.expand('./uploads/files/')
  defp get_url(:prod), do: Path.expand('./uploads/files/')
  defp get_url(_), do: nil

  def insert_file_batch(batch_id, params) do
    # batch = Batch
    #         |> Repo.get!(batch_id)
    data =
      %{
        name: "BATCH_SOA_#{params["filename"]}"
        # batch_id: batch_id
      }

    # file = File
    #        |> Repo.get_by(data)

    # if is_nil(file) do
      %UploadFile{}
      |> UploadFile.changeset(data)
      |> Repo.insert()
    # else
    #   file =
    #     file
    #     |> Repo.delete()

    #   %UploadFile{}
    #   |> UploadFile.changeset_batch(data)
    #   |> Repo.insert()
    # end
  end

  def update_file_batch(params, file, batch_id, user) do
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

    file_path = "#{file.name}"
    file_params = %{"type" => %Plug.Upload{
      content_type: params["content_type"],
      path: "#{path}/#{file_path}",
      filename: "#{file_path}"
    }}

    file
    |> UploadFile.changeset_file(file_params)
    |> Repo.update()

    batch_file_params = %{
      batch_id: batch_id ,
      file_id: file.id,
      updated_by_id: user.id,
      created_by_id: user.id
    }

    %BatchFile{}
    |> BatchFile.changeset(batch_file_params)
    |> Repo.insert()
  end

  # def upload_a_file_acu_schedule(acu_schedule_id, params) do
  #   for param <- params do
  #     {:ok, file} = insert_file_acu_schedule(acu_schedule_id, param)
  #     pathsample = case Application.get_env(:data, :env) do
  #       :test ->
  #         Path.expand('./../../uploads/files/')
  #       :dev ->
  #         Path.expand('./uploads/files/')
  #       :prod ->
  #         Path.expand('./uploads/files/')
  #       _ ->
  #         nil
  #     end
  #     File.mkdir_p!(Path.expand('./uploads/files'))
  #     File.write!(pathsample <> "/ACU_SCHEDULE_BATCH_SOA_#{file.name}.#{param["extension"]}", Base.decode64!(param["base_64_encoded"]))
  #     {:ok, file} = update_file_acu_schedule(param, file)
  #     File.rm_rf(pathsample <> "/ACU_SCHEDULE_BATCH_SOA_#{file.name}.#{param["extension"]}")
  #   end
  # end

  # def insert_file_acu_schedule(acu_schedule_id, params) do
  #   acu_schedule = AcuSchedule
  #           |> Repo.get!(acu_schedule_id)
  #           |> Repo.preload(:files)
  #   data =
  #     %{
  #       name: params["name"],
  #       batch_id: acu_schedule_id
  #     }

  #   file = UploadFile
  #          |> Repo.get_by(data)

  #   if is_nil(file) do
  #     %UploadFile{}
  #     |> UploadFile.changeset_acu_schedule(data)
  #     |> Repo.insert()
  #   else
  #     file =
  #       file
  #       |> Repo.delete()

  #     %UploadFile{}
  #     |> UploadFile.changeset_acu_schedule(data)
  #     |> Repo.insert()
  #   end
  # end

  # def update_file_acu_schedule(params, file) do
  #   path = case Application.get_env(:data, :env) do
  #     :test ->
  #       Path.expand('./../../uploads/files/')
  #     :dev ->
  #       Path.expand('./uploads/files/')
  #     :prod ->
  #       Path.expand('./uploads/files/')
  #     _ ->
  #       nil
  #   end

  #   file_path = "ACU_SCHEDULE_BATCH_SOA_#{file.name}.#{params["extension"]}"
  #   file_params = %{"type" => %Plug.Upload{
  #     content_type: "application/#{params["extension"]}",
  #     path: "#{path}/#{file_path}",
  #     filename: "#{file_path}"
  #   }}

  #   file
  #   |> UploadFile.changeset_file(file_params)
  #   |> Repo.update()
  # end
  #END
end

defmodule Innerpeace.Db.Base.FileContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.File
  }

  def delete_file(file_id) do
    File
    |> where([f], f.id == ^file_id)
    |> Repo.one()
    |> Repo.delete()
  end

  def insert_file(params \\ %{}) do
    %File{}
    |> File.changeset(params)
    |> Repo.insert()
  end

  def upload_file(file, params) do
    file
    |> File.changeset_file(params)
    |> Repo.update()
  end

end

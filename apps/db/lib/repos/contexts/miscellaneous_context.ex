defmodule Innerpeace.Db.Base.MiscellaneousContext do
  @moduledoc false
  import Ecto.Query

  alias Innerpeace.Db.{
    Repo,
    Schemas.Miscellaneous
  }

  def get_all_miscellaneous do
    Miscellaneous
    |> Repo.all()
  end

  def create_miscellaneous(miscellaneous_params) do
    %Miscellaneous{}
    |> Miscellaneous.changeset_create(miscellaneous_params)
    |> Repo.insert()
  end

  def get_miscellaneous(id) do
    Miscellaneous
    |> Repo.get(id)
  end

  def get_all_miscellaneous_code do
    Miscellaneous
    |> select([:code])
    |> Repo.all()
  end

  def update_miscellaneous(miscellaneous_params, miscellaneous) do
    miscellaneous
    |> Miscellaneous.changeset_update(miscellaneous_params)
    |> Repo.update()
  end

  def delete_miscellaneous(id) do
    record =
      id
      |> get_miscellaneous
      |> Repo.delete
  end

end

defmodule Innerpeace.Db.Base.ApplicationContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Application
  }

  def insert_or_update_application(params) do
    application = get_application_by_name(params.name)
    if is_nil(application) do
      create_application(params)
    else
      update_application(application.id, params)
    end
  end

  def get_application_by_name(name) do
    Application
    |> Repo.get_by(name: name)
  end

  def get_all_applications do
    Application
    |> Repo.all
    |> Repo.preload(:roles)
  end

  def get_application(id) do
    Application
    |> Repo.get!(id)
  end

  def create_application(application_param) do
    %Application{}
    |> Application.changeset(application_param)
    |> Repo.insert
  end

  def update_application(id, application_param) do
    id
    |> get_application()
    |> Application.changeset(application_param)
    |> Repo.update
  end

  def delete_application(id) do
    id
    |> get_application()
    |> Repo.delete
  end

end

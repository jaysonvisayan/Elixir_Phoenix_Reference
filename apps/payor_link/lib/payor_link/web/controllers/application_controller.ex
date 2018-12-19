defmodule Innerpeace.PayorLink.Web.ApplicationController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.Application

  def index(conn, _params) do
    applications = get_all_applications()
    render(conn, "index.html", applications: applications)
  end

  def new(conn, _params) do
    changeset = Application.changeset(%Application{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"application" => application_params}) do
    case create_application(application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: application_path(conn, :show, application))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    application = get_application(id)
    render(conn, "show.html", application: application)
  end

  def edit(conn, %{"id" => id}) do
    application = get_application(id)
    changeset = Application.changeset(application)
    render(conn, "edit.html", application: application, changeset: changeset)
  end

  def update(conn, %{"id" => id, "application" => application_params}) do
    application = get_application(id)

    case update_application(id, application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application updated successfully.")
        |> redirect(to: application_path(conn, :show, application))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", application: application, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    _application = delete_application(id)

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: application_path(conn, :index))
  end
end

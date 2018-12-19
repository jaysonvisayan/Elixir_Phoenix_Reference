defmodule Innerpeace.PayorLink.Web.CoverageController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.Coverage

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{coverages: [:manage_coverages]},
       %{coverages: [:access_coverages]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{coverages: [:manage_coverages]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "clusters"}
  when not action in [:index]

  def index(conn, _params) do
    coverages = get_all_coverages()
    render(conn, "index.html", coverages: coverages)
  end

  def new(conn, _params) do
    changeset = Coverage.changeset(%Coverage{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"coverage" => coverage_params}) do
    case create_coverage(coverage_params) do
      {:ok, _coverage} ->
        conn
        |> put_flash(:info, "Coverage Successfully Created")
        |> redirect(to: coverage_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    coverage = get_coverage(id)
    render(conn, "show.html", coverage: coverage)
  end

  def edit(conn, %{"id" => id}) do
    coverage = get_coverage(id)
    changeset = Coverage.changeset(coverage)
    render(conn, "edit.html", coverage: coverage, changeset: changeset)
  end

  def update(conn, %{"id" => id, "coverage" => coverage_params}) do
    coverage = get_coverage(id)

    case update_coverage(id, coverage_params) do
      {:ok, _coverage} ->
        conn
        |> put_flash(:info, "Coverage updated successfully.")
        |> redirect(to: coverage_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", coverage: coverage, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    delete_coverage(id)

    conn
    |> put_flash(:info, "Coverage deleted successfully.")
    |> redirect(to: coverage_path(conn, :index))
  rescue
    Ecto.ConstraintError ->
      conn
      |> put_flash(:error, "Error deleting coverage. Coverage is already used.")
      |> redirect(to: coverage_path(conn, :index))
    _ ->
      conn
      |> put_flash(:error, "Error deleting coverage.")
      |> redirect(to: coverage_path(conn, :index))
  end

  # unused defp
  # defp handle_error(conn, reason) do
  #   conn
  #   |> put_flash(:error, reason)
  #   |> render(Innerpeace.PayorLink.Web.ErrorView, "500.html")
  # end

end

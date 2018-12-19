defmodule Innerpeace.PayorLink.Web.RUVController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.{
    Base.RUVContext,
    Schemas.RUV
  }
  alias Innerpeace.PayorLink.Web.RUVView

  #plug :can_access?, %{permissions: ["manage_ruvs", "access_ruvs"]} when action in [:index]
  #plug :can_access?, %{permissions: ["manage_ruvs"]} when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{ruvs: [:manage_ruvs]},
       %{ruvs: [:access_ruvs]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{ruvs: [:manage_ruvs]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "ruvs"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["ruvs"]
    ruvs = RUVContext.get_ruvs()
    render(conn, "index.html", ruvs: ruvs, permission: pem)
  end

  def new(conn, _params) do
    changeset = RUV.changeset(%RUV{})
    ruv_codes = RUVContext.get_ruv_codes()
    render(conn, "new.html",
           changeset: changeset,
           ruv_codes: Poison.encode!(ruv_codes))
  end

  def create(conn, %{"ruv" => ruv_params}) do
    with {:ok, _ruv} <- RUVContext.create_ruv(conn.assigns.current_user.id,
                                             ruv_params)
    do
      conn
      |> put_flash(:info, "RUV has been successfully created.")
      |> redirect(to: "/ruvs")
    else
      {:error, changeset} ->
        ruv_codes = RUVContext.get_ruv_codes()
        conn
        |> put_flash(:error, "Error creating RUV! Please check the errors below.")
        |> render("new.html",
                  changeset: changeset,
                  ruv_codes: Poison.encode!(ruv_codes))
    end
  end

  def edit(conn, %{"id" => id}) do
    ruv = RUVContext.get_ruv_by_id(id)
    changeset = RUV.changeset(ruv)
    render(conn, "edit.html", ruv: ruv, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ruv" => ruv_params}) do
    ruv = RUVContext.get_ruv_by_id(id)
    with {:ok, _updated_ruv} <- RUVContext.update_ruv(
      conn.assigns.current_user.id, id, ruv_params),
         _ruv_logs <- RUVContext.create_ruv_log(conn.assigns.current_user,
                                               RUV.changeset(ruv, ruv_params))
    do
      conn
      |> put_flash(:info, "RUV has been updated successfully.")
      |> redirect(to: "/ruvs")
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error updating RUV! Please check the errors below.")
        |> render("edit.html", ruv: ruv, changeset: changeset)
    end
  end

  def logs(conn, %{"id" => ruv_id}) do
    ruv_logs = RUVContext.get_logs_by_ruv_id(ruv_id)
    # json conn, Poison.encode!(ruv_logs)
    conn
    |> render(
      Innerpeace.PayorLink.Web.RUVView,
      "ruv_logs.json",
      logs: ruv_logs
    )
  end

  def delete(conn, %{"id" => id}) do
    RUVContext.delete_ruv(id)

    conn
    |> put_flash(:info, "RUV removed successfully.")
    |> redirect(to: "/ruvs")
  end

  def get_ruv_ajax(conn, %{"id" => id}) do
    ruv = RUVContext.get_ruv_by_id(id)
    render(conn, RUVView, "ruv.json", ruv: ruv)
  end

end

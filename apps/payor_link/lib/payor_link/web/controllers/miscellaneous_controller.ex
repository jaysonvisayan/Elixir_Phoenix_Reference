defmodule Innerpeace.PayorLink.Web.MiscellaneousController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Schemas.{
    Miscellaneous
  }

  alias Innerpeace.Db.Base.{
    MiscellaneousContext
  }

  alias Innerpeace.PayorLink.Web.MiscellaneousView

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{miscellaneous: [:manage_miscellaneous]},
       %{miscellaneous: [:access_miscellaneous]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{miscellaneous: [:manage_miscellaneous]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "miscellaneous"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["miscellaneous"]
    changeset = Miscellaneous.changeset(%Miscellaneous{}, %{})
    miscellaneous = MiscellaneousContext.get_all_miscellaneous()
    render(conn, "index.html", miscellaneous: miscellaneous, changeset: changeset, permission: pem)
  end

  def new(conn, _params) do
    changeset = Miscellaneous.changeset(%Miscellaneous{})
    render(conn, "step1.html", changeset: changeset)
  end

  def create_general(conn, %{"miscellaneous" => miscellaneous_params}) do
    current_user = conn.assigns.current_user
    price =
      miscellaneous_params["price"]
      |> String.split(",")
      |> Enum.join

    miscellaneous_params =
      miscellaneous_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", current_user.id)
      |> Map.put("updated_by_id", current_user.id)
      |> Map.put("price", price)

    case MiscellaneousContext.create_miscellaneous(miscellaneous_params) do
      {:ok, miscellaneous} ->
        conn
        |> put_flash(:info, "Item successfully added")
        |> redirect(to: "/miscellaneous")
      {:error, "Error"}
        changeset = Miscellaneous.changeset(%Miscellaneous{})
        conn
        |> put_flash(:error, "Error")
        |> render("step1.html", changeset: changeset)
    end
  end

  def get_all_miscellaneous_code(conn, _params) do
    misc_code =  MiscellaneousContext.get_all_miscellaneous_code()
    json conn, Poison.encode!(misc_code)
  end

  def edit(conn, %{"id" => id}) do
    miscellaneous = MiscellaneousContext.get_miscellaneous(id)
    changeset = Miscellaneous.changeset(miscellaneous)

    render(conn, "step1_edit.html",
           changeset: changeset,
           miscellaneous: miscellaneous)
  end

  def save_edit(conn, %{"id" => id, "miscellaneous" => miscellaneous_params}) do
    current_user = conn.assigns.current_user
    miscellaneous = MiscellaneousContext.get_miscellaneous(id)
    changeset = Miscellaneous.changeset(miscellaneous)

    price =
      miscellaneous_params["price"]
      |> String.split(",")
      |> Enum.join

    miscellaneous_params =
      miscellaneous_params
      |> Map.put("updated_by_id", current_user.id)
      |> Map.put("price", price)

    case MiscellaneousContext.update_miscellaneous(miscellaneous_params, miscellaneous) do
      {:ok, miscellaneous} ->
        conn
        |> put_flash(:info, "Item successfully updated")
        |> redirect(to: "/miscellaneous")
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error")
        |> render("step1_edit.html",
                  changeset: changeset,
                  miscellaneous: miscellaneous)
      {:error, "Error"} ->
        changeset = Miscellaneous.changeset(%Miscellaneous{})
        conn
        |> put_flash(:error, "Error")
        |> render("step1_edit.html",
                  changeset: changeset,
                  miscellaneous: miscellaneous)
    end
  end

 def delete_miscellaneous(conn, %{"id" => id}) do
   case MiscellaneousContext.delete_miscellaneous(id) do
     {:ok, record} ->
       json conn, Poison.encode!(%{valid: true})
      _ ->
       json conn, Poison.encode!(%{valid: false})
   end
  end
end

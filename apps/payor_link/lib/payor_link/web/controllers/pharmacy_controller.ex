defmodule Innerpeace.PayorLink.Web.PharmacyController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.{
    Schemas.Pharmacy,
    Base.PharmacyContext
  }

  alias Guardian.Plug

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{pharmacies: [:manage_pharmacies]},
       %{pharmacies: [:access_pharmacies]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{pharmacies: [:manage_pharmacies]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "pharmacies"}
  when not action in [:index]

  def index(conn, _params) do
    changeset = Pharmacy.changeset(%Pharmacy{}, %{})
    pharmacies = PharmacyContext.get_all_pharmacy()
    pharmacy = List.first(PharmacyContext.get_all_pharmacy())
    render(conn, "index.html", pharmacies: pharmacies, changeset: changeset, pharmacy: pharmacy)
  end

  def new(conn, _params) do
    changeset = Pharmacy.changeset(%Pharmacy{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, params) do
    price =
      params["pharmacy"]["maximum_price"]
      |> String.split(",")
      |> Enum.join

    strength =
      params["pharmacy"]["strength"]
      |> String.split(",")
      |> Enum.join

    params =
      params["pharmacy"]
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("maximum_price", price)
      |> Map.put("strength", strength)

    case PharmacyContext.create_pharmacy(params) do
      {:ok, _pharmacy} ->
        conn
        |> put_flash(:info, "Medicine successfully added")
        |> redirect(to: "/pharmacies")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error was encountered while saving.")
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    pharmacy = PharmacyContext.get_pharmacy(id)
    changeset = Pharmacy.changeset(pharmacy)
    render(conn, "edit.html", pharmacy: pharmacy, changeset: changeset)
  end

  def update(conn, %{"id" => id, "pharmacy" => params}) do
    original_pharmacy = PharmacyContext.get_pharmacy(id)
    pharmacy = PharmacyContext.get_pharmacy(id)

    price =
      params["maximum_price"]
      |> String.split(",")
      |> Enum.join

    strength =
      params["strength"]
      |> String.split(",")
      |> Enum.join

    params =
      params
      |> Map.put("maximum_price", price)
      |> Map.put("strength", strength)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

    with {:ok, _pharmacy} <- PharmacyContext.update_pharmacy(id, params)
    do
      conn
      |> put_flash(:info, "Medicine successfully updated")
      |> redirect(to: "/pharmacies")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error was encountered while updating medicine")
        |> render("edit.html", pharmacy: pharmacy, changeset: changeset)
    end
  end

 def delete_pharmacy(conn, %{"id" => id}) do
   case PharmacyContext.delete_pharmacy(id) do
     {:ok, record} ->
       json conn, Poison.encode!(%{valid: true})
      _ ->
       json conn, Poison.encode!(%{valid: false})
   end
 end

 def get_all_pharmacy_code(conn, _params) do
    pharmacy = PharmacyContext.get_all_pharmacy_code()
    render(conn, Innerpeace.PayorLink.Web.PharmacyView, "load_all_pharmacy.json", pharmacy: pharmacy)
 end
end

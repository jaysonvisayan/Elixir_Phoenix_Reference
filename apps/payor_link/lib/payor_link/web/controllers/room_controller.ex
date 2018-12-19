defmodule Innerpeace.PayorLink.Web.RoomController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    Room
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{rooms: [:manage_rooms]},
       %{rooms: [:access_rooms]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{rooms: [:manage_rooms]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "rooms"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["rooms"]
    rooms = list_all_rooms()
    render(conn, "index.html", rooms: rooms, permission: pem)
  end

  def new(conn, _params) do
    changeset = change_room(%Room{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"room" => room_params}) do
      with {:ok, _room} <- create_room(room_params) do
        conn
        |> put_flash(:info, "Successfully created a room!")
        |> redirect(to: room_path(conn, :index))
      else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create(conn, params) do
    conn
    |> redirect(to: room_path(conn, :index))
  end

  def edit(conn, %{"id" => id}) do
    with {true, _} <- UtilityContext.valid_uuid?(id),
    room = %Room{} <- get_room_by_id(id)
    do
      rooms = get_a_room(room.id)
      changeset = change_room(%Room{})
      render(conn, "edit.html", rooms: rooms, changeset: changeset)
    else
      nil ->
        conn
        |> put_flash(:error, "Room not found")
        |> redirect(to: "/rooms")

      _ ->
        conn
        |> put_flash(:error, "Error")
        |> redirect(to: "/rooms")
    end
  end

  def update(conn, %{"id" => id, "room" => room_params}) do
    rooms = get_a_room(id)

    with false <- validate_params(room_params),
         {:ok, _}  <- update_room(rooms, room_params) do
      create_room_log(
        conn.assigns.current_user,
        Room.changeset(rooms, room_params)
      )

      conn
      |> put_flash(:info, "Successfully updated room!")
      |> redirect(to: room_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Error updating room!")
        |> redirect(to: room_path(conn, :edit, id))
    end
  end

  defp validate_params(params) do
    params
    |> Map.values()
    |> Enum.into([], &(validate_string(&1)))
    |> Enum.member?(true)
  end

  defp validate_params(%{}), do: true
  defp validate_string(nil), do: true
  defp validate_string(""), do: true
  defp validate_string(val), do: UtilityContext.validate_string(val)

  def show(conn, %{"id" => id}) do
    rooms = get_room(id)
    render(conn, "show.html", rooms: rooms)
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _room} = delete_room(id)
    conn
    |> put_flash(:info, "Room deleted successfully.")
    |> redirect(to: room_path(conn, :index))
  end

  def show_logs(conn, %{"id" => id}) do
    room_logs = get_room_logs(id)

    conn
    |> render(
      Innerpeace.PayorLink.Web.RoomView,
      "room_logs.json",
      room_logs: room_logs
    )
  end

  def show_facilities(conn, %{"id" => id}) do
    room = get_a_room(id)
    json conn, Poison.encode!(room)
  end

  # unused defp
  # defp handle_error(conn, reason) do
  #   conn
  #   |> put_flash(:error, reason)
  #   |> render(Innerpeace.PayorLink.Web.ErrorView, "500.html")
  # end

  def get_all_room_type(conn, _params) do
    room =  get_all_room_type()
    json conn, Poison.encode!(room)
  end

  def get_all_room_code_and_type(conn, _params) do
    room =  get_all_room_code_and_type()
    json conn, Poison.encode!(room)
  end

end

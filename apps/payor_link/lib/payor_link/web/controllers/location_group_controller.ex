defmodule Innerpeace.PayorLink.Web.LocationGroupController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Schemas.{
    LocationGroup,
    LocationGroupRegion
  }

  alias Innerpeace.Db.Base.{
    LocationGroupContext,
    LocationGroupRegionContext,
    Api.UtilityContext
  }

  alias Innerpeace.PayorLink.Web.LocationGroupView

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{location_groups: [:manage_location_groups]},
       %{location_groups: [:access_location_groups]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{location_groups: [:manage_location_groups]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "location_groups"}
  when not action in [:index]

  def index(conn, _params) do
    location_group = LocationGroupContext.get_all_location_group()
    render(conn, "index.html", location_group: location_group)
  end

  def new(conn, _params) do
    changeset = LocationGroup.changeset(%LocationGroup{})
    render(conn, "step1.html", changeset: changeset)
  end

  def create_general(conn, %{"location_group" => location_group_params}) do
    current_user = conn.assigns.current_user
    location_group_params =
      location_group_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", current_user.id)
      |> Map.put("updated_by_id", current_user.id)
    case LocationGroupContext.create_location_group(location_group_params) do
      {:ok, location_group} ->
        conn
        |> put_flash(:info, "Succesfully Updated")
        |> redirect(to: "/location_groups/#{location_group.id}/setup?step=2")

      {:error, %Ecto.Changeset{} = changeset_create} ->
        changeset = LocationGroup.changeset(%LocationGroup{})
        conn
        |> put_flash(:error, "Error")
        |> render("step1.html", changeset: changeset)
    end
  end

  def update_general(conn, %{"location_group" => location_group_params}) do
    current_user = conn.assigns.current_user

    location_group_params =
      location_group_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", current_user.id)
      |> Map.put("updated_by_id", current_user.id)

    case LocationGroupContext.create_location_group(location_group_params) do
      {:ok, location_group} ->
        conn
        |> put_flash(:info, "Succesfully Updated")
        |> redirect(to: "/location_groups/#{location_group.id}/setup?step=2")

      {:error, changeset} ->
        changeset = LocationGroup.changeset(%LocationGroup{})

        conn
        |> put_flash(:error, "Error")
        |> render("step1.html", changeset: changeset)
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    location_group = LocationGroupContext.get_location_group(id)

    case step do
      "1" ->
        step1(conn, location_group)

      "2" ->
        step2(conn, location_group)

      "3" ->
        step3(conn, location_group)

      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: "/location_groups/")
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: "/location_groups/")
  end


  def update_setup(conn, %{"id" => id, "step" => step, "location_group" => location_group_params}) do
    location_group = LocationGroupContext.get_location_group(id)

    case step do
      "1" ->
        step1_update(conn, location_group, location_group_params)

      "2" ->
        step2_update(conn, location_group, location_group_params)
        # "3" ->
        #   step3_update(conn, location_group, location_group_params)
    end
  end

  def step1(conn, location_group) do
    changeset = LocationGroup.changeset(location_group)

    render(
      conn,
      "step1_edit.html",
      changeset: changeset,
      location_group: location_group
    )
  end

  def step1_update(conn, location_group, location_group_params) do
    current_user = conn.assigns.current_user

    location_group_params =
      location_group_params
      |> Map.put("step", "2")
      |> Map.put("created_by_id", current_user.id)
      |> Map.put("updated_by_id", current_user.id)

    case LocationGroupContext.update_location_group(
      location_group_params,
      location_group
    ) do
      {:ok, location_group} ->
        conn
        |> put_flash(:info, "Succesfully Updated")
        |> redirect(to: "/location_groups/#{location_group.id}/setup?step=2")

      {:error, changeset} ->
        changeset = LocationGroup.changeset(%LocationGroup{})

        conn
        |> put_flash(:error, "Error")
        |> render("step1.html", changeset: changeset)
    end
  end

  def step2(conn, location_group) do
    changeset = LocationGroup.changeset(location_group)

    lcr_list =
      if location_group.location_group_region != [] do
        Enum.map(location_group.location_group_region, & &1.region_name)
      else
        []
      end

    render(
      conn,
      "step2.html",
      changeset: changeset,
      location_group: location_group,
      lcr_list: lcr_list
    )
  end

  defp insert_location_group_region(params) do
    user_id = params["created_by_id"]
    location_group_id = params["location_group_id"]

    Enum.each(params["region_name"], fn region ->
      [a, b] = String.split(region, ":", trim: true)

      location_group_params = %{
        region_name: "#{a}",
        island_group: "#{b}",
        location_group_id: location_group_id,
        created_by_id: user_id,
        updated_by_id: user_id
      }
      location_group_params
      |> LocationGroupRegionContext.create_location_group_region()
    end)
  end

  def step2_update(conn, location_group, location_group_params) do
    if is_nil(location_group_params["region_name"]) do
      changeset = LocationGroup.changeset(location_group)

      lcr_list =
        if location_group.location_group_region != [] do
          Enum.map(location_group.location_group_region, & &1.region_name)
        else
          []
        end

      conn
      |> put_flash(:error, "Please select at least 1 region")
      |> render(
        "step2.html",
        changeset: changeset,
        location_group: location_group,
        lcr_list: lcr_list
      )
    else
      current_user = conn.assigns.current_user

      location_group_params =
        location_group_params
        |> Map.put("created_by_id", current_user.id)
        |> Map.put("updated_by_id", current_user.id)
        |> Map.put("location_group_id", location_group.id)

      with {_, del_location_region} <-
        LocationGroupRegionContext.delete_location_group_region(
          location_group.id),
        :ok <- insert_location_group_region(location_group_params),
          {:ok, location_group} <-
            LocationGroupContext.update_step2(
              location_group,
              location_group_params
            )
      do
        conn
        |> put_flash(:info, "Sucessfully Updated")
        |> redirect(to: "/location_groups/#{location_group.id}/setup?step=3")
      else
        {:error, changeset} ->
          changeset = LocationGroup.changeset(%LocationGroup{})

          lcr_list =
            if location_group.location_group_region != [] do
              Enum.map(location_group.location_group_region, & &1.region_name)
            else
              []
            end

          conn
          |> put_flash(:error, "Error")
          |> render(
            "step2.html",
            changeset: changeset,
            lcr_list: lcr_list,
            location_group: location_group
          )
      end
    end
  end

  def submit_location_group(conn, %{"id" => id}) do
    location_group = LocationGroupContext.get_location_group(id)
    current_user = conn.assigns.current_user

    location_group_params = %{
      step: "4",
      created_by_id: current_user.id,
      updated_by_id: current_user.id,
      location_group_id: location_group.id
    }
    case LocationGroupContext.update_step3(
      location_group,
      location_group_params)

      do
     {:ok, location_group} ->
        conn
        |> put_flash(:info, "Location group successfully created")
        |> redirect(to: "/location_groups")

      {:error, changeset} ->
        changeset = LocationGroup.changeset(%LocationGroup{})

        conn
        |> put_flash(:error, "Error")
        |> render("step3.html", changeset: changeset)
    end
  end

  def step3(conn, location_group) do
    changeset = LocationGroup.changeset(location_group)

    luzon_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Luzon")

    visayas_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Visayas")

    mindanao_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Mindanao")

    render(
      conn,
      "step3.html",
      changeset: changeset,
      location_group: location_group,
      luzon_island: luzon_island,
      visayas_island: visayas_island,
      mindanao_island: mindanao_island
    )
  end

  def show_summary(conn, %{"id" => id}) do
    location_group = LocationGroupContext.get_location_group(id)

    luzon_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Luzon")

    visayas_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Visayas")

    mindanao_island =
      LocationGroupRegionContext.get_all_region_per_island_group(
        location_group.id,
        "Mindanao")

    render(
      conn,
      "show_summary.html",
      location_group: location_group,
      luzon_island: luzon_island,
      visayas_island: visayas_island,
      mindanao_island: mindanao_island
    )
  end

  def delete_lg(conn, %{"id" => id}) do
    {:ok, _lg} = LocationGroupContext.delete_lg(id)
    json conn, :success
  end

  def show(conn, %{"id" => id}) do
    with {true, _} <- UtilityContext.valid_uuid?(id),
      location_group = %LocationGroup{} <- LocationGroupContext.get_location_group_by_id(id)
    do
      facility = LocationGroupContext.get_facility_per_location_group(id)
      luzon_island =
        LocationGroupRegionContext.get_all_region_per_island_group(
          location_group.id,
          "Luzon")

      visayas_island =
        LocationGroupRegionContext.get_all_region_per_island_group(
          location_group.id,
          "Visayas")

      mindanao_island =
        LocationGroupRegionContext.get_all_region_per_island_group(
          location_group.id,
          "Mindanao")

      render(
        conn,
        "show.html",
        location_group: location_group,
        facility: facility,
        luzon_island: luzon_island,
        visayas_island: visayas_island,
        mindanao_island: mindanao_island
      )
    else
      nil ->
        conn
        |> put_flash(:error, "Location Group Not Found")
        |> redirect(to: "/location_groups")
      _ ->
        conn
        |> put_flash(:error, "Error")
        |> redirect(to: "/location_groups")
    end
  end

  def get_all_location_group_name(conn, _params) do
    lg_name =  LocationGroupContext.get_all_location_group_name()
    json conn, Poison.encode!(lg_name)
  end

end

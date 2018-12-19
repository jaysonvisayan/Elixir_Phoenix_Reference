defmodule Innerpeace.PayorLink.Web.Main.FacilityGroupController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.PayorLink.Web.FacilityGroupView
  alias Phoenix.View

  alias Innerpeace.Db.Base.LocationGroupContext, as: LGC
  alias Innerpeace.Db.{
    Schemas.LocationGroup,
    Datatables.LocationGroupDatatable
  }

  def index(conn, _) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    facility_group = LGC.get_location_group(id)
    region = get_all_region(facility_group.location_group_region)
    render(conn, "show.html",
      region: region,
      facility_group: facility_group
    )
  end

  defp get_all_region(nil), do: []
  defp get_all_region(lgr) do
    lgr
    |> Enum.into([], &(get_region(&1.region)))
    |> List.flatten()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def get_region(nil), do: nil
  def get_region(region) do
    if region.region == "All" do
      lgc = LGC.get_all_region(region.island_group)
      Enum.map(lgc, &(%{region: &1.region, island_group: &1.island_group}))
    else
      region
    end
  end

  def location_group_index(conn, params) do
    count = LocationGroupDatatable.get_location_group_count()
    filtered_count = LocationGroupDatatable.get_location_group_filtered_count(params["search"]["value"])
    datas = if params["start"] == "NaN" do
      []
    else
      LocationGroupDatatable.get_location_group(params["start"], params["length"], params["search"]["value"], params["order"]["0"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def new(conn, _params) do
    regions = LGC.get_all_region()
    # regions = []
    changeset = LocationGroup.changeset(%LocationGroup{})
    render(conn, "new.html", changeset: changeset, regions: regions, swal: false, selected_regions: [])
  end

  def create(conn, %{"location_group" => lg_params}) do
    params = type_region_params(lg_params, lg_params["selecting_type"])
    regions = LGC.get_all_region()

    with {:ok, location_group} <- LGC.create_location_group(params),
         {:ok, location_group_v2} <- LGC.create_location_group_region_or_facility(location_group, params),
         false <- location_group.status == "Draft"
    do
      selected_regions = LGC.get_inserted_region(location_group.id)
      changeset = LocationGroup.changeset(location_group)
      render(conn, "new.html", changeset: changeset, regions: regions, swal: true, selected_regions: selected_regions)
    else
      {:error, changeset} ->
        conn
        render(conn, "new.html", changeset: changeset, regions: regions, swal: false, selected_regions: [])
      {:error_message, message} ->
        changeset = LocationGroup.changeset(%LocationGroup{})
        conn
        |> put_flash(:error, message)
        |> render("new.html", changeset: changeset, regions: regions, swal: false, selected_regions: [])
      true ->
        conn
        |> redirect(to: "/web/facility_groups")
    end
  end

  defp type_region_params(params, nil), do: params
  defp type_region_params(params, "Region") do
    params
    |> Map.put("regions", [])
    |> check_luzon(params["Luzon"])
    |> check_visayas(params["Visayas"])
    |> check_mindanao(params["Mindanao"])
  end
  defp type_region_params(params, _), do: params

  defp check_luzon(params, nil), do: params
  defp check_luzon(params, _luzon) do
    if Enum.count(params["Luzon"]) == 8 do
      Map.put(params, "regions", params["regions"] ++ [params["luzon_all"]])
    else
      Map.put(params, "regions", params["regions"] ++ params["Luzon"])
    end
  end

  defp check_visayas(params, nil), do: params
  defp check_visayas(params, _visayas) do
    if Enum.count(params["Visayas"]) == 3 do
      Map.put(params, "regions", params["regions"] ++ [params["visayas_all"]])
    else
      Map.put(params, "regions", params["regions"] ++ params["Visayas"])
    end
  end

  defp check_mindanao(params, nil), do: params
  defp check_mindanao(params, _mindanao) do
    if Enum.count(params["Mindanao"]) == 6 do
      Map.put(params, "regions", params["regions"] ++ [params["mindanao_all"]])
    else
      Map.put(params, "regions", params["regions"] ++ params["Mindanao"])
    end
  end

  def load_facilities(conn, params) do
    facility_ids = params["facility_ids"] || []

    count =
      facility_ids
      |> LocationGroupDatatable.get_location_group_add_facility_count()

    data =
      facility_ids
      |> LocationGroupDatatable.get_location_group_add_facility(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count =
      facility_ids
      |> LocationGroupDatatable.get_location_group_add_facility_filtered_count(
        params["search"]["value"]
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def show_load_datatable(conn, params) do
    count = LocationGroupDatatable.get_location_group_view_facility_count(params["id"])
    filtered_count = LocationGroupDatatable.get_location_group_view_facility_filtered_count(params["search"]["value"], params["id"])
    datas = LocationGroupDatatable.get_location_group_view_facility(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])

    conn
    |> json(%{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def get_all_names(conn, _params) do
    names = LGC.get_all_names()
    json conn, Poison.encode!(names)
  end

  def check_existing_facility_group_name(conn, %{"facility_group_name" => facility_group_name}) do
    facility_name =
      facility_group_name
      |> LGC.check_facility_group_name()
      |> facility_group_exist?(conn)
  end

  def check_existing_facility_group_name_edit(conn, %{"facility_group_name" => facility_group_name}) do
    facility_name =
      facility_group_name
      |> LGC.check_facility_group_name()
      |> facility_group_exist?(conn)
  end

  defp facility_group_exist?(nil, conn) do
    json(conn, %{valid: true})
  end

  defp facility_group_exist?(facility_name, conn) do
    json(conn, %{valid: false})
  end

  def edit_draft(conn, %{"id" => id}) do
    facility_group = LGC.get_location_group(id)
    selected_regions = LGC.get_inserted_region(facility_group.id)
    regions = LGC.get_all_region()
    changeset = LocationGroup.changeset_update(facility_group)
    render(conn, "edit_draft.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
  end

  def edit_save(conn, %{"id" => id}) do
    facility_group = LGC.get_location_group(id)
    selected_regions = LGC.get_inserted_region(facility_group.id)
    regions = LGC.get_all_region()
    changeset = LocationGroup.changeset_update(facility_group)
    render(conn, "edit_save.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
  end

  def update_draft(conn, %{"id" => id, "location_group" => lg_params}) do
    params =
      lg_params
      |> Map.put("regions", [])
      |> check_luzon(lg_params["Luzon"])
      |> check_visayas(lg_params["Visayas"])
      |> check_mindanao(lg_params["Mindanao"])

    regions = LGC.get_all_region()

    with location_group = %LocationGroup{} <- LGC.get_location_group(id),
         {:ok, location_group} <- LGC.update_location_group(lg_params, location_group),
         location_group_v2 <- LGC.create_location_group_region_or_facility(location_group, params)
    do
      if location_group.status == "Draft" do
        conn
        |> redirect(to: "/web/facility_groups")
      else
        selected_regions = LGC.get_inserted_region(location_group.id)
        changeset = LocationGroup.changeset(location_group)
        render(conn, "new.html", changeset: changeset, regions: regions, swal: true, selected_regions: selected_regions)
      end
    else
      nil ->
        conn
        |> redirect(to: "/web/facility_groups")
      {:error, changeset} ->
        facility_group = LGC.get_location_group(id)
        selected_regions = LGC.get_inserted_region(facility_group.id)
        regions = LGC.get_all_region()
        changeset = LocationGroup.changeset_update(facility_group)
        conn
        |> render("edit_draft.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
      {:error_message, message} ->
        facility_group = LGC.get_location_group(id)
        selected_regions = LGC.get_inserted_region(facility_group.id)
        regions = LGC.get_all_region()
        changeset = LocationGroup.changeset_update(facility_group)
        conn
        |> render("edit_draft.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
    end
  end

  def update_save(conn, %{"id" => id, "location_group" => lg_params}) do
    user = conn.assigns.current_user.id
    lg_params =
      lg_params
      |> Map.put("updated_by_id", user)
    params =
      lg_params
      |> Map.put("regions", [])
      |> check_luzon(lg_params["Luzon"])
      |> check_visayas(lg_params["Visayas"])
      |> check_mindanao(lg_params["Mindanao"])

    regions = LGC.get_all_region()

    with location_group = %LocationGroup{} <- LGC.get_location_group(id),
        {:ok, location_group} <- LGC.update_location_group(lg_params, location_group),
         location_group_v2 <- LGC.create_location_group_region_or_facility(location_group, params)
    do
      facility_group = LGC.get_location_group(location_group.id)
      region = get_all_region(facility_group.location_group_region)

      render(conn, "show.html",
             region: region,
             facility_group: facility_group
      )
    else
      nil ->
        conn
        |> redirect(to: "/web/facility_groups")
      {:error, changeset} ->
        facility_group = LGC.get_location_group(id)
        selected_regions = LGC.get_inserted_region(facility_group.id)
        regions = LGC.get_all_region()
        changeset = LocationGroup.changeset_update(facility_group)
        conn
        |> render("edit_save.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
      {:error_message, message} ->
        facility_group = LGC.get_location_group(id)
        selected_regions = LGC.get_inserted_region(facility_group.id)
        regions = LGC.get_all_region()
        changeset = LocationGroup.changeset_update(facility_group)
        conn
        |> render("edit_save.html", changeset: changeset, regions: regions, swal: false, selected_regions: selected_regions, location_group: facility_group)
    end
  end

  def load_facility_group(conn, %{"id" => id}) do
    fg_data = LGC.load_facility_group_data(id)
    render(
      conn,
      Innerpeace.PayorLink.Web.Main.FacilityGroupView,
      "load_facility_group.json",
      facility_group: fg_data
    )
  end

end

defmodule Innerpeace.PayorLink.Web.PackageController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.{
    # Db.Repo,
    Db.Schemas.Package,
    # Db.Schemas.PayorProcedure,
    Db.Schemas.PackagePayorProcedure,
    Db.Schemas.PackageFacility,
    Db.Base.Api.UtilityContext
  }
  alias Innerpeace.Db.Base.{
    PackageContext
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{packages: [:manage_packages]},
       %{packages: [:access_packages]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{packages: [:manage_packages]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "packages"}
  when not action in [:index]

  def index(conn, _params) do
    packages = list_all_packages()
    render(conn, "index.html", packages: packages)
  end

  def new(conn, _params) do
    changeset = change_package(%Package{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"package" => package_params}) do
    package_params =
      package_params
      |> Map.put("step", 2)
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)

    with {:ok, package} <- create_package(package_params)
    do
      create_package_logs(
          package,
          conn.assigns.current_user,
          package_params,
          "General"
      )
      conn
      |> put_flash(:info, "Package successfully created!")
      |> redirect(to: "/packages/#{package.id}/setup?step=2") # pass to setup
    else {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> put_flash(:error, "Error creating package! Check the errors below.")
      render(conn, "new.html", changeset: changeset)
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    if is_nil(step) do
      conn
      |> put_flash(:error, "Invalid Step")
      |> redirect(to: package_path(conn, :index))
    else
      package = get_package(id)
      validate_step(conn, package, step)
      case step do
        "1" ->
          step1(conn, package)
        "2" ->
          step2(conn, package)
        "3" ->
          step3(conn, package)
        _ ->
          conn
          |> put_flash(:error, "Invalid step!")
          |> redirect(to: package_path(conn, :index))
      end
    end

    rescue
      _ ->
        conn
        |> put_flash(:error, "Invalid Step")
        |> redirect(to: package_path(conn, :index))
  end

  def setup(conn, params) do
    conn
    |> put_flash(:error, "Page Not Found!")
    |> redirect(to: package_path(conn, :show, params["id"]))
  end

  def step1(conn, package) do
    changeset = change_package(package)
    render(conn, "edit.html", changeset: changeset, package: package)
  end

  def step2(conn, package) do
    changeset = Package.changeset(%Package{})
    packages = get_package(package.id)
    package_payor_procedures = get_package_payor_procedures(package.id)
    payor_procedures = get_all_payor_procedures()
    all_package_payor_procedures = list_all_package_payor_procedures()
    render(conn, "step2.html", package: package,
           changeset: changeset,
           packages: packages,
           payor_procedures: payor_procedures,
           package_payor_procedures: package_payor_procedures,
           all_package_payor_procedures: all_package_payor_procedures)
  end

  def step3(conn, package) do
    changeset = Package.changeset(%Package{})
    packages = get_all_packages()
    package_payor_procedures = get_package_payor_procedures(package.id)
    payor_procedures = get_all_payor_procedures()
    all_package_payor_procedures = list_all_package_payor_procedures()
    if package_payor_procedures == [] do
      conn
      |> put_flash(:error, "Please select at least one procedure!")
      |> render("step2.html", changeset: changeset,
                package: package,
                packages: packages,
                package_payor_procedures: package_payor_procedures,
                payor_procedures: payor_procedures,
                modal_open: true,
                all_package_payor_procedures: all_package_payor_procedures)
    else
      render(conn, "step3.html", package: package,
             changeset: changeset,
             packages: packages,
             payor_procedures: payor_procedures,
             package_payor_procedures: package_payor_procedures,
             all_package_payor_procedures: all_package_payor_procedures)
    end
  end

  def validate_step(conn, package, step) do
    if package.step < String.to_integer(step) do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: package_path(conn, :index))
    end
  end

  def next_step3(conn, %{"id" => package_id}) do
    package = list_package!(package_id)
    if package.step == 2 do
      update_package_step(
        list_package!(package_id),
        %{step: 3}
      )
    end
    conn
    |> redirect(to: "/packages/#{package_id}/setup?step=3")
  end

  def update(conn, %{"id" => id, "package" => package_params}) do
    package = get_package(id)
    with {:ok, package} <- update_package(id, package_params)
    do
      conn
      |> put_flash(:info, "Package successfully updated!")
      |> redirect(to: package_path(conn, :show, package))
    else {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> put_flash(:error, "Error updating package! Check the errors below.")
      render(conn, "edit.html", package: package, changeset: changeset)
    end
  end

  def update_setup(conn, %{"id" => id, "step" => step, "package" => package_params}) do
    package = get_package(id)
    case step do
      "1" ->
        step1_update(conn, package, package_params)
      "2" ->
        step2_update(conn, package, package_params)
      "3" ->
        step3_update(conn, package, package_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: package_path(conn, :index))
    end
  end

  def submit(conn, %{"id" => id}) do
    package = get_package(id)
    update_step(conn, package, 0)
    conn
    |> put_flash(:info, "Package successfully created!")
    |> redirect(to: "/packages/#{package.id}?active=procedures")
  end

  def step1_update(conn, package, package_params) do
    package_params =
      package_params
      |> Map.put("step", 2)
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)
    with {:ok, package} <- update_a_package(package.id, package_params)
    do
      conn
      |> put_flash(:info, "Package successfully updated!")
      |> redirect(to: "/packages/#{package.id}/setup?step=2")
    else {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "edit.html", package: package, changeset: changeset)
    end

  end

  def step2_update(conn, package, package_params) do
    packages = get_package(package.id)
    package_payor_procedures = get_package_payor_procedures(package.id)
    _payor_procedures = get_all_payor_procedures()
    all_package_payor_procedures = list_all_package_payor_procedures()

    payor_procedures = get_all_payor_procedures()
    _changeset = PackagePayorProcedure.changeset(%PackagePayorProcedure{})

    with {:ok, _params} <- insert_package_payor_procedures(package.id, package_params)
    do
      create_procedure_logs(
          package,
          conn.assigns.current_user,
          PackagePayorProcedure.changeset(%PackagePayorProcedure{}, package_params),
          "Procedures"
      )
      update_step(conn, package, "3")
      conn
      |> put_flash(:info, "Payor Procedure successfully added!")
      |> redirect(to: "/packages/#{package.id}/setup?step=2")
    else {:error, changeset} ->
       conn
        |> put_flash(:error, "Error adding procedure! Please check the errors below.")
        |> render("step2.html", changeset: changeset,
                package: package,
                packages: packages,
                package_payor_procedures: package_payor_procedures,
                payor_procedures: payor_procedures,
                modal_open: true,
                all_package_payor_procedures: all_package_payor_procedures)
    end
  end

  def step3_update(_conn, _package, _package_params) do
  end

  defp update_step(_conn, package, step) do
    update_package(package, %{"step" => step})
  end

  def show(conn, %{"id" => id, "active" => active}) do
    pem = conn.private.guardian_default_claims["pem"]["packages"]
    if active != "procedures" and active != "facilities" do
      conn
      |> put_flash(:error, "Page not found.")
      |> redirect(to: package_path(conn, :index))
    else
      with {true, id}  <- UtilityContext.valid_uuid?(id),
      package = %Package{} <- PackageContext.get_package(id)
      do
        package_payor_procedures = get_package_payor_procedures(id)
        payor_procedures = get_all_payor_procedures()
        all_package_payor_procedures = list_all_package_payor_procedures()
        package_facilities = get_package_facility(package.id)
        facilities = get_all_facility()
        all_package_facilities = list_all_package_facility()
        changeset = PackageFacility.changeset(%PackageFacility{})
        render(conn, "show.html", package: package,
           package_payor_procedures: package_payor_procedures,
           payor_procedures: payor_procedures,
           all_package_payor_procedures: all_package_payor_procedures,
           package_facilities: package_facilities,
           facilities: facilities,
           all_package_facilities: all_package_facilities,
           changeset: changeset,
           active: active,
           permission: pem
        )
      else
      _ ->
        conn
          |> put_flash(:error, "Package not found")
          |> redirect(to: "/packages")
      end
    end
  end

  def show(conn, params) do
    param_count = Enum.map(params, fn(x) -> x end)
    param_count =
      param_count
      |> Enum.count()

    if param_count == 1 and not is_nil(params["id"]) do
      conn
      |> redirect(to: "/packages/#{params["id"]}?active=procedures")
    else
      conn
      |> put_flash(:error, "Page not found.")
      |> redirect(to: package_path(conn, :index))
    end
  end

  def show_log(conn, %{"id" => id, "message" => message}) do
    package_logs = get_package_log(id, message)
    package_logs =
      Enum.into(package_logs, [],
      &(%{
        inserted_at: &1.inserted_at,
        message: UtilityContext.sanitize_value(&1.message)
      }))
    json conn, Poison.encode!(package_logs)
  end

  def show_all_log(conn, %{"id" => id}) do
    package_logs = get_all_package_log(id)
    package_logs =
      Enum.into(package_logs, [],
      &(%{
        inserted_at: &1.inserted_at,
        message: UtilityContext.sanitize_value(&1.message)
      }))
    json conn, Poison.encode!(package_logs)
  end

  def delete_package_payor_procedure(conn, %{"id" => id}) do
    package_payor_procedure = get_package_payor_procedure(id)
    params = %{payor_procedure_id: package_payor_procedure.payor_procedure_id}
    delete_payor_procedure_logs(package_payor_procedure.package_id, conn.assigns.current_user, params, "Procedures")
    {:ok, _package_payor_procedure} = delete_a_package_payor_procedure(package_payor_procedure.id)
    conn
    |> put_flash(:info, "Package Payor Procedure successfully deleted!")
    |> redirect(to: "/packages/#{package_payor_procedure.package_id}/setup?step=2")
  end

  def delete_package_payor_procedure_edit(conn, %{"id" => id}) do
    package_payor_procedure = get_package_payor_procedure(id)
    params = %{payor_procedure_id: package_payor_procedure.payor_procedure_id}
    delete_payor_procedure_log(package_payor_procedure.package_id, conn.assigns.current_user, params, "Procedures")
    {:ok, _package_payor_procedure} = delete_a_package_payor_procedure(package_payor_procedure.id)
    conn
    |> put_flash(:info, "Package Payor Procedure successfully deleted!")
    |> redirect(to: "/packages/#{package_payor_procedure.package_id}/edit?tab=payor_procedure")
  end

  def delete_package_facility_edit(conn, %{"id" => id}) do
    package_facility = get_package_facilities(id)
    {:ok, package_facility} = delete_a_package_facility(package_facility.id)
    conn
    |> put_flash(:info, "Package Facility successfully deleted!")
    |> redirect(to: "/packages/#{package_facility.package_id}/edit?tab=facility")
  end

  def delete_package_facility(conn, %{"id" => id}) do
    package_facility = get_package_facilities(id)
    params =
      %{
        facility_code: package_facility.facility.code,
        facility_name: package_facility.facility.name,
        facility_rate: package_facility.rate
      }
    delete_facility_log(package_facility.package_id, conn.assigns.current_user, params, "Facilities")

    {:ok, package_facility} = delete_a_package_facility(package_facility.id)
    conn
    |> put_flash(:info, "Package Facility successfully deleted!")
    |> redirect(to: "/packages/#{package_facility.package_id}/edit?tab=facility")
  end

  def delete(conn, %{"id" => id}) do
    package = get_package(id)
    with {:ok, _package} <- delete_package(package.id)
    do
      conn
      |> put_flash(:info, "Package deleted successfully.")
      |> redirect(to: package_path(conn, :index))
    end
  end

  def get_all_package_code_and_name(conn, _params) do
    package =  get_all_package_code_and_name()
    json conn, Poison.encode!(package)
  end

  def edit(conn, params)do
    if Map.has_key?(params, "tab") do
      package = get_package(params["id"])
      case params["tab"] do
        "general" ->
          edit_general(conn, package)
        "payor_procedure" ->
          edit_payor_procedure(conn, package)
        "facility" ->
          edit_facility(conn, package)
        _ ->
          conn
          |> put_flash(:error, "Page not found")
          |> redirect(to: "/packages/#{params["id"]}")
      end
    else
      conn
      |> put_flash(:error, "Page not found")
      |> redirect(to: "/packages/#{params["id"]}")
    end
  end

  def update_edit_setup(conn, %{"id" => id, "tab" => tab, "package" => package_params}) do
  package = get_package(id)
    case tab do
      "general" ->
        update_edit_general(conn, package, package_params)
      "payor_procedure" ->
        update_edit_procedure(conn, package, package_params)
      "facility" ->
        update_edit_facility(conn, package, package_params)
      _ ->
        conn
        |> put_flash(:error, "Page not found")
        |> redirect(to: "/packages/#{id}")
    end
  end

  def create_facility_setup(conn, %{"id" => id, "package" => package_params}) do
      package = get_package(id)
      create_a_facility(conn, package, package_params)
  end

  def create_a_facility(conn, package, package_params) do
    package_params =
      package_params
      |> Map.put("package_id", package.id)

    _packages = get_package(package.id)
    _package_facilities = get_package_facility(package.id)
    _facilities = get_all_facility()
    _all_package_facilities = list_all_package_facility()
    _changeset = PackageFacility.changeset(%PackageFacility{})

    with {:ok, _params} <- insert_package_facilities(package.id, package_params)
      do

      create_facility_log(
          package,
          conn.assigns.current_user,
          PackageFacility.changeset(%PackageFacility{}, package_params),
          "Facilities"
      )

      update_step(conn, package, "3")
        conn
        |> put_flash(:info, "Facility successfully added!")
        |> redirect(to: "/packages/#{package.id}?active=facilities")
      else  {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error adding facility! Please check the errors below.")
    end
  end

  def edit_general(conn, package) do
    changeset = Package.update_general_changeset(package, %{})
    render(conn, "edit/general.html", package: package, changeset: changeset)
  end

  def edit_payor_procedure(conn, package) do
    changeset = PackagePayorProcedure.changeset(%PackagePayorProcedure{})
    packages = get_package(package.id)
    package_payor_procedures = get_package_payor_procedures(package.id)
    payor_procedures = get_all_payor_procedures()
    all_package_payor_procedures = list_all_package_payor_procedures()
    render(conn, "edit/payor_procedure.html", package: package,
           changeset: changeset,
           packages: packages,
           payor_procedures: payor_procedures,
           package_payor_procedures: package_payor_procedures,
           all_package_payor_procedures: all_package_payor_procedures)
  end

  def edit_facility(conn, package) do
    changeset = PackageFacility.changeset(%PackageFacility{})
    packages = get_package(package.id)
    package_facilities = get_package_facility(package.id)
    facilities = get_all_facilities_with_code()
    all_package_facilities = list_all_package_facility()
    render(conn, "edit/facility.html", package: package,
           changeset: changeset,
           packages: packages,
           facilities: facilities,
           package_facilities: package_facilities,
           all_package_facilities: all_package_facilities)
  end

  def update_edit_general(conn, package, package_params) do
    package_params =
      package_params
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)
    with {:ok, _update_package} <- update_a_package(package.id, package_params)
    do
     create_package_log(
          conn.assigns.current_user,
          Package.changeset(package, package_params),
          "General"
      )
      conn
      |> put_flash(:info, "Package successfully updated!")
      |> redirect(to: "/packages/#{package.id}/edit?tab=general")
    else {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "edit.html", package: package, changeset: changeset)
    end
  end

  def update_edit_procedure(conn, package, package_params) do
    _package_payor_procedure = get_one_package_payor_procedure(package.id)
    _packages = get_package(package.id)
    _package_payor_procedures = get_package_payor_procedures(package.id)
    _payor_procedures = get_all_payor_procedures()
    _all_package_payor_procedures = list_all_package_payor_procedures()
    _payor_procedures = get_all_payor_procedures()
    _changeset = PackagePayorProcedure.changeset(%PackagePayorProcedure{})
    with {:ok, _params} <- insert_package_payor_procedures(package.id, package_params)
      do
      create_procedure_log(
          package,
          conn.assigns.current_user,
          PackagePayorProcedure.changeset(%PackagePayorProcedure{}, package_params),
          "Procedures"
      )

      update_step(conn, package, "3")
        conn
        |> put_flash(:info, "Payor Procedure successfully added!")
        |> redirect(to: "/packages/#{package.id}/edit?tab=payor_procedure")
      else  {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error adding procedure! Please check the errors below.")
    end
  end

  def update_edit_facility(conn, package, package_params) do
    _packages = get_package(package.id)
    _package_facilities = get_package_facility(package.id)
    _facilities = get_all_facility()
    _all_package_facilities = list_all_package_facility()
    _changeset = PackageFacility.changeset(%PackageFacility{})
    with {:ok, _params} <- insert_package_facilities(package.id, package_params)
      do

      create_facility_log(
          package,
          conn.assigns.current_user,
          PackageFacility.changeset(%PackageFacility{}, package_params),
          "Facilities"
      )

      update_step(conn, package, "3")
        conn
        |> put_flash(:info, "Facility successfully added!")
        |> redirect(to: "/packages/#{package.id}/edit?tab=facility")
      else  {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error adding facility! Please check the errors below.")
    end
  end

  def get_facility_by_name(conn, %{"name" => name}) do
    code = check_one_facility(name)
    json conn, Poison.encode!(code)
  end

  def update_package_facilities(conn, %{"id" => id, "package_facility" => package_params}) do
      package_facility = get_package_facilities(package_params["package_facility_id"])
      package = get_package(id)
      update_a_package_facilities(conn, package_facility, package, package_params)
  end

  def update_a_package_facilities(conn, package_facility, package, package_params) do
    _changeset = PackageFacility.changeset(%PackageFacility{})
    with {:ok, _params} <- update_package_facility(package_facility.id, package_params)
      do

      create_facility_log_update(
          package,
          conn.assigns.current_user,
          PackageFacility.changeset(package_facility, package_params),
          "Facilities"
      )

      update_step(conn, package, "3")
        conn
        |> put_flash(:info, "Package successfully updated!")
        |> redirect(to: "/packages/#{package.id}/edit?tab=facility")
      else  {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error adding facility! Please check the errors below.")
    end
  end

  def show_summary(conn, %{"id" => id}) do
    package = get_package(id)
    render(conn, "show_summary.html", package: package)
  end

end

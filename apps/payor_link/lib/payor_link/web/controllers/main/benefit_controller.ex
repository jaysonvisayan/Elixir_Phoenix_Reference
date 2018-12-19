defmodule Innerpeace.PayorLink.Web.Main.BenefitController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  import Ecto.Query

  alias Innerpeace.Db.Schemas.{
    Benefit,
    BenefitPackage,
    Package,
  }

  alias Innerpeace.Db.Datatables.{
    DiagnosisDatatable,
    ProcedureDatatable,
    BenefitDatatable,
    BenefitDatatableV2
  }

  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    BenefitContext,
    CoverageContext,
    DiagnosisContext,
    ProcedureContext,
    PackageContext
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{benefits: [:manage_benefits]},
       %{benefits: [:access_benefits]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{benefits: [:manage_benefits]},
     ]] when not action in [
       :index,
       :show,
       :load_benefit,
       :load_index,
       :load_coverages,
       :load_diagnosis,
       :load_packages,
       :load_benefit_package_dt,
       :load_procedure,
       :get_package
     ]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["benefits"]
    changeset = Benefit.changeset_health(%Benefit{})
    render(conn, "index.html", changeset: changeset, permission: pem)
  end

  def load_index(conn, params) do
    count = BenefitDatatable.benefit_count() # Count of all data, unfiltered

    data =
      params["start"]
      |> BenefitDatatable.benefit_data(
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count = # Count of all data according to search value
      params["search"]["value"]
      |> BenefitDatatable.benefit_filtered_count()

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def choose_benefit_type(conn, %{"id" => id}) do
    benefit_2 = BenefitContext.get_benefits_by_id(id)
    benefit = BenefitContext.get_benefit_new!(id)
    changeset = Benefit.changeset_health(%Benefit{})
    coverages = CoverageContext.get_all_coverages()
    type = String.downcase(benefit.category)

    params = %{
      "conn" => conn,
      "type" => type,
      "changeset" => changeset,
      "step" => benefit.step,
      "text" => "edit_benefit_#{type}.html",
      "benefit_type" => benefit.category,
      "benefit_id" => benefit.id,
      "benefit_2" => benefit_2
    }
    validate_type_edit(params)
  end

  def choose_benefit_type(conn, %{"benefit" => benefit}) do
    changeset = Benefit.changeset_health(%Benefit{})
    type = String.downcase(benefit["type"])

    params = %{
      "conn" => conn,
      "type" => benefit["type"],
      "changeset" => changeset,
      "step" => 1,
      "text" => "add_benefit_#{type}.html"
    }
    validate_type(params)
  end

  defp validate_type(%{
    "conn" => conn,
    "type" => type,
    "changeset" => changeset,
    "step" => step,
    "text" => text
  }) when type == "health" or type == "riders" do
    if type == "health" do
      conn
      |> redirect(to: "/benefits/new")
    else
      conn
      |> render(
        text,
        changeset: changeset,
        benefit_type: type,
        step: 1,
        modal_result: false
      )
    end
  end

  defp validate_type_edit(%{
    "conn" => conn,
    "type" => type,
    "changeset" => changeset,
    "step" => step,
    "text" => text,
    "benefit_type" => benefit_type,
    "benefit_id" => benefit_id,
    "benefit_2" => benefit_2
  }) when type == "health" or type == "riders" do
    conn
    |> render(
      text,
      changeset: changeset,
      benefit_type: benefit_type,
      benefit_id: benefit_id,
      benefit_2: benefit_2,
      step: step
    )
  end

  defp validate_type(%{
    "conn" => conn,
    "type" => type,
    "changeset" => changeset,
    "step" => step,
    "text" => text
  }) do
    conn
    |> put_flash(:error, "Please select benefit type.")
    |> redirect(
      to: "/web/benefits"
    )
  end

  def create(conn, %{"benefit" => params}) do
    params =
      params
      |> check_creation(params["is_draft"])
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put_new("acu_package_ids", nil)

    label_creation = with true <- params["is_draft"] == "true" do
      "Benefit has been saved as draft."
    else
      _ ->
        "Benefit Successfully Created"
    end

    category =
      params["category"]
      |> String.downcase()

    with {:done, benefit} <- BenefitContext.create_benefit(category, params) do
      conn
      |> put_flash(:info, label_creation)
      |> redirect(to: "/web/benefits/#{benefit.id}")
    else
      {:schemaless_error, changeset} ->
        conn
        |> put_flash(:error, "Please Check your params")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Benefit Code must be unique")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders")

      {:draft} ->
        conn
        |> put_flash(:info, "Benefit has been saved as draft.")
        |> redirect(to: "/web/benefits")

      {:limit_type_error} ->
        conn
        |> put_flash(:error, "Benefit limit type error.")
        |> redirect(to: "/web/benefits")
    end
  end

  def create_v2(conn, %{"benefit" => params}) do
    with true <- BenefitContext.check_coverage_if_dental(params["coverage_ids"]),
         true <- BenefitContext.check_if_type_is_availment_for_dental(params["type"]) do
           create_dental_benefit(conn, params)
    else
      _ ->

    changeset = Benefit.changeset_health(%Benefit{})
    coverages = CoverageContext.get_all_coverages()
    type = String.downcase(params["type"])

    params =
      params
      |> check_creation(params["is_draft"])
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put_new("acu_package_ids", nil)

    label_creation = with true <- params["is_draft"] == "true" do
      "Benefit has been saved as draft."
    else
      _ ->
        "Benefit Successfully Created"
    end

    category =
      params["category"]
      |> String.downcase()

    with {:done, benefit} <- BenefitContext.create_benefit(category, params) do

      benefit_coverages = CoverageContext.get_coverage_name_by_id(params["coverage_ids"])

      conn
      |> put_flash(:info, "Dental Benefit successfully created.")
      |> render(
        "add_benefit_riders.html",
        changeset: changeset,
        benefit_type: type,
        step: 1,
        modal_result: true,
        benefit_code: benefit.code,
        benefit_coverages: benefit_coverages
      )

      # dental_code = params["code"]
      # if List.first(benefit.benefit_coverages).coverage.code == "DENTL" do
      #   conn
      #   |> put_flash(:info, label_creation)
      #   |> redirect(to: "/web/benefits/#{dental_code}/view")
      # else
      #   conn
      #   |> put_flash(:info, label_creation)
      #   |> redirect(to: "/web/benefits/#{benefit.id}")
      # end
    else
      {:schemaless_error, changeset} ->
        conn
        |> put_flash(:error, "Please Check your params")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders", modal_result: false)

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Benefit Code must be unique")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders", modal_result: false)

      {:draft} ->
        conn
        |> put_flash(:info, "Benefit has been saved as draft.")
        |> redirect(to: "/web/benefits")


      {:limit_type_error} ->
        conn
        |> put_flash(:error, "Benefit limit type error.")
        |> redirect(to: "/web/benefits")
    end
         end
  end

  def create_dental_benefit(conn, params) do
    params =
      params
      |> check_creation(params["is_draft"])
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("classification", nil)
      |> Map.put("benefit_classification", nil)
      |> Map.put(
        "category",
        String.capitalize(params["category"])
      )
      |> Map.put_new("coverage_ids", nil)
      |> Map.put_new("limits", nil)
      |> Map.put_new("package_ids", nil)
      |> Map.put_new("procedure_ids", nil)

    changeset = Benefit.changeset_health(%Benefit{})
    coverages = CoverageContext.get_all_coverages()
    type = String.downcase(params["type"])

    category =
      params["category"]
      |> String.downcase()

    with {:done, benefit} <- BenefitContext.create_dental(category, params) do
      benefit_coverages = CoverageContext.get_coverage_name_by_id(params["coverage_ids"])

      conn
      |> put_flash(:info, "Dental Benefit successfully created.")
      |> render(
        "add_benefit_riders.html",
        changeset: changeset,
        benefit_type: type,
        step: 1,
        modal_result: true,
        benefit_code: benefit.code,
        benefit_coverages: benefit_coverages
      )
    else
      {:schemaless_error, changeset} ->
        conn
        |> put_flash(:error, "Please Check your params")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders", modal_result: false)

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Benefit Code must be unique")
        |> render("add_benefit_riders.html", changeset: changeset, benefit_type: "Riders", modal_result: false)

      {:draft} ->
        conn
        |> put_flash(:info, "Benefit has been saved as draft.")
        |> redirect(to: "/web/benefits")

      {:limit_type_error} ->
        conn
        |> put_flash(:error, "Benefit limit type error.")
        |> redirect(to: "/web/benefits")

    end
  end

  def create_new_rider(conn, %{}) do
    changeset = Benefit.changeset_health(%Benefit{})
    params = %{
      "conn" => conn,
      "type" => "riders",
      "changeset" => changeset,
      "step" => 1,
      "text" => "add_benefit_riders.html"
    }
    validate_type(params)
  end

  def create_healthplan(conn, %{"benefit" => params}) do
    params =
      params
      |> check_creation(params["is_draft"])
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put(
        "category",
        String.capitalize(params["category"])
      )
      |> Map.put(
        "coverage_ids",
        String.split(params["coverage_ids"], ",")
      )
      |> Map.put_new("coverage_ids", nil)
      |> Map.put_new("limits", nil)
      |> Map.put_new("package_ids", nil)
      |> Map.put_new("procedure_ids", nil)

    label_creation =
      params["is_draft"]
      |> is_label_draft("Created")

    with {:ok, benefit} <- BenefitContext.create_benefit_healthplan(params) do
      conn
      |> put_flash(:info, label_creation)
      |> redirect(to: "/web/benefits/#{benefit.id}")
    else
      _ ->
        conn
        |> put_flash(:error, "There was an error creating the benefit.")
        |> redirect(to: "/web/benefits")
    end
  end

  defp is_label_draft(status, action) when status == "true", do: "Benefit has been saved as draft."
  defp is_label_draft(status, action), do: "Benefit Successfully #{action}"

  def check_creation(map, "true"), do: map |> Map.put("step", "1")
  def check_creation(map, ""), do: map |> Map.put("step", "0")

  def load_coverages(conn, params) do
    case params["type"] do
      "health_plan" ->
        conn
        |> json(%{
          success: true,
          results: CoverageContext.load_coverage_dropdown(params["type"])
        })
      "riders" ->
        conn
        |> json(%{
          success: true,
          results: CoverageContext.load_coverage_dropdown(params["type"])
        })
      _ ->
        ### to counter null bytes and other type of encoding
        conn
        |> put_status(400)
        |> json(%{success: false, message: "Please try again!"})
    end
  end

  def load_diagnosis(conn, params) do
    diagnosis_ids =
      params["diagnosis_ids"]
      |> String.split(",")

    count =
      diagnosis_ids
      |> DiagnosisDatatable.diagnosis_count(
        params["type"]
      )

    data =
      diagnosis_ids
      |> DiagnosisDatatable.diagnosis_data(
        params
      )

    filtered_count =
      diagnosis_ids
      |> DiagnosisDatatable.diagnosis_filtered_count(
        params["type"],
        params["search"]["value"]
      )

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })

    rescue
      Elixir.Postgrex.Error ->
        conn
        |> put_flash(:error, "Error in parsing data. Unable to load datatable")
        |> redirect(to: "/web/benefits")
      _ ->
        conn
        |> put_flash(:error, "Unable to load datatable")
        |> redirect(to: "/web/benefits")
  end

  def load_all_diagnosis(conn, params) do
    diagnosis_ids =
      params["diagnosis_ids"]
      |> String.split(",")

    data =
      diagnosis_ids
      |> DiagnosisDatatable.diagnosis_all_data(
        params
      )

    conn
    |> json(%{
      data: data
    })
  end

  def load_packages(conn, _) do
    packages = PackageContext.load_package_dropdown()
    conn
    |> json(%{success: true, results: packages})
  end

  def load_procedure(conn, params) do
    if not is_nil(params["procedure_ids"]) || params["procedure_ids"] == "" do
      procedure_ids =
        params["procedure_ids"]
        |> String.split(",")
        |> Enum.uniq()
        |> List.delete("null")

      count =
        procedure_ids
        |> ProcedureDatatable.procedure_count()

      data =
        procedure_ids
        |> ProcedureDatatable.procedure_data(
          params["start"],
          params["length"],
          params["search"]["value"],
          params["order"]["0"]
        )

      filtered_count =
        procedure_ids
        |> ProcedureDatatable.procedure_filtered_count(
          params["search"]["value"]
        )

      conn
      |> json(%{
        data: data,
        draw: params["draw"],
        recordsTotal: count,
        recordsFiltered: filtered_count
      })
    else
      conn
      |> put_status(400)
      |> json(%{
        result: "failed"
      })
    end
  end

  def get_package(conn, %{"id" => id}) do
    package = PackageContext.load_package(id)

    conn
    |> json(package)
  end

  def load_benefit(conn, %{"id" => id}) do
    benefit_data = BenefitContext.load_benefit_data(id)

    conn
    |> json(benefit_data)
  end

  def load_benefit(conn, params) do
    conn
    |> put_status(400)
    |> json(%{
      result: "failed"
    })
  end

  ################################## Start: Adding a Package ##################################

  def set_benefit_package(conn, %{"current_package" => a, "newly_added_package" => b}), do: set_benefit_package(conn, a, b)
  def set_benefit_package(conn, "", newly_added_package) do
    with {:ok} <- BenefitContext.set_acu_packages(newly_added_package |> String.split()) do
      conn
      |> json(PackageContext.load_package(newly_added_package))
    else
      {:invalid, message} ->
        conn
        |> put_status(400)
        |> json(%{success: false, message: message})
      _ ->
        conn
        |> put_status(400)
        |> json(%{success: false, message: "Error setting up benefit package."})
    end
  end

  def set_benefit_package(conn, current_package, newly_added_package) do
    packages = merge_package_id(current_package, newly_added_package)
    with {:ok} <- BenefitContext.set_acu_packages(packages) do
      conn
      |> json(PackageContext.load_package(newly_added_package))
    else
      {:invalid, message} ->
        conn
        |> put_status(400)
        |> json(%{success: false, message: message})
      _ ->
        conn
        |> put_status(400)
        |> json(%{success: false, message: "Error setting up benefit package."})
    end
  end

  def set_benefit_package(conn, params) do
    conn
    |> put_status(400)
    |> json(%{success: false, message: "Invalid Parameters."})
  end

  defp merge_package_id(x, y), do: (x |> String.split(",")) ++ (y |> String.split())

  ################################## End: Adding a Package ##################################

  def add_benefit_healthplan(conn, _), do: render(conn, "add_benefit_healthplan.html")
  def add_benefit_riders(conn, _), do: render(conn, "add_benefit_riders.html")
  def benefit_detail(conn, _), do: render(conn, "benefit_detail.html")

  ########## BENEFIT SHOW PAGE ##########

  def show(conn, %{"id" => id}) do
    with {true, id}  <- UtilityContext.valid_uuid?(id),
      benefit = %Benefit{} <- BenefitContext.get_benefit_by_id(id)
    do
      benefit = BenefitContext.get_benefits_by_id(id)
      changeset_discontinue_benefit = Benefit.changeset_discontinue_benefit(%Benefit{})
      changeset_disabling_benefit = Benefit.changeset_disabling_benefit(%Benefit{})
      changeset_delete_benefit = Benefit.changeset_delete_benefit(%Benefit{})

      render(
        conn, "show.html",
        benefit: benefit,
        changeset_discontinue_benefit: changeset_discontinue_benefit,
        changeset_disabling_benefit: changeset_disabling_benefit,
        changeset_delete_benefit: changeset_delete_benefit
      )
    else
      _ ->
        conn
          |> put_flash(:error, "Benefit not found")
          |> redirect(to: "/web/benefits")
    end
  end

  def discontinue_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["discontinue_date"]
      |> String.split("  ", trim: true)

    dates_month = (Enum.at(dates, 0))
    months_map = %{"Jan" => '01', "Feb" => '02', "Mar" => '03', "Apr" => '04', "May" => '05', "Jun" => '06', "Jul" => '07', "Aug" => '08', "Sep" => '09', "Oct" => '10', "Nov" => '11', "Dec" => '12'}
    converted_date = months_map[dates_month]

    discontinue_date = Ecto.Date.cast!("#{Enum.at(dates, 2)}-#{converted_date}-#{Enum.at(dates, 1)}")
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "Discontinuing")
      |> Map.put("discontinue_date", discontinue_date)
      |> Map.put("id", params["id"])

    case BenefitContext.discontinue_benefit(benefit, params) do
      {:success} ->
        benefit =  get_benefit(benefit.id)
        discontinue_peme_log(
          conn.assigns.current_user,
          benefit,
          params
        )
        conn
        |> put_flash(:success, "For Discontinuing.")
        |> redirect(to: "/web/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "Discontinued.")
        |> redirect(to: "/web/benefits/#{benefit.id}")
    end
  end

  def delete_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["delete_date"]
      |> String.split("  ", trim: true)

    dates_month = (Enum.at(dates, 0))
    months_map = %{"Jan" => '01', "Feb" => '02', "Mar" => '03', "Apr" => '04', "May" => '05', "Jun" => '06', "Jul" => '07', "Aug" => '08', "Sep" => '09', "Oct" => '10', "Nov" => '11', "Dec" => '12'}
    converted_date = months_map[dates_month]

    delete_date = Ecto.Date.cast!("#{Enum.at(dates, 2)}-#{converted_date}-#{Enum.at(dates, 1)}")
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "For Deletion")
      |> Map.put("delete_date", delete_date)

    case BenefitContext.delete_peme_benefit(benefit, params) do
      {:success} ->
        benefit =  get_benefit(benefit.id)
        delete_peme_log(
          conn.assigns.current_user,
          benefit,
          params
        )
        conn
        |> put_flash(:info, "Benefit was successfully added for Deletion.")
        |> redirect(to: "/web/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "There was an error in Deleting Benefit.")
        |> redirect(to: "/web/benefits/#{benefit.id}")
    end
  end

  def disabling_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["disabled_date"]
      |> String.split("-")

    disabled_date = Ecto.Date.cast!("#{Enum.at(dates, 2)}-#{Enum.at(dates, 1)}-#{Enum.at(dates, 0)}")
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "For Disabled")
      |> Map.put("disabled_date", disabled_date)
      |> Map.drop(["id"])

    case BenefitContext.disabling_peme_benefit(benefit, params) do
      {:success} ->
        conn
        |> put_flash(:success, "For disabling!")
        |> redirect(to: "/web/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "Disabled!")
        |> redirect(to: "/web/benefits/#{benefit.id}")
    end
  end

  def disabling_benefit(conn, %{"benefit" => params}) do
    dates =
      params["disabled_date"]
      |> String.split("  ")

    dates_month = (Enum.at(dates, 0))
    months_map = %{"Jan" => '01', "Feb" => '02', "Mar" => '03', "Apr" => '04', "May" => '05', "Jun" => '06', "Jul" => '07', "Aug" => '08', "Sep" => '09', "Oct" => '10', "Nov" => '11', "Dec" => '12'}
    converted_date = months_map[dates_month]

    disabled_date = Ecto.Date.cast!("#{Enum.at(dates, 2)}-#{converted_date}-#{Enum.at(dates, 1)}")
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "Disabling")
      |> Map.put("disabled_date", disabled_date)
      |> Map.put("id", params["id"])

    case BenefitContext.disable_benefit(benefit, params) do
      {:success} ->
        benefit =  get_benefit(benefit.id)
        disable_peme_log(
          conn.assigns.current_user,
          benefit,
          params
        )
        conn
        |> put_flash(:info, "Benefit was successfully disabling!")
        |> redirect(to: "/web/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "There was an error disabling this benefit!")
        |> redirect(to: "/web/benefits/#{benefit.id}")
    end
  end

  def edit(conn, benefit) do
    choose_benefit_type(
      conn,
      %{
        "id" => benefit["id"]
      }
    )
  end

  def update(conn, %{"id" => id, "benefit" => benefit_params}) do
    label_creation =
      benefit_params["is_draft"]
      |> is_label_draft("Updated")

    benefit = BenefitContext.get_benefit(id)
    benefit_params =
      benefit_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> check_creation(benefit_params["is_draft"])

    with {:ok, benefit} <- BenefitContext.update_benefit_record(benefit, benefit_params) do
      conn
      |> put_flash(:info, label_creation)
      |> redirect(to: "/web/benefits/#{benefit.id}")

    else
      {:error, _} ->
        conn
        |> put_flash(:error, "Error editing benefit!")
        |> redirect(to: "/web/benefits")
      {:limit_type_error} ->
        conn
        |> put_flash(:error, "Benefit limit type error.")
        |> redirect(to: "/web/benefits")
      _ ->
        conn
        |> put_flash(:error, "Error editing benefit!")
        |> redirect(to: "/web/benefits")
    end
  rescue
    _ ->
      conn
      |> put_flash(:error, "Error editing benefit!")
      |> redirect(to: "/web/benefits")
  end

  def update_v2(conn, %{"id" => id, "benefit" => benefit_params}) do
    policy = benefit_params["benefit_policy"]
    label_creation =
      benefit_params["is_draft"]
      |> is_label_draft("Updated")

    benefit = BenefitContext.get_benefit(id)
    benefit_params =
      benefit_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> check_creation(benefit_params["is_draft"])

    with {:ok, benefit} <- BenefitContext.update_benefit_record_v2(benefit, benefit_params, policy) do
      conn
      |> put_flash(:info, label_creation)
      |> redirect(to: "/web/benefits/#{benefit.id}")

    else
      {:error, _} ->
        conn
        |> put_flash(:error, "Error editing benefit!")
        |> redirect(to: "/web/benefits")

      {:limit_type_error} ->
        conn
        |> put_flash(:error, "Benefit limit type error.")
        |> redirect(to: "/web/benefits")

      {:schemaless_error, changeset} ->
        category = String.downcase("#{benefit_params["category"]}")
        conn
        |> render("edit_benefit_#{category}.html",
                  changeset: changeset,
                  step: benefit_params["step"],
                  benefit_id: id
        )

      _ ->
        conn
        |> put_flash(:error, "Error.")
        |> redirect(to: "/web/benefits")
    end
  rescue
    _ ->
      conn
      |> put_flash(:error, "Error editing benefit!")
      |> redirect(to: "/web/benefits")
  end

  def check_code(conn, %{"code" => code}) do
    conn
    |> json(%{
      result: BenefitContext.check_code(code)
    })
  end

  def delete_benefit(conn, %{"id" => id}) do
    with {:ok, benefit} <- BenefitContext.delete_benefit(id) do
      conn
      |> put_flash(:info, "Benefit successfully discarded.")
      |> redirect(to: "/web/benefits")
    else
      _ ->
        conn
        |> put_flash(:error, "Error discarding benefit.")
        |> redirect(to: "/web/benefits")
    end
  end

  def load_benefit_package_dt(conn, params) do
    count = BenefitDatatableV2.get_benefit_package_count(params["id"])
    filtered_count = BenefitDatatableV2.get_benefit_package_filtered_count(params["search"]["value"], params["id"])

    datas = if params["start"] == "NaN" do
      []
    else
      BenefitDatatableV2.get_benefit_package(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_benefit_limit_dt(conn, params) do
    count = BenefitDatatableV2.get_benefit_limit_count(params["id"])
    filtered_count = BenefitDatatableV2.get_benefit_limit_filtered_count(params["search"]["value"], params["id"])

    datas = if params["start"] == "NaN" do
      []
    else
      BenefitDatatableV2.get_benefit_limit(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_procedure_data(conn, params) do
    count = BenefitDatatable.get_benefit_procedure_count(params["id"])
    filtered_count = BenefitDatatable.get_benefit_procedure_filtered_count(params["search"]["value"], params["id"])
    datas = if params["start"] == "NaN" do
      []
    else
      BenefitDatatable.get_benefit_procedure(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_diagnosis_data(conn, params) do
    count = BenefitDatatable.get_benefit_diagnosis_count(params["id"])
    filtered_count = BenefitDatatable.get_benefit_diagnosis_filtered_count(params["search"]["value"], params["id"])
    datas = if params["start"] == "NaN" do
      []
    else
      BenefitDatatable.get_benefit_diagnosis(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def load_dental_procedure_data(conn, params) do
    count = BenefitDatatable.get_benefit_dental_procedure_count(params["id"])
    filtered_count = BenefitDatatable.get_benefit_dental_procedure_filtered_count(params["search"]["value"], params["id"])
    datas = if params["start"] == "NaN" do
      []
    else
      BenefitDatatable.get_benefit_dental_procedure(params["start"], params["length"], params["search"]["value"], params["order"]["0"], params["id"])
    end
    json(conn, %{
      data: datas,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  # DENTAL BENEFIT
  def view(conn, %{"code" => code}) do
    render(conn, "view.html", code: code)
  end

  #ALL COVERAGES
  def view_benefit(conn, %{"code" => code}) do
    render(conn, "vue_benefit_show.html", code: code)
  end
end

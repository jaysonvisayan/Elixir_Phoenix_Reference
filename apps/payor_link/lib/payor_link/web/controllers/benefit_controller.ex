defmodule Innerpeace.PayorLink.Web.BenefitController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    Benefit,
    BenefitProcedure,
    BenefitDiagnosis,
    BenefitLimit,
    BenefitRUV,
    BenefitPackage,
    BenefitPharmacy,
    BenefitMiscellaneous
  }

  alias Innerpeace.Db.Base.{
    BenefitContext,
    RUVContext,
    PackageContext,
    CoverageContext,
    PharmacyContext,
    MiscellaneousContext,
    ProcedureContext
  }

  alias Innerpeace.Db.Datatables.BenefitDatatableV2

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
       :show
     ]

  plug :valid_uuid?, %{origin: "benefits"}
  when not action in [:index]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["benefits"]
    # benefits = get_benefit_index("", 0)
    # trigger_benefit_delete_date()
    # trigger_benefit_disabling_date()
    # trigger_benefit_discontinue_date()
    benefits = []
    render(conn, "index.html", benefits: benefits, permission: pem)
  end

  def index_load_datatable(conn, %{"params" => params}) do
    # benefits = get_benefit_index(params["search_value"], params["offset"])
    benefits = []
    render(conn, Innerpeace.PayorLink.Web.BenefitView, "load_all_benefits.json", benefits: benefits)
  end

  def new(conn, _params) do
    coverages =  get_all_coverages()
    changeset_health = Benefit.changeset_health(%Benefit{})
    changeset_riders = Benefit.changeset_riders(%Benefit{})
    render(
      conn,
      "step1.html",
      changeset_health: changeset_health,
      changeset_riders: changeset_riders,
      coverages: coverages,
      tab_checker: "health"
    )
  end

  def create_basic(conn, %{"benefit" => benefit_params}) do
    coverages =  get_all_coverages()
    case benefit_params["category"] do
      "Health" ->
        create_health(conn, coverages, benefit_params)
      "Riders" ->
        create_riders(conn, coverages, benefit_params)
      _ ->
        raise "invalid category"
    end
  end

  def create_health(conn, coverages, benefit_params) do
    changeset_riders = Benefit.changeset_riders(%Benefit{})
    benefit_params =
      benefit_params
      |> Map.put("step", 2)
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case create_benefit_health(benefit_params) do
      {:ok, benefit} ->
        set_benefit_coverages(benefit.id, benefit_params["coverage_ids"])
        conn
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating benefit! Check the errors below.")
        |> render(
          "step1.html",
          changeset_health: changeset,
          changeset_riders: changeset_riders,
          coverages: coverages,
          tab_checker: "health"
        )
    end
  end

  def create_riders(conn, coverages, benefit_params) do
    step = if CoverageContext.get_coverage(benefit_params["coverage_id"]).code == "ACU" ||
      CoverageContext.get_coverage(benefit_params["coverage_id"]).code == "PEME" do
      4
    else
      2
    end
    changeset_health = Benefit.changeset_health(%Benefit{})
    benefit_params =
      benefit_params
      |> Map.put("step", step)
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case create_benefit_riders(benefit_params) do
      {:ok, benefit} ->
        set_benefit_coverages(benefit.id, [benefit_params["coverage_id"]])
        if CoverageContext.get_coverage(benefit_params["coverage_id"]).code == "ACU" ||
           CoverageContext.get_coverage(benefit_params["coverage_id"]).code == "PEME" do
          conn
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
        else
          conn
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=2")
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating benefit! Check the errors below.")
        |> render(
          "step1.html",
          changeset_health: changeset_health,
          changeset_riders: changeset,
          coverages: coverages,
          tab_checker: "riders"
        )
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    benefit = get_benefit(id)
    list = Enum.map(benefit.benefit_coverages, &(&1.coverage.name))

    if benefit.step == 0 do
        conn
        |> put_flash(:error, "You are not allowed to get back to creation steps")
        |> redirect(to: benefit_path(conn, :show, benefit))
    else
      case step do
        "1" ->
          step1(conn, benefit)
        "2" ->
          step2(conn, benefit)
        "3" ->
          step3(conn, benefit, list)
        "4" ->
          step4(conn, benefit, list)
        "4.1" ->
          step4(conn, benefit, list)
        "5" ->
          step5(conn, benefit, list)
        "6" ->
          step6(conn, benefit, list)
        "7" ->
          step7(conn, benefit, list)
        "8" ->
          step8(conn, benefit, list)
        "9" ->
          step9(conn, benefit, list)
        _ ->
          invalid_step(conn)
      end
    end
  end

  def setup(conn, %{"id" => id}) do
    invalid_step(conn)
  end

  defp invalid_step(conn) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: benefit_path(conn, :index))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "benefit" => benefit_params}) do
    benefit = get_benefit(id)
    list = Enum.map(benefit.benefit_coverages, &(&1.coverage.name))
    case step do
      "1" ->
        validate_step1_update(conn, benefit, benefit_params)
      "2" ->
        step2_update(conn, benefit, benefit_params)
      "2.2" ->
        step2_edit_update_acu(conn, benefit, list, benefit_params)
      "3" ->
        step3_update(conn, benefit, list, benefit_params)
      "4" ->
        update_acu_checker(conn, benefit, list, benefit_params)
      "4.1" ->
        step4_update_benefit_limit(conn, benefit, list, benefit_params)
      "5" ->
        step5_update(conn, benefit, list, benefit_params)
      "6" ->
        step6_update(conn, benefit, list, benefit_params)
      "7" ->
        step7_update(conn, benefit, list, benefit_params)
      "8" ->
        step8_update(conn, benefit, list, benefit_params)

      _ ->
        invalid_step(conn)
    end
  end

  defp update_acu_checker(conn, benefit, list, benefit_params) do
    if acu_coverage?(benefit.benefit_coverages) || peme_coverage?(benefit.benefit_coverages) do
      step4_update_acu(conn, benefit, list, benefit_params)
    else
      step4_update(conn, benefit, list, benefit_params)
    end
  end

  defp update_peme_checker(conn, benefit, list, benefit_params) do
    if peme_coverage?(benefit.benefit_coverages) do
      step4_update_acu(conn, benefit, list, benefit_params)
    else
      step4_update(conn, benefit, list, benefit_params)
    end
  end

  def validate_step1_update(conn, benefit, benefit_params) do
    case benefit_params["category"] do
      "Riders" ->
        step1_update_riders(conn, benefit, benefit_params)
      "Health" ->
        step1_update_health(conn, benefit, benefit_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid category!")
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=1")
    end
  end

  def step1(conn, benefit) do
    coverages =  get_all_coverages()
    coverage_ids = [] ++ for coverage_benefit <- benefit.benefit_coverages do
      coverage_benefit.coverage.id
    end
    benefit = Map.put(benefit, :coverage_ids, coverage_ids)
    select_coverage = for select_coverage <- benefit.benefit_coverages, into: [] do
      select_coverage.coverage.name
    end
    if Enum.member?(select_coverage, "OP Consult") do
      benefit = Map.put(benefit, :coverage_picker, "OP Consult")
    else
      benefit = Map.put(benefit, :coverage_picker, "Others")
    end
    {changeset_health, changeset_riders, tab_checker} = setup_changeset(benefit, coverage_ids)
    render(
      conn,
      "step1_edit.html",
      benefit: benefit,
      changeset_health: changeset_health,
      changeset_riders: changeset_riders,
      coverages: coverages,
      tab_checker: tab_checker
    )
  end

  def setup_changeset(benefit, coverage_ids) do
    if benefit.category == "Health" do
      {Benefit.changeset_health(benefit), Benefit.changeset_riders(%Benefit{}), "health"}
    else
      benefit =
        benefit
        |> Map.delete(:coverage_ids)
        |> Map.put(:coverage_id, List.to_string(coverage_ids))
        {Benefit.changeset_health(%Benefit{}), Benefit.changeset_riders(benefit), "riders"}
    end
  end

  def step1_update_riders(conn, benefit, benefit_params) do
    step = if acu_coverage?(benefit.benefit_coverages) || peme_coverage?(benefit.benefit_coverages) do
      4
    else
      2
    end
    old_coverages = for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.id
    end
    coverages =  get_all_coverages()
    changeset_health = Benefit.changeset_health(%Benefit{})
    benefit_params =
      benefit_params
      |> Map.put("step", step)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case update_benefit_riders(benefit, benefit_params) do
      {:ok, benefit} ->
        if Enum.sort([benefit_params["coverage_id"]] || []) != Enum.sort(old_coverages) do
          clear_all(benefit.id)
          set_benefit_coverages(benefit.id, [benefit_params["coverage_id"]])
        end
        benefit = get_benefit(benefit.id)
        if acu_coverage?(benefit.benefit_coverages) || peme_coverage?(benefit.benefit_coverages) do
          conn
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
        else
          conn
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=2")
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating benefit! Check the errors below.")
        |> render(
          "step1_edit.html",
          benefit: benefit,
          changeset_health: changeset_health,
          changeset_riders: changeset,
          coverages: coverages,
          tab_checker: "riders"
        )
    end
  end

  def step1_update_health(conn, benefit, benefit_params) do
    old_coverages = for benefit_coverage <- benefit.benefit_coverages do
      benefit_coverage.coverage.id
    end
    coverages =  get_all_coverages()
    changeset_riders = Benefit.changeset_riders(%Benefit{})
    benefit_params =
      benefit_params
      |> Map.put("step", 2)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case update_benefit_health(benefit, benefit_params) do
      {:ok, benefit} ->
        if Enum.sort(benefit_params["coverage_ids"] || []) != Enum.sort(old_coverages) do
          clear_all(benefit.id)
          set_benefit_coverages(benefit.id, benefit_params["coverage_ids"])
        end
        conn
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating benefit! Check the errors below.")
        |> render("step1_edit.html",
                  benefit: benefit,
                  changeset_health: changeset,
                  changeset_riders: changeset_riders,
                  coverages: coverages,
                  tab_checker: "health"
        )
    end
  end

  def step2(conn, benefit) do
    procedures = ProcedureContext.get_procedures_modal_benefit(0, 100, "", benefit.id)
    benefit_procedures = get_benefit_procedures(benefit.id)
    # benefit_procedures = BenefitContext.get_benefit_procedures_modal(0, 100, "")
    # packages = get_all_packages()
    packages = []
    changeset = BenefitProcedure.changeset(%BenefitProcedure{})
    render(conn, "step2.html", changeset: changeset, benefit: benefit, procedures: procedures, packages: packages, benefit_procedures: benefit_procedures)
  end

  def step2_update(conn, benefit, benefit_params) do
    procedures = ProcedureContext.get_procedures_modal_benefit(0, 100, "", benefit.id)
    benefit_procedures = get_benefit_procedures(benefit.id)
    changeset =
      %BenefitProcedure{}
      |> BenefitProcedure.changeset()
      |> Map.put(:action, "insert")
    procedure = String.split(benefit_params["procedure_ids_main"], ",")
    if procedure == [""] do
      conn
      |> render("step2.html", changeset: changeset, benefit: benefit, procedures: procedures, benefit_procedures: benefit_procedures, modal_open: true)
    else
      set_benefit_procedures(benefit.id, procedure)
      update_step(conn, benefit, "3")
      conn
      |> redirect(to: "/benefits/#{benefit.id}/setup?step=2")
    end
  end

  def step4_update_acu(conn, benefit, list, benefit_params) do
    # ongoing for benefit with multiple packages
    packages = get_all_packages()
    changeset =
      %BenefitPackage{}
      |> BenefitPackage.changeset()
      |> Map.put(:action, "insert")
    package = String.split(benefit_params["package_ids_main"], ",")
    if package == [""] do
      conn
      |> render("step_package.html", changeset: changeset, benefit: benefit, packages: packages, modal_open: true)
    else
      case set_acu_benefit_packages(benefit.id, package) do
        {:ok} ->
          update_step(conn, benefit, "4")
          conn
          |> put_flash(:info, "Package Successfully Added.")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")

        {:error_overlapping_age, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")

        {:invalid, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
      end

    end

  end

  def step2_edit_update_acu(conn, benefit, list, benefit_params) do
    gender = Enum.join(benefit_params["gender"] || [], " & ")
    benefit_params =
      benefit_params
      |> Map.put("gender", gender)
    case update_benefit_procedure(benefit_params["benefit_procedure_id"], benefit_params) do
      {:ok, _benefit_procedure} ->
        if Enum.member?(list, "RUV") == true do
          conn
          |> put_flash(:info, "Package successfully updated!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
        else
          conn
          |> put_flash(:info, "Package successfully updated!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
        end
      {:error, _changeset} ->
        conn
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
    end
  end

  def step3(conn, benefit, list) do
    case Enum.member?(list, "RUV") do
      true ->
        ruvs = RUVContext.get_ruvs()
        changeset = BenefitRUV.changeset(%BenefitRUV{})
        render(conn, "step_ruv.html", changeset: changeset, benefit: benefit, ruvs: ruvs)
      false ->
        diagnoses =  get_all_diagnoses()
        changeset = BenefitProcedure.changeset(%BenefitProcedure{})
        render(conn, "step3.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses)
    end
  end

  def step3_update(conn, benefit, list, benefit_params) do
    case Enum.member?(list, "RUV") do
      true ->
        ruvs = RUVContext.get_ruvs()
        changeset =
          %BenefitRUV{}
          |> BenefitRUV.changeset()
          |> Map.put(:action, "insert")
          ruv = String.split(benefit_params["ruv_ids_main"], ",")
          if ruv == [""] do
            conn
            |> render("step_ruv.html", changeset: changeset, benefit: benefit, ruvs: ruvs, modal_open: true)
          else
            set_benefit_ruvs(benefit.id, ruv)
            update_step(conn, benefit, "4")
            conn
            |> put_flash(:info, "Benefit RUV successfully added!")
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=3")
          end
      false ->
        diagnoses = get_all_diagnoses()
        changeset =
          %BenefitProcedure{}
          |> BenefitProcedure.changeset()
          |> Map.put(:action, "insert")
          diagnosis = String.split(benefit_params["diagnosis_ids_main"], ",")
          if diagnosis == [""] do
            conn
            |> render("step3.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses, modal_open: true)
          else
            set_benefit_diagnoses(benefit.id, diagnosis)
            update_step(conn, benefit, "4")
            conn
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=3")
          end
    end
  end

  def step4(conn, benefit, list) do
    case Enum.member?(list, "RUV") do
      true ->
        diagnoses =  get_all_diagnoses()
        changeset = BenefitProcedure.changeset(%BenefitProcedure{})
        render(conn, "step3.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses)
      false ->
        packages =  PackageContext.get_all_packages
        changeset = BenefitPackage.changeset(%BenefitPackage{})
        render(conn, "step_package.html", changeset: changeset, benefit: benefit, packages: packages)
    end
  end

  def step4_update(conn, benefit, list, benefit_params) do
    case Enum.member?(list, "RUV") do
      true ->
        diagnoses = get_all_diagnoses()
        changeset =
          %BenefitDiagnosis{}
          |> BenefitDiagnosis.changeset()
          |> Map.put(:action, "insert")
          diagnosis = String.split(benefit_params["diagnosis_ids_main"], ",")
          if diagnosis == [""] do
            conn
            |> render("step3.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses, modal_open: true)
          else
            set_benefit_diagnoses(benefit.id, diagnosis)
            update_step(conn, benefit, "5")
            conn
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
          end
      false ->
        packages = get_all_packages()
        changeset =
          %BenefitPackage{}
          |> BenefitPackage.changeset()
          |> Map.put(:action, "insert")
          package = String.split(benefit_params["package_ids_main"], ",")
          if package == [""] do
            conn
            |> render("step_package.html", changeset: changeset, benefit: benefit, packages: packages, modal_open: true)
          else
            set_benefit_packages(benefit.id, package)
            update_step(conn, benefit, "5")
            conn
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=4")
          end
    end
  end

  def step5(conn, benefit, list) do
    case Enum.member?(list, "RUV") do
      true ->
        packages =  PackageContext.get_all_packages
        changeset = BenefitPackage.changeset(%BenefitPackage{})
        render(conn, "step_package.html", changeset: changeset, benefit: benefit, packages: packages)
      false ->
        changeset = BenefitLimit.changeset(%BenefitLimit{})
        benefit_limits = for benefit_limit <- benefit.benefit_limits do
          benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
          coverage_names = for coverage_code <- benefit_limit_coverages do
            get_coverage_name_by_code(coverage_code)
          end
          Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
        end
      render(conn, "step4.html", changeset: changeset, benefit: benefit, benefit_limits: benefit_limits)
    end
  end

  ######################################## start: new changes for benefit disabling steps
  def step6(conn, benefit, list) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        ## benefit_limit
        ## true true
        changeset = BenefitLimit.changeset(%BenefitLimit{})
        benefit_limits = for benefit_limit <- benefit.benefit_limits do
          benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
          coverage_names = for coverage_code <- benefit_limit_coverages do
            get_coverage_name_by_code(coverage_code)
          end
          Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
        end
        render(conn, "step4.html", changeset: changeset, benefit: benefit, benefit_limits: benefit_limits)

      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) == false ->
        ## benefit_limit
        ## true false
        changeset = BenefitLimit.changeset(%BenefitLimit{})
        benefit_limits = for benefit_limit <- benefit.benefit_limits do
          benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
          coverage_names = for coverage_code <- benefit_limit_coverages do
            get_coverage_name_by_code(coverage_code)
          end
          Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
        end
        render(conn, "step4.html", changeset: changeset, benefit: benefit, benefit_limits: benefit_limits)

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        ## pharmacy
        ## false true
        pharmacies = PharmacyContext.get_all_pharmacy()
        changeset = BenefitPharmacy.changeset(%BenefitPharmacy{})
        render(conn, "step_pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies)

      true ->
        ## summary
        ##  false false
        changeset = Benefit.changeset_step(benefit)
        render(conn, "step5.html", changeset: changeset, benefit: benefit)

    end

    rescue
      _ ->
        conn
        |> put_flash(:error, "Error in Step")
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
  end

  def step7(conn, benefit, list) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        ## pharmacy
        ## true true
        pharmacies = PharmacyContext.get_all_pharmacy()
        changeset = BenefitPharmacy.changeset(%BenefitPharmacy{})
        render(conn, "step_pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies)

      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) == false ->
        ## summary
        ## true false
        changeset = Benefit.changeset_step(benefit)
        render(conn, "step5.html", changeset: changeset, benefit: benefit)

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        ## miscellaneous
        ## false true
        miscellaneous = MiscellaneousContext.get_all_miscellaneous()
        changeset = BenefitMiscellaneous.changeset(%BenefitMiscellaneous{})
        render(conn, "step_miscellaneous.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous)

      true ->
        ##  false false
        changeset = Benefit.changeset_step(benefit)
        render(conn, "step6.html", changeset: changeset, benefit: benefit)
    end

    rescue
      _ ->
        conn
        |> put_flash(:error, "Error in Step")
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
  end

  def step8(conn, benefit, list) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        ## miscellaneous
        ## true true
        miscellaneous = MiscellaneousContext.get_all_miscellaneous()
        changeset = BenefitMiscellaneous.changeset(%BenefitMiscellaneous{})
        render(conn, "step_miscellaneous.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous)

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        ## summary
        ## false true
        changeset = Benefit.changeset_step(benefit)
        render(conn, "step5.html", changeset: changeset, benefit: benefit)

      true ->
        ##  false false
        changeset = Benefit.changeset_step(benefit)
        render(conn, "step7.html", changeset: changeset, benefit: benefit)
    end

    rescue
      _ ->
        conn
        |> put_flash(:error, "Error in Step")
        |> redirect(to: "/benefits/#{benefit.id}/setup?step=7")
  end

  def step9(conn, benefit, list) do
    if Enum.member?(list, "RUV") and ip_opl_emer_checker(list) do
      ## summary
      ## true true
      changeset = Benefit.changeset_step(benefit)
      render(conn, "step5.html", changeset: changeset, benefit: benefit)
    else
      changeset = Benefit.changeset_step(benefit)
      render(conn, "step5.html", changeset: changeset, benefit: benefit)
    end
  end

  def ip_opl_emer_checker(list) do
    ["OP Laboratory", "Inpatient", "Emergency"] -- list
    |> Enum.count()
    |> pharmacy_misc_setup()
  end

  def pharmacy_misc_setup(count) do
    if count != 3 do
      true
    else
      false
    end
  end
  ######################################## end: new changes for benefit disabling steps

  def step4_update_benefit_limit(conn, benefit, list, benefit_params) do
    case Enum.member?(list, "RUV") do
      true ->
        coverages =
          benefit_params["coverages"]
          |> String.split(",")
          |> Enum.join(", ")
          benefit_params =
            benefit_params
            |> Map.put("coverages", coverages)
            benefit_params = setup_limits_params(benefit_params)
            case update_benefit_limit(benefit_params["benefit_limit_id"], benefit_params) do
              {:ok, _params} ->
                conn
                |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
              {:error, _changeset} ->
                conn
                |> put_flash(:error, "Error updating benefit limit!")
                |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
            end
      false ->
        coverages =
          benefit_params["coverages"]
          |> String.split(",")
          |> Enum.join(", ")
          benefit_params =
            benefit_params
            |> Map.put("coverages", coverages)
            benefit_params = setup_limits_params(benefit_params)
            case update_benefit_limit(benefit_params["benefit_limit_id"], benefit_params) do
              {:ok, _params} ->
                conn
                |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
              {:error, _changeset} ->
                conn
                |> put_flash(:error, "Error updating benefit limit!")
                |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
            end
    end
  end

  def step5_update(conn, benefit, list, benefit_params) do
    case Enum.member?(list, "RUV") do
      true ->
        packages = get_all_packages()
        changeset =
          %BenefitPackage{}
          |> BenefitPackage.changeset()
          |> Map.put(:action, "insert")
          package = String.split(benefit_params["package_ids_main"], ",")
          if package == [""] do
            conn
            |> render("step_package.html", changeset: changeset, benefit: benefit, packages: packages, modal_open: true)
          else
            set_benefit_packages(benefit.id, package)
            update_step(conn, benefit, "6")
            conn
            |> put_flash(:info, "Benefit packages successfully added!")
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
          end
      false ->
        benefit_params = setup_limits_params(benefit_params)
        coverages_string = Enum.join(benefit_params["coverages"] || [], ", ")
        benefit_params =
          benefit_params
          |> Map.put("coverages", coverages_string)
          |> Map.put("benefit_id", benefit.id)
          benefit_limits = for benefit_limit <- benefit.benefit_limits do
            benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
            coverage_names = for coverage_code <- benefit_limit_coverages do
              get_coverage_name_by_code(coverage_code)
            end
            Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
          end
          case insert_benefit_limit(benefit.id, benefit_params) do
            {:ok, _params} ->
              update_step(conn, benefit, "5")
              conn
              |> redirect(to: "/benefits/#{benefit.id}/setup?step=5")
            {:error, changeset} ->
              conn
              |> put_flash(:error, "Error adding benefit limits! Please check the errors below.")
              |> render("step4.html", changeset: changeset, benefit: benefit, modal_open: true, benefit_limits: benefit_limits)
          end
    end
  end

  # start: new changes for benefit disabling steps, for updating a step
  def step6_update(conn, benefit, list, benefit_params) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        benefit_params = setup_limits_params(benefit_params)
        coverages_string = Enum.join(benefit_params["coverages"] || [], ", ")
        benefit_params =
          benefit_params
          |> Map.put("coverages", coverages_string)
          |> Map.put("benefit_id", benefit.id)
          benefit_limits = for benefit_limit <- benefit.benefit_limits do
            benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
            coverage_names = for coverage_code <- benefit_limit_coverages do
              get_coverage_name_by_code(coverage_code)
            end
            Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
          end
      case insert_benefit_limit(benefit.id, benefit_params) do
        {:ok, _params} ->
          update_step(conn, benefit, "5")
          conn
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Error adding benefit limits! Please check the errors below.")
          |> render("step4.html", changeset: changeset, benefit: benefit, modal_open: true, benefit_limits: benefit_limits)
      end

      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) == false ->
        benefit_params = setup_limits_params(benefit_params)
        coverages_string = Enum.join(benefit_params["coverages"] || [], ", ")
        benefit_params =
        benefit_params
          |> Map.put("coverages", coverages_string)
          |> Map.put("benefit_id", benefit.id)
        benefit_limits = for benefit_limit <- benefit.benefit_limits do
          benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
          coverage_names = for coverage_code <- benefit_limit_coverages do
            get_coverage_name_by_code(coverage_code)
          end
          Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
        end
        case insert_benefit_limit(benefit.id, benefit_params) do
          {:ok, _params} ->
            update_step(conn, benefit, "5")
            conn
            |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error adding benefit limits! Please check the errors below.")
            |> render("step4.html", changeset: changeset, benefit: benefit, modal_open: true, benefit_limits: benefit_limits)
        end

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        pharmacies = PharmacyContext.get_all_pharmacy()
        changeset =
          %BenefitPharmacy{}
          |> BenefitPharmacy.changeset()
          |> Map.delete(:action)
          |> Map.put(:action, "insert")

        pharmacies = String.split(benefit_params["pharmacy_ids_main"], ",")
        if pharmacies == [""] do
          conn
          |> render("step_pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies, modal_open: true)
        else
          set_benefit_pharmacies(benefit.id, pharmacies)
          update_step(conn, benefit, "7")
          conn
          |> put_flash(:info, "Benefit pharmacy successfully added!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=6")
        end

      true ->
        raise "Invalid updating step"

    end

  end

  def step7_update(conn, benefit, list, benefit_params) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        pharmacies = PharmacyContext.get_all_pharmacy()
        changeset =
          %BenefitPharmacy{}
          |> BenefitPharmacy.changeset()
          |> Map.delete(:action)
          |> Map.put(:action, "insert")

        pharmacy_ids = String.split(benefit_params["pharmacy_ids_main"], ",")
        if pharmacy_ids == [""] do
          conn
          |> render("step_pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies, modal_open: true)
        else
          set_benefit_pharmacies(benefit.id, pharmacy_ids)
          update_step(conn, benefit, "7")
          conn
          |> put_flash(:info, "Benefit pharmacy successfully added!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=7")
        end

      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) == false ->
        raise "Invalid updating step, theres nothing to update in this step if no ip, opl, emer"

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        miscellaneous = MiscellaneousContext.get_all_miscellaneous()
        changeset =
          %BenefitMiscellaneous{}
          |> BenefitMiscellaneous.changeset()
          |> Map.delete(:action)
          |> Map.put(:action, "insert")

        miscellaneous_ids = String.split(benefit_params["miscellaneous_ids_main"], ",")
        if  miscellaneous_ids == [""] do
          conn
          |> render("step_pharmacy.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous, modal_open: true)
        else
          set_benefit_miscellaneous(benefit.id, miscellaneous_ids)
          update_step(conn, benefit, "7")
          conn
          |> put_flash(:info, "Benefit miscellaneous successfully added!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=7")
        end

      true ->
        raise "Invalid updating step"

    end
  end

  def step8_update(conn, benefit, list, benefit_params) do
    cond do
      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) ->
        miscellaneous = MiscellaneousContext.get_all_miscellaneous()
        changeset =
          %BenefitMiscellaneous{}
          |> BenefitMiscellaneous.changeset()
          |> Map.delete(:action)
          |> Map.put(:action, "insert")

        miscellaneous_ids = String.split(benefit_params["miscellaneous_ids_main"], ",")
        if  miscellaneous_ids == [""] do
          conn
          |> render("step_miscellaneous.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous, modal_open: true)
        else
          set_benefit_miscellaneous(benefit.id, miscellaneous_ids)
          update_step(conn, benefit, "7")
          conn
          |> put_flash(:info, "Benefit miscellaneous successfully added!")
          |> redirect(to: "/benefits/#{benefit.id}/setup?step=8")
        end

      Enum.member?(list, "RUV") and ip_opl_emer_checker(list) == false ->
        raise "Invalid updating step, theres nothing to update in this step if no ip, opl, emer"

      Enum.member?(list, "RUV") == false and ip_opl_emer_checker(list) ->
        raise "Invalid updating step, theres nothing to update in this step if no ruv"

    end

  end

  #################################################### end: new changes for benefit disabling steps, for updating a step

  def submit(conn, %{"id" => id}) do
    benefit = get_benefit(id)
    update_step(conn, benefit, 0)

    create_benefit_peme_log(conn.assigns.current_user, benefit)
    conn
    |> put_flash(:info, "Benefit successfully created!")
    |> redirect(to: "/benefits/#{benefit.id}")
  end

  def show(conn, %{"id" => id}) do
    with benefit = %Benefit{} <- get_benefit!(id) do
      changeset_disabling_benefit = Benefit.changeset_disabling_benefit(%Benefit{})
      changeset_discontinue_benefit = Benefit.changeset_discontinue_benefit(%Benefit{})
      changeset_delete_benefit = Benefit.changeset_delete_benefit(%Benefit{})

      render(
        conn,
        "show.html",
        benefit: benefit,
        changeset_disabling_benefit: changeset_disabling_benefit,
        changeset_discontinue_benefit: changeset_discontinue_benefit,
        changeset_delete_benefit: changeset_delete_benefit
      )
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid Benefit ID")
        |> redirect(to: benefit_path(conn, :index))
    end
  end

  def show_benefit_log(conn, %{"id" => id, "message" => message}) do
    benefit_log = get_benefit_log(id, message)
    json conn, Poison.encode!(benefit_log)
  end

  def show_all_benefit_log(conn, %{"id" => id}) do
    benefit_log = get_all_benefit_log(id)
    json conn, Poison.encode!(benefit_log)
  end

  def delete_benefit_limit(conn, %{"id" => benefit_limit_id}) do
    delete_benefit_limit(benefit_limit_id)
    json conn, Poison.encode!(%{valid: true})
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _benefit} = delete_benefit(id)
    conn
    |> redirect(to: benefit_path(conn, :index))
  end

  defp update_step(conn, benefit, step) do
    update_benefit(benefit, %{"step" => step, "updated_by_id" => conn.assigns.current_user.id})
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    benefit = get_benefit(id)
    with true <- check_benefit(benefit) do
      list = Enum.map(benefit.benefit_coverages, &(&1.coverage.name))
      case tab do
        "general" ->
          edit_coverage_checker(conn, benefit)
        "procedures" ->
          cond do
            acu_coverage?(benefit.benefit_coverages) ->
              edit_procedures_acu(conn, benefit)
            peme_coverage?(benefit.benefit_coverages) ->
              edit_procedures_peme(conn, benefit)
            true ->
              edit_procedures(conn, benefit)
          end
        "limits" ->
          edit_limits(conn, benefit)
        "diseases" ->
          edit_diseases(conn, benefit)
        "ruvs" ->
          edit_ruvs(conn, benefit)
        "packages" ->
          edit_packages(conn, benefit)
        "pharmacy" ->
          edit_pharmacy(conn, benefit, list)
        "miscellaneous" ->
          edit_miscellaneous(conn, benefit, list)
        _ ->
          conn
          |> put_flash(:error, "Invalid tab")
          |> redirect(to: benefit_path(conn, :show, benefit))
      end
    else
      {:invalid, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: benefit_path(conn, :show, benefit))
      _ ->
        conn
        |> put_flash(:error, "Error has been occurred. Cannot edit benefit!")
        |> redirect(to: benefit_path(conn, :show, benefit))
    end
  end

  def edit_setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Page not found")
    |> redirect(to: benefit_path(conn, :index))
  end

  defp edit_coverage_checker(conn, benefit) do
    if benefit.category == "Riders" do
      edit_general_riders(conn, benefit)
    else
      edit_general_health(conn, benefit)
    end
  end

  # def discontinue_benefit(benefit, benefit_params) do
  #   raise 123
  #   benefit = BenefitContext.get_benefit(id)
  #   update_discontinue_benefit(benefit, benefit_params)
  #   case update_discontinue_benefit(benefit, benefit_params) do
  #     {:ok, benefit} ->
  #         conn
  #         |> redirect(to: "/benefits/#{benefit.id}/edit?tab")

  #     {:error, changeset} ->
  #       conn
  #         |> put_flash(:error, "Invalid")
  #         |> redirect(to: benefit_path(conn, :index))
  #   end
  # end

  def save(conn, %{"id" => id, "tab" => tab, "benefit" => benefit_params}) do
    benefit = get_benefit(id)
    list = Enum.map(benefit.benefit_coverages, &(&1.coverage.name))
    case tab do
      "general" ->
        save_benefit_coverage_checker(conn, benefit, benefit_params)
      "package" ->
        update_acu_package(conn, benefit, benefit_params)
      "procedures" ->
        acu_checker(conn, benefit, benefit_params)
      "diseases" ->
        update_diseases(conn, benefit, benefit_params)
      "limits" ->
        update_limits(conn, benefit, benefit_params)
      "limit_update" ->
        update_limit(conn, benefit, benefit_params)
      "ruv" ->
        update_ruv(conn, benefit, benefit_params)
      "packages" ->
        update_packages(conn, benefit, benefit_params)
      "pharmacy" ->
        update_pharmacy(conn, benefit, list, benefit_params)
      "miscellaneous" ->
        update_miscellaneous(conn, benefit, list, benefit_params)
    end
  end

  defp save_benefit_coverage_checker(conn, benefit, benefit_params) do
    if benefit.category == "Riders" do
      update_general_riders(conn, benefit, benefit_params)
      edit_benefit_peme_log(
        conn.assigns.current_user,
        Benefit.changeset(benefit, benefit_params),
        "General"
      )
    else
      update_general_health(conn, benefit, benefit_params)
    end
  end

  defp acu_checker(conn, benefit, benefit_params) do
    if acu_coverage?(benefit.benefit_coverages) || peme_coverage?(benefit.benefit_coverages) do
      update_procedures_acu(conn, benefit, benefit_params)
    else
      update_procedures(conn, benefit, benefit_params)
    end
  end

  def edit_general_riders(conn, benefit) do
    coverage_ids = [] ++ for coverage_benefit <- benefit.benefit_coverages do
      coverage_benefit.coverage.id
    end
    benefit = Map.put(benefit, :coverage_id, List.to_string(coverage_ids))
    coverages =  get_all_coverages()
    changeset = Benefit.changeset_edit_riders(benefit)
    render(conn, "edit/general_riders.html", benefit: benefit, coverages: coverages, changeset: changeset)
  end

  def update_general_riders(conn, benefit, benefit_params) do
    coverages =  get_all_coverages()
    case edit_update_benefit_riders(benefit, benefit_params) do
      {:ok, benefit} ->
        conn
        |> put_flash(:info, "Benefit updated successfully.")
        |> redirect(to: "/benefits/#{benefit.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating benefit! Check the errors below.")
        |> render("edit/general_riders.html", benefit: benefit, changeset: changeset, coverages: coverages)
    end
  end

  def edit_general_health(conn, benefit) do
    coverage_ids = [] ++ for coverage_benefit <- benefit.benefit_coverages do
      coverage_benefit.coverage.id
    end
    benefit = Map.put(benefit, :coverage_ids, coverage_ids)
    coverages =  get_all_coverages()
    changeset = Benefit.changeset_edit_health(benefit)
    render(conn, "edit/general_health.html", benefit: benefit, coverages: coverages, changeset: changeset)
  end

  def update_general_health(conn, benefit, benefit_params) do
    coverages =  get_all_coverages()
    case edit_update_benefit_health(benefit, benefit_params) do
      {:ok, benefit} ->
        conn
        |> put_flash(:info, "Benefit updated successfully.")
        |> redirect(to: "/benefits/#{benefit.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating benefit! Check the errors below.")
        |> render("edit/general_health.html", benefit: benefit, changeset: changeset, coverages: coverages)
    end
  end

  def edit_procedures(conn, benefit) do
    procedures = ProcedureContext.get_procedures_modal_benefit(0, 100, "", benefit.id)
    changeset = BenefitProcedure.changeset(%BenefitProcedure{})
    render(conn, "edit/procedures.html", changeset: changeset, benefit: benefit, procedures: procedures)
  end

  def update_procedures(conn, benefit, benefit_params) do
    procedures = ProcedureContext.get_procedures_modal_benefit(0, 100, "", benefit.id)
    changeset =
      %BenefitProcedure{}
      |> BenefitProcedure.changeset()
      |> Map.put(:action, "insert")
    procedure = String.split(benefit_params["procedure_ids_main"], ",")
    # add_package_peme_log(conn.assigns.current_user, benefit, benefit_params, "Packages")
    # edit_package_peme_log(
    #   conn.assigns.current_user,
    #   Benefit.changeset(benefit, benefit_params),
    #   "Procedure"
    # )

    if procedure == [""] do
      conn
      |> render("edit/procedures.html", changeset: changeset, benefit: benefit, procedures: procedures, modal_open: true)
    else
      set_benefit_procedures(benefit.id, procedure)
      conn
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
    end
  end

  def edit_procedures_acu(conn, benefit) do
    # packages = get_all_packages()
    # procedures =  get_all_procedures()
    # changeset = BenefitProcedure.changeset_acu(%BenefitProcedure{})
    # render(conn, "edit/procedures_acu.html", changeset: changeset, benefit: benefit, procedures: procedures, packages: packages)

    packages =  PackageContext.get_all_packages
    changeset = BenefitPackage.changeset(%BenefitPackage{})
    render(conn, "edit/procedures_acu.html", changeset: changeset, benefit: benefit, packages: packages)

  end

  def edit_procedures_peme(conn, benefit) do
    packages = PackageContext.get_all_packages
    changeset = BenefitPackage.changeset(%BenefitPackage{})
    render(conn, "edit/procedures_peme.html", changeset: changeset, benefit: benefit, packages: packages)
  end

  def update_acu_package(conn, benefit, benefit_params) do
    if benefit_params["package_id"] == "" do
      conn
      |> put_flash(:error, "Please select package!")
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=package")
    else
      _procedures =  get_all_procedures()
      package = get_package(benefit_params["package_id"])
      clear_benefit_procedures(benefit.id)
      insert_acu_procedure(benefit.id, benefit_params["package_id"], package.package_payor_procedure)
      clear_benefit_limits(benefit.id)
      # set_acu_limit(benefit.id)

      # For accountlink Single Enrollment of PEME
      clear_benefit_packages(benefit.id)
      set_benefit_packages(benefit.id, [package.id])

      conn
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
    end
  end

  def update_procedures_acu(conn, benefit, benefit_params) do
    # gender = Enum.join(benefit_params["gender"] || [], " & ")
    # benefit_params =
    #   benefit_params
    #   |> Map.put("gender", gender)
    # case update_benefit_procedure(benefit_params["benefit_procedure_id"], benefit_params) do
    #   {:ok, _benefit_procedure} ->
    #     conn
    #     |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
    #   {:error, _changeset} ->
    #     conn
    #     |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
    # end

    packages = get_all_packages()
    changeset =
      %BenefitPackage{}
      |> BenefitPackage.changeset()
      |> Map.put(:action, "insert")
    package = String.split(benefit_params["package_ids_main"], ",")
    if package == [""] do
      conn
      |> render("edit/procedures_acu.html", changeset: changeset, benefit: benefit, packages: packages, modal_open: true)
    else
      # set_benefit_packages(benefit.id, package)
      # update_step(conn, benefit, "5")
      # conn
      # |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
      add_package_peme_log(conn.assigns.current_user, benefit, benefit_params, "Packages")
      case set_acu_benefit_packages(benefit.id, package) do
        {:ok} ->
          # update_step(conn, benefit, "5")
          conn
          |> put_flash(:info, "Package Successfully Added.")
          |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")

          # {:ok} = PackageContext.delete_package(package.id)
          # conn
          # |> put_flash(:info, "Package Successfully Removed")
          # |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")

          # add_package_peme_log(conn.assigns.current_user, benefit, benefit_params, "Packages")
        {:error_overlapping_age, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: "/benefits/#{benefit.id}/edit?tab=procedures")
      end
    end
  end

  def edit_limits(conn, benefit) do
    changeset = BenefitLimit.changeset(%BenefitLimit{})
    benefit_limits = for benefit_limit <- benefit.benefit_limits do
      benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
      coverage_names = for coverage_code <- benefit_limit_coverages do
        get_coverage_name_by_code(coverage_code)
      end
      Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
    end
    render(conn, "edit/limits.html", changeset: changeset, benefit: benefit, benefit_limits: benefit_limits)
  end

  def update_limits(conn, benefit, benefit_params) do
    benefit_params = setup_limits_params(benefit_params)
    coverages_string = Enum.join(benefit_params["coverages"] || [], ", ")
    benefit_params =
      benefit_params
      |> Map.put("coverages", coverages_string)
      |> Map.put("benefit_id", benefit.id)
    benefit_limits = for benefit_limit <- benefit.benefit_limits do
      benefit_limit_coverages = String.split(benefit_limit.coverages, ", ")
      coverage_names = for coverage_code <- benefit_limit_coverages do
        get_coverage_name_by_code(coverage_code)
      end
      Map.merge(benefit_limit, %{names: Enum.join(coverage_names, ", ")})
    end
    case insert_benefit_limit(benefit.id, benefit_params) do
      {:ok, _benefit_procedure} ->
        conn
        |> redirect(to: "/benefits/#{benefit.id}/edit?tab=limits")
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error adding benefit limits! Please check the errors below.")
        |> render("edit/limits.html", changeset: changeset, benefit: benefit, modal_open: true, benefit_limits: benefit_limits)
    end
  end

  def update_limit(conn, benefit, benefit_params) do
    coverages =
      benefit_params["coverages"]
      |> String.split(",")
      |> Enum.join(", ")
    benefit_params =
      benefit_params
      |> Map.put("coverages", coverages)
    benefit_params = setup_limits_params(benefit_params)
    case update_benefit_limit(benefit_params["benefit_limit_id"], benefit_params) do
      {:ok, _params} ->
        conn
        |> redirect(to: "/benefits/#{benefit.id}/edit?tab=limits")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error updating benefit limit!")
        |> redirect(to: "/benefits/#{benefit.id}/edit?tab=limits")
    end
  end

  def edit_packages(conn, benefit) do
    packages =  PackageContext.get_all_packages()
    changeset = BenefitPackage.changeset(%BenefitPackage{})
    render(conn, "edit/packages.html", benefit: benefit, packages: packages, changeset: changeset)
  end

  def update_packages(conn, benefit, benefit_params) do
    packages = get_all_packages()
    changeset =
      %BenefitPackage{}
      |> BenefitPackage.changeset()
      |> Map.put(:action, "insert")
    package = String.split(benefit_params["package_ids_main"], ",")
    if package == [""] do
      conn
      |> render("edit/packages.html", changeset: changeset, benefit: benefit, packages: packages, modal_open: true)
    else
      set_benefit_packages(benefit.id, package)
      conn
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=packages")
    end
  end

  def edit_pharmacy(conn, benefit, list) do
    pharmacies = PharmacyContext.get_all_pharmacy()
    changeset = BenefitPharmacy.changeset(%BenefitPharmacy{})
    render(conn, "edit/pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies)
  end

  def update_pharmacy(conn, benefit, list, benefit_params) do
    pharmacies = PharmacyContext.get_all_pharmacy()
    changeset =
      %BenefitPharmacy{}
      |> BenefitPharmacy.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    pharmacy_ids = String.split(benefit_params["pharmacy_ids_main"], ",")
    if pharmacy_ids == [""] do
      conn
      |> render("edit/pharmacy.html", changeset: changeset, benefit: benefit, pharmacies: pharmacies, modal_open: true)
    else
      set_benefit_pharmacies(benefit.id, pharmacy_ids)
      update_step(conn, benefit, "7")
      conn
      |> put_flash(:info, "Benefit pharmacy successfully added!")
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=pharmacy")
    end

  end

  def edit_miscellaneous(conn, benefit, list) do
    miscellaneous = MiscellaneousContext.get_all_miscellaneous()
    changeset = BenefitMiscellaneous.changeset(%BenefitMiscellaneous{})
    render(conn, "edit/miscellaneous.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous)
  end

  def update_miscellaneous(conn, benefit, list, benefit_params) do
    miscellaneous = MiscellaneousContext.get_all_miscellaneous()
    changeset =
      %BenefitMiscellaneous{}
      |> BenefitMiscellaneous.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")

    miscellaneous_ids = String.split(benefit_params["miscellaneous_ids_main"], ",")
    if  miscellaneous_ids == [""] do
      conn
      |> render("edit/miscellaneous.html", changeset: changeset, benefit: benefit, miscellaneous: miscellaneous, modal_open: true)
    else
      set_benefit_miscellaneous(benefit.id, miscellaneous_ids)
      update_step(conn, benefit, "7")
      conn
      |> put_flash(:info, "Benefit miscellaneous successfully added!")
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=miscellaneous")
    end

  end

  def edit_ruvs(conn, benefit) do
    ruvs =  RUVContext.get_ruvs()
    changeset = BenefitRUV.changeset(%BenefitRUV{})
    render(conn, "edit/ruvs.html", changeset: changeset, benefit: benefit, ruvs: ruvs)
  end

  def update_ruv(conn, benefit, benefit_params) do
    ruvs = RUVContext.get_ruvs()
    changeset =
      %BenefitRUV{}
      |> BenefitRUV.changeset()
      |> Map.put(:action, "insert")
    ruv = String.split(benefit_params["ruv_ids_main"], ",")
    if ruv == [""] do
      conn
      |> render("edit/ruvs.html", changeset: changeset, benefit: benefit, ruvs: ruvs, modal_open: true)
    else
      set_benefit_ruvs(benefit.id, ruv)
      conn
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=ruvs")
    end
  end

  def edit_diseases(conn, benefit) do
    diagnoses =  get_all_diagnoses()
    changeset = BenefitProcedure.changeset(%BenefitProcedure{})
    render(conn, "edit/diseases.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses)
  end

  def update_diseases(conn, benefit, benefit_params) do
    diagnoses = get_all_diagnoses()
    changeset =
      %BenefitProcedure{}
      |> BenefitProcedure.changeset()
      |> Map.put(:action, "insert")
    diagnosis = String.split(benefit_params["diagnosis_ids_main"], ",")
    if diagnosis == [""] do
      conn
      |> render("edit/diseases.html", changeset: changeset, benefit: benefit, diagnoses: diagnoses, modal_open: true)
    else
      set_benefit_diagnoses(benefit.id, diagnosis)
      conn
      |> redirect(to: "/benefits/#{benefit.id}/edit?tab=diseases")
    end
  end

  def delete_benefit_procedure(conn, %{"id" => benefit_procedure_id}) do
    with %BenefitProcedure{} = benefit_procedure <- get_benefit_procedure!(benefit_procedure_id),
         {:ok, %BenefitProcedure{}} <- delete_benefit_procedure(benefit_procedure) do
        json conn, Poison.encode!(%{success: true})
    else
      _ ->
        json conn, Poison.encode!(%{success: true})
    end
  end

  def delete_benefit_disease(conn, %{"id" => benefit_disease_id}) do
    delete_benefit_disease!(benefit_disease_id)
    json conn, Poison.encode!(%{success: true})
  end

  def delete_benefit_ruv(conn, %{"id" => benefit_ruv_id}) do
    with {:ok, %BenefitRUV{}} <- delete_benefit_ruv!(benefit_ruv_id) do
      json conn, Poison.encode!(%{success: true})
    else
      {:error} ->
        raise conn
      _ ->
        raise conn
    end
  end

  def delete_benefit_package(conn, %{"id" => id}) do
    benefit_package = BenefitContext.get_benefit_package(id)
    package = PackageContext.get_package(benefit_package.package_id)
    benefit = BenefitContext.get_benefit(benefit_package.benefit_id)
    params =
    %{
      package_code: package.code,
      package_name: package.name,
      package_id: package.id
     }
    delete_package_peme_log(conn.assigns.current_user, benefit, params, "Packages")
    delete_benefit_package!(id)
    json conn, Poison.encode!(%{success: true})

  end

  def delete_benefit_pharmacy(conn, %{"id" => benefit_pharmacy_id}) do
    delete_benefit_pharmacy!(benefit_pharmacy_id)
    json conn, Poison.encode!(%{success: true})
  end

  def delete_benefit_miscellaneous(conn, %{"id" => benefit_miscellaneous_id}) do
    delete_benefit_miscellaneous!(benefit_miscellaneous_id)
    json conn, Poison.encode!(%{success: true})
  end

  def show_summary(conn, %{"id" => id}) do
    benefit = get_benefit(id)
    render(conn, "show_summary.html", benefit: benefit)
  end

  def get_all_benefit_code(conn, _params) do
    benefit = BenefitContext.get_all_benefit_code()
    json conn, Poison.encode!(benefit)
  end

  def get_benefit_code(conn, %{"code" => code}) do
    if is_nil(BenefitContext.get_benefit_code(code)) do
      json(conn, Poison.encode!(true))
    else
      json(conn, Poison.encode!(false))
    end
  end

  def delete_benefit(conn, %{"id" => benefit_id}) do
    benefit = get_benefit(benefit_id)
    clear_all(benefit.id)
    delete_benefit(benefit.id)
    json conn, Poison.encode!(%{success: true})
  end

  def download_benefits(conn, %{"benefit_param" => download_param}) do
    data = [["Code", "Name", "Created By",
             "Date Created", "Updated By", "Date Updated", "Coverages"]]
             ++ BenefitContext.download_benefits(download_param)
             |> CSV.encode
             |> Enum.to_list
             |> to_string

    conn
    |> json(data)
  end

  def disabling_benefit(conn, %{"benefit" => params}) do
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "Disabling")
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
        |> put_flash(:success, "Benefit was successfully disabling!")
        |> redirect(to: "/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "There was an error disabling this benefit!")
        |> redirect(to: "/benefits/#{benefit.id}")
    end
  end

  def disabling_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["disabled_date"]
      |> String.split("-")

    disabled_date = Ecto.Date.cast!("#{Enum.at(dates, 0)}-#{Enum.at(dates, 1)}-#{Enum.at(dates, 2)}")
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
        |> redirect(to: "/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "Disabled!")
        |> redirect(to: "/benefits/#{benefit.id}")
    end
  end

  def discontinue_benefit(conn, %{"benefit" => params}) do
    benefit = get_benefit(params["id"])
    params =
      params
      |> Map.put("status", "Discontinuing")
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
        |> put_flash(:success, "Benefit was successfully for discontinuing!")
        |> redirect(to: "/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "There was an error discontinuing this benefit!")
        |> redirect(to: "/benefits/#{benefit.id}")
    end
  end

  def discontinue_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["discontinue_date"]
      |> String.split("-")

    discontinue_date = Ecto.Date.cast!("#{Enum.at(dates, 2)}-#{Enum.at(dates, 0)}-#{Enum.at(dates, 1)}")
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
        |> put_flash(:success, "For Discontinuing")
        |> redirect(to: "/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "Discontinued")
        |> redirect(to: "/benefits/#{benefit.id}")
    end
  end

  def delete_peme_benefit(conn, %{"benefit" => params}) do
    dates =
      params["delete_date"]
      |> String.split("-")

    delete_date = Ecto.Date.cast!("#{Enum.at(dates, 0)}-#{Enum.at(dates, 1)}-#{Enum.at(dates, 2)}")
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
        |> put_flash(:success, "Benefit was successfully added for deletion!")
        |> redirect(to: "/benefits/#{benefit.id}")
      {:error} ->
        conn
        |> put_flash(:error, "There was an error deleting benefit!")
        |> redirect(to: "/benefits/#{benefit.id}")
    end
  end

  def redirect_delete(conn, params) do
    conn
    |> put_flash(:info, "Successfully Removed Package")
    |> redirect(to: "/benefits/#{params["id"]}/setup?step=#{params["step"]}")
  end

  def edit_redirect_delete(conn, params) do
    conn
    |> put_flash(:info, "Successfully Remove Package")
    |> redirect(to: "/benefits/#{params["id"]}/edit?tab=procedures")
  end


  defp check_benefit(benefit) do
    with {:valid} <- is_acu?(benefit.benefit_coverages),
         {:valid} <- is_peme?(benefit.benefit_coverages),
         {:valid} <- is_benefit_already_used?(benefit)
    do
      true
    else
      {:invalid, message} ->
        {:invalid, message}
      _ ->
        {:invalid, "Error has been occurred. Cannot edit benefit"}
    end
  end

  defp is_acu?(benefit_coverages) do
    benefit_coverages
    |> Enum.map(&(
      if &1.coverage.name == "ACU" do
        true
      else
        false
      end
    ))

    if Enum.member?(benefit_coverages, true) do
      {:invalid, "Benefit with ACU coverage cannot be edited!"}
    else
      {:valid}
    end
  end

  def is_peme?(benefit_coverages) do
    benefit_coverages
    |> Enum.map(&(
      if &1.coverage.name == "PEME" do
        true
      else
        false
      end
    ))

    if Enum.member?(benefit_coverages, true) do
      {:invalid, "Benefit with PEME coverage cannot be edited!"}
    else
      {:valid}
    end
  end

  def is_benefit_already_used?(benefit) do
    benefit =
      benefit
      |> Innerpeace.Db.Repo.preload([:product_benefits])

    if not Enum.empty?(benefit.product_benefits) do
      {:invalid, "Benefit already used in plan cannot be edited!"}
    else
      {:valid}
    end
  end

  def modal_procedure_index(conn, params) do
    count = ProcedureContext.get_procedures_modal_count(params["search"]["value"], params["id"])
    benefits = ProcedureContext.get_procedures_modal(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: benefits, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def load_all_benefits(conn, params) do
    count = BenefitDatatableV2.get_benefits_count(params["search"]["value"])
    benefits = BenefitDatatableV2.get_benefits(params["start"], params["length"], params["search"]["value"])

    json(conn, %{
      data: benefits,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: count
    })
  end
end

 defmodule Innerpeace.PayorLink.Web.ExclusionController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    Exclusion,
    ExclusionProcedure,
    ExclusionDisease,
    ExclusionDuration,
  }

  alias Innerpeace.Db.Base.{
    ExclusionContext,
    DiagnosisContext,
    ProcedureContext
  }

  alias Ecto.UUID

  plug :valid_uuid?, %{origin: "exclusions"}
  when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{exclusions: [:manage_exclusions]},
       %{exclusions: [:access_exclusions]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{exclusions: [:manage_exclusions]},
     ]] when not action in [
       :index,
       :show
     ]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["exclusions"]
    exclusions = ExclusionContext.get_all_exclusions()
    diagnoses = DiagnosisContext.get_all_tagged_diagnoses()
    payor_procedures = ProcedureContext.get_all_tagged_procedures()
    render(conn, "index.html", exclusions: exclusions, diagnoses: diagnoses, payor_procedures: payor_procedures, permission: pem)
  end

  def new(conn, _params) do
    exclusions = ExclusionContext.get_all_exclusions
    changeset_exclusion = Exclusion.changeset_exclusion(%Exclusion{})
    changeset_pre_existing = Exclusion.changeset_pre_existing(%Exclusion{})

    conn
    |> render(
      "step1.html",
      changeset_exclusion: changeset_exclusion,
      changeset_pre_existing: changeset_pre_existing,
      tab_checker: "exclusion",
      exclusions: exclusions
    )
  end

  def create_basic(conn, %{"exclusion" => exclusion_params}) do
     case exclusion_params["coverage"] do
      "General Exclusion" ->
        create_exclusion(conn, exclusion_params)
      "Pre-existing Condition" ->
        create_pre_existing(conn, exclusion_params)
    end
  end

  def create_exclusion(conn, exclusion_params) do
    changeset_pre_existing = Exclusion.changeset_pre_existing(%Exclusion{})
    exclusion_params =
      exclusion_params
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

      with {:ok, exclusion} <- ExclusionContext.create_exclusion(exclusion_params) do
        update_step(conn, exclusion, "2")
        conn
        |> put_flash(:info, "Success")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating General exclusion! Check the errors below.")
        |> render("step1.html", changeset_exclusion: changeset, changeset_pre_existing: changeset_pre_existing, tab_checker: "exclusion")
    end
  end

  def create_pre_existing(conn, exclusion_params) do
    changeset_exclusion = Exclusion.changeset_exclusion(%Exclusion{})
    cond do
      exclusion_params["limit_type"] == "Percentage" ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_percentage", exclusion_params["limit_amount"])
      exclusion_params["limit_type"] == "Sessions" ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_session", exclusion_params["limit_amount"])
      true ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_amount", exclusion_params["limit_amount"])
    end
    exclusion_params =
      exclusion_params
      |> Map.put("created_by_id", conn.assigns.current_user.id)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

      with {:ok, exclusion} <- ExclusionContext.create_pre_existing(exclusion_params) do
        update_step(conn, exclusion, "2")
        conn
        |> put_flash(:info, "Success")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating pre-existing condition! Check the errors below.")
        |> render("step1.html", changeset_exclusion: changeset_exclusion, changeset_pre_existing: changeset, tab_checker: "pre_existing")
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    exclusion = ExclusionContext.get_exclusion(id)
    coverage = exclusion.coverage
    cond do
      is_nil(exclusion) ->
        conn
        |> put_flash(:error, "Page not found!")
        |> redirect(to: exclusion_path(conn, :index))
      !is_nil(ExclusionContext.is_used?(id)) ->
        conn
        |> put_flash(:error, "Exclusion already used! Cannot be edited.")
        |> redirect(to: exclusion_path(conn, :index))
      step == "1" ->
        step1(conn, exclusion)
      step == "2" ->
        step2(conn, exclusion, coverage)
      step == "3" ->
        step3(conn, exclusion, coverage)
      step == "4" ->
        step4(conn, exclusion)
      true ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: exclusion_path(conn, :index))
    end
  end

  def setup(conn, params) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: exclusion_path(conn, :index))
  end

 def update_setup(conn, %{"id" => id, "step" => step, "exclusion" => exclusion_params}) do
    exclusion = ExclusionContext.get_exclusion(id)
    coverage = exclusion.coverage
    case step do
      "1" ->
        validate_step1_update(conn, exclusion, exclusion_params)
      "2" ->
        step2_coverage(conn, exclusion, exclusion_params, coverage)
      "2.1" ->
        step2_duration_delete(conn, exclusion, exclusion_params)
      "2.2" ->
        step2_delete(conn, exclusion, exclusion_params)
      "3" ->
        step3_coverage(conn, exclusion, exclusion_params, coverage)
      "3.1" ->
        step3_delete(conn, exclusion, exclusion_params)
      "3.2" ->
        step3_disease_delete(conn, exclusion, exclusion_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: user_path(conn, :index))
    end
  end

  defp step2_coverage(conn, exclusion, exclusion_params, coverage) do
    case coverage do
      "Pre-existing Condition" ->
        step2_duration_update(conn, exclusion, exclusion_params, coverage)
      "General Exclusion" ->
        step2_disease_update(conn, exclusion, exclusion_params, coverage)
        _ ->
        conn
        |> put_flash(:error, "Invalid coverage!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
     end
  end

  defp step3_coverage(conn, exclusion, exclusion_params, coverage) do
    case coverage do
      "Pre-existing Condition" ->
        step2_disease_update(conn, exclusion, exclusion_params, coverage)
      "General Exclusion" ->
        step3_update(conn, exclusion, exclusion_params)
        _ ->
        conn
        |> put_flash(:error, "Invalid coverage!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
    end
  end

  def validate_step1_update(conn, exclusion, exclusion_params) do
      case exclusion_params["coverage"] do
      "Pre-existing Condition" ->
        step1_update_pre_existing(conn, exclusion, exclusion_params)
      "General Exclusion" ->
        step1_update_exclusion(conn, exclusion, exclusion_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid coverage!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
    end
  end

  def step1(conn, exclusion) do
    {changeset_exclusion, changeset_pre_existing, tab_checker} = setup_changeset(exclusion.coverage, exclusion)

    conn
    |>  render(
      "step1_edit.html",
      exclusion: exclusion,
      changeset_exclusion: changeset_exclusion,
      changeset_pre_existing: changeset_pre_existing,
      tab_checker: tab_checker
    )
  end

  def setup_changeset(_category, exclusion) do
    if exclusion.coverage == "General Exclusion" do
      {Exclusion.changeset_exclusion(exclusion), Exclusion.changeset_pre_existing(%Exclusion{}), "exclusion"}
    else
      exclusion =
        exclusion
        {Exclusion.changeset_exclusion(%Exclusion{}), Exclusion.changeset_pre_existing(exclusion), "pre_existing"}
    end
  end

   def step1_update_pre_existing(conn, exclusion, exclusion_params) do
    changeset_exclusion = Exclusion.changeset_exclusion(%Exclusion{})
    cond do
      exclusion_params["limit_type"] == "Percentage" ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_percentage", exclusion_params["limit_amount"])
      exclusion_params["limit_type"] == "Sessions" ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_session", exclusion_params["limit_amount"])
      true ->
        exclusion_params = exclusion_params
                           |> Map.put("limit_amount", exclusion_params["limit_amount"])
    end
    exclusion_params =
      exclusion_params
      |> Map.put("step", 2)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      with {:ok, exclusion} <- ExclusionContext.update_pre_existing(exclusion, exclusion_params) do
        ExclusionContext.exclusion_clear_all(exclusion.id)
        conn
        |> put_flash(:info, "Pre-existing Condition successfully updated")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating pre-existing condition! Check the errors below.")
        |> render(
          "step1_edit.html",
          exclusion: exclusion,
          changeset_exclusion: changeset_exclusion,
          changeset_pre_existing: changeset,
          exclusion: exclusion,
          tab_checker: "pre_existing"
        )
    end
  end

  def step1_update_exclusion(conn, exclusion, exclusion_params) do
    changeset_pre_existing = Exclusion.changeset_pre_existing(%Exclusion{})
    exclusion_params =
      exclusion_params
      |> Map.put("step", 2)
      |> Map.put("updated_by_id", conn.assigns.current_user.id)

      with {:ok, exclusion} <- ExclusionContext.update_exclusion(exclusion, exclusion_params) do
        ExclusionContext.exclusion_clear_all(exclusion.id)
        conn
        |> put_flash(:info, "General Exclusion successfully updated")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating general exclusion! Check the errors below.")
        |> render(
          "step1_edit.html",
          exclusion: exclusion,
          changeset_exclusion: changeset,
          changeset_pre_existing: changeset_pre_existing,
          exclusion: exclusion,
          tab_checker: "exclusion"
        )
    end
  end

   def step2(conn, exclusion, coverage) do
    case coverage do
      "Pre-existing Condition" ->
        step2_duration(conn, exclusion, coverage)
      "General Exclusion" ->
        step2_disease(conn, exclusion, coverage)
      _ ->
        conn
        |> put_flash(:error, "Invalid coverage!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
    end
  end

  def step2_disease(conn, exclusion, coverage) do
    diseases =  DiagnosisContext.get_all_diagnoses()
    changeset = ExclusionDisease.changeset(%ExclusionDisease{})
    render(conn, "step2.html", changeset: changeset, exclusion: exclusion, diseases: diseases, coverage: coverage)
  end

  def step2_duration(conn, exclusion, coverage) do
    changeset = ExclusionDuration.changeset(%ExclusionDuration{})
    durations = ExclusionContext.list_all_durations()
    dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")
    non_dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Non-Dreaded")

    conn
    |> render(
      "step2_duration.html",
      durations: durations,
      changeset: changeset,
      exclusion: exclusion,
      coverage: coverage,
      dreaded: dreaded,
      non_dreaded: non_dreaded
    )
  end

  def step2_disease_update(conn, exclusion, exclusion_params, coverage) do
    changeset =
      %ExclusionDisease{}
      |> ExclusionDisease.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    disease_ids = String.split(exclusion_params["disease_ids_main"], ",")

    with false <- validate_ids(disease_ids) do
      ExclusionContext.set_exclusion_disease(exclusion.id, disease_ids)
      update_step(conn, exclusion, "#{disease_step(coverage)}")

      conn
      |> put_flash(:info, "Disease successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=#{disease_step(coverage)-1}")
    else
      {:empty} ->
        diseases = DiagnosisContext.get_all_diagnoses()
        conn
        |> render("step2.html",
          changeset: changeset,
          exclusion: exclusion,
          diseases: diseases,
          coverage: coverage,
          modal_open: true
        )
      _ ->
        conn
        |> put_flash(:error, "Error adding disease. Please try again!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
    end
  end

  defp disease_step("Pre-existing Condition"), do: 4
  defp disease_step("General Exclusion"), do: 3
  defp disease_step(_), do: 1

  defp validate_ids([""]), do: {:empty}
  defp validate_ids(ids) do
    ids
    |> Enum.into([], &(valid_uuid?(UUID.cast(&1))))
    |> Enum.member?(false)
  end

  defp valid_uuid?({:ok, _}), do: true
  defp valid_uuid?(:error), do: false

  def step2_delete(conn, exclusion, exclusion_params) do
    delete_exclusion_disease!(exclusion.id, exclusion_params["disease_id"])
    conn
    |> put_flash(:info, "Disease successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
  end

  def step2_duration_delete(conn, exclusion, exclusion_params) do
    delete_exclusion_duration!(exclusion.id, exclusion_params["duration_id"])
    conn
    |> put_flash(:info, "Duration successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
  end

   def step3(conn, exclusion, coverage) do
    case coverage do
      "Pre-existing Condition" ->
        step3_disease(conn, exclusion, coverage)
      "General Exclusion" ->
        step3_procedure(conn, exclusion)
      _ ->
        conn
        |> put_flash(:error, "Invalid coverage!")
        |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=1")
    end
  end

  def step3_procedure(conn, exclusion) do
    procedures =  ProcedureContext.get_all_payor_procedures()
    changeset = ExclusionProcedure.changeset(%ExclusionProcedure{})
    render(conn, "step3.html", changeset: changeset, exclusion: exclusion, procedures: procedures)
  end

  def step3_disease(conn, exclusion, coverage) do
    diseases =  DiagnosisContext.get_all_diagnoses()
    changeset = ExclusionDisease.changeset(%ExclusionDisease{})
    render(conn, "step2.html", changeset: changeset, exclusion: exclusion, diseases: diseases, coverage: coverage)
  end

  def step3_update(conn, exclusion, exclusion_params) do
    procedures =  ProcedureContext.get_all_payor_procedures()
    changeset =
      %ExclusionProcedure{}
      |> ExclusionProcedure.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    procedure = String.split(exclusion_params["procedure_ids_main"], ",")

    if procedure == [""] do
      conn
      |> render("step3.html", changeset: changeset, exclusion: exclusion, procedures: procedures, modal_open: true)
    else
      ExclusionContext.set_exclusion_procedure(exclusion.id, procedure)
      update_step(conn, exclusion, "4")
      conn
      |> put_flash(:info, "Procedure successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=3")
    end
  end

  def step3_delete(conn, exclusion, exclusion_params) do
    delete_exclusion_procedure!(exclusion.id, exclusion_params["procedure_id"])
    conn
    |> put_flash(:info, "Procedure successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=3")
  end

  def step3_disease_delete(conn, exclusion, exclusion_params) do
    delete_exclusion_disease!(exclusion.id, exclusion_params["disease_id"])
    conn
    |> put_flash(:info, "Disease successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=3")
  end

  def step4(conn, exclusion) do
    changeset = Exclusion.changeset_step(exclusion)
    render(conn, "step4.html", changeset: changeset, exclusion: exclusion)
  end

  def show(conn, %{"id" => id}) do
    pem = conn.private.guardian_default_claims["pem"]["exclusions"]
    exclusion = ExclusionContext.get_exclusion(id)
    coverage = exclusion.coverage
    render(conn, "show.html", exclusion: exclusion, coverage: coverage, tab_checker: "exclusion_procedure", permission: pem)
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _exclusion} = ExclusionContext.delete_exclusion(id)
    conn
    |> put_flash(:info, "Exclusion successfully deleted!")
    |> redirect(to: exclusion_path(conn, :index))
  end

  def submit(conn, %{"id" => id}) do
    exclusion = get_exclusion(id)
    update_step(conn, exclusion, 0)
    conn
    |> put_flash(:info, "Exclusion successfully created!")
    |> redirect(to: "/exclusions/#{exclusion.id}")
  end

  # defp handle_error(conn, reason) do
  #   conn
  #   |> put_flash(:error, reason)
  #   |> render(Innerpeace.PayorLink.Web.ErrorView, "500.html")
  # end

  defp update_step(conn, exclusion, step) do
    ExclusionContext.update_exclusion_step(exclusion, %{"step" => step, "updated_by_id" => conn.assigns.current_user.id})
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    exclusion = ExclusionContext.get_exclusion(id)
    validate_edit_tab(conn, exclusion, exclusion.coverage, tab)
  end

  def edit_setup(conn, _), do: page_not_found(conn)

  defp validate_edit_tab(conn, nil, _, _), do: page_not_found(conn)
  defp validate_edit_tab(conn, exclusion, coverage, "general"), do: edit_general(conn, exclusion, coverage)
  defp validate_edit_tab(conn, exclusion, _, "diseases"), do: edit_diseases(conn, exclusion)
  defp validate_edit_tab(conn, exclusion, coverage, "procedures") when coverage == "General Exclusion", do: edit_procedures(conn, exclusion)
  defp validate_edit_tab(conn, exclusion, coverage, "durations") when coverage == "Pre-existing Condition", do: edit_durations(conn, exclusion)
  defp validate_edit_tab(conn, _, _, _), do: page_not_found(conn)

  defp edit_general(conn, exclusion, coverage) when coverage == "Pre-existing Condition", do: edit_general_pre_existing(conn, exclusion)
  defp edit_general(conn, exclusion, coverage) when coverage == "General Exclusion", do: edit_general_exclusion(conn, exclusion)
  defp edit_general(conn, _, _), do: page_not_found(conn)

  defp page_not_found(conn) do
    conn
    |> put_flash(:error, "Page not found!")
    |> redirect(to: exclusion_path(conn, :index))
  end

  def save(conn, %{"id" => id, "tab" => tab, "exclusion" => exclusion_params}) do
    exclusion = ExclusionContext.get_exclusion(id)
    case tab do
      "general" ->
        if exclusion.coverage == "Pre-existing Condition" do
          update_general_pre_existing(conn, exclusion, exclusion_params)
        else
          update_general_exclusion(conn, exclusion, exclusion_params)
        end
      "diseases" ->
        update_diseases(conn, exclusion, exclusion_params)
      "procedures" ->
        update_procedures(conn, exclusion, exclusion_params)
      "durations" ->
        update_durations(conn, exclusion, exclusion_params)
    end
  end

  def edit_general_pre_existing(conn, exclusion) do
    changeset = Exclusion.changeset_edit_pre_existing(exclusion)
    render(conn, "edit/general_pre_existing.html", exclusion: exclusion, changeset: changeset)
  end

  def update_general_pre_existing(conn, exclusion, exclusion_params) do
      with{:ok, exclusion} <- ExclusionContext.edit_update_pre_existing(exclusion, exclusion_params) do
        conn
        |> put_flash(:info, "Pre-existing Condition successfully updated")
        |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=general")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating Pre-existing condition! Check the errors below.")
        |> render("edit/general_pre_existing.html", exclusion: exclusion, changeset: changeset)
    end
  end

  def edit_general_exclusion(conn, exclusion) do
    changeset = Exclusion.changeset_edit_exclusion(exclusion)
    render(conn, "edit/general_exclusion.html", exclusion: exclusion, changeset: changeset)
  end

  def update_general_exclusion(conn, exclusion, exclusion_params) do
      with {:ok, exclusion} <- ExclusionContext.edit_update_exclusion(exclusion, exclusion_params) do
        conn
        |> put_flash(:info, "General Exclusion successfully updated")
        |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=general")
      else {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating General exclusion! Check the errors below.")
        |> render("edit/general_exclusion.html", exclusion: exclusion, changeset: changeset)
    end
  end

  def edit_durations(conn, exclusion) do
    changeset = ExclusionDuration.changeset(%ExclusionDuration{})
    durations = ExclusionContext.list_all_durations()
    dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")
    non_dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Non-Dreaded")

    conn
    |> render(
      "edit/durations.html",
      dreaded: dreaded,
      non_dreaded: non_dreaded,
      durations: durations,
      changeset: changeset,
      exclusion: exclusion
    )
  end

  def update_durations(conn, exclusion, exclusion_params) do
    _durations =  ExclusionContext.list_all_durations()
      ExclusionContext.create_duration(exclusion.id, exclusion_params)
      conn
      |> put_flash(:info, "Duration successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=durations")
    end

  def edit_procedures(conn, exclusion) do
    procedures =  ProcedureContext.get_all_payor_procedures()
    changeset = ExclusionProcedure.changeset(%ExclusionProcedure{})
    render(conn, "edit/procedures.html", changeset: changeset, exclusion: exclusion, procedures: procedures)
  end

  def update_procedures(conn, exclusion, exclusion_params) do
    procedures =  ProcedureContext.get_all_payor_procedures()
    changeset =
      %ExclusionProcedure{}
      |> ExclusionProcedure.changeset()
      |> Map.put(:action, "insert")
    procedure = String.split(exclusion_params["procedure_ids_main"], ",")
    if procedure == [""] do
      conn
      |> render("edit/procedures.html", changeset: changeset, exclusion: exclusion, procedures: procedures, modal_open: true)
    else
      ExclusionContext.set_exclusion_procedure(exclusion.id, procedure)
      conn
      |> put_flash(:info, "Procedure successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=procedures")
    end
  end

  def edit_diseases(conn, exclusion) do
    diseases =  DiagnosisContext.get_all_diagnoses()
    changeset = ExclusionProcedure.changeset(%ExclusionProcedure{})
    render(conn, "edit/diseases.html", changeset: changeset, exclusion: exclusion, diseases: diseases)
  end

  def update_diseases(conn, exclusion, exclusion_params) do
    diseases = DiagnosisContext.get_all_diagnoses()
    changeset =
      %ExclusionProcedure{}
      |> ExclusionProcedure.changeset()
      |> Map.put(:action, "insert")
    disease = String.split(exclusion_params["disease_ids_main"], ",")
    if disease == [""] do
      conn
      |> render("edit/diseases.html", changeset: changeset, exclusion: exclusion, diseases: diseases, modal_open: true)
    else
      ExclusionContext.set_exclusion_disease(exclusion.id, disease)
      conn
      |> put_flash(:info, "Disease successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=diseases")
    end
  end

  def get_all_exclusion_code(conn, _params) do
    exclusion =  ExclusionContext.get_all_exclusion_code()
    json conn, Poison.encode!(exclusion)
  end

  def step2_duration_update(conn, exclusion, exclusion_params, _coverage) do
    _durations =  ExclusionContext.list_all_durations()
      ExclusionContext.create_duration(exclusion.id, exclusion_params)
      update_step(conn, exclusion, "3")
      conn
      |> put_flash(:info, "Duration successfully added!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
  end

  def delete_exclusion_procedure(conn, %{"id" => exclusion_id, "procedure_id" => procedure_id}) do
    exclusion = get_exclusion(exclusion_id)
    delete_exclusion_procedure!(exclusion.id, procedure_id)
    conn
    |> put_flash(:info, "Procedure successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=procedures")
  end

  def delete_exclusion_disease(conn, %{"id" => exclusion_id, "disease_id" => disease_id}) do
    exclusion = get_exclusion(exclusion_id)
    delete_exclusion_disease!(exclusion.id, disease_id)
    conn
    |> put_flash(:info, "Disease successfully deleted!")
    |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=diseases")
  end

  def delete_exclusion_duration_dreaded(conn, %{"id" => exclusion_id, "duration_id" => duration_id}) do
    exclusion = get_exclusion(exclusion_id)
    _disease_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Dreaded")
    dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")

    if dreaded <= 1 do
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
    else
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
    end
  end

  def delete_exclusion_duration_non_dreaded(conn, %{"id" => exclusion_id, "duration_id" => duration_id}) do
    exclusion = get_exclusion(exclusion_id)
    _disease_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Dreaded")
    _disease_non_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Non-Dreaded")
    _dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")
    non_dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Non-Dreaded")

    if non_dreaded <= 1 do
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Non-Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
    else
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/setup?step=2")
    end
  end

  def delete_edit_exclusion_duration_dreaded(conn, %{"id" => exclusion_id, "duration_id" => duration_id}) do
    exclusion = get_exclusion(exclusion_id)
    _disease_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Dreaded")
    dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")

    if dreaded <= 1 do
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=durations")
    else
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=durations")
    end
  end

  def delete_edit_exclusion_duration_non_dreaded(conn, %{"id" => exclusion_id, "duration_id" => duration_id}) do
    exclusion = get_exclusion(exclusion_id)
    _disease_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Dreaded")
    _disease_non_dreaded = ExclusionContext.check_disease_type(exclusion.id, "Non-Dreaded")
    _dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Dreaded")
    non_dreaded = ExclusionContext.check_duration_disease_type(exclusion.id, "Non-Dreaded")

    if non_dreaded <= 1 do
      clear_exclusion_disease_by_diseases_type(exclusion.id, "Non-Dreaded")
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=durations")
    else
      delete_exclusion_duration!(exclusion.id, duration_id)
      conn
      |> put_flash(:info, "Duration successfully deleted!")
      |> redirect(to: "/exclusions/#{exclusion.id}/edit?tab=durations")
    end
  end

  ### exclusion general batch upload
  def render_batch_upload(conn, _params) do
    uploaded_files = ExclusionContext.all_batch_upload_files()
    render(conn, "batch_upload.html", conn: conn, uploaded_files: uploaded_files)
  end

  def submit_batch_upload(conn, %{"exclusion" => batch_file}) do
    case ExclusionContext.create_batch_upload(batch_file, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/exclusions/batch_upload/files")

      {:missing_header_column, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/exclusions/batch_upload/files")

      {:invalid_format} ->
        conn
        |> put_flash(:error, "Wrong format")
        |> redirect(to: "/exclusions/batch_upload/files")

      {:empty_file, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/exclusions/batch_upload/files")

    end
  end

  def submit_batch_upload(conn, _params) do
    conn
    |> put_flash(:error, "Please choose a file.")
    |> redirect(to: "/exclusions/batch_upload/files")
  end

  def download_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"General Exclusion Batch.csv\"")
    |> send_resp(200, template_content())
  end

  defp template_content do
    [['Payor CPT Code', 'Diagnosis Code'], ['', '']]
      |> CSV.encode
      |> Enum.to_list
      |> to_string
  end

  # def cpt_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

  #   data = [["Payor Cpt Code", "Remarks"]] ++
  #     ExclusionContext.cpt_get_batch_log(log_id, status)
  #     |> CSV.encode
  #     |> Enum.to_list
  #     |> to_string

  #   conn
  #   |> json(data)

  # end

  # def icd_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

  #   data = [["Diagnosis Code", "Remarks"]] ++
  #     ExclusionContext.icd_get_batch_log(log_id, status)
  #     |> CSV.encode
  #     |> Enum.to_list
  #     |> to_string

  #   conn
  #   |> json(data)

  # end

  def delete_exclusion(conn, %{"id" => exclusion_id}) do
    exclusion = get_exclusion(exclusion_id)
    clear_all(exclusion.id)
    delete_exclusion(exclusion.id)
    json conn, Poison.encode!(%{success: true})
  end

  def cpt_delete_tag(conn, %{"payor_procedure_id" => payor_procedure_id}) do
    payor_procedure = get_payor_procedure!(payor_procedure_id)
    case ProcedureContext.cpt_clear_tagging(payor_procedure) do
      {:ok, _payor_procedure} ->
        conn
        |> put_flash(:info, "Payor CPT tag successfully remove.")
        |> redirect(to: exclusion_path(conn, :index, active: "general-payor_procedure"))
      {:error} ->
        conn
        |> put_flash(:error, "Invalid submit")
        |> redirect(to: exclusion_path(conn, :index, active: "general-payor_procedure"))
    end
  end

  def icd_delete_tag(conn, %{"disease_id" => disease_id}) do
    diagnosis = DiagnosisContext.get_diagnosis(disease_id)
    case DiagnosisContext.icd_clear_tagging(diagnosis) do
      {:ok, _diagnosis} ->
        conn
        |> put_flash(:info, "Diagnosis tag successfully remove.")
        |> redirect(to: exclusion_path(conn, :index, active: "general-disease"))
      {:error} ->
        conn
        |> put_flash(:error, "Invalid submit")
        |> redirect(to: exclusion_path(conn, :index, active: "general-disease"))
    end
  end

end

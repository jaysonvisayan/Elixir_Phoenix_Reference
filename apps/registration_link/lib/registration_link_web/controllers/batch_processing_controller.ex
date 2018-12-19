defmodule RegistrationLinkWeb.BatchController do
  use RegistrationLinkWeb, :controller
  alias Innerpeace.Db.Schemas.{
    # Facility,
    # Practitioner,
    Authorization,
    Batch
  }
  alias Innerpeace.Db.Base.{
    PractitionerContext,
    FacilityContext,
    BatchContext,
    AuthorizationContext,
    UserContext,
    MemberContext,
    CoverageContext
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  alias Guardian.Plug
  alias RegistrationLinkWeb.Authorize
  alias Innerpeace.FileUploader
  import Ecto.{Query, Changeset}, warn: false

  def new_pf_batch(conn, _params) do
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    facility = BatchContext.list_facility
    practitioner = PractitionerContext.get_all_practitioners()
    changeset = Batch.changeset(%Batch{})
    render(conn, "pf_new.html",
           changeset: changeset,
           data: [],
           facility: facility,
           practitioner: practitioner,
           batch_files: [],
           open: false)
  end

  def create_pf_batch(conn, %{"batch" => batch_params}) do
    batch_id = batch_params["id"]
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    user = Plug.current_resource(conn)
    practitioner = PractitionerContext.get_all_practitioners()
    facility = BatchContext.list_facility

    if batch_id == "" do
      with {:ok, batch} <- BatchContext.create_pf_batch(batch_params, user.id)
      do
        has_comment = Map.has_key?(batch_params, "comment")
        if has_comment do
          BatchContext.insert_single_comment(
            batch.id, batch_params, conn.assigns.current_user.id
          )
        end
        changeset = Batch.changeset(%Batch{})
        render(
          conn, "pf_new.html",
          changeset: changeset,
          data: [Map.put(batch, :description, batch_params["description"])],
          facility: facility,
          practitioner: practitioner,
          batch: batch,
          batch_files: [],
          open: true
        )
      else
        {:error, changeset} ->
          render(conn, "pf_new.html",
                 changeset: changeset,
                 facility: facility, data: [],
                 batch_files: [],
                 open: false,
                 practitioner: practitioner)
      end
    else
      batch = BatchContext.get_batch!(batch_id)
      batch_files = BatchContext.get_batch_files_by_batch_id(batch_id)
      params = %{status: ""}

      with {:ok, batch} <- BatchContext.update_pf_batch(batch, params, user.id)
      do
        has_comment = Map.has_key?(batch_params, "comment")
        if has_comment do
          BatchContext.insert_single_comment(
            batch.id, batch_params, conn.assigns.current_user.id
          )
        end
        changeset = Batch.changeset(%Batch{})
        render(
          conn, "pf_new.html",
          changeset: changeset,
          data: [Map.put(batch, :description, batch_params["description"])],
          facility: facility,
          practitioner: practitioner,
          batch: batch,
          batch_files: batch_files,
          open: true
        )
      else
        {:error, changeset} ->
          render(conn, "pf_new.html",
                 changeset: changeset,
                 facility: facility, data: [],
                 batch_files: [],
                 open: false,
                 practitioner: practitioner)
      end
    end
  end

  def edit_pf_batch(conn, %{"id" => id}) do
    batch = BatchContext.get_batch!(id)
    batch_files = BatchContext.get_batch_files_by_batch_id(id)
    facility = BatchContext.list_facility
    practitioner = PractitionerContext.get_all_practitioners()
    changeset = Batch.changeset(batch)
    description = "#{batch.facility.code} : #{batch.facility.name}"
    render(conn, "pf_edit.html",
      changeset: changeset,
      data: [Map.put(batch, :description, description)],
      facility: facility,
      practitioner: practitioner,
      batch_files: batch_files,
      open: false,
      batch: batch)
  end

  def update_pf_batch(conn, %{"id" => id, "batch" => batch_params}) do
    batch = BatchContext.get_batch!(id)
    batch_files = BatchContext.get_batch_files_by_batch_id(id)
    user = Plug.current_resource(conn)
    practitioner = PractitionerContext.get_all_practitioners()
    facility = BatchContext.list_facility
    description = "#{batch.facility.code} : #{batch.facility.name}"
    batch_params =
      batch_params
      |> Map.put("updated_by_id", user.id)

    case BatchContext.update_pf_batch(batch, batch_params, user.id) do
      {:ok, batch} ->
        batch = BatchContext.get_batch!(batch.id)
        changeset = Batch.changeset(batch)
        description = "#{batch.facility.code} : #{batch.facility.name}"

        conn
        |> put_flash(:success, "PF Batch Successfully Updated")
        |> render("pf_edit.html",
            changeset: changeset,
            data: [Map.put(batch, :description, description)],
            facility: facility,
            practitioner: practitioner,
            batch_files: batch_files,
            open: true,
            batch: batch)

      {:error, changeset}  ->
        conn
        |> put_flash(:error, changeset)
        |> render("pf_edit.html",
            changeset: changeset,
            data: [],
            facility: facility,
            practitioner: practitioner,
            batch_files: [],
            open: false, batch: batch)
    end

  end

  def new_hb_batch(conn, _) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch"]})
    facilities = BatchContext.list_facility
    changeset = Batch.changeset(%Batch{})
    render(conn, "hb_new.html",
           changeset: changeset,
           data: [],
           facilities: facilities,
           batch_files: [],
           open: false)
  end

  def create_hb_batch(conn, %{"batch" => batch_params}) do
    batch_id = batch_params["id"]
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch"]})
    user = Plug.current_resource(conn)
    facilities = BatchContext.list_facility

    if batch_id == "" do
      with {:ok, batch} <- BatchContext.create_hb_batch(batch_params, user.id)
      do
        has_comment = Map.has_key?(batch_params, "comment")
        if has_comment do
          BatchContext.insert_single_comment(
            batch.id, batch_params, conn.assigns.current_user.id
          )
        end
        changeset = Batch.changeset(%Batch{})
        render(
          conn, "hb_new.html",
          changeset: changeset,
          data: [Map.put(batch, :description, batch_params["description"])],
          facilities: facilities,
          batch: batch,
          batch_files: [],
          open: true
        )
      else
        {:error, changeset} ->
          render(conn, "hb_new.html",
                 changeset: changeset,
                 data: [],
                 facilities: facilities,
                 batch_files: [],
                 open: false)
      end
    else
      batch = BatchContext.get_batch!(batch_id)
      batch_files = BatchContext.get_batch_files_by_batch_id(batch_id)
      params = %{status: ""}

      with {:ok, batch} <- BatchContext.update_hb_batch(batch, params, user.id)
      do
        has_comment = Map.has_key?(batch_params, "comment")
        if has_comment do
          BatchContext.insert_single_comment(
            batch.id, batch_params, conn.assigns.current_user.id
          )
        end
        changeset = Batch.changeset(%Batch{})
        render(
          conn, "hb_new.html",
          changeset: changeset,
          data: [Map.put(batch, :description, batch_params["description"])],
          facilities: facilities,
          batch: batch,
          batch_files: batch_files,
          open: true
        )
      else
        {:error, changeset} ->
          render(conn, "hb_new.html",
                 changeset: changeset,
                 data: [],
                 facilities: facilities,
                 batch_files: [],
                 open: false)
      end
    end
  end

  def edit_hb_batch(conn, %{"id" => id}) do
    batch = BatchContext.get_batch!(id)
    batch_files = BatchContext.get_batch_files_by_batch_id(id)
    facilities = BatchContext.list_facility
    changeset = Batch.changeset(batch)
    description = "#{batch.facility.code} : #{batch.facility.name}"
    render(conn, "hb_edit.html",
      changeset: changeset,
      data: [Map.put(batch, :description, description)],
      facilities: facilities,
      batch_files: batch_files,
      open: false,
      batch: batch)
  end

  def update_hb_batch(conn, %{"id"=> id, "batch" => batch_params}) do
    batch = BatchContext.get_batch!(id)
    batch_files = BatchContext.get_batch_files_by_batch_id(id)
    user = Plug.current_resource(conn)
    facilities = BatchContext.list_facility
    changeset = Batch.changeset(batch)
    description = "#{batch.facility.code} : #{batch.facility.name}"
    batch_params =
      batch_params
      |> Map.put("updated_by_id", user.id)

    case BatchContext.update_hb_batch(batch, batch_params, user.id) do
      {:ok, batch} ->
        batch = BatchContext.get_batch!(batch.id)
        changeset = Batch.changeset(batch)
        description = "#{batch.facility.code} : #{batch.facility.name}"
        conn
        |> put_flash(:success, "HB Batch Successfully Updated")
        |> render("hb_edit.html",
            changeset: changeset,
            data: [Map.put(batch, :description, description)],
            facilities: facilities,
            batch_files: batch_files,
            open: true,
            batch: batch)
      {:error, changeset} ->
        conn
        |> put_flash(:error, changeset)
        |> render("hb_edit.html",
            changeset: changeset,
            data: [],
            facilities: facilities,
            batch_files: [],
            open: false,
            batch: batch)
    end
  end

  def get_facility_address(conn, %{"id" => facility_id}) do
    facility = BatchContext.get_facility_address(facility_id)
    with nil <- facility do
      json conn, Poison.encode!([])
    else
      _ ->
      json conn, Poison.encode!(facility)
    end
  end

  def get_practitioner_details(conn, %{"id" => practitioner_id}) do
    practitioner = BatchContext.get_practitioner_details(practitioner_id)
    with nil <- practitioner do
      json conn, Poison.encode!([])
    else
      _ ->
      json conn, Poison.encode!(practitioner)
    end
  end

  def hb_batch_summary(conn, _) do
    render conn, "hb_summary.html"
  end

  def index(conn, __params) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
    batch = BatchContext.get_all_batch()
    batch_authorizations = BatchContext.get_all_saved_batch_authorization()
    if is_nil(batch_authorizations) do
      batch_authorizations = []
    else
      batch_authorizations
    end

    authorizations = AuthorizationContext.list_approved_authorizations()
    render conn, "index.html", batch_processing: batch, authorizations: authorizations, batch_authorizations: batch_authorizations
  end

  def batch_download(conn, %{"batch_param" => download_param}) do
   data = [["Batch No.", "Facility",
            "Coverage", "Batch Type", "Status",
            "Assigned To", "Date Created", "Created By"]] ++ BatchContext.download_batch(download_param)
            |> CSV.encode
            |> Enum.to_list
            |> to_string
   conn
   |> json(data)
  end

  def show(conn, %{"id" => id}) do
    with {true, id} <- UtilityContext.valid_uuid?(id)
    do
      batch = BatchContext.get_batch!(id)
      changeset = Batch.changeset(batch)

      if batch.status == "Draft" do
        Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
        batch_files = BatchContext.get_batch_files_by_batch_id(id)
        facility = BatchContext.list_facility
        practitioner = PractitionerContext.get_all_practitioners()
        description = "#{batch.facility.code} : #{batch.facility.name}"

        if batch.type == "PF" do
          render(conn, "pf_new.html",
                 changeset: changeset,
                 data: [Map.put(batch, :description, description)],
                 facility: facility,
                 practitioner: practitioner,
                 batch: batch,
                 batch_files: batch_files,
                 open: false)
        else
          render(conn, "hb_new.html",
                 changeset: changeset,
                 data: [Map.put(batch, :description, description)],
                 facilities: facility,
                 batch: batch,
                 batch_files: batch_files,
                 open: false)
        end
      else
        render(conn, "batch_details2.html", batch: batch, changeset: changeset)
      end
    else
      _ ->
        conn
        |> put_flash(:error, "Page not found!")
        |> redirect(to: batch_path(conn, :index))
    end
  end

  # ADD LOA AND ATTACH DOCUMENTS
  def new_loa(conn, _params) do
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    with authorization = %Authorization{} <- AuthorizationContext.get_authorization_by_id(_params["authorization_id"]),
      batch = %Batch{} <- BatchContext.get_batch!(_params["id"]) do
      coverage = CoverageContext.get_coverage(authorization.coverage_id)
      case String.downcase(coverage.name) do
        "acu" ->
          new_acu(conn, _params, authorization, batch)
        "op consult" ->
          new_consult(conn, _params, authorization, batch)
        _ ->
          Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
          batch_id = batch.id
          batch = BatchContext.get_all_batch()
          batch_authorizations = BatchContext.get_all_saved_batch_authorization()
          if is_nil(batch_authorizations) do
            batch_authorizations = []
          else
            batch_authorizations
          end

          authorizations = AuthorizationContext.list_approved_authorizations()
          conn
          |> put_flash(:error, "Selected LOA has unsupported coverage for batching.")
          |> render("index.html",
                    batch_processing: batch,
                    authorizations: authorizations,
                    batch_authorizations: batch_authorizations,
                    modal_open: true,
                    batch_id: batch_id)
      end
    else
       _ ->
        conn
        |> put_flash(:error, "Page not found!")
        |> redirect(to: batch_path(conn, :index))
    end
  end

  def new_acu(conn, _params, authorization, batch) do
    acu_product = MemberContext.get_acu_product_by_member_id(authorization.member_id)
    batch_authorization = BatchContext.get_batch_authorization_by_ids(authorization.id, batch.id)
    has_batch_authorization = BatchContext.get_batch_authorization_by_authorization_id(authorization.id, batch.id)
    if is_nil(has_batch_authorization) do
      if is_nil(batch_authorization) do
      batch_authorization = []
      else
        batch_authorization
        batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
      end

      if is_nil(batch_authorization_files) do
        batch_authorization_files = []
      else
        batch_authorization_files
      end

      batch_authorizations = BatchContext.get_all_batch_authorization()
      if is_nil(batch_authorizations) do
        batch_authorizations = []
      else
        batch_authorizations
      end
      batch_authorization2 = [batch_authorization] |> List.delete(nil) |> List.flatten()

      authorizations = AuthorizationContext.list_approved_authorizations()
      changeset = Batch.changeset(%Batch{})
      render(conn, "loa_new.html",
        changeset: changeset,
        batch: batch,
        authorization: authorization,
        batch_authorization_files: batch_authorization_files,
        batch_authorization: batch_authorization,
        authorizations: authorizations,
        batch_authorizations: batch_authorizations,
        acu_product: acu_product,
        batch_authorization2: batch_authorization2)
    else
      Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
      batch_id = batch.id
      batch = BatchContext.get_all_batch()
      batch_authorizations = BatchContext.get_all_saved_batch_authorization()
      if is_nil(batch_authorizations) do
        batch_authorizations = []
      else
        batch_authorizations
      end

      authorizations = AuthorizationContext.list_approved_authorizations()
      conn
        |> put_flash(:error, "Selected LOA is already used in other batch. Please choose other LOA.")
        |> render("index.html",
          batch_processing: batch,
          authorizations: authorizations,
          batch_authorizations: batch_authorizations,
          modal_open: true,
          batch_id: batch_id)
    end
  end

  def new_consult(conn, _params, authorization, batch) do
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    batch = BatchContext.get_batch!(_params["id"])
    authorization = AuthorizationContext.get_authorization_by_id(_params["authorization_id"])
    batch_authorization = BatchContext.get_batch_authorization_by_ids(authorization.id, batch.id)
    has_batch_authorization = BatchContext.get_batch_authorization_by_authorization_id(authorization.id, batch.id)
    if is_nil(has_batch_authorization) do
      if is_nil(batch_authorization) do
      batch_authorization = []
      else
        batch_authorization
        batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
      end

      if is_nil(batch_authorization_files) do
        batch_authorization_files = []
      else
        batch_authorization_files
      end

      batch_authorizations = BatchContext.get_all_batch_authorization()
      if is_nil(batch_authorizations) do
        batch_authorizations = []
      else
        batch_authorizations
      end
      batch_authorization2 = [batch_authorization] |> List.delete(nil) |> List.flatten()

      authorizations = AuthorizationContext.list_approved_authorizations()
      changeset = Batch.changeset(%Batch{})
      render(conn, "loa_new.html",
        changeset: changeset,
        batch: batch,
        authorization: authorization,
        batch_authorization_files: batch_authorization_files,
        batch_authorization: batch_authorization,
        authorizations: authorizations,
        batch_authorizations: batch_authorizations,
        batch_authorization2: batch_authorization2)
    else
      Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
      batch_id = batch.id
      batch = BatchContext.get_all_batch()
      batch_authorizations = BatchContext.get_all_saved_batch_authorization()
      if is_nil(batch_authorizations) do
        batch_authorizations = []
      else
        batch_authorizations
      end

      authorizations = AuthorizationContext.list_approved_authorizations()
      conn
        |> put_flash(:error, "Selected LOA is already used in other batch. Please choose other LOA.")
        |> render("index.html",
          batch_processing: batch,
          authorizations: authorizations,
          batch_authorizations: batch_authorizations,
          modal_open: true,
          batch_id: batch_id)
    end
  end

  def create_new_batch_loa(conn, %{"batch" => batch_params}) do
    authorization = AuthorizationContext.get_authorization_by_id(batch_params["authorization_id"])
    coverage = CoverageContext.get_coverage(authorization.coverage_id)
    case String.downcase(coverage.name) do
      "op consult" ->
        new_batch_loa_op_consult(conn, batch_params, authorization)
      "acu" ->
        new_batch_loa_acu(conn, batch_params, authorization)
      #to follow for other coverages
    end
  end

  def new_batch_loa_op_consult(conn, batch_params, authorization) do
    batch = BatchContext.get_batch!(batch_params["id"])
    authorization = AuthorizationContext.get_authorization_by_id(batch_params["authorization_id"])
    changeset = Batch.changeset(%Batch{})
    user_id = conn.assigns.current_user.id
    member = MemberContext.get_active_member_by_id(authorization.member_id)
    batch_authorization = BatchContext.get_batch_authorization_by_ids(authorization.id, batch.id)

    if is_nil(batch_authorization) do
      batch_authorization = []
    else
      batch_authorization
      batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
    end

    if is_nil(batch_authorization_files) do
      batch_authorization_files = []
    else
      batch_authorization_files
    end

    if Enum.empty?(batch_authorization_files) do
      create_files_checker(batch, authorization, batch_authorization, batch_params, conn)
    else
      create_files_checker(batch, authorization, batch_authorization, batch_params, conn)
    end
  end

  def new_batch_loa_acu(conn, batch_params, authorization) do
    batch = BatchContext.get_batch!(batch_params["id"])
    changeset = Batch.changeset(%Batch{})
    user_id = conn.assigns.current_user.id
    member = MemberContext.get_active_member_by_id(authorization.member_id)

    if Map.has_key?(batch_params, "availment_date") == true do
      availment_date = if batch_params["availment_date"] == "" do
                        Ecto.Date.cast!("0001-01-01")
                      else
                        Ecto.Date.cast!(batch_params["availment_date"])
                      end
      is_member_covered_effectivity = Ecto.DateTime.compare(availment_date, member.effectivity_date)
      is_member_covered_expiry = Ecto.DateTime.compare(availment_date, member.expiry_date)

      batch_params =
          batch_params
          |> Map.put("availment_date", Ecto.Date.cast!(availment_date))
    end

    with :gt <- is_member_covered_effectivity,
         :lt <- is_member_covered_expiry do
      batch_authorization = BatchContext.get_batch_authorization_by_ids(authorization.id, batch.id)
      if is_nil(batch_authorization) do
        batch_authorization = []
      else
        batch_authorization
        batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
      end

      if is_nil(batch_authorization_files) do
        batch_authorization_files = []
      else
        batch_authorization_files
      end

      if Enum.empty?(batch_authorization_files) do
        create_files_checker(batch, authorization, batch_authorization, batch_params, conn)
      else
        create_files_checker(batch, authorization, batch_authorization, batch_params, conn)
      end
    else
      _ ->
        conn
          |> put_flash(:error, "Availment Date is not within the coverage period of the member.")
          |> redirect(to: batch_path(conn, :new_loa, batch.id, authorization.id))
    end
  end

  defp create_files_checker(batch, authorization, batch_authorization, batch_params, conn) do
    user_id = conn.assigns.current_user.id
    if is_nil(batch_params["files"]) do
      with {:ok, batch_authorization} <- BatchContext.insert_batch_authorization(batch_params, user_id) do
      batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
      conn
        |> put_flash(:info, "Details successfully saved.")
        |> redirect(to: batch_path(conn, :new_loa, batch.id, authorization.id))
      else
        _ ->
          conn
          |> put_flash(:error, "Error occurs upon saving!")
          |> redirect(to: batch_path(conn, :new_loa, batch.id, authorization.id))
      end
    else
      files = [] ++ for file <- batch_params["files"] do
        %{"name" => file.filename, "type" => file}
      end

      with {:ok, batch_authorization} <- BatchContext.create_batch_authorization_files(batch_params, user_id, files) do
        batch_authorization_files = BatchContext.get_batch_authorization_file_by_id(batch_authorization.id)
        conn
          |> put_flash(:info, "Successfully Added Document!")
          |> redirect(to: batch_path(conn, :new_loa, batch.id, authorization.id))
      else
        _ ->
          conn
          |> put_flash(:error, "Error occurs upon adding!")
          |> redirect(to: batch_path(conn, :new_loa, batch.id, authorization.id))
      end
    end
  end

  def delete_batch_authorization_file(conn, %{"id" => id}) do
    batch_authorization_file = BatchContext.get_a_batch_authorization_file_by_id(id)
    batch_id = batch_authorization_file.batch_authorization.batch_id
    authorization_id = batch_authorization_file.batch_authorization.authorization_id

    {:ok, _batch_authorization_file} = BatchContext.delete_file(batch_authorization_file.file.id)
    conn
    |> put_flash(:info, "Document successfully removed!")
    |> redirect(to: "/batch_processing/#{batch_id}/loa/#{authorization_id}/new")
  end

  def delete_batch_authorization(conn, %{"id" => id}) do
    batch_authorization_files = BatchContext.get_all_batch_authorization_file_by_id(id)
    batch_authorization = BatchContext.get_a_batch_authorization(id)

    for batch_authorization_file <- batch_authorization_files do
      batch_id = batch_authorization_file.batch_authorization.batch_id
      authorization_id = batch_authorization_file.batch_authorization.authorization_id
      with {:ok, _batch_authorization_file} <- BatchContext.delete_file(batch_authorization_file.file.id) do
        %{batch_id: batch_id, authorization_id: authorization_id}
      end
    end

    with {:ok, _batch_authorization} <-
        BatchContext.delete_batch_authorization(batch_authorization.authorization_id, batch_authorization.batch_id) do
      Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
      batch = BatchContext.get_all_batch()
      batch_authorizations = BatchContext.get_all_saved_batch_authorization()
      if is_nil(batch_authorizations) do
        batch_authorizations = []
      else
        batch_authorizations
      end

      authorizations = AuthorizationContext.list_approved_authorizations()
      conn
        |> put_flash(:info, "Transaction was cancelled!")
        |> render("index.html",
            batch_processing: batch,
            authorizations: authorizations,
            batch_authorizations: batch_authorizations,
            modal_open: true,
            batch_id: batch_authorization.batch_id)
    end
  end

  def return_index(conn, %{"id" => id}) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
    batch_id = id
    batch = BatchContext.get_all_batch()
    batch_authorizations = BatchContext.get_all_saved_batch_authorization()
    if is_nil(batch_authorizations) do
      batch_authorizations = []
    else
      batch_authorizations
    end

    authorizations = AuthorizationContext.list_approved_authorizations()
    conn
      |> render("index.html",
          batch_processing: batch,
          authorizations: authorizations,
          batch_authorizations: batch_authorizations,
          modal_open: true,
          batch_id: batch_id)
  end

  def return_not_available_loa(conn, %{"id" => id}) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch", "access_hbbatch", "manage_pfbatch", "access_pfbatch"]})
    batch_id = id
    batch = BatchContext.get_all_batch()
    batch_authorizations = BatchContext.get_all_saved_batch_authorization()
    if is_nil(batch_authorizations) do
      batch_authorizations = []
    else
      batch_authorizations
    end

    authorizations = AuthorizationContext.list_approved_authorizations()
    conn
      |> put_flash(:error, "Selected LOA is already used in other batch. Please choose other LOA.")
      |> render("index.html",
          batch_processing: batch,
          authorizations: authorizations,
          batch_authorizations: batch_authorizations,
          modal_open: true,
          batch_id: batch_id)
  end

  def batch_authorization_availability_checker(conn, %{"id" => batch_id, "authorization_id" => authorization_id}) do
    has_batch_authorization =
      authorization_id
      |> BatchContext.get_batch_authorization_by_authorization_id(batch_id)

    if is_nil(has_batch_authorization) do
      params = %{
        has_batch_authorization: false
      }
      json conn, Poison.encode!(params)
    else
      params = %{
        has_batch_authorization: true
      }
      json conn, Poison.encode!(params)
    end
  end

  # END OF ADD LOA AND ATTACH DOCUMENTS

  def get_affiliated_practitioner(conn, %{"id" => facility_id}) do
    practitioner_facility = BatchContext.get_affiliated_practitioner(facility_id)
    with nil <- practitioner_facility do
      json conn, Poison.encode!([])
    else
      _ ->
      json conn, Poison.encode!(practitioner_facility)
    end
  end

  def update_soa_amount(conn, %{"id" => batch_id, "batch" => batch_params}) do
    batch = BatchContext.get_batch!(batch_id)
    case BatchContext.update_batch(batch, batch_params) do
      {:ok, batch} ->
        conn
        |> put_flash(:info, "Successfully edited SOA Amount")
        |> redirect(to: batch_path(conn, :show, batch))
      {:error, changeset} ->
        render(conn, "batch_details2.html", batch: batch, changeset: changeset)
    end
  end

  def submit_batch(conn, %{"batch_id" => batch_id}) do
    case BatchContext.submit_batch(batch_id) do
      {:ok, batch} ->
        json conn, "success"
      {:error, message} ->
        json conn, "error"
    end
  end

  def get_current_user(conn, %{"user_id" => user_id}) do
    user = UserContext.get_user!(user_id)
    json(conn, Poison.encode!(user))
  end

  def delete_batch(conn, %{"batch_id" => batch_id}) do
    case BatchContext.delete_batch(batch_id) do
      {:ok, _batch} ->
        json(conn, Poison.encode!(%{success: true}))
      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(Poison.encode!(%{error: true}))
    end
  end

  def add_batch_comment(conn, %{"batch_id" => batch_id, "batch_params" => batch_params}) do
    case BatchContext.insert_single_comment(batch_id, batch_params, conn.assigns.current_user.id) do
      {:ok, batch_comment} ->
        current_user = UserContext.get_user!(conn.assigns.current_user.id)
        json(conn, Poison.encode!(%{
          inserted_at: batch_comment.inserted_at,
          comment: batch_comment.comment,
          created_by: "#{current_user.first_name} #{current_user.last_name}"}))
      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(Poison.encode!(%{error: true}))
    end
  end

  def search_batch_loa(conn, batch_params) do
    loas = BatchContext.filter_batch_loa(batch_params)

    conn
    |> render(RegistrationLinkWeb.BatchView, "loas.json", loas: loas)

  end

  # SCANNING
  def save_pf_batch(conn, params) do
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    batch_params = params["batch"]
    batch_id = batch_params["id"]
    user = Plug.current_resource(conn)
    batch_params =
      batch_params
      |> Map.put("created_by_id", user.id)
      |> Map.put("updated_by_id", user.id)
      |> Map.put("status", "Draft")

    if batch_id == "" do
      batch_params =
        batch_params
        |> Map.put("created_by_id", user.id)
        |> Map.put("updated_by_id", user.id)
        |> Map.put("status", "Draft")

      with {:ok, batch} <- BatchContext.create_pf_batch(batch_params, user.id)
      do
        json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          raise changeset
          json conn, Poison.encode!(%{valid: false})
        _ ->
          json conn, Poison.encode!(%{valid: false})
      end
    else
      batch = BatchContext.get_batch!(batch_id)
      batch_params =
        batch_params
        |> Map.put("updated_by_id", user.id)
        |> Map.put("status", "Draft")

      with {:ok, batch} <- BatchContext.update_pf_batch(batch, batch_params, user.id)
      do
        json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          raise changeset
          json conn, Poison.encode!(%{valid: false})
        _ ->
          json conn, Poison.encode!(%{valid: false})
      end
    end
  end

  def save_hb_batch(conn, params) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch"]})
    batch_params = params["batch"]
    batch_id = batch_params["id"]
    user = Plug.current_resource(conn)

    if batch_id == "" do
      batch_params =
        batch_params
        |> Map.put("status", "Draft")

      with {:ok, batch} <- BatchContext.create_hb_batch(batch_params, user.id)
      do
        json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          raise changeset
          json conn, Poison.encode!(%{valid: false})
        _ ->
          json conn, Poison.encode!(%{valid: false})
      end
    else
      batch = BatchContext.get_batch!(batch_id)
      batch_params =
        batch_params
        |> Map.put("updated_by_id", user.id)
        |> Map.put("status", "Draft")

      with {:ok, batch} <- BatchContext.update_hb_batch(batch, batch_params, user.id)
      do
        json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          raise changeset
          json conn, Poison.encode!(%{valid: false})
        _ ->
          json conn, Poison.encode!(%{valid: false})
      end
    end
  end

  def save_edit_pf_batch(conn, params) do
    Authorize.can_access?(conn, %{permissions: ["manage_pfbatch"]})
    user = Plug.current_resource(conn)
    batch_params = params["batch"]
    batch_id = batch_params["id"]
    batch = BatchContext.get_batch!(batch_id)
    batch_params =
      batch_params
      |> Map.put("updated_by_id", user.id)

    with {:ok, batch} <- BatchContext.update_pf_batch(batch, batch_params, user.id)
    do
      json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        raise changeset
        json conn, Poison.encode!(%{valid: false})
      _ ->
        json conn, Poison.encode!(%{valid: false})
    end
  end

  def save_edit_hb_batch(conn, params) do
    Authorize.can_access?(conn, %{permissions: ["manage_hbbatch"]})
    user = Plug.current_resource(conn)
    batch_params = params["batch"]
    batch_id = batch_params["id"]
    batch = BatchContext.get_batch!(batch_id)
    batch_params =
      batch_params
      |> Map.put("updated_by_id", user.id)

    with {:ok, batch} <- BatchContext.update_hb_batch(batch, batch_params, user.id)
    do
      json conn, Poison.encode!(%{valid: true, batch_id: batch.id})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        raise changeset
        json conn, Poison.encode!(%{valid: false})
      _ ->
        json conn, Poison.encode!(%{valid: false})
    end
  end

  def save_scan_doc(conn, params) do
    batch_id = params["id"]
    batch = BatchContext.get_batch!(batch_id)
    user_id = batch.created_by_id

    with {:ok, file} <- BatchContext.create_batch_files(params, user_id)
    do
      json conn
      |> put_status(200), %{message: "success"}
    else
      {:error, changeset} ->
        json conn
        |> put_status(400), %{message: "bad_request"}
      _ ->
        json conn
        |> put_status(400), %{message: "bad_request"}
    end
  end

  def delete_batch_file(conn, %{"batch_file_id" => batch_file_id}) do
    batch_file = BatchContext.get_batch_file(batch_file_id)
    batch = BatchContext.get_batch!(batch_file.batch_id)
    if batch.type == "PF" do
      type = "pf_batch"
    else
      type = "hb_batch"
    end

    with {:ok, file} <- BatchContext.delete_file(batch_file.file_id)
    do
      path = batch_file.file.type
      scope = batch_file.file
      FileUploader.delete({path, scope})

      if batch.status == "Draft" do
        conn
        |> put_flash(:info, "Document Successfully Removed!")
        |> redirect(to: "/batch_processing/#{batch_file.batch_id}")
      else
        conn
        |> put_flash(:info, "Document Successfully Removed!")
        |> redirect(to: "/batch_processing/#{batch_file.batch_id}/#{type}")
      end
    else
      {:error, changeset} ->
        conn
        |> put_flash(:info, "Error in Removing Document!")
        |> redirect(to: "/batch_processing/#{batch_file.batch_id}")
      _ ->
        conn
        |> put_flash(:info, "Error in Removing Document!")
        |> redirect(to: "/batch_processing/#{batch_file.batch_id}")
    end
  end

  def save_scan_loa(conn, %{"id" => batch_id,
    "user_id" => user_id, "loa_number" => loa_number,
    "RemoteFile" => remote_file}
  ) do
    files = %{
      "name" => remote_file.filename,
      "type" => remote_file
    }

    file = File.read!(remote_file.path)
    with {:ok, zbar} <- file |> Zbar.scan()
    do
      [f1, f2] = String.split(remote_file.filename, "_")
      case Enum.count(zbar) do
        0 ->
          if f2 == "0.jpg" do
            json conn
            |> put_status(200), %{message: "error",
              description: "Invalid LOA Document! Missing QR-Code."}
          else
            authorization =
              AuthorizationContext.get_authorization_by_loa_number(loa_number)
            batch_params = %{
              user_id: user_id,
              batch_id: batch_id,
              authorization: authorization,
              files: files
            }
            create_batch_loa_with_file(conn, batch_params)
          end
        1 ->
          zbar = List.first(zbar)
          # TODO: Assuming QRCode value is LOA number
          loa_number = zbar.data
          params = %{"id" => batch_id}
          loas = BatchContext.filter_batch_loa(params)
          if Enum.any?(loas, fn(x) -> x.number == loa_number end) do
            authorization =
              AuthorizationContext.get_authorization_by_loa_number(loa_number)
            batch_params = %{
              user_id: user_id,
              batch_id: batch_id,
              authorization: authorization,
              files: files
            }
            create_batch_loa_with_file(conn, batch_params)
          else
            json conn
            |> put_status(200), %{message: "error",
              description: "LOA is not from facility or
              is already used in other batch!"}
          end
        _ ->
          json conn
          |> put_status(400), %{message: "error",
            description: "Error in Scanning LOA Document!"}
      end
    else
      {:error, :timeout} ->
        json conn
        |> put_status(408), %{message: "error", description: "Timeout!"}
      _ ->
        json conn
        |> put_status(400), %{message: "error", description: "Bad Request!"}
    end
  end

  defp create_batch_loa_with_file(conn, batch_params) do
    user_id = batch_params.user_id
    batch_id = batch_params.batch_id
    authorization = batch_params.authorization
    files = [batch_params.files]

    if authorization.coverage.code == "OPC" do
      amount = authorization.authorization_amounts.consultation_fee
    else
      amount = authorization.authorization_amounts.total_amount
    end

    params = %{
      "batch_id" => batch_id,
      "authorization_id" => authorization.id,
      "assessed_amount" => amount,
      "status" => "Save",
      "document_type" => "LOA",
    }

    with {:ok, batch_authorization} <-
      BatchContext.create_batch_authorization_files(params, user_id, files)
    do
      json conn
      |> put_status(200), %{message: "success",
        loa_number: authorization.number}
    else
      _ ->
        json conn
        |> put_status(400), %{message: "error",
          description: "Error in Adding LOA!"}
    end
  end
  # END OF SCANNING
end

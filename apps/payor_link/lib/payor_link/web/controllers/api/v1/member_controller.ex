defmodule Innerpeace.PayorLink.Web.Api.V1.MemberController do
  @moduledoc false

  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.Base.{
    Api.MemberContext,
    FacilityContext,
    MigrationContext
  }

  alias Innerpeace.Db.Base.MemberContext, as: MC
  alias Innerpeace.Db.Schemas.{
    Member,
    Facility,
    PemeMember,
    Peme,
    # to transfer
    Authorization
  }
  alias Innerpeace.PayorLink.Web.AuthorizationView
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController, as: AuthorizationControllerAPI
  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationContextAPI
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias PayorLink.Guardian, as: PG

  def validate_details(conn, %{"params" => %{"full_name" => full_name, "birth_date" => birth_date}}) do
    case MemberContext.validate_details(%{full_name: full_name, birth_date: birth_date}) do
      {:ok, members} ->
        members =
          Enum.map(members, fn(member) ->
            MemberContext.check_last_attempt(member)
          end)
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "show_members.json", members: members)
      {:error, message} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
    end
  end

  def validate_card(conn, %{"card_number" => card_number, "birth_date" => birth_date}) do
    with member = %Member{} <- MemberContext.validate_card(card_number, birth_date),
         {:valid} <- validate_status(String.downcase("#{member.status}"))
    do
      render(conn, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      {:invalid, message} ->
        error_msg(conn, message, 404)
      _ ->
        error_msg(conn, "Member not found", 404)
    end
  end
  def validate_card(conn, _), do: error_msg(conn, "Invalid parameter", 400)

  defp validate_status(""), do: {:invalid, "Member is not active"}
  defp validate_status("active"), do: {:valid}
  defp validate_status(_), do: {:invalid, "Member is not active"}

  defp validate_attempt(nil), do: {:invalid, "Member not found"}
  defp validate_attempt(member), do: validate_attempt_2(member.attempts)

  defp validate_attempt_2(nil), do: {:valid}
  defp validate_attempt_2(attempts) when attempts > 2, do: {:invalid, "Member is Blocked. Please contact Maxicare."}
  defp validate_attempt_2(_), do: {:valid}

  def validate_evoucher(conn, params) do
    with {:ok, changeset} <- MemberContext.validate_evoucher_field(params),
         member = %Member{} <- MemberContext.validate_evoucher(params["evoucher_number"])
    do
      conn
      |> render("show_member.json", member: member)
    else
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)
      nil ->
        error_msg(conn, "eVoucher Number not found!", 404)
    end
  end

  def create(conn, params) do
    with false <- is_nil(conn.private[:guardian_default_resource])
    do
      members_count =
        params
        |> Enum.count()

      {:ok, migration} =
      PG.current_resource_api(conn).id
      |> MigrationContext.start_of_migration()

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "member_migration_job",
        "Innerpeace.Db.Worker.Job.MemberMigrationJob",
        [params, conn.private[:guardian_default_resource].id, members_count])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        render(conn, Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  def create_with_user(conn, params) do
    current_user = PG.current_resource_api(conn)

    if is_nil(current_user) do
      conn
      |> put_status(404)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login again to refresh token", code: 404)
    else

      case MemberContext.create_with_user(params, current_user) do
        {:ok, member} ->
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

        {:changeset_error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      end

    end
  end

  defp error_msg(conn, message, status) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
  end

  def get_member(conn, params) do
    with member = %Member{} <- MC.get_member_by_card_no(params["card_no"])
    do
      render(conn, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      _ ->
      error_msg(conn, "Member not found", 404)
    end
  end

  def member_cancellation(conn, params) do
    case MemberContext.validate_member_cancellation(PG.current_resource_api(conn), params) do
      {:ok, member} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "cancelled_member.json", member: member)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
    end
  end

  def member_suspension(conn, params) do
    case MemberContext.validate_member_suspension(PG.current_resource_api(conn), params) do
      {:ok, member} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "suspended_member.json", member: member)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
    end
  end

  def get_facility_by_code(facility_code) do
    with facility = %Facility{} <- FacilityContext.get_facility_by_code(facility_code)
    do
      facility
    else
      nil ->
        {:empty_facility_code}
    end
  end

  def validate_facility(conn, params) do
    with {:ok}  <- MemberContext.validate_loa_facility_fields(params),
         member = %Member{} <- MemberContext.get_member_by_card_number(params["card_number"]),
         facility = %Facility{} <- get_facility_by_code(params["facility_code"]),
         true <- Enum.empty?(MemberContext.get_all_member_facility(member.id)) == false
    do
      facility_codes = MemberContext.get_all_member_facility(member.id)

      if Enum.member?(facility_codes, params["facility_code"]) do
        render(conn, "validate_facility_code.json", message: "Member is not allowed to access this facility", code: 200)
      else
        conn
        |> put_status(400)
        |> render("validate_facility_code.json", message: "Member is not allowed to access this facility", code: 400)
      end
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)

      nil ->
        conn
        |> put_status(404)
        |> render("validate_facility_code.json", message: "Card number not found", code: 404)

      {:empty_facility_code} ->
        conn
        |> put_status(404)
        |> render("validate_facility_code.json", message: "Facility not found", code: 404)
    end
  end

  def validate_facility(conn, _params) do
    conn
    |> put_status(400)
    |> render("validate_facility_code.json", message: "Card number and Facility code are required", code: 400)
  end

  def retract_movement(conn, params) do
    if params == %{} do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid parameters")
    else
      case  MemberContext.validate_member_movement_retraction(PG.current_resource_api(conn), params) do
        {:ok, _retraction} ->
          conn
          |> put_status(200)
          |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "retract.json", message: "Successfully retract a movement", code: 200)
        {:error, changeset} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
        {:not_found} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def reactivate(conn, params) do
    date_today = Date.add(Date.utc_today, 1)
    with {:ok, member} <- MemberContext.validate_reactivate(params) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      nil ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Member not found", code: 404)

      false ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Only Suspended member can reactivate", code: 404)
      {:cancellation_gt, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is greater than cancellation date. Reactivation date should be greater than current date(#{date_today}) and less than the member's cancellation date(#{date}).", code: 404)
      {:cancellation_eq, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is equal to cancellation date. Reactivation date should be greater than current date(#{date_today}) and less than the member's cancellation date(#{date}).", code: 404)
      {:current_eq, _date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is equal to current date. Reactivation date should be greater than date today(#{date_today}).", code: 404)
      {:current_prior, _date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is prior to current date. Reactivation date should be greater than date today(#{date_today}).", code: 404)
      {:effectivity_prior, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is equal to effectivity date. Reactivation date should be greater than current date(#{date_today}) and member's effectivity date(#{date}).", code: 404)
      {:effectivity_lt, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is prior effectivity date. Reactivation date should be greater than current date(#{date_today}) and member's effectivity date(#{date}).", code: 404)
      {:expiry_gt, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is greater than expiry date. Reactivation date should be greater than current date(#{date_today}) and less than member's expiry date(#{date}).", code: 404)
      {:expiry_eq, date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Reactivation Date is equal to expiry date. Reactivation date should be greater than current date(#{date_today}) and less than member's expiry date(#{date}).", code: 404)
      {:no_expiry_date} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Member has no expiry date.", code: 404)
    end
  end

  def get_member_by_id(conn, %{"params" => %{"member_id" => member_id}}) do
    with {true, _id} <- UtilityContext.valid_uuid?(member_id),
         %Member{} = member <- Innerpeace.Db.Base.MemberContext.get_member(member_id)
    do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      {:invalid_id} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid ID", code: 404)
      {:error, _changeset} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Member not found", code: 404)
    end
  end

  def get_member_by_id(conn, params) do
    conn
    |> put_status(404)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid parameters", code: 404)
  end

  def batch_upload(conn, params) do
    with true <- Map.has_key?(params, "_json") do
      members = Enum.map(params["_json"], &(MemberContext.create_batch(&1)))
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "batch.json", members: members)
    else
      _ ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
    end
  end

  def batch_upload_with_user(conn, params) do

    current_user = PG.current_resource_api(conn)
    with true <- Map.has_key?(params, "_json"),
         false <- is_nil(current_user)
    do
      members = Enum.map(params["_json"], &(MemberContext.create_batch_with_user(&1, current_user)))
      with {:error, "Not found"} <- members do
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Error creating member batch", code: 404)
      else
        _ ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "batch.json", members: members)
      end
      conn
    else
      true ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login again to refresh token", code: 404)
      _ ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
    end
  end

  def update_mobile_no(conn, %{"id" => member_id, "mobile_no" => mobile_no}) do
    with {:updated, member} <- MemberContext.validate_mobile_no(member_id, mobile_no) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      {:empty_mobile} ->
        error_msg(conn, "Empty Mobile No", 400)
      {:empty_fields} ->
        error_msg(conn, "Fields empty", 400)
      {:invalid_id} ->
        error_msg(conn, "Invalid member_id", 400)
      nil ->
        error_msg(conn, "Member not found", 404)
      {:same} ->
        error_msg(conn, "Mobile Number must not be the same with the current mobile number.", 400)
      {:already_taken} ->
        error_msg(conn, "Mobile number is already taken.", 400)
      _ ->
        error_msg(conn, "Invalid parameters", 400)
    end
  end

  def get_all_mobile_no(conn, %{"id" => member_id}) do
    mobile_nos =  MemberContext.get_all_mobile_no(member_id)
    json conn, Poison.encode!(mobile_nos)
  end

  def get_all_mobile_no(conn, _params) do
    mobile_nos =  MemberContext.get_all_mobile_no()
    json conn, Poison.encode!(mobile_nos)
  end

  defp error_msg(conn, msg, status) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: msg, code: status)
  end

  # def create_existing_member(conn, params) do
  #   case MemberContext.create_existing_member(params) do
  #     {:ok, member} ->
  #       conn
  #       |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
  #     {:error, message} ->
  #       conn
  #       |> put_status(400)
  #       |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
  #   end
  # end

  def create_existing_member(conn, params) do
    with false <- is_nil(conn.private[:guardian_default_resource])
    do
      members_count =
        params
        |> Enum.count()

      {:ok, migration} =
      PG.current_resource_api(conn).id
      |> MigrationContext.start_of_migration()

      params =
        params
        |> Map.put("migration_id", migration.id)

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "member_existing_migration_job",
        "Innerpeace.Db.Worker.Job.MemberExistingMigrationJob",
        [params, conn.private[:guardian_default_resource].id, members_count])

      url =
        if Application.get_env(:payor_link, :env) == :prod do
          Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
        else
          Innerpeace.PayorLink.Web.Endpoint.url
        end

        render(conn, Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView, "link.json", link: "#{url}/migration/#{migration.id}/results")

    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")

    end
  end

  def get_member_status(conn, params) do
    status = MemberContext.get_member_status(params["card_number"])
    if status do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "philhealth_status.json", status: status)
    else
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid card number.")
    end
  end

  def get_remaining_limits(conn, params) do
    with %Member{} = member <- MemberContext.check_card_number(params["card_number"]) do
      haha = MemberContext.list_remaining_product_limits(member)
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "product_limits.json", member_products: haha)
    else
      nil ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid card number")
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Error")
    end
  end

  def get_member_peme_by_evoucher(conn, %{"evoucher" => evoucher, "provider_code" => provider_code}) do
    provider = FacilityContext.get_facility_by_code(provider_code)

    with peme = %Peme{} <- MemberContext.get_member_peme_by_evoucher(evoucher),
          "Eligible" <- AuthorizationControllerAPI.validate_coverage_peme(conn,
          %{
            "member_id" => peme.member.id,
            "facility_code" => provider_code,
            "coverage_name" => "PEME"
          })
    do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "member_peme.json", peme: peme)
    else
      {:invalid, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
      {:not_covered, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member is not allowed to access this facility")
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "E-voucher number is invalid")
    end
  end

  defp check_peme_member(member) do
    peme = Enum.map(member.products, fn(x) ->
      x.account_product.product.product_category
    end)

    if Enum.member?(peme, "PEME Product") do
      {:valid}
    else
      {:invalid, "Member is not eligible to avail PEME. Reason: No PEME benefit."}
    end
  end

  defp check_peme_availed(peme_member) do
    if is_nil(peme_member.approved_datetime) do
      {:valid}
    else
      date =
      peme_member.approved_datetime
      |> Ecto.DateTime.to_date()
      |> Ecto.Date.to_string()
      |> AuthorizationView.format_birthdate()
      {:invalid, "You are no longer valid to request PEME. Reason: Already availed PEME last #{date}"}
    end
  end

  defp check_peme_provider(provider, peme_member) do
    if peme_member.peme.facility_id == provider.id do
      {:valid}
    else
      {:invalid, "You are not allowed to avail PEME in this provider. Reason: E-voucher is addressed to a different facility"}
    end
  end

  defp check_peme_cancel(peme_member) do
    if String.downcase("#{peme_member.member.status}") != "cancelled" do
      {:valid}
    else
      {:invalid, "Member is not eligible to avail PEME’. Reason:E-voucher is cancelled."}
    end
  end

  defp check_peme_date(peme_member) do
    date_from =
    peme_member.peme.date_from
    |> Ecto.Date.compare(Ecto.Date.utc())

    date_to =
    peme_member.peme.date_to
    |> Ecto.Date.compare(Ecto.Date.utc())

    if date_from != :gt and date_to != :lt do
      {:valid}
    else
      {:invalid, "Member is not eligible to avail PEME. Reason:Date of Availment must be within the indicated date on the e-voucher."}
    end
  end

  def update_peme_member(conn, params) do
    member = MemberContext.get_member(params["member_id"])
    with {:ok, _member} <- MemberContext.update_peme_member(member, params) do
      conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Successfully updated")
    else
      _ ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member not updated")
    end
  end

  def replicate_member(conn, params) do
    with {:ok}  <- MemberContext.validate_loa_facility_fields(params),
         member = %Member{} <- MemberContext.get_member_by_card_num(params["card_number"]),
         facility = %Facility{} <- get_facility_by_code(params["facility_code"]),
         true <- Enum.empty?(MemberContext.get_all_member_facility(member.id)) == false
    do
      facility_codes = MemberContext.get_all_member_facility(member.id)

      if Enum.member?(facility_codes, params["facility_code"]) do
        render(conn, "replicate_member.json", member: member, code: 200)
      else
        conn
        |> put_status(400)
        |> render("validate_facility_code.json", message: "Member is not allowed to access this facility", code: 400)
      end
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)

      nil ->
        conn
        |> put_status(404)
        |> render("validate_facility_code.json", message: "Card number not found", code: 404)

      {:empty_facility_code} ->
        conn
        |> put_status(404)
        |> render("validate_facility_code.json", message: "Facility not found", code: 404)

      false ->
        conn
        |> put_status(400)
        |> render("validate_facility_code.json", message: "Member is not allowed to access this facility", code: 400)
    end
  end

  def add_product(conn, params) do
    with true <- Map.has_key?(params, "_json") do
      members = Enum.map(params["_json"], &(MemberContext.validate_insert_product(&1)))
      if Enum.empty?(Enum.filter(members, &(Map.has_key?(&1, :errors)))) do
        Enum.map(params["_json"], &(MemberContext.insert_member_products2(&1)))
      end
      conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "batch2.json", members: members)
    else
      _ ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
    end
  end

  def remove_product(conn, params) do
    with true <- Map.has_key?(params, "_json") do
      members = Enum.map(params["_json"], &(MemberContext.validate_remove_product(&1)))
      if Enum.empty?(Enum.filter(members, &(Map.has_key?(&1, :errors)))) do
        Enum.map(params["_json"], &(MemberContext.remove_member_products(&1)))
      end
      conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.MemberView, "batch_remove.json", members: members)
    else
      _ ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
    end
  end

  def csv_get_account_members_csv_download(conn, %{"am_param" => am_param}) do
    data = [["Type", "Account_Name", "First_Name", "Middle_Name", "Last_Name", "Member_Type", "Card_No.", "Status"]]

    test = MC.account_group_member_search_csv_download(am_param)
    data =
      data ++ test
    |> CSV.encode
    |> Enum.to_list
    |> to_string

    conn
    |> json(data)
  end
  def csv_get_account_members_csv_download(conn, _), do: json(conn, "[]")

  def get_member_security(conn, params) do
    with member = %Member{} <- MC.get_member_by_card_no(params["card_no"]),
         {:valid} <- validate_status(String.downcase("#{member.status}"))
         # {:valid} <- validate_attempt(MemberContext.check_last_attempt(member))
    do
      render(conn, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", member: member)
    else
      {:invalid, message} ->
        error_msg(conn, message, 404)
      _ ->
        error_msg(conn, "Member not found", 404)
    end
  end

  def batch_active_members(conn, %{"card_numbers" => card_numbers, "status" => status}) do
    # if Enum.member?([:ist, :migration, :dev], Mix.env) do
      failed = []
      passed = []
      try do
        return =
          card_numbers
          |> Enum.map(fn(card_number) ->
              [passed, failed] = passed_or_failed(card_number, status)
              %{passed: passed ++ passed, failed: failed ++ failed}
            end)
        passed = Enum.concat(Enum.map(return, &(&1.passed)))
        failed = Enum.concat(Enum.map(return, &(&1.failed)))
        render(conn, "return.json", return: %{passed: Enum.uniq(passed), failed: Enum.uniq(failed)})
      rescue
        _ ->
        render(conn, "return.json", return: "Invalid parameters")
      end
    # else
    #   render(conn, "return.json", return: "This API can only be used in DEV, IST and Migration env only.")
    # end
  end

  def batch_active_members(conn, _params) do
    render(conn, "return.json", return: "Invalid parameters")
  end

  defp passed_or_failed(card_number, status) do
    try do
      with {:ok, _member} <- MemberContext.update_status_n_date(card_number, status) do
        [[card_number], []]
      else
        _ ->
        [[], [card_number]]
      end
    rescue
      _ ->
        [[], [card_number]]
    end
  end

  def block_member(conn, %{"card_no" => card_no}) do
    with member= %Member{} <- MemberContext.get_member_by_card_no(card_no),
         {:ok, member} <- MemberContext.add_member_attempt(member)
    do
      MemberContext.check_last_attempt(member)
      if member.attempts >= 3 do
       MemberContext.block_member(member)
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "blocked")
      else
       MemberContext.add_last_attempted(member)
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
      end
    else
      _ ->
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "fail")
    end
  end

 def remove_member_attempts(conn, %{"card_no" => card_no}) do
   member = MemberContext.get_member_by_card_no(card_no)
   if is_nil(member) do
     conn
     |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Card no. does not exist.")
   else
     remove_member_attempt(conn, member)
   end
 end

 defp remove_member_attempt(conn, member) do
    with {:ok, member} <- MemberContext.remove_member_attempt(member) do
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      _ ->
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "fail")
    end
 end

  def create_batch_with_user(conn, params) do
    user = PG.current_resource_api(conn)
    with false <- is_nil(user),
        {:valid} <- validate_params(params)
    do
      members_count =
        params["members"]
        |> Enum.count()

      {:ok, migration} =
        user.id
        |> MigrationContext.start_of_migration(members_count)

      params =
        params
        |> Map.put("migration_id", migration.id)

      url = get_url(conn, Application.get_env(:payor_link, :env))

      Exq.Enqueuer.start_link

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue(
        "member_with_user_job",
        "Innerpeace.Db.Worker.Job.MemberWithUserJob",
        ["Member", url, params, members_count])

        render(conn, "links.json", url: url, migration_id: migration.id)
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      true ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please Login Again to refresh Bearer Token")
    end
  end

  defp get_url(conn, :prod), do: Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
  defp get_url(_, _), do: Innerpeace.PayorLink.Web.Endpoint.url

  defp validate_params(params) do
    dummy_data = %{}
    general_types = %{
      members: {:array, :map}
    }

    changeset =
      {dummy_data, general_types}
      |> Ecto.Changeset.cast(params, Map.keys(general_types))
      |> validate_required([
        :members
      ])

    if changeset.valid? do
      {:valid}
    else
      {:error, changeset}
    end
  end

 def member_document(conn, params) do
   case MemberContext.validate_document(params) do
     {:ok, member_document} ->
      if params["authorization"] == "true" do
        AuthorizationContextAPI.insert_facial_image(params)
      end
       conn
       |> render("member_document.json", member_document: member_document)

     {:changeset_error, changeset} ->
       conn
       |> put_status(400)
       |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

     _ ->
       conn
       |> put_status(400)
       |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Got Error")

   end
 end

end

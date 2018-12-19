defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.AuthorizationController do
    use Innerpeace.PayorLink.Web, :controller
    import Ecto.{Query, Changeset}, warn: false

    alias PayorLink.Guardian, as: PG
    alias Ecto.Changeset
    alias Ecto.DateTime
    alias Timex.Duration

    alias Innerpeace.Db.Base.Api.{
      Vendor.DiagnosisContext
    }

    alias Innerpeace.Db.Base.{
        AuthorizationContext,
        AcuScheduleContext,
        DiagnosisContext,
        MemberContext,
        FacilityContext,
        PractitionerContext,
        CoverageContext,
        ProductContext,
        BatchContext
      }

    alias Innerpeace.Db.Base.Api.UtilityContext
    alias Innerpeace.Db.Schemas.{
        Authorization,
        Facility,
        Practitioner,
        Diagnosis,
        Member,
        Coverage,
        PractitionerSpecialization
    }

    alias Innerpeace.Db.Validators.OPConsultValidator
    alias Innerpeace.PayorLink.Web.Api.V1.Vendor.AuthorizationView
    alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView
    alias Innerpeace.PayorLink.Web.Api.V1.ErrorView
    alias Innerpeace.PayorLink.Web.Api.ErrorView

    alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController, as: AuthorizationControllerAPI
    alias Innerpeace.Db.Base.Api.Vendor.AuthorizationContext, as: AuthorizationContextVendor
    alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationAPI
    @moduledoc false

    def create_authorization(conn, params) do
      if is_nil(params["coverage"]) do
        error_msg(conn, 400, "Please enter a coverage")
      else
        coverage = flatten_data(CoverageContext.get_coverage_code(params["coverage"]))

        if coverage == [] or is_nil(coverage) do
          error_msg(conn, 400, "Coverage does not exist")
        else
          case coverage.code do
            "OPC" ->
              get_opc_api_params(conn, params, coverage)
            "ACU" ->
              get_acu_api_params(conn, params, coverage)
            "PEME" ->
              get_peme_api_params(conn, params, coverage)
            "OPL" ->
              get_oplab_api_params(conn, params, coverage)
            _ ->
          end
        end
      end
    end

  defp get_oplab_api_params(conn, params, coverage) do
    user = PG.current_resource_api(conn)
    with {:ok, changeset} <- AuthorizationContextVendor.validate_oplab_params(params),
         {:ok, authorization} <- AuthorizationContextVendor.insert_oplab(changeset, user),
         {:ok, aps} <- AuthorizationContextVendor.insert_aps(authorization, changeset),
         {:ok, _apd} <- AuthorizationContextVendor.insert_oplab_apds(authorization, changeset, aps),
         {:ok, _authorization_amount} <- AuthorizationContextVendor.insert_oplab_amount(authorization)
    do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.Vendor.AuthorizationView, "authorization.json", authorization: authorization, copy: params["copy"], conn: conn)
    else
      {:changeset_error, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
      _ ->
        raise "error"
    end
  end

    # CREATE OP CONSULT AUTHORIZATION

    def get_opc_api_params(conn, params, coverage) do
        with {:valid} <-
            AuthorizationContextVendor.op_consult_validate_required(params),
            {:ok, member} <-
            AuthorizationContextVendor.validate_card_number_consult(params["card_number"]),
            {:ok, ps} <-
            AuthorizationContextVendor.validate_practitioner_specialization(
                                       params["practitioner_code"],
                                       params["practitioner_specialization"]),
            {:ok, facility} <- AuthorizationContextVendor.validate_facility(params["facility_code"]),
            {:ok, diagnosis} <- AuthorizationContextVendor.validate_diagnosis_code(params)
        do

            consult_params =
            %{
                "coverage_id" => coverage.id,
                "member_id" => member.id,
                "card_number" => params["card_number"],
                "practitioner_specialization_id" => ps.id,
                "facility_id" => facility.id,
                "diagnosis_id" => diagnosis.id,
                "datetime" => Ecto.Date.cast!(params["service_date"]),
                "chief_complaint" => params["chief_complaint"],
                "consultation_type" => params["consultation_type"],
                "copy" => params["copy"]
            }

            create_op_consult_authorization(conn, consult_params, coverage)
        else
            {:error, message} ->
                error_msg(conn, 400, message)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    def create_op_consult_authorization(conn, params, coverage) do
        params =
            params
            |> Map.put("origin", "payorlink")
        user = PG.current_resource_api(conn)

        with {:valid} <-
                AuthorizationContextVendor.validate_required_consult(params),
            {:ok, ps} <-
                AuthorizationContextVendor.check_practitioner_specialization_consult(params["practitioner_specialization_id"]),
            {:ok, practitioner} <-
                AuthorizationContextVendor.validate_practitioner_vat(ps),
            {:ok, facility} <-
                AuthorizationContextVendor.check_facility_consult(params["facility_id"]),
            {:ok, diagnosis} <-
                AuthorizationContextVendor.check_diagnosis_consult(params["diagnosis_id"]),
            {:ok, member_card} <-
                AuthorizationContextVendor.validate_card_number_consult(params["card_number"]),
            {:ok, member} <-
                AuthorizationContextVendor.validate_member_consult(params["member_id"]),
            {:valid} <-
                AuthorizationContextVendor.validate_member_card_consult(member.id, member.card_no),
            {:valid} <-
                AuthorizationContextVendor.validate_origin_consult(params["origin"]),
            {:valid} <-
                AuthorizationContextVendor.validate_consultation_type_consult(params["consultation_type"]),
            false <-
                Enum.empty?(member.products),
            {:ok_coverage} <-
                AuthorizationContext.validate_coverage(params),
            {:ok} <-
                AuthorizationContextVendor.validate_ps_consultation_fee_consult(facility.id, ps.id),
            {:ok, authorization} <-
                AuthorizationContext.create_authorization_api(user.id,
                params = params |> Map.merge(%{"coverage_id" => coverage.id})),
            {:ok, changeset} <-
                OPConsultValidator.request(params =
                params |> Map.merge(%{"authorization_id" => authorization.id, "user_id" => user.id})),
            loa = AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)
        do
            if is_nil(loa.number) do
                conn
                |> put_status(200)
                |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "vendor_op_consult.json", authorization: loa)
            else
                print_params =
                %{
                    "loa_number" => loa.number,
                    "copy" => params["copy"]
                }

                AuthorizationControllerAPI.vendor_print_pdf(conn, print_params)
            end
        else
            {:invalid_datetime_format} ->
                error_msg(conn, 400, "Invalid DateTime Format")
            {:error_coverage} ->
                error_msg(conn, 400, "There's no OP Consult Coverage in Any Product")
            true  ->
                error_msg(conn, 400, "There's no Product in Member")
            false  ->
                error_msg(conn, 400, "No Consultation Fee")
            {:error, message} ->
                error_msg(conn, 400, message)
            {:error, changeset} ->
                conn
                |> put_status(400)
                |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    # END OF OP CONSULT

    # ACU CREATE AUTHORIZATION

    def get_acu_api_params(conn, params, coverage) do
        with {:valid} <-
            AuthorizationContextVendor.acu_validate_required(params)
        do
            create_acu_authorization(conn, params, coverage)
        else
            {:error, message} ->
                error_msg(conn, 400, message)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    def create_acu_authorization(conn, params, coverage) do
        params =
            params
            |> Map.put("origin", "payorlink")
        user = PG.current_resource_api(conn)

        with {:ok, facility} <-
            AuthorizationContextVendor.validate_facility(params["facility_code"]),
            {:ok, member_card} <-
            AuthorizationContextVendor.validate_card_number_consult(params["card_number"]),
            {:ok, member} <-
            AuthorizationContextVendor.validate_member_consult(member_card.id)
        do
            validate_coverage_params = %{
                "card_no" => params["card_number"],
                "coverage_name" => "ACU",
                "coverage_code" => "ACU",
                "facility_code" => facility.code,
                "discharge_date" => params["discharge_date"],
                "admission_date" => params["service_date"]
            }

            if validate_coverage(conn, validate_coverage_params) == "Eligible" do
                AuthorizationControllerAPI.vendor_request_acu(conn,
                                                 AuthorizationControllerAPI.vendor_get_acu_details(conn, validate_coverage_params))
            else
                error_msg(conn, 400, "Not Eligible")
            end
        else
            {:error, message} ->
                error_msg(conn, 400, message)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    def validate_coverage(conn, params) do
        case AuthorizationAPI.validate_coverage_params(params) do
          {:ok} ->
            "Eligible"
          {:error, changeset} ->
            message = AuthorizationControllerAPI.coverage_validation1(changeset)
            message =
              if is_nil(message) do
                AuthorizationControllerAPI.coverage_validation2(changeset)
              else
                message
              end
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
          {:not_covered, message} ->
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member is not allowed to access this facility")
        end
     end

     # END OF ACU

     # PEME CREATE AUTHORIZATION

    def get_peme_api_params(conn, params, coverage) do
        with {:valid} <-
            AuthorizationContextVendor.peme_validate_required(params)
        do
            create_peme_authorization(conn, params, coverage)
        else
            {:error, message} ->
                error_msg(conn, 400, message)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    def create_peme_authorization(conn, params, coverage) do
        params =
            params
            |> Map.put("origin", "payorlink")
        user = PG.current_resource_api(conn)

        with {:ok, facility} <-
            AuthorizationContextVendor.validate_facility(params["facility_code"]),
            {:ok, member_card} <-
            AuthorizationContextVendor.validate_card_number_consult(params["card_number"]),
            {:ok, member} <-
            AuthorizationContextVendor.validate_member_consult(member_card.id)
        do
            validate_coverage_params = %{
                "card_no" => params["card_number"],
                "coverage_name" => "PEME",
                "coverage_code" => "PEME",
                "facility_code" => facility.code,
                "admission_date" => params["service_date"]
            }

            if validate_coverage(conn, validate_coverage_params) == "Eligible" do
                AuthorizationControllerAPI.request_peme(conn,
                                                 AuthorizationControllerAPI.vendor_get_peme_details(conn, validate_coverage_params))
            else
                error_msg(conn, 400, "Not Eligible")
            end
        else
            {:error, message} ->
                error_msg(conn, 400, message)
            _ ->
                error_msg(conn, 500, "Server Error")
        end
    end

    def validate_coverage(conn, params) do
        case AuthorizationAPI.validate_coverage_params(params) do
          {:ok} ->
            "Eligible"
          {:error, changeset} ->
            message = AuthorizationControllerAPI.coverage_validation1(changeset)
            message =
              if is_nil(message) do
                AuthorizationControllerAPI.coverage_validation2(changeset)
              else
                message
              end
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
          {:not_covered, message} ->
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member is not allowed to access this facility")
        end
     end

     # END OF PEME

    defp error_msg(conn, status, message) do
      conn
      |> put_status(status)
      |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: message, code: status)
    end

    def flatten_data(data) do
        data =
            data
            |> List.flatten()
            |> List.first()
    end
  end


defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerController do
    @moduledoc false
    use Innerpeace.PayorLink.Web, :controller
    import Ecto.{Query, Changeset}, warn: false

    alias Innerpeace.Db.Base.Api.{
      Vendor.PractitionerContext
    }
    alias Innerpeace.Db.Schemas.{
      PractitionerFacility
    }

    def get_accredited_verification(conn, params) do
        if Map.has_key?(params, "practitioner_code") do
            practitioner_code = params["practitioner_code"]
            practitioner = PractitionerContext.get_practitioner_by_code(practitioner_code)
            if not is_nil(practitioner) do
                status = case practitioner.affiliated do
                    "Yes" ->
                        "Accredited"
                    "No" ->
                        "Not Accredited"
                end

                conn
                |> put_status(200)
                |> render(
                    Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView,
                    "accredited_verification.json",
                    status: status
                )
            else
                conn
                |> put_status(400)
                |> render(
                    Innerpeace.PayorLink.Web.Api.ErrorView,
                    "error.json",
                    message: "Practitioner code does not exist."
                )
            end
        else
            conn
            |> put_status(400)
            |> render(
                Innerpeace.PayorLink.Web.Api.ErrorView,
                "error.json",
                message: "Invalid parameter. 'practitioner_code' is requried."
            )
        end
    end

    def get_affiliated_verification(conn, params) do
        p_code = if Map.has_key?(params, "practitioner_code"), do: true, else: false
        f_code = if Map.has_key?(params, "facility_code"), do: true, else: false
        check_parameter = [p_code, f_code]

        if Enum.member?(check_parameter, false) do
            conn
            |> put_status(400)
            |> render(
                Innerpeace.PayorLink.Web.Api.ErrorView,
                "error.json",
                message: "Invalid parameter. 'practitioner_code' and 'facility_code' is requried."
            )
        else
            get_affiliated_verification_level2(conn, params)
        end
    end

    def get_affiliated_verification_level2(conn, params) do
        practitioner_code = params["practitioner_code"]
        facility_code = params["facility_code"]

        practitioner = PractitionerContext.get_practitioner_by_code(practitioner_code)
        facility = PractitionerContext.get_facility_by_code(facility_code)

        with true <- not is_nil(practitioner),
             true <- not is_nil(facility)
        do
            get_affiliated_verification_level3(conn, practitioner.id, facility.id)
        else
            _ ->
                conn
                |> put_status(400)
                |> render(
                    Innerpeace.PayorLink.Web.Api.ErrorView,
                    "error.json",
                    message: "Practitioner or facility does not exist."
                )
        end
    end

    def get_affiliated_verification_level3(conn, p_id, f_id) do
        with pf = %PractitionerFacility{} <- PractitionerContext.get_practitioner_facility_by_code(p_id, f_id) do
          conn
          |> put_status(200)
          |> render(
              Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView,
              "accredited_verification.json",
              status: pf.practitioner_status.value
          )
        else
          _ ->
          conn
          |> put_status(400)
          |> render(
              Innerpeace.PayorLink.Web.Api.ErrorView,
              "error.json",
              message: "Practitioner is not affiliated with the facility."
          )
        end
    end

    def get_practitioner(conn, params) do
      practitioners = if params == %{} do
        PractitionerContext.get_practitioner()
      else
        if Map.has_key?(params, "practitioner") do
          PractitionerContext.get_practitioner(params["practitioner"])
        else
          PractitionerContext.get_practitioner()
        end
      end

      conn
      |> put_status(200)
      |> render(
        Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView,
        "practitioners.json",
        practitioners: practitioners
      )
    end
end

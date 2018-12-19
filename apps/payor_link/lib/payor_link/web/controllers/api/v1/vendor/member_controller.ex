defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberController do
  use Innerpeace.PayorLink.Web, :controller
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.Db.Base.Api.{
    Vendor.MemberContext
  }

  @moduledoc false

  def get_member_product_rnb(conn, params) do
    case MemberContext.validate_params(params) do
      {:ok, member_rnbs} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView, "show_member_rnb.json", member_rnbs: member_rnbs)

      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
    end
  end

  def get_member_utilization(conn, params) do
    with true <- Map.has_key?(params, "card_number"),
         true <- Map.has_key?(params, "coverage")
    do
      case MemberContext.get_member_utilization(
        params["card_number"],
        params["coverage"]
      ) do
        {:ok, utilizations} ->
          conn
          |> put_status(200)
          |> render(
            Innerpeace.PayorLink.Web.Api.V1.MemberView,
            "utilizations.json",
            utilizations: utilizations
          )
        _ ->
          conn
          |> put_status(400)
          |> render(
            Innerpeace.PayorLink.Web.Api.ErrorView,
            "error.json",
            message: "Either card number or coverage does not exist."
          )
      end
    else
      _ ->
        conn
        |> put_status(400)
        |> render(
          Innerpeace.PayorLink.Web.Api.ErrorView,
          "error.json",
          message: "Invalid Parameters. 'card_number' and 'coverage' is required."
        )
    end
  end

  def pre_availment(conn, params) do
    with {:ok, params} <- MemberContext.validate_pre_availment_params(params) do
      conn
      |> render(
        "pre_availment.json",
        procedure: params.procedure,
        remarks: params.remarks,
        procedure_amount: params.procedure_amount
      )
    else
      {:error, message} ->
        render_error_json(conn, message)
      {:incomplete_params, message} ->
        render_error_json(conn, "Invalid Parameters. #{message} is required.")
      _ ->
        raise 123
    end
  end

  def verification(conn, params) do
    ## /api/v1/vendor/members/verification
    case MemberContext.validate_params_verification(params) do
      {:ok, member, account_latest_version} ->
        conn
        |> render(
          Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView,
          "member_verification.json", member: member, account_latest_version: account_latest_version)

      {:ok_list, account_latest_version_list} ->
        conn
        |> render(
          Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView,
          "member_verification_list.json", account_latest_version_list: account_latest_version_list)

      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)

      {:fullname_bdate_not_matched, message} ->
        render_error_json(conn, message)

      {:both_are_not_accepted, message} ->
        render_error_json(conn, message)

      {:birthdate_is_missing, message} ->
        render_error_json(conn, message)

      {:full_name_is_missing, message} ->
        render_error_json(conn, message)
    end
  end

  def validate_member_eligibility(conn, params) do
    with {:ok, params} <- MemberContext.validate_member_eligibility(params) do
      conn
      |> render(
        "member_eligiblity.json",
        eligibility: params.message
      )
    else 
      {:error, params} ->
        conn
        |> render(
          "member_eligiblity.json",
          eligibility: params.message
        )
      {:incomplete_params, message} ->
        render_error_json(conn, "Invalid Parameters. #{message} is required.")
      _ ->
        raise 123
    end
  end

  defp render_error_json(conn, message) do
    conn
    |> put_status(400)
    |> render(
      Innerpeace.PayorLink.Web.Api.ErrorView,
      "error.json",
      message: message
    )
  end

end

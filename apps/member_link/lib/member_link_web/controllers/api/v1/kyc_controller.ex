defmodule MemberLinkWeb.Api.V1.KycController do
  use MemberLinkWeb, :controller


  alias Guardian.Plug
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.Base.Api.{
    KycContext
  }
  alias MemberLink.Guardian, as: MG

  def create_kyc_bank(conn, params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      with {:ok, kyc} <- KycContext.create_kyc_bank(user, params) do
        render(conn, "kyc.json", kyc: kyc)
    else
        {:error_number, message} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: message, code: 400)
        {:error_phones} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: "Invalid Phones", code: 400)
        {:error_emails} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: "Invalid Emails", code: 400)
        {:error_upload_params} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: "Invalid Upload Parameters", code: 400)
        {:error_base_64} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "error.json", message: "Invalid Upload Base 64", code: 400)
        {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error_api.json", changeset: changeset)
        _ ->
        conn
        |> put_status(500)
        |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end

  def get_kyc_bank(conn, _params) do
    user = MG.current_resource_api(conn)
    if user.member_id == "" || user.member_id == nil do
      conn
      |> put_status(400)
      |> render(ErrorView, "error.json", message: "Wrong User and Password", code: 400)
    else
      with {:ok, kyc} <- KycContext.get_kyc_bank_info(user.member_id) do
        render(conn, "get_kyc.json", kyc: kyc)
      else
        {:no_results_found} ->
        conn
        |> put_status(404)
        |> render(ErrorView, "error.json", message: "No KYC Bank info", code: 404)
      _ ->
        conn
        |> put_status(500)
        |> render(ErrorView, "error.json", message: "Server Error", code: 500)
      end
    end
  end
end

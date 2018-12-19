defmodule AccountLinkWeb.ApprovalController do
  use AccountLinkWeb, :controller

  # alias AccountLink.Guardian.Plug
  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    ApprovalContext,
    DropdownContext
  }

  alias Innerpeace.Db.Schemas.{
    AuthorizationAmount
  }

  # alias Innerpeace.Db.Base.Api.AccountContext, as: ApiAccount

  def show_special(conn, _params) do
    special_approval = DropdownContext.get_dropdown_by_name("Corporate Guarantee")
    specials = ApprovalContext.list_special_approval(special_approval.id)
    render(conn, "approval_special_index.html", specials: specials)
  end

  def show_special_details(conn, %{"id" => id}) do
    special = ApprovalContext.get_special_authorization(id)
    authorization_amount = ApprovalContext.get_authorization_amount(id)
    changeset = AuthorizationAmount.changeset(authorization_amount)
    render(conn, "approval_special_details.html", changeset: changeset,
           special: special, id: authorization_amount.id)
  end

  def special_action(conn, %{"id" => id, "authorization_amount" => authorization_amount}) do
    special_approval = DropdownContext.get_dropdown_by_name("Corporate Guarantee")
    case authorization_amount["action"] do
      "Approve" ->
        approve_request(conn, id, authorization_amount, special_approval.id)
      _ ->
        reject_request(conn, id, authorization_amount, special_approval.id)
    end
  end

  def approve_request(conn, id, authorization_amount, special_id) do
    case ApprovalContext.update_authorization_amount(id, authorization_amount) do
      {:ok, special} ->
        ApprovalContext.update_authorization_status(special.authorization_id)
        specials = ApprovalContext.list_special_approval(special_id)
        conn
        |> put_flash(:info, "LOA approved")
        |> render("approval_special_index.html", specials: specials)
      {:error} ->
        raise "approve error"
    end
  end

  def reject_request(conn, id, authorization_amount, special_id) do
    reason = authorization_amount["reason"]
    case ApprovalContext.update_authorization_reason(id, reason) do
      {:ok, _autho_special} ->
        specials = ApprovalContext.list_special_approval(special_id)
        conn
        |> put_flash(:info, "LOA disapproved")
        |> render("approval_special_index.html", specials: specials)
      {:error} ->
        raise "reject error"
    end
  end

  def download_special(conn, %{"special_param" => download_param}) do
    data = [["Reference No.", "Member Name",
             "Card No.", "Member Type", "Employee No.",
             "Date Requested", "Coverage", "Amount", "Status"]] ++ ApprovalContext.csv_downloads(download_param)
             |> CSV.encode
             |> Enum.to_list
             |> to_string

    conn
    |> json(data)
  end

end

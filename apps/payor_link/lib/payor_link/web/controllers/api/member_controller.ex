defmodule Innerpeace.PayorLink.Web.Api.MemberController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    Member
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    UserContext
  }

  def get_members_by_account_group(conn, %{"id" => member_id, "account_group_code" => account_group_code}) do
    members =
      if member_id == "" do
        list_members_by_account_group(account_group_code)
      else
        list_members_by_account_group(member_id, account_group_code)
      end
    json conn, Poison.encode!(members)
  end

  def get_members_by_account_group(conn, %{"account_group_code" => account_group_code}) do
    members =list_members_by_account_group(account_group_code)
    json conn, Poison.encode!(members)
  end

  def get_members_by_account_group(conn, params), do: json conn, Poison.encode!([])

  def get_member_details(_conn, %{"id" => member_id}) do
    member = get_member_product_tier1(member_id)
  end

  def member_batch_download(conn, %{"log_id" => log_id, "status" => status, "type" => type}) do
    type = String.downcase(type)
    if type == "change of product" do
      data =
        [[
          'Upload Status',
          'Member ID',
          'Change of Product Effective Date',
          'Old Plan Code',
          'New Plan Code',
          'Reason'
        ]]

      data =
        data ++ get_cop_member_batch_log(log_id, status, type)
        |> CSV.encode
        |> Enum.to_list
        |> to_string

      conn
      |> json(data)
    else
      data =
        if type == "corporate" || type == "enrollment" do
          if status == "success" do
            [[
              'Upload Status', 'Card No', 'Account Code', 'Employee No',
              'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Date Hired', 'Regularization Date', 'Address', 'City', 'Plan Code',
              'For Card Issuance', 'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          else
            [[
              'Upload Status', 'Account Code', 'Employee No', 'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Date Hired', 'Regularization Date', 'Address', 'City', 'Plan Code',
              'For Card Issuance', 'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          end
        else
          if status == "success" do
            [[
              'Upload Status', 'Card No', 'Account Code', 'Principal Number', 'Member Type',
              'Relationship', 'Effective Date', 'Expiry Date',
              'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Address', 'City', 'Plan Code', 'For Card Issuance', 'Tin No',
              'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          else
            [[
              'Upload Status', 'Account Code', 'Principal Number', 'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Address', 'City', 'Plan Code', 'For Card Issuance', 'Tin No',
              'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          end
      end

      data =
        data ++ get_member_batch_log(log_id, status, type)
        |> CSV.encode
        |> Enum.to_list
        |> to_string

      conn
      |> json(data)
    end
  end

  #ajax for skipping hierarchy
  def approve_skipping_hierarchy(conn, %{"param" => params, "user_id" => user_id}) do
    for m_id <- params["member_id"] do
      MemberContext.approve_skipping_hierarchy(m_id, user_id)
    end
    conn
    |> json([])

    #skipped_dependents = get_all_skipping_hierarchy()
    #render(conn, "skipping.json", skipped_dependents: skipped_dependents)
  end

  def disapprove_skipping_hierarchy(conn, %{"param" => params, "user_id" => user_id, "reason" => reason}) do
    for m_id <- params["member_id"] do
      _skipped = MemberContext.disapprove_skipping_hierarchy(m_id, user_id, reason)
    end
    conn
    |> json([])

    #skipped_dependents = get_all_skipping_hierarchy()
    #render(conn, "skipping.json", skipped_dependents: skipped_dependents)
  end

  def download_skipping(conn, %{"skipping_param" => download_param, "type" => type}) do
    skipping = MemberContext.get_all_skipping_based_on_param(download_param, type)
    if type == "processed" do
      head = [["Member Name", "Account Name", "Principal Name", "Skipped Dependent", "Skipped Dependent's Relationship",
               "Birth Date", "Gender", "Reason for Skipping", "Date Requested", "Requested By", "Requested From", "Date Processed", "Processed By", "Status"]]
      data = for skip <- skipping do
        ["#{skip.member.first_name <> "  " <> skip.member.last_name}", "#{skip.member.account_group.name}", "#{skip.member.principal.first_name <> "  " <> skip.member.principal.last_name}", "#{skip.first_name <> "  " <> skip.last_name}", "#{skip.relationship}", "#{skip.birthdate}", "#{skip.gender}", "#{skip.reason}", "#{DateTime.to_date(skip.inserted_at)}", "#{skip.created_by.username}", "Payorlink", "#{DateTime.to_date(skip.updated_at)}", "#{skip.updated_by.username}", "#{skip.status}"]
      end
      download_data = head ++ data
                      |> CSV.encode
                      |> Enum.to_list
                      |> to_string
      conn
      |> json(download_data)
    else
      head = [["Member Name", "Account Name", "Principal Name", "Skipped Dependent", "Skipped Dependent's Relationship", "Birth Date", "Gender", "Reason for Skipping", "Date Requested", "Requested By", "Requested From"]]
      data = for skip <- skipping do
        ["#{skip.member.first_name <> "  " <> skip.member.last_name}", "#{skip.member.account_group.name}", "#{skip.member.principal.first_name <> "  " <> skip.member.principal.last_name}", "#{skip.first_name <> "  " <> skip.last_name}", "#{skip.relationship}", "#{skip.birthdate}", "#{skip.gender}", "#{skip.reason}", "#{DateTime.to_date(skip.inserted_at)} ", "#{skip.created_by.username}", "Payorlink"]
      end
      download_data = head ++ data
                      |> CSV.encode
                      |> Enum.to_list
                      |> to_string
      conn
      |> json(download_data)

    end
  end
end

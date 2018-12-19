defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Repo

  def render("show_member_rnb.json", %{member_rnbs: member_rnbs}) do
    render_many(member_rnbs, Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView, "member_rnb.json", as: :member_rnb)
  end

  def render("member_rnb.json", %{member_rnb: member_rnb}) do
    member_rnb =
      member_rnb
      |> Repo.preload([
        :product,
        :coverage
      ])

    %{
      coverage: member_rnb.coverage.description,
      product_code: member_rnb.product.code,
      room_and_board: member_rnb.product_coverage_room_and_board.room_and_board,
      room_limit_amount: member_rnb.product_coverage_room_and_board.room_limit_amount,
      room_type: member_rnb.product_coverage_room_and_board.room_type,
      room_upgrade: member_rnb.product_coverage_room_and_board.room_upgrade,
      room_upgrade_time: member_rnb.product_coverage_room_and_board.room_upgrade_time,
    }
  end

  def render("pre_availment.json", %{procedure: procedure, remarks: remarks, procedure_amount: procedure_amount}) do
    %{
      procedure_rate: procedure_amount,
      remarks: remarks
    }
  end

  def render("member_verification.json", %{member: member, account_latest_version: account_latest_version}) do
    %{
      full_name: "#{member.first_name} #{member.middle_name} #{member.last_name}",
      card_number: member.card_no,
      status: member.status,
      gender: member.gender,
      birthdate: member.birthdate,
      account: render_one(
        account_latest_version,
        Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView,
        "account_latest_version.json", as: :account_latest_version)
    }
  end

  def render("account_latest_version.json", %{account_latest_version: account_latest_version}) do
    %{
      name: account_latest_version.account_group.name,
      code: account_latest_version.account_group.code,
      status: account_latest_version.status
    }
  end

  def render("member_verification_list.json", %{account_latest_version_list: account_latest_version_list}) do
    render_many(
      account_latest_version_list,
      Innerpeace.PayorLink.Web.Api.V1.Vendor.MemberView,
      "account_latest_version_list.json", as: :account_latest_version_list)
  end

  def render("account_latest_version_list.json", %{account_latest_version_list: account_latest_version_list}) do
    account_latest_version_list
  end

  def render("member_eligiblity.json", %{eligibility: eligibility}) do
    if String.contains? eligibility, "Eligible" do
      return = if eligibility == "Eligible" do
        "Y (Eligible)"
      else
        "N (Not Eligible)"
      end
    else
      return = eligibility
    end

    %{
      message: return
    }
    
  end
end

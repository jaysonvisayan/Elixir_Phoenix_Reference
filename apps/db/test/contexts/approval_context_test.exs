defmodule Innerpeace.Db.Base.ApprovalContextTest do
  use Innerpeace.Db.SchemaCase
  import Innerpeace.Db.Base.ApprovalContext
  alias Innerpeace.Db.Schemas.{
    Authorization,
    # AuthorizationAmount
  }

  # @invalid_attrs %{}

  test "list all special approval" do
    dropdown =
      insert(
        :dropdown,
        type: "Special Approval",
        text: "Corporate Guarantee",
        value: "CG"
      )
    authorization =
      :authorization
      |> insert(
        special_approval: dropdown
      )
      |> Repo.preload([
        :member,
        :coverage,
        :authorization_amounts
      ])
    special_approval = list_special_approval(authorization.special_approval_id)
    assert special_approval == [authorization]
  end

  test "get details a single special authorization" do
    dropdown =
      insert(
        :dropdown,
        type: "Special Approval",
        text: "Corporate Guarantee",
        value: "CG"
      )
    authorization =
      :authorization
      |> insert(
        special_approval: dropdown
      )
      |> Repo.preload([
        :member,
        :coverage,
        :authorization_amounts
      ])
    special_approval = get_special_authorization(authorization.id)
    assert special_approval == authorization
  end

  test "get_authorization_amount" do
    authorization = insert(:authorization)
    authorization_amount =
      insert(
        :authorization_amount,
        authorization: authorization
      )
    authorization_amount =
      [authorization_amount]
      |> Enum.at(0)
      |> Map.delete([:facility])
    result = get_authorization_amount(authorization.id)
    assert result == authorization_amount
  end

  test "update authorization amount" do
    authorization = insert(:authorization)
    authorization_amount =
      insert(
        :authorization_amount,
        authorization: authorization,
        member_covered: "10",
        payor_covered: "20"
      )
    {:ok, result} =
      update_authorization_amount(
        authorization_amount.id,
        %{member_covered: "12"}
      )
    assert result.member_covered == Decimal.new(12)
  end

  test "update authorization status" do
    user = insert(:user)
    authorization =
      insert(
        :authorization,
        status: "For Approval",
        step: "4",
        created_by_id: user.id,
        updated_by_id: user.id
      )
    {:ok, result} = update_authorization_status(authorization.id)
    assert result.status == "Approved"
  end

  test "update_authorization_reason" do
    authorization = insert(:authorization)
    authorization_amount =
      insert(
        :authorization_amount,
        authorization: authorization,
        member_covered: "10",
        payor_covered: "20"
      )
    {:ok, result} =
      update_authorization_reason(
        authorization_amount.id,
        "test reason"
      )
    assert result.reason == "test reason"
  end

  test "csv_params gets the model for export" do
    dropdown =
      insert(
        :dropdown,
        type: "Special Approval",
        text: "Corporate Guarantee"
      )
    authorization =
      insert(
        :authorization,
        status: "Approved",
        special_approval: dropdown
      )

      insert(
        :authorization_amount,
        authorization: authorization,
        member_covered: "10",
        payor_covered: "20"
      )

    params = %{"search_value" => "Approved"}
    result = csv_downloads(params)
    query =
      Authorization
      |> join(:inner, [a], m in assoc(a, :member))
      |> join(:inner, [a, m], aa in assoc(a, :authorization_amounts))
      |> join(:inner, [a, m, aa], c in assoc(a, :coverage))
      |> join(:inner, [a, m, aa, c], d in assoc(a, :special_approval))
      |> where([a, m, aa, c, d], d.text == ^"Corporate Guarantee")
      |> select(
        [a, m, aa, c],
        [
          m.policy_no,
          fragment(
            "CONCAT(?,?,?,?,?,?,?)",
            m.first_name,
            " ",
            m.middle_name,
            " ",
            m.last_name,
            " ",
            m.suffix
          ),
          m.card_no,
          m.type,
          m.employee_no,
          fragment(
            "to_char(?, 'YYYY-MM-DD hh:mi:ss')",
            a.inserted_at
          ),
          c.name,
          fragment(
            "case when ? is null then ? + ? else ? + ? + ? end",
            aa.company_covered,
            aa.member_covered,
            aa.payor_covered,
            aa.member_covered,
            aa.payor_covered,
            aa.company_covered
          ),
          a.status
        ]
      )
      |> Repo.all

    assert result == query
  end
end

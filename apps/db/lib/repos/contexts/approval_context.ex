defmodule Innerpeace.Db.Base.ApprovalContext do

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Authorization,
    Db.Schemas.AuthorizationAmount,
    Db.Schemas.Member,
    Db.Schemas.Coverage,
    Db.Schemas.Dropdown
  }

  def list_special_approval(id) do
    Authorization
    |> where([a], a.special_approval_id == ^id)
    |> Repo.all()
    |> Repo.preload(
      [
        :member,
        :coverage,
        :authorization_amounts,
        :special_approval,
        [
          facility: [
            :vat_status,
            :releasing_mode,
            :prescription_clause,
            :payment_mode,
            :type,
            :category
          ]
        ]
      ])
  end

  def get_special_authorization(id) do
    Authorization
    |> Repo.get!(id)
    |> Repo.preload(
      [
        :member,
        :coverage,
        :authorization_amounts,
        :special_approval,
        [
          facility: [
            :vat_status,
            :releasing_mode,
            :prescription_clause,
            :payment_mode,
            :type,
            :category
          ]
        ]
      ])
  end

  def get_authorization_amount(id) do
    AuthorizationAmount
    |> Repo.get_by(authorization_id: id)
    |> Repo.preload(
      [
        authorization:
        [
          :member,
          :coverage,
          facility:
          [
            :vat_status,
            :releasing_mode,
            :prescription_clause,
            :payment_mode,
            :type,
            :category
          ]
        ]
      ]
    )
  end

  def update_authorization_amount(id, authorization_amount) do
    AuthorizationAmount
    |> Repo.get!(id)
    |> AuthorizationAmount.changeset_update_amount(authorization_amount)
    |> Repo.update()
  end

  def update_authorization_status(id) do
    Authorization
    |> Repo.get!(id)
    |> Authorization.changeset(%{status: "Approved"})
    |> Repo.update()
  end

  def update_authorization_reason(id, reason) do
    authorization_amount =
      AuthorizationAmount
      |> Repo.get(id)

    Authorization
    |> Repo.get(authorization_amount.authorization_id)
    |> Authorization.reason_changeset(
      %{
        reason: reason,
        status: "Rejected"
      }
    )
    |> Repo.update()

  end

  def csv_downloads(params) do
    param = params["search_value"]

    case param do
      "All" ->
        query = (
          from a in Authorization,
          join: m in Member, on: a.member_id == m.id,
          join: aa in AuthorizationAmount, on: a.id == aa.authorization_id,
          join: c in Coverage, on: a.coverage_id == c.id,
          join: d in Dropdown, on: a.special_approval_id == d.id,
          where: d.text == ^"Corporate Guarantee",
          select: ([
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
          ])
        )
      _ ->
        query = (
          from a in Authorization,
          join: m in Member, on: a.member_id == m.id,
          join: aa in AuthorizationAmount, on: a.id == aa.authorization_id,
          join: c in Coverage, on: a.coverage_id == c.id,
          join: d in Dropdown, on: a.special_approval_id == d.id,
          where: ilike(a.status, ^("%#{param}%")) and d.text == ^"Corporate Guarantee",
          select: ([
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
          ])
        )

    end

    query = Repo.all(query)
  end

end

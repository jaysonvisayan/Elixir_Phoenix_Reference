defmodule Innerpeace.Db.Datatables.AuthorizationDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Authorization,
    Member,
    Coverage,
    User,
    AuthorizationAmount
  }

  def new_get_clean_auth(offset, limit, params) do
    Authorization
    |> join(:left, [a], m in Member, m.id == a.member_id)
    |> join(:left, [a, m], c in Coverage, c.id == a.coverage_id)
    |> join(:left, [a, m, c], cb in User, cb.id == a.created_by_id)
    |> join(:left, [a, m, c, cb], ub in User, ub.id == a.updated_by_id)
    |> join(:left, [a, m, c, cb, ub], aa in AuthorizationAmount, aa.authorization_id == a.id)
    |> where([a, m, c, cb, ub, aa],
      ilike(a.transaction_no, ^"%#{params}%") or
      ilike(a.number, ^"%#{params}%") or
      ilike(a.loe_number, ^"%#{params}%") or
      ilike(m.first_name, ^"%#{params}%") or
      ilike(m.middle_name, ^"%#{params}%") or
      ilike(m.last_name, ^"%#{params}%") or
      ilike(m.suffix, ^"%#{params}%") or
      ilike(m.account_code, ^"%#{params}%") or
      ilike(cb.username, ^"%#{params}%") or
      ilike(ub.username, ^"%#{params}%") or
      ilike(a.origin, ^"%#{params}%") or
      ilike(fragment("text(?)", a.version), ^"%#{params}%") or
      ilike(a.status, ^"%#{params}%"))
    |> order_by([a], desc: a.inserted_at)
    |> select([a, m, c, cb, ub, aa], %{
        id: a.id,
        step: a.step,
        transaction_no: a.transaction_no,
        number: a.number,
        loe_number: a.loe_number,
        member_first_name: m.first_name,
        member_middle_name: m.middle_name,
        member_last_name: m.last_name,
        member_suffix: m.suffix,
        member_account_code: m.account_code,
        coverage_name: c.name,
        created_by: cb.username,
        updated_by: ub.username,
        inserted_at: a.inserted_at,
        origin: a.origin,
        version: a.version,
        status: a.status
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all
    |> convert_to_tbl_cols([])
  end

  def new_get_clean_auth_count() do
    Authorization
    |> join(:left, [a], m in Member, m.id == a.member_id)
    |> join(:left, [a, m], c in Coverage, c.id == a.coverage_id)
    |> join(:left, [a, m, c], cb in User, cb.id == a.created_by_id)
    |> join(:left, [a, m, c, cb], ub in User, ub.id == a.updated_by_id)
    |> join(:left, [a, m, c, cb, ub], aa in AuthorizationAmount, aa.authorization_id == a.id)
    |> select([a, m, c, cb, ub, aa], %{
        id: a.id,
        step: a.step,
        transaction_no: a.transaction_no,
        number: a.number,
        loe_number: a.loe_number,
        member_first_name: m.first_name,
        member_middle_name: m.middle_name,
        member_last_name: m.last_name,
        member_suffix: m.suffix,
        member_account_code: m.account_code,
        coverage_name: c.name,
        created_by_id: cb.id,
        updated_by_id: ub.id,
        inserted_at: a.inserted_at,
        origin: a.origin,
        version: a.version,
        status: a.status
      })
    |> Repo.all()
    |> Enum.count()
  end

  defp convert_to_tbl_cols([head | tails], tbl) do
    redirect = generate_redirect(head, head.step)
    tbl =
      tbl ++ [[
        redirect,
        head.number,
        check_if_nil(head.loe_number),
        member_name(head),
        head.member_account_code,
        check_if_nil(head.coverage_name),
        check_if_nil(head.created_by),
        check_if_nil(head.updated_by),
        head.inserted_at,
        capitalize(head.origin),
        head.version,
        head.status,
        generate_log(head.id)
      ]]

    convert_to_tbl_cols(tails, tbl)
  end
  defp convert_to_tbl_cols([], tbl), do: tbl

  defp member_name(head), do:
    Enum.join([
      head.member_first_name,
      head.member_middle_name,
      head.member_last_name,
      head.member_suffix
    ], " ")

  defp generate_redirect(auth, step) when step == 5, do:
    "<td><a href='/authorizations/#{auth.id}'>#{auth.transaction_no}</td>"
  defp generate_redirect(auth, step), do:
    "<td><a href='/authorizations/#{auth.id}/setup?step=#{auth.step}'#{auth.transaction_no}></td>"

  defp generate_log(id), do:
    "<td>
      <span class='table-icon--holder'>
        <div class='ui icon top right floated pointing dropdown'>
          <i class='primary medium ellipsis vertical icon'></i>
          <div class='left menu transition hidden'>
            <div class='item view-authorization-logs' authID='#{id}'>
              Logs
            </div>
          </div>
        </div>
      </span>
    </td>"

  defp check_if_nil(nil), do: ""
  defp check_if_nil(value), do: value

  defp capitalize(nil), do: ""
  defp capitalize(value), do: String.capitalize("#{value}")

end

defmodule Innerpeace.Db.Datatables.AccountDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    AccountGroup,
    Account
  }

  alias Innerpeace.Db.Base.Api.UtilityContext

  def list_account_groups do
    AccountGroup
    |> join(:left, [ag], s in subquery(account_query), s.account_group_id == ag.id)
    |> join(:left, [ag, s], a in Account, a.account_group_id == ag.id
      and (fragment("concat(?,'.',?,'.',?)",
            a.major_version,
            a.minor_version,
            a.build_version)) == s.version
      )
    |> order_by([ag, s, a], ag.code)
    |> select([ag, s, a], %{
        id: ag.id, code: ag.code, name: ag.name,
        start_date: a.start_date, end_date: a.end_date, status: a.status,
        version: s.version
      })
    |> offset(0)
    |> limit(10)
    |> Repo.all()
  end

  defp account_query do
    account = (
      from a in Account,
      where: not a.status in [
        "For Renewal",
        "For Activation",
        "Renewal Cancelled"],
      group_by: a.account_group_id,
      select: %{
        account_group_id: a.account_group_id,
        version: max(fragment("concat(?,'.',?,'.',?)",
                      a.major_version,
                      a.minor_version,
                      a.build_version))
      }
    )
  end

  def get_accounts(offset, limit, params, account_id) do
    AccountGroup
    |> join(:left, [ag], s in subquery(account_query), s.account_group_id == ag.id)
    |> join(:left, [ag, s], a in Account, a.account_group_id == ag.id
      and (fragment("concat(?,'.',?,'.',?)",
            a.major_version,
            a.minor_version,
            a.build_version)) == s.version
      )
    |> where([ag, s, a],
      ilike(ag.code, ^"%#{params}%") or
      ilike(ag.name, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", a.start_date), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", a.end_date), ^"%#{params}%") or
      ilike(a.status, ^"%#{params}%"))
    |> order_by([ag, s, a], ag.code)
    |> select([ag, s, a], %{
        id: ag.id, code: ag.code, name: ag.name,
        start_date: a.start_date, end_date: a.end_date, status: a.status,
        version: s.version
      })
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_accounts_cols([])
  end

  def get_accounts_count(params, account_id) do
    AccountGroup
    |> join(:left, [ag], s in subquery(account_query), s.account_group_id == ag.id)
    |> join(:left, [ag, s], a in Account, a.account_group_id == ag.id
      and (fragment("concat(?,'.',?,'.',?)",
            a.major_version,
            a.minor_version,
            a.build_version)) == s.version
      )
    |> where([ag, s, a],
      ilike(ag.code, ^"%#{params}%") or
      ilike(ag.name, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", a.start_date), ^"%#{params}%") or
      ilike(fragment("to_char(?, 'Mon DD, YYYY')", a.end_date), ^"%#{params}%") or
      ilike(a.status, ^"%#{params}%"))
    |> select([a], count(a.id))
    |> Repo.one()
  end

  defp convert_to_tbl_accounts_cols([head | tails], tbl) do
    code = get_code(head.code, head.id)
    class =  get_class(String.downcase("#{head.status}"))
    status = get_status(head.status, class)

    tbl =
      tbl ++ [[
        code,
        head.name,
        UtilityContext.convert_date_format(head.start_date),
        UtilityContext.convert_date_format(head.end_date),
        status
      ]]

    convert_to_tbl_accounts_cols(tails, tbl)
  end

  defp convert_to_tbl_accounts_cols([], tbl), do: tbl

  defp get_code(nil, _), do: "|"
  defp get_code(_, nil), do: "|"
  defp get_code(code, id), do: "#{code}|#{id}"

  defp get_class("active"), do: "status eligible"
  defp get_class("pending"), do: "status pending"
  defp get_class("suspended"), do: "status disapproved"
  defp get_class("cancelled"), do: "status cancelled"
  defp get_class("for activation"), do: "status for-activation"
  defp get_class("for renewal"), do: "status for-renewal"
  defp get_class("draft"), do: "status draft"
  defp get_class("lapsed"), do: "status disapproved"
  defp get_class(_), do: "status disapproved"


  defp get_status(nil, class), do: "N/A|#{class}"
  defp get_status(status, class), do:
    "#{status}|#{class}"

end

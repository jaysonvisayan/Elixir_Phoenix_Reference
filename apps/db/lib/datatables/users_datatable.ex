defmodule Innerpeace.Db.Datatables.UserDatatable do
  @moduledoc false

  import Ecto.{
      Query,
      Changeset
  }, warn: false

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User,
    UserRole,
    Role
  }

  def list_users do
    User
    |> join(:left, [u], ur in UserRole, u.id == ur.user_id)
    |> join(:left, [u, ur], r in Role, ur.role_id == r.id)
    |> join(:left, [u, ur, r], ub in User, u.updated_by_id == ub.id)
    |> group_by([u, ur, r, ub], u.id)
    |> group_by([u, ur, r, ub], ub.id)
    |> order_by([u, ur, r, ub], desc: u.inserted_at)
    |> select([u, ur, r, ub], %{
      id: u.id,
      status: u.status,
      updated_at: u.updated_at,
      updated_by: ub.username,
      username: u.username,
      roles: fragment("string_agg(?, ', ')", r.name),
      email: u.email,
      first_name: u.first_name,
      last_name: u.last_name
    })
    |> offset(0)
    |> limit(10)
    |> Repo.all()
  end

  def count(params) do
    User
    |> join(:left, [u], ur in UserRole, u.id == ur.user_id)
    |> join(:left, [u, ur], r in Role, ur.role_id == r.id)
    |> join(:left, [u, ur, r], ub in User, u.updated_by_id == ub.id)
    |> where([u, ur, r, ub],
      ilike(u.username, ^"%#{params}%") or
      ilike(u.first_name, ^"%#{params}%") or
      ilike(u.last_name, ^"%#{params}%") or
      ilike(u.email, ^"%#{params}%") or
      ilike(r.name, ^"%#{params}%") or
      ilike(u.status, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", u.updated_at), ^"%#{params}%") or
      ilike(ub.username, ^"%#{params}%")
    )
    |> Repo.aggregate(:count, :id)
  end

  def get_users(offset, limit, params, account_id) do
    User
    |> join(:left, [u], ur in UserRole, u.id == ur.user_id)
    |> join(:left, [u, ur], r in Role, ur.role_id == r.id)
    |> join(:left, [u, ur, r], ub in User, u.updated_by_id == ub.id)
    |> group_by([u, ur, r, ub], u.id)
    |> group_by([u, ur, r, ub], ub.id)
    |> order_by([u, ur, r, ub], desc: u.inserted_at)
    |> select([u, ur, r, ub], %{
      id: u.id,
      status: u.status,
      updated_at: u.updated_at,
      updated_by: ub.username,
      username: u.username,
      roles: fragment("string_agg(?, ', ')", r.name),
      email: u.email,
      first_name: u.first_name,
      last_name: u.last_name
    })
    |> where([u, ur, r, ub],
      ilike(u.username, ^"%#{params}%") or
      ilike(u.first_name, ^"%#{params}%") or
      ilike(u.last_name, ^"%#{params}%") or
      ilike(u.email, ^"%#{params}%") or
      ilike(r.name, ^"%#{params}%") or
      ilike(u.status, ^"%#{params}%") or
      ilike(fragment("to_char(?, 'YYYY-MM-DD')", u.updated_at), ^"%#{params}%") or
      ilike(ub.username, ^"%#{params}%")
    )
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> convert_to_tbl_accounts_cols([])
  end

  defp convert_to_tbl_accounts_cols([head | tails], tbl) do
    class =
      if head.status == "Deactivated" do
        "red"
      else
        "green"
      end

    tbl =
      tbl ++ [[
        "#{head.username}|#{head.id}",
        "#{head.first_name} #{head.last_name}|#{head.email}",
        head.roles,
        "#{class}|#{head.status || 'Active'}",
        NaiveDateTime.to_date(head.updated_at),
        head.updated_by
      ]]

    convert_to_tbl_accounts_cols(tails, tbl)
  end
  defp convert_to_tbl_accounts_cols([], tbl), do: tbl

end

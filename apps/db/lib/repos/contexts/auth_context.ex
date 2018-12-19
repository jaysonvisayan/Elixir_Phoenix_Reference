defmodule Innerpeace.Db.Base.AuthContext do
  @moduledoc false
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  import Ecto.Query

  alias Innerpeace.Db.{
    Repo,
    Schemas.UserTerm,
    Schemas.TermsNCondition
  }
  alias Innerpeace.Db.Base.UserContext

  def authenticate(username, given_pass) do
    user = UserContext.get_username(username)
    if is_nil(user) || is_nil(user.hashed_password) do
      dummy_checkpw()
      {:error, :not_found}
    else
      cond do
        user && checkpw(given_pass, user.hashed_password) ->
          {:ok, user}
        user ->
          {:error, :unauthorized}
        true ->
          dummy_checkpw()
          {:error, :not_found}
      end
    end
  end

  def get_user_terms(nil), do: nil
  def get_user_terms(user) do
    UserTerm
    |> where([ut], ut.user_id == ^user.id)
    |> limit_by_one()
  end

  def get_latest_terms do
    limit_by_one(TermsNCondition)
  end

  defp limit_by_one(struct) do
    struct
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_terms_n_conditions(params) do
    Repo.get_by(TermsNCondition, params)
  end

  def insert_or_update_terms(params) do
    terms = get_terms_n_conditions(params)
    if is_nil(terms) do
      create_terms_n_condition(params)
    else
      update_terms_n_condition(terms, params)
    end
  end

  def create_terms_n_condition(params) do
    %TermsNCondition{}
    |> TermsNCondition.changeset(params)
    |> Repo.insert()
  end

  def update_terms_n_condition(terms, params) do
    terms
    |> TermsNCondition.changeset(params)
    |> Repo.update()
  end

  def insert_user_terms(params) do
    %UserTerm{}
    |> UserTerm.changeset(params)
    |> Repo.insert()
  end

  def load_permissions(role) do
    role =
      role
      |> Repo.preload(:permissions)
    role.permissions
  end

  def get_permissions(role) do

    if is_nil(role) do
      permissions = []
    else
      permissions = role |> load_permissions
    end

    %{
      accounts: get_permissions(permissions, "Accounts"),
      acu_schedules: get_permissions(permissions, "Acu_Schedules"),
      authorizations: get_permissions(permissions, "Authorizations"),
      benefits: get_permissions(permissions, "Benefits"),
      caserates: get_permissions(permissions, "CaseRates"),
      clusters: get_permissions(permissions, "Clusters"),
      companies: get_permissions(permissions, "Company"),
      coverages: get_permissions(permissions, "Coverages"),
      diseases: get_permissions(permissions, "Diseases"),
      exclusions: get_permissions(permissions, "Exclusions"),
      facilities: get_permissions(permissions, "Facilities"),
      location_groups: get_permissions(permissions, "Location_Groups"),
      members: get_permissions(permissions, "Members"),
      miscellaneous: get_permissions(permissions, "Miscellaneous"),
      packages: get_permissions(permissions, "Packages"),
      pharmacies: get_permissions(permissions, "Pharmacies"),
      practitioners: get_permissions(permissions, "Practitioners"),
      procedures: get_permissions(permissions, "Procedures"),
      products: get_permissions(permissions, "Products"),
      roles: get_permissions(permissions, "Roles"),
      rooms: get_permissions(permissions, "Rooms"),
      ruvs: get_permissions(permissions, "RUVs"),
      users: get_permissions(permissions, "Users")
    }
  end

  defp get_permissions(permissions, module) do
    loop_permissions(permissions, [], module)
  end

  defp loop_permissions([], acc, module), do: acc
  defp loop_permissions([head | tail], acc, module) do
    if head.module == module do
      acc = acc ++ [String.to_atom(head.keyword)]
    end
    loop_permissions(tail, acc, module)
  end

end

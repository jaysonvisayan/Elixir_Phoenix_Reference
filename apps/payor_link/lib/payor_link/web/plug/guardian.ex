defmodule PayorLink.Guardian do
  @moduledoc false

  use Guardian, otp_app: :payor_link,
    permissions: %{
      accounts: [:manage_accounts, :access_accounts],
      acu_schedules: [:manage_acu_schedules, :access_acu_schedules],
      authorizations: [:manage_authorizations, :access_authorizations],
      benefits: [:manage_benefits, :access_benefits],
      caserates: [:manage_caserates, :access_caserates],
      clusters: [:manage_clusters, :access_clusters],
      companies: [:manage_company, :access_company],
      coverages: [:manage_coverages, :access_coverages],
      diseases: [:manage_diseases, :access_diseases],
      exclusions: [:manage_exclusions, :access_exclusions],
      facilities: [:manage_facilities, :access_facilities],
      location_groups: [:manage_location_groups, :access_location_groups],
      members: [:manage_members, :access_members],
      miscellaneous: [:manage_miscellaneous, :access_miscellaneous],
      packages: [:manage_packages, :access_packages],
      pharmacies: [:manage_pharmacies, :access_pharmacies],
      practitioners: [:manage_practitioners, :access_practitioners],
      procedures: [:manage_procedures, :access_procedures],
      products: [:manage_products, :access_products],
      roles: [:manage_roles, :access_roles],
      rooms: [:manage_rooms, :access_rooms],
      ruvs: [:manage_ruvs, :access_ruvs],
      users: [:manage_users, :access_users],
    }
  use Guardian.Permissions.Bitwise

  alias Innerpeace.Db.{Repo, Schemas.User}

  def subject_for_token(sr, _claims) do
    {:ok, sr}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    {:ok, find_me_a_resource(claims["sub"])}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  def find_me_a_resource(token), do: token

  def current_resource(conn) do
      [id, random] =
        conn
        |> Guardian.Plug.current_resource()
        |> String.split("+")

      get_encrypted_user(conn.cookies["nova"], encrypt256(random), id)
    rescue
     _ ->
      nil
  end

  defp get_encrypted_user(cookies, random, id) when cookies == random, do: Repo.get(User, id)
  defp get_encrypted_user(cookies, random, id), do: nil

  defp encrypt256(value) do
    :sha256
    |> :crypto.hash(value)
    |> Base.encode16()
  end

  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
    {:ok, claims}
  end

  def current_resource_api(conn) do
    [id, random] =
      conn
      |> Guardian.Plug.current_resource()
      |> String.split("+")

    Repo.get(User, id)
  end

  # The following functions are for fetching of previous url for access rights

  def get_previous_url(conn_referer, permissions, request_path) when conn_referer != [] do
    splitted_url = conn_referer |> List.first() |> String.split("/")

    conn_referer
    |> url_web_checker(splitted_url, permissions, request_path)
  end

  def get_previous_url(conn_referer, permissions, request_path) when conn_referer == [] do
    splitted_request = request_path |> String.split("/")

    if Enum.member?(splitted_request, "web"), do: "/web", else: "/"
  end

  def url_web_checker(conn_referer, splitted_url, permissions, request_path) do
    splitted_request =
      request_path
      |> String.split("/")

    is_web = Enum.member?(splitted_request, "web")

    is_valid_request?(is_web, request_path, permissions, conn_referer, splitted_url)
  end

  defp is_valid_request?(true, request_path, permissions, conn_referer, splitted_url) do
    module =
      request_path
      |> String.split("/")
      |> Enum.at(2)

    if module == "case_rates", do: module = "caserates", else: module
    if Enum.empty?(permissions[module]) do
      "/web"
    else
      splitted_url
      |> Enum.member?("web")
      |> is_valid_link?(conn_referer)
    end
  end

  defp is_valid_request?(false, request_path, permissions, conn_referer, splitted_url) do
    module =
      request_path
      |> String.split("/")
      |> Enum.at(1)

    if module == "case_rates", do: module = "caserates", else: module
    if Enum.empty?(permissions[module]) do
      "/"
    else
      splitted_url
      |> Enum.member?("web")
      |> is_valid_link?(conn_referer)
    end
  end

  defp is_valid_link?(true, conn_referer), do:
    "/web#{conn_referer |> transforms_url("/web", 1)}"
  defp is_valid_link?(false, conn_referer) do
      get_payorlink_modules
      |> Enum.find(&(&1 == conn_referer |> get_conn_referer_val()))
      |> nil_module?(conn_referer)
  end

  defp get_conn_referer_val(conn_referer) do
    val = conn_referer |> transforms_url("/", 3)
    if val == "case_rates", do: "caserates", else: val
  end

  defp nil_module?(mod, _conn_referer) when is_nil(mod), do: "/"
  defp nil_module?(mod, conn_referer) when not is_nil(mod), do: conn_referer |> transforms_url(mod, 1)

  defp transforms_url(conn_referer, "/web", count) when count == 1, do:
    conn_referer |> List.first() |> String.split("/web") |> Enum.at(count)
  defp transforms_url(conn_referer, "/", count) when count == 3, do:
    conn_referer |> List.first() |> String.split("/") |> Enum.at(count)
  defp transforms_url(conn_referer, mod_link, count) do
    if mod_link == "caserates", do: mod_link = "case_rates", else: mod_link
    "/#{mod_link}#{conn_referer |> List.first() |> String.split("/#{mod_link}") |> Enum.at(count)}"
  end

  defp get_payorlink_modules do
    [
      "authorizations",
      "accounts",
      "plans",
      "products",
      "coverages",
      "benefits",
      "procedures",
      "diseases",
      "pharmacies",
      "clusters",
      "exclusions",
      "packages",
      "ruvs",
      "caserates",
      "acu_schedules",
      "facilities",
      "rooms",
      "practitioners",
      "location_groups",
      "miscellaneous",
      "users",
      "members",
      "roles",
      "companies"
    ]
  end
end

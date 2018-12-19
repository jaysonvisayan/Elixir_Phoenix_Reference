defmodule MemberLink.Guardian do
  @moduledoc false
  use Guardian, otp_app: :member_link

  alias Innerpeace.Db.{Repo, Schemas.User}

  def subject_for_token(resource, _claims) do
    {:ok, resource}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    # raise claims["sub"]

    {:ok, find_me_a_resource(claims["sub"])}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  def find_me_a_resource(token), do: token

  def current_resource_api(conn) do
    [id, random] =
      conn
      |> Guardian.Plug.current_resource()
      |> String.split("+")

    Repo.get(User, id)
  end

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
end

defmodule Innerpeace.Db.Hydra do
  @moduledoc "Logic for hydra SSO"

  defp host do
    Application.get_env(
      :db,
      __MODULE__
    )[:private_link]
  end

  defp public_host do
    Application.get_env(
      :db,
      __MODULE__
    )[:public_link]
  end

  defp parse_profile(user) do
    unless is_nil(user.member) do
      %{
        email: user.email,
        given_name: user.member.first_name,
        family_name: user.member.last_name,
        birthdate: user.member.birthdate,
        gender: String.downcase(user.member.gender)
      }
    end
  end

  defp parse_id_token(scopes, user) do
    loop_id_token(scopes, %{}, user)
  end

  defp loop_id_token([], acc, user), do: acc
  defp loop_id_token([head | tail], acc, user) do
    case head do
      "profile" ->
        acc = Map.put(acc, :profile, parse_profile(user))
        acc = Map.put(acc, :given_name, user.member.first_name)
        acc = Map.put(acc, :family_name, user.member.last_name)
        acc = Map.put(acc, :birthdate, user.member.birthdate)
        acc = Map.put(acc, :gender, String.downcase(user.member.gender))
      "email" ->
        acc = Map.put(acc, :email, user.email)
      "policy_number" ->
        acc = Map.put(acc, :policy_number, user.member.policy_no)
      _ ->
    end
    loop_id_token(tail, acc, user)
  end

  def accept(consent, scopes, user) do
    token = authenticate
    url = "#{host}/oauth2/consent/requests/#{consent}/accept"
    body = %{
      grantScopes: scopes,
      subject: user.id,
      idTokenExtra: parse_id_token(scopes, user)
    } |> Poison.encode!
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    patch(url, headers, options, body)
  end

  def deny(consent, scopes, user_id) do
    token = authenticate
    url = "#{host}/oauth2/consent/requests/#{consent}/deny"
    body = %{
      grantedScopes: scopes,
      subject: user_id
    } |> Poison.encode!
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    patch(url, headers, options, body)
  end

  def get_consent(consent) do
    token = authenticate
    url = "#{host}/oauth2/consent/requests/#{consent}"
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    get(url, headers, options)
  end

  def headers do
    token = authenticate
    ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
  end

  def authenticate do
    url = "#{host}/oauth2/token"
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    body = "grant_type=client_credentials&client_id=medi&client_secret=p@ssw0rd&scope=hydra.clients hydra.policies hydra.consent openid hydra.keys.create hydra.keys.delete hydra.keys.get hydra.keys.update offline"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    key = post(url, headers, options, body)
    key["access_token"]
  end

  def create_client(request) do
    token = authenticate
    url = "#{host}/clients"
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    body = %{
      client_name: request.name,
      client_uri: request.uri,
      logo_uri: request.logo_uri,
      tos_uri: request.tos_uri,
      policy_uri: request.policy_uri,
      owner: request.owner,
      grant_types: [
        "authorization_code",
        "refresh_token",
        "client_credentials",
        "implicit"
      ],
      scope: request.scopes,
      response_types: request.response_types,
      redirect_uris: request.redirect_uris
    } |> Poison.encode!
    post(url, headers, options, body)
  end

  def initialize(id, secret, redirect_url) do
    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode,
      client_id: id,
      client_secret: secret,
      site: host,
      redirect_uri: redirect_url,
      authorize_url: "#{public_host}/oauth2/auth",
      token_url: "#{host}/oauth2/token",
      scope: "auth offline id_token openid"
    ])
  end

  def get_client(client_id) do
    token = authenticate
    url = "#{host}/clients/#{client_id}"
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 5000]
    get(url, headers, options)
  end

  def get_token(client, code) do
    client
    |> OAuth2.Client.basic_auth
    |> OAuth2.Client.get_token!(code: code, scope: "offline openid id_token")
  end

  defp get(url, headers, options) do
    case HTTPoison.get(url, headers, options) do
      {:ok, res} ->
        res.body |> Poison.decode!
      {:error, reason} ->
        raise reason
    end
  end

  defp post(url, headers, attr, body) do
    case HTTPoison.post(url, body, headers, attr) do
      {:ok, res} ->
        res.body |> Poison.decode!
      {:error, reason} ->
        raise reason
    end
  end

  defp patch(url, headers, attr, body) do
    case HTTPoison.patch(url, body, headers, attr) do
      {:ok, res} ->
        {:ok}
      {:error, reason} ->
        raise reason
    end
  end
end

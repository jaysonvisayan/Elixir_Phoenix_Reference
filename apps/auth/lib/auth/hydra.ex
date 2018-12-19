defmodule Auth.Hydra do
  @moduledoc "Logic for hydra SSO"

  defp host do
    "http://localhost:9000"
  end

  def accept(consent, scopes, user_id) do
    token = authenticate
    url = "#{host}/oauth2/consent/requests/#{consent}/accept"
    body = %{
      grantedScopes: scopes,
      subject: user_id
    } |> Poison.encode!
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
    patch(url, headers, options, body)
  end

  def get_consent(consent) do
    token = authenticate
    url = "#{host}/oauth2/consent/requests/#{consent}"
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
    get(url, headers, options)
  end

  def authenticate do
    url = "#{host}/oauth2/token"
    body = "grant_type=client_credentials&client_id=medi&client_secret=p@ssw0rd&scope=hydra.clients hydra.policies hydra.consent"
    attr = [{"Content-Type", "application/x-www-form-urlencoded"}]
    key = post(url, body, attr)
    key["access_token"]
  end

  defp get(url, headers, options) do
    case HTTPoison.get(url, headers, options) do
      {:ok, res} ->
        res.body |> Poison.decode!
      {:error, reason} ->
        raise reason
    end
  end

  defp post(url, body, attr) do
    case HTTPoison.post(url, body, attr) do
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

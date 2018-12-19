defmodule Innerpeace.PayorLink.Email do
  @moduledoc false

  @behaviour Bamboo.Adapter
  @default_api_link "https://api.maxicare.com.ph/commstackapi/mail/send"

  def deliver(email, _config) do
    deliver_in_commstack(email)
  end

  def handle_config(config) do
    # Return the config if nothing special is required
    config

    # Or you could require certain config options
     if Map.get(config, :username) do
       config
     else
       raise "username and password is required in config, got #{inspect config}"
     end
  end

  def deliver_in_commstack(email) do
    url = get_api_link()
    case HTTPoison.post(
      url,
      email |> to_commstack_format() |> Poison.encode!,
      [
        "Content-Type": "application/json",
        "Authorization": "Bearer #{commstack_login()}"
      ],
      [ssl: [{:versions, [:'tlsv1.2']}]]
    ) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_commstack_format(email) do
    %{}
    |> Map.put(:AppName, "Messagecast")
    |> Map.put(:BodyFormat, "HTML")
    |> Map.put(:CopyRecipients, [])
    |> Map.put(:BlindCopyRecipients, [])
    |> Map.put(:Importance, "NORMAL")
    |> Map.put(:Sensitivity, "NORMAL")
    |> Map.put(:FileAttachments, [])
    |> Map.put(:PriorityLevel, 4)
    |> put_from(email)
    |> put_to(email)
    |> put_subject(email)
    |> put_html_body(email)
    |> put_text_body(email)
  end

  defp put_from(body, %{from: {"", address}}), do: Map.put(body, :from, address)
  defp put_from(body, %{from: {name, address}}) do
    body
    |> Map.put(:from, address)
    |> Map.put(:fromname, name)
  end

  defp put_to(body, %{to: to}) do
    {names, addresses} = Enum.unzip(to)
    body
    |> put_addresses(:Recipients, addresses)
    |> put_names(:recipientsname, names)
  end

  defp put_cc(body, %{cc: []}), do: body
  defp put_cc(body, %{cc: cc}) do
    {names, addresses} = Enum.unzip(cc)
    body
    |> put_addresses(:cc, addresses)
    |> put_names(:ccname, names)
  end

  defp put_bcc(body, %{bcc: []}), do: body
  defp put_bcc(body, %{bcc: bcc}) do
    {names, addresses} = Enum.unzip(bcc)
    body
    |> put_addresses(:bcc, addresses)
    |> put_names(:bccname, names)
  end

  defp put_subject(body, %{subject: subject}), do: Map.put(body, :subject, subject)

  defp put_html_body(body, %{html_body: nil}), do: body
  defp put_html_body(body, %{html_body: html_body}), do: Map.put(body, :body, html_body)

  defp put_text_body(body, %{text_body: nil}), do: body
  defp put_text_body(body, %{text_body: text_body}), do: Map.put(body, :text, text_body)

  defp put_addresses(body, field, addresses), do: Map.put(body, field, addresses)
  defp put_names(body, field, names) do
    if list_empty?(names) do
      body
    else
      Map.put(body, field, names)
    end
  end

  defp list_empty?([]), do: true
  defp list_empty?(list) do
    Enum.all?(list, fn(el) -> el == "" || el == nil end)
  end

  defp get_api_link do
    Application.get_env(:bamboo, :api_link) || @default_api_link
  end

  defp commstack_login do
    url = "https://api.maxicare.com.ph/commstackapi/api/login"
    body = Poison.encode!(%{
      username: :payor_link |> Application.get_env(Innerpeace.PayorLink.Mailer) |> Keyword.get(:username),
      password: :payor_link |> Application.get_env(Innerpeace.PayorLink.Mailer) |> Keyword.get(:password)
    })
    case HTTPoison.post(
      url,
      body,
      ["Content-Type": "application/json"],
      [ssl: [{:versions, [:'tlsv1.2']}]]
    ) do
      {:ok, response} ->
        Poison.decode!(response.body)["Token"]
      {:error, _reason} ->
        raise "Cannot connect to commstack API!"
    end
  end

end

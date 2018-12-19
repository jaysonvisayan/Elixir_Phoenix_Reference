defmodule Innerpeace.Db.Utilities.SMS do
  @moduledoc false

  def send(params) do
    if String.to_existing_atom(cached?) do
      {:ok, %{body: "{\"isvalid\":true,\"message\":\"message sent to next instance\",\"id\":\"328ff0e5-82fb-4f76-95b8-f3fbac21759b\"}", headers: [{"cache-control", "no-cache"}, {"pragma", "no-cache"}, {"content-type", "application/json; charset=utf-8"}, {"expires", "-1"}, {"server", "microsoft-iis/8.5"}, {"x-aspnet-version", "4.0.30319"}, {"x-powered-by", "asp.net"}, {"date", "fri, 31 mar 2017 01:28:16 gmt"}, {"content-length", "102"}, {"strict-transport-security", "max-age=31526000; includesubdomains; preload"}, {"set-cookie", "sto-id=clbhbakm; expires=mon, 29-mar-2027 09:28:00 gmt; path=/"}], status_code: 200}}
    else
      case HTTPoison.post(
        "http://api.infobip.com/api/v3/sendsms/json",
        Poison.encode!(to_infobip_format(params)),
        ["Content-Type": "application/json"],
        []
      ) do
        {:ok, response} ->
          response_body = Poison.decode!(response.body)
          response_body = Enum.at(response_body["results"], 0)
          if response_body["status"] == "0" do
            {:ok, %HTTPoison.Response{
              body: Poison.encode!(%{
                "IsValid" => true,
                "Message" => "Message sent to next instance"
              })
            }
            }
          else
            error_code = response_body["status"]
            {:ok, %HTTPoison.Response{
              body: Poison.encode!(%{
                "IsValid" => false,
                "Message" => "Infobip error code: #{error_code}"
              })
            }
            }
          end
        {:error, reason} ->
        {:ok, %HTTPoison.Response{
          body: Poison.encode!(%{
            "IsValid" => false,
            "Message" => "error connecting to commstack & infobip"
          })
        }
        }
      end
    end
  end

  defp to_infobip_format(params) do
    credentials = get_infobip_credentials()
    %{
      authentication: %{
        username: credentials.username,
        password: credentials.password
      },
      messages: %{
        sender: "Maxicare",
        text: params.text,
        type: "longSMS",
        recipients: [%{gsm: params.to}]
      }
    }
  end

  defp cached? do
    :db |> Application.get_env(Innerpeace.Db.Utilities.SMS) |> Keyword.get(:sms_cached)
  end

  defp get_proxy do
    :db |> Application.get_env(Innerpeace.Db.Utilities.SMS) |> Keyword.get(:proxy) || {}
  end

  defp get_infobip_credentials do
    username = :db |> Application.get_env(Innerpeace.Db.Utilities.SMS) |> Keyword.get(:infobip_username)
    password = :db |> Application.get_env(Innerpeace.Db.Utilities.SMS) |> Keyword.get(:infobip_password)
    %{username: username, password: password}
  end
end

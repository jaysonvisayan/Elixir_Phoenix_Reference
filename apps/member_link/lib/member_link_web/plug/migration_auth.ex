defmodule MemberLinkWeb.Plug.MigrationAuth do
    @moduledoc """
      A plug for checking a static token for the use 
      of member's change of password API endpoint.
    """
    import Plug.Conn

    def init(default), do: default

    def call(conn, default) do
      valid_token =
        :member_link
        |> Application.get_env(MemberLink.Guardian)
        |> Keyword.get(:mg_key)

      token =
        conn
        |> get_req_header("authorization")
        |> List.first()

      with {:granted} <- get_auth(token),
           {:valid_token} <- validate_token(token, valid_token)
      do
        conn
      else
        {:error} ->
          auth_return(conn, 404, "Authorization Token is required", "false")
        {:invalid_token} ->
          auth_return(conn, 404, "Unauthorized", "false")
      end
    end

    defp auth_return(conn, status, remarks, is_success) do
     return_json = %{
       remarks: remarks,
       is_success: is_success
     }

     conn
     |> put_resp_content_type("application/json")
     |> send_resp(
       status,
       Poison.encode!(return_json)
     )
    end

    defp get_auth(token) when is_nil(token), do: {:error}
    defp get_auth(token) when not is_nil(token), do: {:granted}

    defp validate_token(token, valid_token) when token == valid_token, do: {:valid_token}
    defp validate_token(token, valid_token) when token != valid_token, do: {:invalid_token}

  end

defmodule AuthWeb.SessionController do
  use AuthWeb, :controller

  alias Innerpeace.Db.{
    Repo,
    Base.AuthContext,
    Hydra
  }

  alias Auth.Guardian.Plug

  def index(conn, %{"consent" => consent}) do
    mg_url =
      :auth
      |> Application.get_env(AuthWeb.Endpoint)
      |> Keyword.get(:mg_url)

    conn
    |> render("index.html", consent: consent, mg_url: mg_url)
  end

  defp same?(nil), do: false
  defp same?(terms_n_condition_id) do
    terms_n_condition_id == AuthContext.get_latest_terms().id
  end

  def index(conn, _) do
    render conn, "status.json"
  end

  defp parse_scopes(scopes) do
    scopes
    |> Enum.map(fn(scope) ->
      case scope do
        "profile" ->
          %{
            name: "Profile",
            description: [
              "Name",
              "Birthdate",
              "Gender",
              "Mobile Number",
              "E-mail Address"
            ]
          }
        "email" ->
          %{
            name: "Email",
            description: ["Allow client app to access your email"]
          }
        "policy_number" ->
          %{
            name: "Policy Number",
            description: ["Allow client app to access your policy number"]
          }
        _ ->
      end
    end)
    |> Enum.filter(& !is_nil(&1))
  end

  def logout(conn, %{"consent" => consent}) do
    conn
    |> Plug.sign_out
    |> redirect(to: session_path(conn, :index, consent: consent))
  end

  def unauthenticated(conn, consent) do
    mg_url =
      :auth
      |> Application.get_env(AuthWeb.Endpoint)
      |> Keyword.get(:mg_url)

    conn
    |> put_flash(:error, "You need to authenticate your account.")
    |> render("index.html", consent: consent, mg_url: mg_url)
  end

  def authorize(conn, %{"consent" => consent}) do
    user =
      conn
      |> Plug.current_resource()

    if is_nil(user) do
      conn
      |> unauthenticated(consent)
    else
      res =
        consent
        |> Hydra.get_consent()

      case res do
        %{"error" => error} ->
          conn
          |> render(AuthWeb.ErrorView, "404.html")
        res ->
          scopes = res["requestedScopes"]

          client = Hydra.get_client(res["clientId"])
          client = client |> parse_client(scopes)

          conn
          |> render("authorize.html", client: client, consent: consent, scopes: scopes)
      end
    end
  end

  defp forced_accept(conn, consent) do
    user =
      conn
      |> Plug.current_resource()
      |> Repo.preload(:member)

    if is_nil(user) do
      conn
      |> unauthenticated(consent)
    else
      res =
        consent
        |> Hydra.get_consent()

      case res do
        %{"error" => error} ->
          conn
          |> render(AuthWeb.ErrorView, "404.html")
        res ->
          scopes = res["requestedScopes"]

          with {:ok} <- Hydra.accept(consent, scopes, user),
               res <- Hydra.get_consent(consent)
          do
            conn
            |> redirect(external: res["redirectUrl"])
          end
      end
    end
  end

  defp parse_client(client, scopes) do
    %{
      name: client["client_name"],
      logo_uri: client["logo_uri"],
      policy_uri: client["policy_uri"],
      tos_uri: client["tos_uri"],
      scopes: parse_scopes(scopes)
    }
  end

  def accept(conn, %{
    "consent" => consent,
    "scopes" => scopes
  }) do

    user =
      conn
      |> Plug.current_resource()
      |> Repo.preload(:member)

    if is_nil(user) do
      conn
      |> unauthenticated(consent)
    else
      with {:ok} <- Hydra.accept(consent, scopes, user),
           res <- Hydra.get_consent(consent)
      do
        terms = AuthContext.get_latest_terms()
        AuthContext.insert_user_terms(%{
          user_id: user.id,
          terms_n_condition_id: terms.id
        })

        conn
        |> redirect(external: res["redirectUrl"])
      end
    end
  end

  def deny(conn, %{
    "consent" => consent,
    "scopes" => scopes
  }) do
    user = Plug.current_resource(conn)
    if is_nil(user) do
      conn
      |> unauthenticated(consent)
    else
      with {:ok} <- Hydra.deny(consent, scopes, user.id),
           res <- Hydra.get_consent(consent)
      do
        conn
        |> Plug.sign_out
        |> redirect(to: session_path(conn, :index, consent: consent))
      end
    end
  end

  def login(conn, %{"session" => user_params}) do
    username = user_params["username"]
    password = user_params["password"]
    consent = user_params["consent"]

    case AuthContext.authenticate(username, password) do
      {:ok, user} ->
        mg_url =
          :auth
          |> Application.get_env(AuthWeb.Endpoint)
          |> Keyword.get(:mg_url)

        terms =
          user
          |> AuthContext.get_user_terms()

        cond do
          is_nil(user) ->
            render conn, "index.html", consent: consent, mg_url: mg_url
          is_nil(terms) ->
            conn
            |> Plug.sign_in(user)
            |> redirect(to: session_path(conn, :authorize, consent: consent))
          same?(terms.terms_n_condition_id) ->
            conn
            |> Plug.sign_in(user)
            |> forced_accept(consent)
          true ->
            conn
            |> Plug.sign_in(user)
            |> redirect(to: session_path(conn, :authorize, consent: consent))
        end
      _ ->
        mg_url =
          :auth
          |> Application.get_env(AuthWeb.Endpoint)
          |> Keyword.get(:mg_url)

        conn
        |> put_flash(:error, "Error in user login. Please try again.")
        |> render("index.html", consent: consent, mg_url: mg_url)
    end
  end
end

defmodule Auth.SlidingSessionTimeout do
  @moduledoc """
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts \\ []) do
    Keyword.merge([timeout_after_seconds: 600], opts)
  end

  def call(conn, opts) do
    timeout_at = get_session(conn, :session_timeout_at)
    if timeout_at && now() > timeout_at do
      logout_user(conn)
    else
      put_session(conn, :session_timeout_at, new_session_timeout_at(opts[:timeout_after_seconds]))
    end
  end

  defp logout_user(conn) do
    conn
    |> clear_session()
    |> configure_session([:renew])
    |> assign(:session_timeout, true)
    |> put_flash(:info, "You have been logout due to inactivity.")
    |> redirect(to: "/sign_in")
  end

  defp now do
    DateTime.utc_now() |> DateTime.to_unix
  end

  defp new_session_timeout_at(timeout_after_seconds) do
    now() + timeout_after_seconds
  end
end

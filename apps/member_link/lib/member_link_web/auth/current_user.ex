defmodule MemberLinkWeb.Auth.CurrentUser do
  @moduledoc false

  import Plug.Conn
  import MemberLink.Guardian.Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = current_resource(conn)
    assign(conn, :current_user, current_user)
  end
end

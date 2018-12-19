defmodule AccountLinkWeb.Auth.CurrentUser do
  @moduledoc false

  import Plug.Conn
  import AccountLink.Guardian.Plug
  alias AccountLink.Guardian, as: AG
  alias Innerpeace.Db.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = AG.current_resource(conn)
    current_user = Repo.preload(current_user, :user_account)
    assign(conn, :current_user, current_user)
  end
end

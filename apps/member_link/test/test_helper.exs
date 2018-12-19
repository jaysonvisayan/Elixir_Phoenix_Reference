defmodule Innerpeace.MemberLink.TestHelper do
  # @permission Application.get_env(:member_link, :permission)
  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  def conn_with_fetched_session(the_conn) do
    the_conn.secret_key_base
    |> put_in(@secret)
    |> Plug.Session.call(@signing_opts)
    |> Plug.Conn.fetch_session
  end

  def sign_in(conn, resource) do
    conn
    |> conn_with_fetched_session
    |> Guardian.Plug.sign_in(resource)
    |> plug_session()
  end

  def plug_session(conn) do
    keyword = Innerpeace.Permission.Mock.get_permission(conn)
    permissions = Map.merge(conn.private.plug_session, %{"permissions" => List.wrap(keyword)})
    private = conn.private |> Map.delete(:plug_session) |> Map.merge(%{plug_session: permissions})
    conn
    |> Map.delete(:private)
    |> Map.put_new(:private, private)
  end
end

{:ok, _} = Application.ensure_all_started(:ex_machina)

Application.ensure_all_started(:hound)
ExUnit.configure exclude: [integration: true]
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Innerpeace.Db.Repo, :manual)


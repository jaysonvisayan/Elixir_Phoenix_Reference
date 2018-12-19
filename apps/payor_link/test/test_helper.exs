defmodule Innerpeace.PayorLink.TestHelper do
  # @permission Application.get_env(:payor_link, :permission)
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
    random = Ecto.UUID.generate
    secure_random = "#{resource.id}+#{random}"
    conn
    |> conn_with_fetched_session
    |> add_random_cookie(random)
    |> PayorLink.Guardian.Plug.sign_in(secure_random)
    |> plug_session()
  end

  defp add_random_cookie(conn, random) do
    random
    |> encrypt256
    |> store_cookie(conn)
  end

  defp encrypt256(value) do
    :sha256
    |> :crypto.hash(value)
    |> Base.encode16()
  end

  defp store_cookie(value, conn) do
    conn
    |> Plug.Conn.put_resp_cookie("nova", value, [
        secure: false,
        http_only: true,
        domain: conn.host
      ])
  end

  def plug_session(conn) do
    keyword = Innerpeace.Permission.Mock.get_permission(conn)
    permissions = Map.merge(conn.private.plug_session, %{"permissions" => List.wrap(keyword)})
    private = conn.private |> Map.delete(:plug_session) |> Map.merge(%{plug_session: permissions})
    _conn =
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

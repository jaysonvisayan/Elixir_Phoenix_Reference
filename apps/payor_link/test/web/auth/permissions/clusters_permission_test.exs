defmodule Innerpeace.PayorLink.Web.Permission.ClusterTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Cluster Permission /clusters" do
    test "with manage_clusters should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_clusters",
        module: "Clusters"
      })

      conn = get authenticated(conn, u), cluster_path(conn, :index)
      assert html_response(conn, 200) =~ "Cluster"
    end

    test "with access_clusters should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_clusters",
        module: "Clusters"
      })

      conn = get authenticated(conn, u), cluster_path(conn, :index)
      assert html_response(conn, 200) =~ "Cluster"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), cluster_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end

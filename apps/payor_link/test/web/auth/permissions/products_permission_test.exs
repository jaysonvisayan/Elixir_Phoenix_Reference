defmodule Innerpeace.PayorLink.Web.Permission.ProductTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Product Permission /products" do
    test "with manage_products should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_products",
        module: "Products"
      })

      conn = get authenticated(conn, u), product_path(conn, :index)
      assert html_response(conn, 200) =~ "Plans"
    end

    test "with access_products should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_products",
        module: "Products"
      })

      conn = get authenticated(conn, u), product_path(conn, :index)
      assert html_response(conn, 200) =~ "Plans"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), product_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end

#defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.ProductControllerTest do
#  use Innerpeace.PayorLink.Web.ConnCase

#  alias Innerpeace.Db.Base.Api.ProductContext
#  alias PayorLink.Guardian.Plug

#  setup do
#    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
#    random = Ecto.UUID.generate
#    secure_random = "#{user.id}+#{random}"
#    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
#    jwt = Plug.current_token(conn)
#  end

#  describe "Create Dental Plan /products/dental" do
#    test "create_dental/1 creates dental plan API" do
#      #TODO: create test data here
#    end
#  end
#end

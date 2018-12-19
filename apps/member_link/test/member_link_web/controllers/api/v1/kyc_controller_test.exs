defmodule MemberLinkWeb.Api.V1.KycControllerTest do
  use MemberLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase

  # alias MemberLink.Guardian.Plug
  # alias Innerpeace.Db.Schemas.User
#
#  setup do
#    params =
#      %{
#        "personal" =>
#        %{
#          "country" => "sample_country",
#          "city" => "sample_city",
#          "citizenship" => "sample_data",
#          "civil_status" => "sample_data",
#          "mother_maiden" => "sample_data",
#          "tin" => "sample_data",
#          "sss_number" => "sample_data",
#          "unified_id_number" => "sample_data"
#        },
#        "professional" =>
#        %{
#          "educational_attainment" => "sample_data",
#          "company" => %{
#            "name" => "sample_data",
#            "branch" => "sample_data",
#            "position_title" => "sample_data",
#            "occupation" => "sample_data",
#            "nature_of_work" => "sample_data",
#            "source_of_fund" => "sample_data"
#          }
#        },
#        "contact" =>
#        %{
#          "phones" => [
#            "0" => %{
#              "number" => "12314",
#              "type" => "sample_type"
#            }
#          ],
#          "emails" => [
#            "0" => %{
#              "email" => "sample_email@medilink.com"
#            }
#          ],
#          "street" => "string",
#          "district" => "string",
#          "country" => "string",
#          "city" => "string",
#          "postal_code" => "string"
#        },
#        "uploads" => [
#        "0" => %{
#          "link" => "medilink.com.ph",
#          "type" => "sample_type"
#        }
#        ]
#      }
#
#    member = insert(:member)
#    {:ok, user} = Repo.insert(%User{username: "masteradmin", password: "P@ssw0rd",
#      member_id: member.id})
#    conn = Plug.sign_in(build_conn(), user)
#    jwt = Plug.current_token(conn)
#
#    {:ok, %{
#      member: member,
#      jwt: jwt,
#      conn: conn,
#      user: user,
#      params: params
#    }}
#  end
#
#  test "create_kyc_bank creates kyc bank when params are valid", %{conn: conn, jwt: jwt, params: params,member: member,user: user} do
#    conn =
#      conn
#      |> put_req_header("authorization", "Bearer #{jwt}")
#      |> post(kyc_path(conn, :create_kyc_bank, params))
#      assert json_response(conn, 200)
#      assert json_response(conn, 200)["message"] == "Successfully Submitted Info"
#  end
#
end

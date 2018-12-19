defmodule Innerpeace.Db.Base.Api.KycBankContextTest do
  use Innerpeace.Db.SchemaCase
  # alias Innerpeace.Db.Schemas.{
  #   Kycbank
  # }
  alias Innerpeace.Db.Base.Api.KycContext
  # alias Innerpeace.Db.Repo

  setup do
    params =
      %{
        "personal" =>
        %{
          "country" => "sample_country",
          "city" => "sample_city",
          "citizenship" => "sample_data",
          "civil_status" => "sample_data",
          "mother_maiden" => "sample_data",
          "tin" => "123456789012",
          "sss_number" => "123456789012",
          "unified_id_number" => "123456789012",
          "identification_card" => "License 1",
          "mother_first_name" => "SampleA",
          "mother_middle_name" => "SampleB",
          "mother_last_name" => "SampleC"
        },
        "professional" =>
        %{
          "educational_attainment" => "sample_data",
          "company" => %{
            "name" => "sample_data",
            "branch" => "sample_data",
            "position_title" => "sample_data",
            "occupation" => "sample_data",
            "nature_of_work" => "sample_data",
            "source_of_fund" => "sample_data"
          }
        },
        "contact" =>
        %{
          "phones" => [
            %{
              "number" => "12123444314",
              "type" => "sample_type"
            }
          ],
          "emails" => [
            %{
              "email" => "sample_email@medilink.com"
            }
          ],
          "street" => "string",
          "district" => "string",
          "country" => "string",
          "city" => "string",
          "postal_code" => "string"
        },
        "uploads" => [
        %{
          "base_64_encoded" => "TWVtYmVyIE5hbWUsTWVtYmVyIElELEVtcGxveWVlIE5vLENhcmQgTm8sU3VzcGVuc2lvbiBEYXRlLFJlYXNvbgpNZW1iZXJsaW5rQWRtaW5pc3RyYXRvciBNZW1iZXIgbGluayxlZmJiNmExNS1kMzMxLTQ3YWQtYTgyZC04Yzc4YmRiNTI0NjUsMTIzMTIzMTIzLDExNjgwMTEwMzQyODAwOTIsMTEvMjIvMjAxNyxSZWFzb24gMQo=",
          "type" => "file",
          "extension" => "csv",
          "link" => "batch+maintenance+upload",
          "name" => "front-side"
        }
        ]
      }
    {:ok, %{params: params}}
  end

  # test "create_kyc_bank creates kyc bank when params are valid", %{params: params} do
  #   member = insert(:member)
  #   user = insert(:user, member_id: member.id)
  #   assert {:ok, "kyc_bank"} == KycContext.create_kyc_bank(user,params)
  # end

   test "create_kyc_bank returns error phones when phones are invalid", %{params: params} do
     member = insert(:member)
     user = insert(:user, member_id: member.id)
     contact = %{
           "phones" => [
             %{
               "type" => "sample_type"
             }
           ],
           "emails" => [
             %{
               "email" => "sample_email@medilink.com"
             }
           ],
           "street" => "string",
           "district" => "string",
           "country" => "string",
           "city" => "string",
           "postal_code" => "string"
         }
     params = Map.delete(params, "contact")
     params = Map.put_new(params, "contact", contact)
     assert {:error_phones} == KycContext.create_kyc_bank(user, params)
   end

   test "create_kyc_bank returns error emails when emails are invalid", %{params: params} do
     member = insert(:member)
     user = insert(:user, member_id: member.id)
     email = %{
           "phones" => [
             %{
               "number" => "12311233314",
               "type" => "sample_type"
             }
           ],
           "emails" => [
             %{
               "email" => "sample_emailmedilinkcom"
             }
           ]
         }
     params = Map.delete(params, "contact")
     params = Map.put_new(params, "contact", email)
     assert {:error_emails} == KycContext.create_kyc_bank(user, params)
   end

   test "create_kyc_bank returns error uploads when uploads are invalid", %{params: params} do
     member = insert(:member)
     user = insert(:user, member_id: member.id)
     upload =
       [
         %{
           "type" => "sample_type"
         }
         ]
     params = Map.delete(params, "uploads")
     params = Map.put_new(params, "uploads", upload)
     assert {:error_upload_params} == KycContext.create_kyc_bank(user, params)
   end

   test "create_kyc_bank returns error changeset when params are invalid", %{params: params} do
     member = insert(:member)
     user = insert(:user, member_id: member.id)
     params = Map.delete(params, "personal")
     assert {:error, _changeset} = KycContext.create_kyc_bank(user, params)
   end

   test "insert_kyc_bank inserts kyc bank when params are valid", %{params: params} do
     member = insert(:member)
     insert(:user, member_id: member.id)
     assert {:ok, _kyc_bank} = KycContext.insert_or_update_kyc_bank(member.id, params)
   end

   test "create_phones creates phone when phones are valid", %{params: params} do
     member = insert(:member)
     insert(:user, member_id: member.id)
     kyc_bank = insert(:kyc_bank)
     assert {:ok, "phones"} == KycContext.create_or_update_phones(kyc_bank.id, params)
   end

   test "create_emails creates emails when emails are valid", %{params: params} do
     member = insert(:member)
     insert(:user, member_id: member.id)
     kyc_bank = insert(:kyc_bank)
     assert {:ok, "emails"} == KycContext.create_or_update_emails(kyc_bank.id, params)
   end

   test "create_address creates address when address are valid", %{params: params} do
     member = insert(:member)
     insert(:user, member_id: member.id)
     kyc_bank = insert(:kyc_bank)
     assert {:ok, _address} = KycContext.create_or_update_address(kyc_bank.id, params)
   end

   test "create_uploads creates uploads when uploads are valid", %{params: params} do
     member = insert(:member)
     insert(:user, member_id: member.id)
     insert(:kyc_bank)
     assert {:ok, "uploads"} = KycContext.validate_uploads(params["uploads"])
   end

end

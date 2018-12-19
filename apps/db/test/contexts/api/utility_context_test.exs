defmodule Innerpeace.Db.Base.Api.UtilityContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.Api.{
    UtilityContext
  }

  test "transform_birth_date/1 transforms valid date string to MM/DD/YYYY format" do
    datetime_string = "01/30/2017"
    assert true = UtilityContext.transform_birth_date(datetime_string)
  end

  test "transform_birth_date/1 does not transform invalid date" do
    datetime_string = "09/30/02017"
    datetime_string2 = "13/30/2017"
    assert {:invalid_date_format} == UtilityContext.transform_birth_date(datetime_string)
    assert {:invalid_date_format} == UtilityContext.transform_birth_date(datetime_string2)
  end

  test "payorlink_one_sign_in with not existing api address" do
    result = UtilityContext.payorlink_one_sign_in(:https)

    assert {:api_address_not_exists} == result
  end

  #TODO
#   test "payorlink_one_sign_in with existing api address" do
#     insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
#     {status, _} = UtilityContext.payorlink_one_sign_in

#     assert status == :ok
#   end

  test "get_payorlink_one_bearer with invalid api address" do
    api_address = insert(:api_address, name: "PAYORLINK 1.0", address: "api.maxicare.com.ph")
    {status, _} =
      api_address
      |> UtilityContext.get_payorlink_one_bearer(:http)

    assert status == :unable_to_login
  end

  #TODO
#   test "get_payorlink_one_bearer with valid api address" do
#     api_address = insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph/")
#     {status, _} = UtilityContext.get_payorlink_one_bearer(api_address)

#     assert status == :ok
#   end

  test "generate random string" do
    random = UtilityContext.randomizer(100)
    assert 100 = String.length(random)
    assert String.match?(random, ~r/[A-Za-z0-9]/)
  end

  test "generate random numbers" do
    random = UtilityContext.randomizer(100, :numeric)
    assert 100 = String.length(random)
    refute String.match?(random, ~r/[A-Za-z]/)
  end

  test "generate random upper case" do
    random = UtilityContext.randomizer(100, :upcase)
    assert 100 = String.length(random)
    refute String.match?(random, ~r/[a-z0-9]/)
  end

  test "generate random lower case" do
    random = UtilityContext.randomizer(100, :downcase)
    assert 100 = String.length(random)
    refute String.match?(random, ~r/[A-Z0-9]/)
  end

  test "generate random alphabets only" do
    random = UtilityContext.randomizer(100, :alpha)
    assert 100 = String.length(random)
    refute String.match?(random, ~r/[0-9]/)
  end

  describe "Get SAP CSRF token" do

    test "authenticate" do
      # UtilityContext.authenticate()
    end

    test "update_account" do
      # UtilityContext.update_account
    end

    # test "with valid api address and valid credentials" do
    #   api_address = insert(:api_address, name: "SAPCSRF",
    #                        address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #                        username: "JQUINGCO", password: "appcentric1")

    #   result = UtilityContext.get_SAP_api_address("SAPCSRF")

    #   assert {:ok, csrf_token} = result
    # end

    # test "with valid api address and invalid credentials" do
    #   api_address = insert(:api_address, name: "SAPCSRF",
    #                        address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #                        username: "JQUINGCO", password: "appcentric2")

    #   result = UtilityContext.get_SAP_api_address("SAPCSRF")

    #   assert result == {:unable_to_login}
    # end

    # test "with invalid api address" do
    #   insert(:api_address, name: "SAPCSRF",
    #                        address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #                        username: "JQUINGCO", password: "appcentric1")

    #   result = UtilityContext.get_SAP_api_address("SAPCSRF2")

    #   assert result == {:api_address_not_exists}
    # end

  end

  describe  "SAP Update Account" do

    # test "with valid parameters" do
    #   migration = insert(:migration, module: "Account")
    #   migration_notification = insert(:migration_notification, migration: migration)
    #   insert(:api_address, name: "SAPCSRF",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #          username: "JQUINGCO", password: "appcentric1")

    #   insert(:api_address, name: "SAP-UpdateAccount",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus")

    #   params = %{
    #     "code" => "TESTACCOUNT1",
    #     "status_code" => "200",
    #     "message" => "SUCCESS",
    #     "module" => "Account",
    #     "migration_notification_id" => migration_notification.id
    #   }

    #   result = UtilityContext.sap_update_status(params)
    #   #TODO
    #   assert result
    # end

    # test "with valid parameters but invalid credentials" do
    #   migration = insert(:migration, module: "Account")
    #   migration_notification = insert(:migration_notification, migration: migration)
    #   insert(:api_address, name: "SAPCSRF",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #          username: "JQUINGCO", password: "appcentric2")

    #   insert(:api_address, name: "SAP-UpdateAccount",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus")

    #   params = %{
    #     "code" => "TESTACCOUNT1",
    #     "status_code" => "200",
    #     "message" => "SUCCESS",
    #     "module" => "Account",
    #     "migration_notification_id" => migration_notification.id
    #   }

    #   result = UtilityContext.sap_update_status(params)
    #   assert result == {:error, "Unable to Login"}

    # end

    # test "with missing account code" do
    #   migration = insert(:migration, module: "Account")
    #   migration_notification = insert(:migration_notification, migration: migration)
    #   insert(:api_address, name: "SAPCSRF",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #          username: "JQUINGCO", password: "appcentric1")

    #   insert(:api_address, name: "SAP-UpdateAccount",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus")

    #   params = %{
    #     "code" => nil,
    #     "status_code" => "200",
    #     "message" => "SUCCESS",
    #     "module" => "Account",
    #     "migration_notification_id" => migration_notification.id
    #   }

    #   result = UtilityContext.sap_update_status(params)
    #   assert result == {:error, "Account Code not found"}

    # end

    # test "with missing status code" do
    #   migration = insert(:migration, module: "Account")
    #   migration_notification = insert(:migration_notification, migration: migration)
    #   insert(:api_address, name: "SAPCSRF",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/",
    #          username: "JQUINGCO", password: "appcentric1")

    #   insert(:api_address, name: "SAP-UpdateAccount",
    #          address: "https://sap-webd.maxicare.com.ph:8081/sap/opu/odata/sap/ZPUBD_SRV/UpdateAccountStatus")

    #   params = %{
    #     "code" => nil,
    #     "status_code" => nil,
    #     "message" => "SUCCESS",
    #     "module" => "Account",
    #     "migration_notification_id" => migration_notification.id
    #   }

    #   result = UtilityContext.sap_update_status(params)
    #   assert result == {:error, "Invalid Parameters"}

    # end

  end

  test "signs in payorlink_2" do
    # insert(:api_address, name: "PAYORLINK_2",
    #         address: "https://payorlink-ip-ist.medilink.com.ph",
    #         username: "masteradmin",
    #         password: "P@ssw0rd"
    # )

    # UtilityContext.payorlink_v2_sign_in()
    # {:ok, token} = result

    #TODO:
    # assert {:ok, token} == result
  end

  test "sends error log email" do
    #insert(:api_address, name: "PAYORLINK_2",
    #        address: "https://payorlink-ip-ist.medilink.com.ph",
    #        username: "masteradmin",
    #        password: "P@ssw0rd"
    #)

    #wel = %{
    #  id: Ecto.UUID.generate(),
    #  job_name: "Test Job",
    #  job_params: "Test Params",
    #  module_name: "Test Module",
    #  function_name: "Test Function",
    #  error_description: "Test Description"
    #}

    #e = ["test@gmail.com.ph"]

    #params = %{
    #  "params" => %{
    #    "logs" => [wel],
    #    "emails" => e
    #  }
    #}

    ##TODO:
    #UtilityContext.send_error_log_email(params)
    ## raise result
  end

  describe "check_valid_params" do
    test "with valid parameters" do
      params = %{"params1" => "123", "params2" => "123"}
      assert  {:ok, validated_params} = UtilityContext.check_valid_params(params, ["params1", "params2"])
    end

    test "with invalid parameters" do
      params = %{"params1" => "123", "params2" => ""}
      assert  {:error_params, message} = UtilityContext.check_valid_params(params, ["params1", "params2"])
      assert message ==  "params2 is required"
    end
  end

end

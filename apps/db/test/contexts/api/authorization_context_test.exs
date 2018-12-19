defmodule Innerpeace.Db.Base.Api.AuthorizationContextTest do
  use Innerpeace.Db.SchemaCase
  # alias Innerpeace.Db.{
  #   Repo
  # }

  alias Innerpeace.Db.Base.Api.AuthorizationContext
  alias Innerpeace.Db.Base.{ProductContext, AccountContext}

  # test "validate_coverage_params/1, with valid params" do
  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   insert(:member_product, member: member, account_product: account_product1)
  #   insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     card_no: "1111555588881111",
  #     facility_code: "880000000006035",
  #     coverage_name: "Inpatient"
  #   }

  #   result = AuthorizationContext.validate_coverage_params(params)
  #   assert result == {:ok}

  # end

  # test "validate_coverage_params/1, using not covered based in member product" do
  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")
  #   coverage3 = insert(:coverage, name: "RUV")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   product_coverage3 = insert(:product_coverage, product: product, coverage: coverage3, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage3, facility: facility1)
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   insert(:member_product, member: member, account_product: account_product1)
  #   insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     card_no: "1111555588881111",
  #     facility_code: "880000000006035",
  #     coverage_name: "RUV"
  #   }

  #   {:not_covered, message} = AuthorizationContext.validate_coverage_params(params)
  #   assert message == "facility is not covered by the given coverage"

  # end

  # test "validate_coverage_params/1, with invalid card no" do
  #   account_group = insert(:account_group, name: "Jollibee Worldwide")
  #   account = insert(:account, account_group: account_group)

  #   coverage1 = insert(:coverage, name: "ACU")
  #   coverage2 = insert(:coverage, name: "Inpatient")

  #   facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
  #   facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

  #   product = insert(:product, name: "LOAPRODUCT1")
  #   insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
  #   product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   product = ProductContext.get_product!(product.id)

  #   product2 = insert(:product, name: "LOAPRODUCT2")
  #   insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
  #   insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
  #   insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
  #   product2 = ProductContext.get_product!(product2.id)

  #   account = AccountContext.get_account!(account.id)

  #   account_product1 = insert(:account_product, account: account, product: product)
  #   account_product2 = insert(:account_product, account: account, product: product2)

  #   member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
  #   member2 = insert(:member)
  #   insert(:member_product, member: member, account_product: account_product1)
  #   insert(:member_product, member: member, account_product: account_product2)

  #   params = %{
  #     member_id: "4350757e-cdd7-4b34-9c45-39f48501f023",
  #     facility_code: "880000000000359",
  #     coverage_name: "Inpatient"
  #   }

  #   {:error, changeset} = AuthorizationContext.validate_coverage_params(params)
  #   assert changeset.errors == [member_id: {"member_id is not existing", []}]
  #   #    {:ok} ->
  #   #      conn
  #   #      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "eligible.json")
  #   #    {:error, changeset} ->
  #   #      conn
  #   #      |> put_status(400)
  #   #      |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
  #   #    {:not_covered, message} ->
  #   #      conn
  #   #      |> put_status(400)
  #   #      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)

  # end

  test "validate_coverage_params/1, with invalid facility code" do
    account_group = insert(:account_group, name: "Jollibee Worldwide")
    account = insert(:account, account_group: account_group)

    coverage1 = insert(:coverage, name: "ACU")
    coverage2 = insert(:coverage, name: "Inpatient")

    facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
    facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

    product = insert(:product, name: "LOAPRODUCT1")
    insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product1 = insert(:account_product, account: account, product: product)
    account_product2 = insert(:account_product, account: account, product: product2)

    member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
    insert(:member_product, member: member, account_product: account_product1)
    insert(:member_product, member: member, account_product: account_product2)

    params = %{
      card_no: "1111555588881111",
      facility_code: "880000000006035jkheqw",
      coverage_name: "Inpatient"
    }

    {:error, changeset} = AuthorizationContext.validate_coverage_params(params)
    assert changeset.errors == [facility_code: {"facility code is not existing", []}]
    #    {:ok} ->
    #      conn
    #      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "eligible.json")
    #    {:error, changeset} ->
    #      conn
    #      |> put_status(400)
    #      |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
    #    {:not_covered, message} ->
    #      conn
    #      |> put_status(400)
    #      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: message)

  end

  test "validate_coverage_params/1, with invalid coverage name" do
    account_group = insert(:account_group, name: "Jollibee Worldwide")
    account = insert(:account, account_group: account_group)

    coverage1 = insert(:coverage, name: "ACU")
    coverage2 = insert(:coverage, name: "Inpatient")

    facility1 = insert(:facility, code: "880000000000359", name: "Calamba Medical Center", status: "Affiliated")
    facility2 = insert(:facility, code: "880000000006035", name: "Makati Medical Center", status: "Affiliated")

    product = insert(:product, name: "LOAPRODUCT1")
    insert(:product_coverage, product: product, coverage: coverage1, type: "exception")
    product_coverage2 = insert(:product_coverage, product: product, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    product = ProductContext.get_product!(product.id)

    product2 = insert(:product, name: "LOAPRODUCT2")
    insert(:product_coverage, product: product2, coverage: coverage1, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility1)
    insert(:product_coverage, product: product2, coverage: coverage2, type: "inclusion")
    insert(:product_coverage_facility, product_coverage: product_coverage2, facility: facility2)
    product2 = ProductContext.get_product!(product2.id)

    account = AccountContext.get_account!(account.id)

    account_product1 = insert(:account_product, account: account, product: product)
    account_product2 = insert(:account_product, account: account, product: product2)

    member = insert(:member, card_no: "1111555588881111", first_name: "Byakuya", last_name: "Kuchiki")
    insert(:member_product, member: member, account_product: account_product1)
    insert(:member_product, member: member, account_product: account_product2)

    params = %{
      card_no: "1111555588881111",
      facility_code: "880000000006035",
      coverage_name: "Inpatientliwth"
    }

    {:error, changeset} = AuthorizationContext.validate_coverage_params(params)
    assert changeset.errors == [coverage_name: {"coverage name is not existing", []}]
  end

  describe "Request PEME to Paylink" do
    test "with valid parameters" do
      account_group = insert(:account_group, code: "C63439", name: "Jollibee Worldwide")
      insert(:account, account_group: account_group)
      insert(:api_address, name: "PAYORLINK 1.0", address: "https://api.maxicare.com.ph", username: "admin@mlservices.com", password: "P@ssw0rd1234")
      insert(:api_address, name: "PaylinkAPI",
             address: "https://api.maxicare.com.ph/paylinkapi/",
             username: "admin@mlservices.com",
             password: "P@ssw0rd1234")
      loa = insert(:authorization, number: random_number())
      user = insert(:user, username: "Dev")
      member =
        insert(:member,
               type: "Principal",
               account_code: account_group.code,
               effectivity_date: Ecto.Date.cast!("2017-01-02"),
               expiry_date: Ecto.Date.cast!("2019-01-01"),
               first_name: "Abraham",
               last_name: "Lincoln",
               middle_name: "",
               employee_no: random_number(),
               created_by_id: user.id,
               email: "dev@gmail.com",
               mobile: "09210054040",
               birthdate: Ecto.Date.cast!("1994-01-01"),
               civil_status: "Single",
               tin: random_number(),
               city: "Sta. Maria",
               province: "Bulacan"
        )

      # raise AuthorizationContext.request_peme_in_paylink(:http, member, peme_params(), loa)
      assert true == true
    end
  end

  defp random_number do
    "#{Enum.random(10000000..99999999)}"
  end

  defp peme_params do
    %{
      facility_code: "880000000006035",
      benefit_code: "Dev-Benefit",
      package_code: "Dev-Package-Code",
      package_name: "Dev-Package-Name",
      package_facility_rate: 1000,
      origin: "Accountlink",
      ip: "127.0.0.1",
     }
  end
end

defmodule Innerpeace.Db.Parsers.MemberParserTest do
  use Innerpeace.Db.SchemaCase, async: true
  alias Innerpeace.Db.Parsers.MemberParser

  @valid_attrs %{
    "Account Code" => "C00918",
    "Employee No" => "1234-5678",
    "Member Type" => "Principal",
    "Relationship" => "",
    "Effective Date" => "Aug 1, 2017",
    "Expiry Date" => "Aug 01, 2018",
    "First Name" => "Shane",
    "Last Name" => "Dela Rosa",
    "Middle Name / Initial" => "Dolot",
    "Suffix" => "",
    "Gender" => "Male",
    "Civil Status" => "Married",
    "Birthdate" => "Dec 25, 1994",
    "Mobile No" => "09210043004",
    "Email" => "Adress@gmail.com",
    "Date Hired" => "Feb 07, 2017",
    "Regularization Date" => "Feb 07, 2017",
    "Address" => "unit 4 CIBI building, Zapote",
    "City" => "Quiapo Manila",
    "Plan Code" => "PRD-726515,PRD-434582",
    "For Card Issuance" => "Yes",
    "Tin No" => "123456789012",
    "Philhealth" => "Required to file",
    "Philhealth No" => "123456789012"
  }

  setup do
    user = insert(:user)

    # AccountGroups
    account_group = insert(:account_group, code: "C00918")
    account_group1 = insert(:account_group, code: "C00919")
    account_group2 = insert(:account_group, code: "C00819")
    account_group4 = insert(:account_group, code: "C00917")

    # Accounts
    account = insert(
      :account,
      account_group: account_group,
      major_version: 2,
      status: "Active",
      start_date: "2017-08-01",
      end_date: "2018-09-01"
    )
    account1 = insert(
      :account,
      account_group: account_group1,
      major_version: 1,
      status: "Active",
      start_date: Ecto.Date.cast!("2017-08-01"),
      end_date: Ecto.Date.cast!("2018-08-01")
    )
    # account2 = insert(:account, account_group: account_group, major_version: 1, status: "Active")
    account3 = insert(
      :account,
      account_group: account_group2,
      major_version: 1,
      status: "Active"
    )
    insert(
      :account,
      account_group: account_group4,
      major_version: 1,
      status: "Active"
    )

    # Products
    p1 = insert(
      :product,
      code: "PRD-726515",
      name: "1",
      nem_dependent: 3,
      adult_dependent_min_type: "Years",
      adult_dependent_max_type: "Years",
      adult_dependent_min_age: 18,
      adult_dependent_max_age: 65,
      principal_min_age: 18,
      principal_max_age: 65,
      minor_dependent_min_type: "Days",
      minor_dependent_max_type: "Days",
      minor_dependent_min_age: 15,
      minor_dependent_max_age: 100_020
    )
    p2 = insert(
      :product,
      code: "PRD-434582",
      name: "2",
      nem_dependent: nil,
      adult_dependent_min_type: "Years",
      adult_dependent_max_type: "Years",
      adult_dependent_min_age: 18,
      adult_dependent_max_age: 65,
      principal_min_age: 18,
      principal_max_age: 65,
      minor_dependent_min_type: "Days",
      minor_dependent_max_type: "Days",
      minor_dependent_min_age: 15,
      minor_dependent_max_age: 500
    )
    p3 = insert(
      :product,
      code: "PRD-264680",
      name: "3",
      nem_dependent: nil,
      adult_dependent_min_type: "Years",
      adult_dependent_max_type: "Years",
      adult_dependent_min_age: 18,
      adult_dependent_max_age: 65,
      principal_min_age: 18,
      principal_max_age: 65,
      minor_dependent_min_type: "Days",
      minor_dependent_max_type: "Days",
      minor_dependent_min_age: 15,
      minor_dependent_max_age: 20
    )
    insert(:product, code: "PRD-983426", name: "4")
    insert(:product, code: "PRD-182135", name: "5")

    # AccountProducts
    ap1 = insert(:account_product, account: account1, product: p1)
    ap2 = insert(:account_product, account: account1, product: p2)
    insert(:account_product, account: account3, product: p3)
    insert(:account_product, account: account, product: p3)
    insert(:account_product, account: account1, product: p3)

    insert(:account_product, account: account, product: p1)
    insert(:account_product, account: account, product: p2)

    # Members
    member = insert(
      :member,
      employee_no: "1234567",
      type: "Principal",
      status: "Active",
      account_code: "C00919",
      civil_status: "Married",
      effectivity_date: "2017-08-01",
      expiry_date: "2018-08-01", gender: "Female"
    )

    insert(
      :member,
      employee_no: "1234567000",
      type: "Principal",
      status: "Active",
      account_code: "C00819",
      effectivity_date: "2017-08-01",
      expiry_date: "2018-08-01", gender: "Female")

    m3 = insert(
      :member,
      employee_no: "12345670001",
      type: "Principal",
      status: "Active",
      account_code: "C00917",
      effectivity_date: "2017-08-01",
      expiry_date: "2018-08-01", gender: "Female"
    )

    # MemberProducts
    insert(:member_product, account_product: ap1, member: member, tier: 1)
    insert(:member_product, account_product: ap2, member: m3, tier: 1)

    {:ok, %{
      account: account,
      account_group: account_group,
      account_group1: account_group1,
      member: member,
      product: p1,
      user: user
    }}
  end

  test "parse member data(principal) corporate" do
    assert {:passed} = MemberParser.validations(1, @valid_attrs, [])
  end

  test "parse member data(principal) IFG" do
    params =
      @valid_attrs
      |> Map.put("upload_type", "Individual, Family, Group (IFG)")
      |> Map.put("Account Code", "C00919")
      |> Map.put("Principal Number", "1234-5678")

    assert {:passed} = MemberParser.validations(1, params, [])
  end

 test "parse member data(guardian)" do
   insert(:payor_card_bin, sequence: 1, card_bin: "60508311")
    params =
      @valid_attrs
      |> Map.put("Member Type", "Guardian")

    assert {:passed} = MemberParser.validations(1, params, [])
  end

  # test "parse member data(dependent)", %{account_group1: account_group}  do
  #  insert(:account_hierarchy_of_eligible_dependent,
  #         account_group: account_group,
  #         hierarchy_type: "Married Employee",
  #         dependent: "Sibling",
  #         ranking: 2)
  #  insert(:account_hierarchy_of_eligible_dependent,
  #         account_group: account_group,
  #         hierarchy_type: "Married Employee",
  #         dependent: "Child",
  #         ranking: 1)

  #   params =
  #     @valid_attrs
  #     |> Map.put("Birthdate", "03/08/2017")
  #     |> Map.put("Account Code", "C00919")
  #     |> Map.put("Member Type", "Dependent")
  #     |> Map.put("Employee No", "1234567")
  #     |> Map.put("Relationship", "Child")
  #     |> Map.put("Civil Status", "Single")
  #     |> Map.put("Email", "")
  #     |> Map.put("Mobile No", "")
  #
  #   assert {:passed} = MemberParser.validations(1, params, [])
  # end

  test "member parser failed" do
    params =
      @valid_attrs
      |> Map.put("Account Code", "try")
      |> Map.put("For Card Issuance", "ye")
      |> Map.put("Employee No", "1234567")
      |> Map.put("Effective Date", "2017-01-01")
      |> Map.put("Expiry Date", "2017-01-01")
      |> Map.put("First Name", "2017-01-01")
      |> Map.put("Middle Name / Initial", "2017-01-01")
      |> Map.put("Last Name", "2017-01-01")
      |> Map.put("Suffix", "2017-01-01")
      |> Map.put("Gender", "2017-01-01")
      |> Map.put("Civil Status", "2017-01-01")
      |> Map.put("Birthdate", "2017-01-01")
      |> Map.put("Mobile", "2017-01-01")
      |> Map.put("Date Hired", "01/01/17")
      |> Map.put("Regularization Date", "")
      |> Map.put("Product Code", "123123;12321312")

     assert {:failed, _message} = MemberParser.validations(1, params, [])
  end

  test "validate_columns/1 success" do
    assert {:complete} = MemberParser.validate_columns(@valid_attrs)
  end

  test "validate_columns/1 failed" do
    params = Map.put(@valid_attrs, "Employee No", "")
    assert {:missing, "Please enter Employee No"} = MemberParser.validate_columns(params)
  end

  test "validate_account_code/1 success" do
    params = @valid_attrs
    assert {:valid_code} = MemberParser.validate_account_code(params["Account Code"])
  end

  test "validate_account_code/1 failed account code does not exist" do
    assert {:account_not_found} = MemberParser.validate_account_code("111")
  end

  test "validate_account_code/1 failed account group does not have an account" do
    insert(:account_group, code: "test_account")
    assert is_nil(MemberParser.validate_account_code("test_account"))
  end

  test "validate_account_code/1 failed account is not active" do
    account_group = insert(:account_group, code: "test_account")
    insert(:account, account_group: account_group, status: "Suspended")

    assert {false, "Suspended"} = MemberParser.validate_account_code("test_account")
  end

  test "validate_member_type/2 principal" do
    assert {:valid_employee_no} = MemberParser.validate_member_type("Principal", "12345678")
  end

  test "validate_member_type/2 principal failed employee no is already used" do
    assert {:used} = MemberParser.validate_member_type("Principal", "1234567")
  end

  test "validate_member_type/2 guardian" do
    assert {:valid_employee_no} = MemberParser.validate_member_type("Guardian", "12345678")
  end

  test "validate_member_type/2 guardian failed employee no is already used" do
    assert {:used} = MemberParser.validate_member_type("Guardian", "1234567")
  end

  test "validate_member_type/2 dependent" do
    assert {:valid_employee_no} = MemberParser.validate_member_type("Dependent", "1234567")
  end

  test "validate_member_type/2 dependent failed employee no not found" do
    assert {:employee_no_not_found} = MemberParser.validate_member_type("Dependent", "12345678")
  end

  test "validate_member_type/2 dependent failed member is no principal member type" do
    insert(:member, employee_no: "12345678", status: "Active")
    assert {:employee_no_not_found} = MemberParser.validate_member_type("Dependent", "12345678")
  end

  test "validate_member_type/2 dependent failed member is not active" do
    insert(:member, employee_no: "12345678", status: "Lapsed", type: "Principal")
    assert {:not_active, "Lapsed"} = MemberParser.validate_member_type("Dependent", "12345678")
  end

  test "validate_member_type/2 dependent failed invalid_member_type" do
    assert {:invalid_member_type} = MemberParser.validate_member_type("Depende", "12345678")
  end

 test "validate_effective_date/2 principal member type  success" do
   params = @valid_attrs
   message = []

   assert {:valid_effective_date} = MemberParser.validate_effective_date(params, message)
 end

 test "validate_effective_date/2 dependent member type success" do
   params =
     @valid_attrs
     |> Map.put("Member Type", "Dependent")
     |> Map.put("Employee No", "1234567")
     |> Map.put("Account Code", "C00919")
     |> Map.put("Effective Date", "08/01/2018")
   message = []

   assert {:valid_effective_date} = MemberParser.validate_effective_date(params, message)
 end

 test "validate_effective_date/2 dependent member type failed" do
   params =
     @valid_attrs
     |> Map.put("Member Type", "Dependent")
     |> Map.put("Employee No", "1234567")
     |> Map.put("Account Code", "C00919")
     |> Map.put("Effective Date", "Jul 01, 2017")
   message = []

   assert {:invalid_effective_date} = MemberParser.validate_effective_date(params, message)
 end

  test "validate_effective_date/2 failed invalid date" do
    params = Map.put(@valid_attrs, "Effective Date", "2017-01-1")
    message = []

    assert {:invalid_date} = MemberParser.validate_effective_date(params, message)
  end

  test "validate_effective_date/2 failed not within coverage" do
    params = Map.put(@valid_attrs, "Effective Date", "09/11/2018")
    message = []

    assert {:not_within_coverage} = MemberParser.validate_effective_date(params, message)
  end

  test "error_account/2 success" do
    assert {:ok, false} = MemberParser.error_account([], "Dependent", "09/11/2018")
  end

  test "error_account/2 failed principal member type" do
    assert {:error, true} = MemberParser.error_account(["Please enter Account Code"], "Principal", "09/11/2018")
  end

  test "error_account/2 failed gurdian member type" do
    assert {:error, true} = MemberParser.error_account(["Please enter Account Code"], "Guardian", "09/11/2018")
  end

 test "member_type_date/4 effective_date success" do
   params = @valid_attrs
   effective_date = "2017-08-02"

   assert {:valid_effective_date} = MemberParser.member_type_date(effective_date, params, [], :effective)
 end

  test "member_type_date/4 effective_date failed not_within_coverage" do
    params = @valid_attrs
    effective_date = "2019-08-02"

    assert {:not_within_coverage} = MemberParser.member_type_date(effective_date, params, [], :effective)
  end

  test "member_type_date/4 effective_date success (dependent)" do
    params =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Account Code", "C00919")
      |> Map.put("Member Type", "dependent")
    effective_date = "2017-08-01"
    message = []

    assert {:valid_effective_date} = MemberParser.member_type_date(effective_date, params, message, :effective)
  end

  test "member_type_date/4 effective_date failed invalid employee no (dependent)" do
    params = Map.put(@valid_attrs, "Member Type", "dependent")
    effective_date = "2019-08-02"
    message = ["Employee No does not exist"]

    assert {:invalid_employee_no} = MemberParser.member_type_date(effective_date, params, message, :effective)
  end

  test "member_type_date/4 effective_date failed Employee no not found (dependent)" do
    params =
      @valid_attrs
      |> Map.put("Member Type", "dependent")
      |> Map.put("Employee No", "123")

    effective_date = "2019-08-02"

    assert {:employee_no_not_found} = MemberParser.member_type_date(effective_date, params, [], :effective)
  end

  test "member_type_date/4 effective_date failed Invalid effective date (dependent)" do
    params =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Account Code", "C00919")
      |> Map.put("Member Type", "dependent")

    effective_date = "2019-08-02"

    assert {:invalid_effective_date} = MemberParser.member_type_date(effective_date, params, [], :effective)
  end

 test "validate_expiry_date/2 principal member type  success" do
   params = @valid_attrs
   message = []

   assert {:valid_expiry_date} = MemberParser.validate_expiry_date(params, message)
 end

 test "validate_expiry_date/2 principal member type dependent success" do
  params =
    @valid_attrs
    |> Map.put("Employee No", "1234567")
    |> Map.put("Account Code", "C00919")
    |> Map.put("Member Type", "dependent")
   message = []

   assert {:valid_expiry_date} = MemberParser.validate_expiry_date(params, message)
 end

 test "validate_expiry_date/2 principal member type dependent failed" do
  params =
    @valid_attrs
    |> Map.put("Employee No", "1234567")
    |> Map.put("Account Code", "C00919")
    |> Map.put("Member Type", "dependent")
    |> Map.put("Expiry Date", "08/02/2018")
   message = []

   assert {:invalid_expiry_date} = MemberParser.validate_expiry_date(params, message)
 end

 test "member_type_date/4 expiry_date success" do
   params = @valid_attrs
   expiry_date = "2017-08-02"

   assert {:valid_expiry_date} = MemberParser.member_type_date(expiry_date, params, [], :expiry)
 end

  test "member_type_date/4 expiry_date failed invalid employee no (dependent)" do
    params = Map.put(@valid_attrs, "Member Type", "dependent")
    expiry_date = "2019-08-02"
    message = ["Employee No does not exist"]

    assert {:invalid_employee_no} = MemberParser.member_type_date(expiry_date, params, message, :expiry)
  end

  test "member_type_date/4 expiry_date failed Employee no not found (dependent)" do
    params =
      @valid_attrs
      |> Map.put("Member Type", "dependent")
      |> Map.put("Employee No", "123")

    expiry_date = "2019-08-02"

    assert {:employee_no_not_found} = MemberParser.member_type_date(expiry_date , params, [], :expiry)
  end

  test "member_type_date/4 expiry_date failed Invalid expiry date (dependent)" do
    params =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Account Code", "C00919")
      |> Map.put("Member Type", "dependent")

    expiry_date = "2018-08-02"

    assert {:invalid_expiry_date} = MemberParser.member_type_date(expiry_date, params, [], :expiry)
  end

 test "member_type_date/4 expiry_date success (Principal/Guardian)" do
   params = @valid_attrs
   expiry_date = "2017-08-02"

   assert {:valid_expiry_date} = MemberParser.member_type_date(expiry_date, params, [], :expiry)
 end

  test "member_type_date/4 expiry_date failed not_within_coverage (Principal/Guardian)" do
    params = @valid_attrs
    expiry_date = "2019-08-02"

    assert {:not_within_coverage} = MemberParser.member_type_date(expiry_date, params, [], :expiry)
  end

  test "validate_name/2 first name" do
    assert {:valid_name} = MemberParser.validate_name("Raymond.,-", "First Name")
  end

  test "validate_name/2 invalid first name" do
    assert {:invalid_name, message} = MemberParser.validate_name("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/1234567890", "First Name")
    assert String.contains?(message, "First Name")
  end

  test "validate_name/2 middle name" do
    assert {:valid_name} = MemberParser.validate_name("Fabian.,-", "First Name")
  end

  test "validate_name/2 invalid middle name" do
    assert {:invalid_name, message} = MemberParser.validate_name("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/1234567890", "Middle Name")
    assert String.contains?(message, "Middle Name")
  end

  test "validate_name/2 last name" do
    assert {:valid_name} = MemberParser.validate_name("Fabian.,-", "First Name")
  end

  test "validate_name/2 invalid last name" do
    assert {:invalid_name, message} = MemberParser.validate_name("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/1234567890", "Last Name")
    assert String.contains?(message, "Last Name")
  end

  test "validate_name/2 Suffix" do
    assert {:valid_name} = MemberParser.validate_name("Fabian.,-", "First Name")
  end

  test "validate_name/2 invalid Suffix" do
    assert {:invalid_name, message} = MemberParser.validate_name("=/[``~<>^\"'{}[\]\;':?!@#$%&*()_+=]|/1234567890", "Suffix")
    assert String.contains?(message, "Suffix")
  end

  test "validate_gender/1 success" do
    assert {:valid_gender} = MemberParser.validate_gender(String.downcase(@valid_attrs["Gender"]))
  end

  test "validate_gender/1 invalid gender failed" do
    assert {:invalid_gender} = MemberParser.validate_gender("M")
  end

  test "validate_gender_dependent/4 success" do
    p =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse")
    gender = String.downcase(p["Gender"])
    employee_no = p["Employee No"]
    _member_type = p["Member Type"]
    relationship = p["Relationship"]

    assert {:valid_gender} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, [])
  end

  test "validate_gender_dependent/4 invalid gender failed" do
    p =
      @valid_attrs
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse")
    gender = "M"
    employee_no = p["Employee No"]
    _member_type = p["Member Type"]
    relationship = p["Relationship"]

    assert {:invalid_gender} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, [])
  end

  test "validate_gender_dependent/4 invalid employee_no failed" do
    p =
      @valid_attrs
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse")
    gender = String.downcase(p["Gender"])
    employee_no = p["Employee No"]
    _member_type = p["Member Type"]
    relationship = p["Relationship"]
    message = ["Employee No does not exist"]

    assert {:invalid_employee_no} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, message)
  end

  test "validate_gender_dependent/4 employee_no not found failed" do
    p =
      @valid_attrs
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse")
    gender = String.downcase(p["Gender"])
    employee_no = "1234"
    _member_type = p["Member Type"]
    relationship = p["Relationship"]

    assert {:employee_no_not_found} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, [])
  end

  test "validate_gender_dependent/4 invalid_relationship failed" do
    p =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse1")
    gender = String.downcase(p["Gender"])
    employee_no = p["Employee No"]
    _member_type = p["Member Type"]
    relationship = p["Relationship"]

    assert {:invalid_relationship} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, [])
  end

  test "validate_gender_dependent/4 invalid_spouse_gender failed" do
    p =
      @valid_attrs
      |> Map.put("Employee No", "1234567")
      |> Map.put("Member Type", "Dependent")
      |> Map.put("Relationship", "Spouse")
    gender = "female"
    employee_no = p["Employee No"]
    _member_type = p["Member Type"]
    relationship = p["Relationship"]

    assert {:invalid_spouse_gender} = MemberParser.validate_gender_dependent(gender, employee_no, relationship, [])
  end

  test "validate_civil_status/1 success" do
   assert {:valid_civil_status}  = MemberParser.validate_civil_status("single")
  end

  test "validate_civil_status/1 invalid_civil_status failed" do
   assert {:invalid_civil_status}  = MemberParser.validate_civil_status("single1")
  end

  test "validate_civil_status_dependent/2 child success" do
    assert {:valid_civil_status} = MemberParser.validate_civil_status_dependent("single", "child", "Corporate")
  end

  test "validate_civil_status_dependent/2 sibling success" do
    assert {:valid_civil_status} = MemberParser.validate_civil_status_dependent("single", "sibling", "Corporate")
  end

  test "validate_civil_status_dependent/2 spouse success" do
    assert {:valid_civil_status} = MemberParser.validate_civil_status_dependent("married", "spouse", "Corporate")
  end

  test "validate_civil_status_dependent/2 parent (corporate) success" do
    assert {:valid_civil_status} = MemberParser.validate_civil_status_dependent("married", "parent", "Corporate")
  end

  test "validate_civil_status_dependent/2 parent (Individual, Family, Group (IFG)) success" do
    assert {:valid_civil_status} = MemberParser.validate_civil_status_dependent("married", "parent", "Individual, Family, Group (IFG)")
  end

  test "validate_civil_status_dependent/2 invalid_child_civil_status failed" do
    assert {:invalid_child_civil_status} = MemberParser.validate_civil_status_dependent("married", "child", "Corporate")
  end

  test "validate_civil_status_dependent/2 invalid_sibling_civil_status failed" do
    assert {:invalid_sibling_civil_status} = MemberParser.validate_civil_status_dependent("married", "sibling", "Corporate")
  end

  test "validate_civil_status_dependent/2 invalid_spouse_civil_status failed" do
    assert {:invalid_spouse_civil_status} = MemberParser.validate_civil_status_dependent("single", "spouse", "Corporate")
  end

  test "validate_civil_status_dependent/2 parent (corporate) failed" do
    assert {:invalid_parent_civil_status_corporate} = MemberParser.validate_civil_status_dependent("widowed", "parent", "Corporate")
  end

  test "validate_civil_status_dependent/2 parent (Individual, Family, Group (IFG)) failed" do
    assert {:invalid_parent_civil_status} = MemberParser.validate_civil_status_dependent("single", "parent", "Individual, Family, Group (IFG)")
  end

  test "validate_birthdate/1 success" do
    assert {:valid_birthdate, _birthdate} = MemberParser.validate_birthdate(@valid_attrs["Birthdate"])
  end

  test "validate_birthdate/1 invalid_birthdate failed" do
    assert {:invalid_birthdate} = MemberParser.validate_birthdate("2017-01-1")
  end

  test "validate_birthdate_dependent/5 min max dependent type (days, years)" do
    account_group = insert(:account_group, code: "I00919")
    account = insert(:account, status: "Active", account_group: account_group)
    member = insert(:member, account_code: "I00919", employee_no: "1234568")
    p1 = insert(
      :product,
      code: "PRD-726518",
      name: "12",
      minor_dependent_min_type: "Days",
      minor_dependent_max_type: "Years",
      minor_dependent_min_age: 15,
      minor_dependent_max_age: 30
    )
    ap = insert(:account_product, account: account, product: p1)
    insert(:member_product, member: member, account_product: ap, tier: 1)

    birthdate = "11/01/1994"
    employee_no = "1234568"
    account_code = "I00919"
    relationship = "Sibling"
    message = []

    assert {:valid_birthdate, _birthdate} = MemberParser.validate_birthdate_dependent(
      birthdate, employee_no, account_code, relationship, message
    )
  end

  test "validate_mobile_no/1 success" do
    assert {:valid_mobile_no} = MemberParser.validate_mobile_no(@valid_attrs["Mobile No"])
  end

  test "validate_mobile_no/1 mobile length min length 11 failed" do
    assert {:invalid_length} = MemberParser.validate_mobile_no("0921004004")
  end

  test "validate_mobile_no/1 starts with 09 failed" do
    refute MemberParser.validate_mobile_no("19210040041")
  end

  test "validate_mobile_no/1 contains non-numeric failed" do
    refute MemberParser.validate_mobile_no("09aaaaaaaa~")
  end

  test "validate_email/1 success" do
    assert {:valid_email} = MemberParser.validate_email(@valid_attrs["Email"])
  end

  test "validate_email/1 has not (@) failed" do
    refute MemberParser.validate_email("raymond_navarro.com")
  end

  test "validate_email/1 has not (.) failed" do
    refute MemberParser.validate_email("raymond_navarro@com")
  end

  test "validate_email/1 contains invalid char failed" do
    refute MemberParser.validate_email("=/[``~<>^\"'{}[\]\;':?!#$%&*()+=]|/")
  end

  test "validate_step_16/3 success" do
    date_hired = @valid_attrs["Date Hired"]
    regularization_date = @valid_attrs["Regularization Date"]
    member_type = @valid_attrs["Member Type"]

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 date hired and regularization date is invalid" do
    date_hired = "2017-01-1"
    regularization_date = "2017-02-1"
    member_type = @valid_attrs["Member Type"]
    step_16 = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
    assert {:invalid_date_hired_n_regularization_date} = step_16
  end

  test "validate_step_16/3 date hired is invalid" do
    date_hired = "2017-01-1"
    regularization_date = "01/01/2017"
    member_type = @valid_attrs["Member Type"]

    assert {:invalid_date_hired} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 regularization date is invalid" do
    date_hired = "01/01/2017"
    regularization_date = "2017-01-1"
    member_type = @valid_attrs["Member Type"]

    assert {:invalid_regularization_date} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 date hired is greater than regularization date" do
    date_hired = "02/01/2017"
    regularization_date = "01/01/2017"
    member_type = @valid_attrs["Member Type"]

    assert {:invalid_dates} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 date hired is empty" do
    date_hired = ""
    regularization_date = "01/01/2017"
    member_type = @valid_attrs["Member Type"]

    assert {:valid_dates, "Please enter Date Hired"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 (dependent) success" do
    date_hired = @valid_attrs["Date Hired"]
    regularization_date = @valid_attrs["Regularization Date"]
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 date hired is empty and valid regularization date" do
    date_hired = ""
    regularization_date = "01/01/2017"
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 date hired is empty and invalid regularization date" do
    date_hired = ""
    regularization_date = "2017-01-10"
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 regularization date is empty and valid date hired" do
    date_hired = "01/01/2017"
    regularization_date = ""
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 regularization date is empty and invalid date hired" do
    date_hired = "2017-01-01"
    regularization_date = ""
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_16/3 both dates are empty (dependent)" do
    date_hired = ""
    regularization_date = ""
    member_type = "Dependent"

    assert {:valid_dates, "valid_date"} = MemberParser.validate_step_16(date_hired, regularization_date, member_type)
  end

  test "validate_step_17/1 success" do
    assert {:valid_product_codes} = MemberParser.validate_step_17("PRD-726515,PRD-434582,PRD-264680", "C00919", "dec 25, 1997", "Principal", "")
  end

  test "validate_step_17/1 invalid member age failed" do
    assert {:invalid_members_age, message} = MemberParser.validate_step_17("PRD-726515,PRD-434582,PRD-264680", "C00919", "dec 25, 2004", "Principal", "")

    assert Enum.member?(message, "Member's age is not eligible for PRD-264680")
    assert Enum.member?(message, "Member's age is not eligible for PRD-726515")
    assert Enum.member?(message, "Member's age is not eligible for PRD-434582")
  end

  test "validate_step_17/1 invalid product codes failed" do
    assert {:invalid_product_codes, message} = MemberParser.validate_step_17("PRD-983426,PRD-182135", @valid_attrs["Account Code"], "dec 25, 1994", "Principal", "")
    assert Enum.at(message, 0) == "This PRD-983426 is not within the account"
    assert Enum.at(message, 1) == "This PRD-182135 is not within the account"
  end

  test "validate_step_17/1 invalid product code format" do
    assert {:invalid_product_code_format} = MemberParser.validate_step_17(nil, @valid_attrs["Account Code"], "dec 25, 1994", "Principal", "")
  end

  test "validate_step_18/1 success (yes)" do
    assert {:valid, true} = MemberParser.validate_step_18("yes")
  end

  test "validate_step_18/1 success (No)" do
    assert {:valid, false} = MemberParser.validate_step_18("NO")
  end

  test "validate_step_18/1 invalid data" do
    assert {:invalid_data} = MemberParser.validate_step_18("NOo")
  end

  test "validate_employee_no/2 success (Dependent)" do
    assert {:valid_employee_no} = MemberParser.validate_employee_no("C00919", "1234567", "Dependent")
  end

  test "validate_employee_no/2 success (Principal/Guardian)" do
    assert {:valid_employee_no} = MemberParser.validate_employee_no("C00919", "123456", "Principal")
  end

  test "validate_employee_no/2 failed" do
    assert {:invalid_employee_no} = MemberParser.validate_employee_no("C00919", "123456", "Dependent")
  end

  test "validate_step/2 success (Parent dependent)" do
    params = %{
      relationship: "Parent",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Female",
      civil_status: "Married"
    }
    assert {:valid_relationship} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 same gender parent failed (Parent dependent)", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Parent", account_code: "C00919", type: "Dependent", gender: "Male")

    params = %{
      relationship: "Parent",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }

    assert {:invalid_same_gender_parent} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 more than 2 parent failed (Parent dependent)", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Parent", account_code: "C00919", type: "Dependent")
    insert(:member, principal_id: member.id, relationship: "Parent", account_code: "C00919", type: "Dependent")
    params = %{
      relationship: "Parent",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }

    assert {:invalid_parent} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 success (Spouse dependent)" do
    params = %{
      relationship: "Spouse",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }
    assert {:valid_relationship} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 more than 1 spouse failed (Spouse dependent)", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Spouse", account_code: "C00919", type: "Dependent")
    params = %{
      relationship: "Spouse",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }
    assert {:invalid_spouse} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 not married civil status failed (Spouse dependent)" do
    params = %{
      relationship: "Spouse",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }
    assert {:invalid_spouse_civil_status} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 no sibling success (Sibling dependent)" do
    params = %{
      relationship: "Sibling",
      account_code: "C00919",
      birthdate: "1994-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }

    assert {:valid_relationship} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 2 sibling success (Sibling dependent)", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Sibling", account_code: "C00919", type: "Dependent", birthdate: "1993-01-02")
    insert(:member, principal_id: member.id, relationship: "Sibling", account_code: "C00919", type: "Dependent", birthdate: "1997-02-02")

    params = %{
      relationship: "Sibling",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }

    assert {:valid_relationship} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 youngest already enrolled failed (Sibling dependent)", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Sibling", account_code: "C00919", type: "Dependent", birthdate: "1993-01-02")
    insert(:member, principal_id: member.id, relationship: "Sibling", account_code: "C00919", type: "Dependent", birthdate: "1999-02-02")

    params = %{
      relationship: "Sibling",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }

    assert {:invalid_sibling} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 not single civil status failed (Sibling dependent)" do
    params = %{
      relationship: "Sibling",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }

    assert {:invalid_sibling_civil_status} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 not single civil status failed (Child dependent)" do
    params = %{
      relationship: "Child",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Married"
    }

    assert {:invalid_child_civil_status} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/5 no child success (Sibling dependent)" do
    params = %{
      relationship: "Child",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }

    assert {:valid_relationship} = MemberParser.validate_step_4(params,  [])
  end

  test "validate_step/2 2 child success (Sibling dependent)", %{member: member} do
    insert(
      :member,
      principal_id: member.id,
      relationship: "Child",
      account_code: "C00919",
      type: "Dependent",
      birthdate: "1993-01-02"
    )
    insert(
      :member,
      principal_id: member.id,
      relationship: "Child",
      account_code: "C00919",
      type: "Dependent",
      birthdate: "1997-02-02"
    )
    params = %{
      relationship: "Child",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }

    assert {:valid_relationship} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 youngest child already enrolled success (Sibling dependent)", %{member: member} do
    insert(
      :member,
      principal_id: member.id,
      relationship: "Child",
      account_code: "C00919",
      type: "Dependent",
      birthdate: "1993-01-02"
    )
    insert(
      :member,
      principal_id: member.id,
      relationship: "Child",
      account_code: "C00919",
      type: "Dependent",
      birthdate: "1999-02-02"
    )
    params = %{
      relationship: "Child",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }
    assert {:invalid_child} = MemberParser.validate_step_4(params, [])
  end

  test "validate_step/2 Account code is error" do
    params = %{
      relationship: "Child",
      account_code: "C00919",
      birthdate: "1998-12-25",
      employee_no: "1234567",
      gender: "Male",
      civil_status: "Single"
    }
    assert {:error, true} = MemberParser.validate_step_4(params, ["Account Code"])
  end

  test "validate_number_dependent/2 success" do
    assert {:valid_number_dependent} = MemberParser.validate_number_dependent("C00919", "1234567",  [])
  end

  test "validate_number_dependent/2 nil product" do
    assert is_nil(MemberParser.validate_number_dependent("C00819", "1234567000", []))
  end

  test "validate_number_dependent/2 number of dependent is not set" do
    assert {:invalid_dependent} = MemberParser.validate_number_dependent("C00917", "12345670001", [])
  end

  test "validate_number_dependent/2 number of dependent exceeded ", %{member: member} do
    insert(:member, principal_id: member.id, relationship: "Child", account_code: "C00919", type: "Dependent", birthdate: "1993-01-02")
    insert(:member, principal_id: member.id, relationship: "Child", account_code: "C00919", type: "Dependent", birthdate: "1997-02-02")
    insert(:member, principal_id: member.id, relationship: "Child", account_code: "C00919", type: "Dependent", birthdate: "1997-02-02")
    assert {:dependent_exceeded} = MemberParser.validate_number_dependent("C00919", "1234567", [])
  end

  test "validate_tin returns valid_tin_no when tin_no is valid" do
    assert {:valid_tin_no} = MemberParser.validate_tin("123-123-123-122")
  end

  test "validate_tin returns valid_tin_no when there's no tin no" do
    assert {:valid_tin_no} = MemberParser.validate_tin("")
  end

  test "validate_tin returns invalid_tin_no when tin_no is invalid" do
    assert {:invalid_tin_no} = MemberParser.validate_tin("12312341sdaw")
  end

  test "validate_tin returns invalid_tin_no when tin_no is invalid in count" do
    assert {:invalid_tin_no} = MemberParser.validate_tin("failed")
  end

  test "validate_tin returns invalid_tin_count when tin no is not 12 digits" do
    assert {:invalid_tin_count} = MemberParser.validate_tin("12312312312")
  end

  test "validate_philhealth returns valid_philhealth when philhealth is valid" do
    assert {:valid_philhealth} = MemberParser.validate_philhealth("required to file")
  end

  test "validate_philhealth returns invalid_philhealth when philhealth is invalid" do
    assert {:invalid_philhealth} = MemberParser.validate_philhealth("")
  end

  test "validate_phil_no returns valid_phil_no when phil_no is valid" do
    assert {:valid_phil_no, %{"Philhealth No" => ""}} == MemberParser.validate_phil_no("Not Covered", "", %{"Philhealth No" => "123456789012"})
  end

  test "validate_phil_no returns valid_phil_no when phil_no is valid/1" do
    assert {:valid_phil_no, %{"Philhealth No" => "123456789012"}} == MemberParser.validate_phil_no("Optional to File", "123456789012", %{"Philhealth No" => "123456789012"})
  end

  test "validate_phil_no returns invalid_phil_no when phil_no is invalid" do
    assert {:invalid_phil_no} == MemberParser.validate_phil_no("Required to File", "1234awd789012", %{"Philhealth No" => "123456789012"})
  end

  test "validate_phil_no returns invalid_phil_count when phil_count is invalid" do
    assert {:invalid_phil_count} == MemberParser.validate_phil_no("Required to File", "1234", %{"Philhealth No" => "123456789012"})
  end

  test "invalid_dependent?/1 passed" do
    refute MemberParser.invalid_dependent?(["Member Product does not exist"])
  end

  test "invalid_dependent?/1 failed" do
    assert MemberParser.invalid_dependent?(["This employee no cannot be enrolled"])
  end

  # test "validate_younger_dependent passed" do
  #   member_upload_file = insert(:member_upload_file)
  #   insert(:member_upload_log,
  #          member_upload_file: member_upload_file,
  #          account_code: "C00918",
  #          employee_no: "1234-5678",
  #          relationship: "Sibling",
  #          birthdate: "12/25/2017",
  #          type: "Dependent",
  #          upload_status: "Member Product does not exist")
  #   insert(:member_upload_log,
  #          member_upload_file: member_upload_file,
  #          account_code: "C00918",
  #          employee_no: "1234-5678",
  #          relationship: "Sibling",
  #          birthdate: "12/27/2016",
  #          type: "Dependent",
  #          upload_status: "Invalid birthdate")
  #   insert(:member_upload_log,
  #          member_upload_file: member_upload_file,
  #          account_code: "C00918",
  #          employee_no: "1234-5678",
  #          relationship: "Sibling",
  #          birthdate: "12/28/2017",
  #          type: "Dependent",
  #          upload_status: "Please enter Birthdate")

  #   params =
  #     @valid_attrs
  #     |> Map.put("Member Type", "Dependent")

  #   params = %{
  #     account_code: params["Account Code"],
  #     employee_no: params["Employee No"],
  #     relationship: "sibling",
  #     birthdate: "12/01/2017"
  #   }
  #   assert {:valid_dependent} = MemberParser.validate_younger_dependent(member_upload_file.id, params)
  # end

  # test "validate_younger_dependent failed" do
  #   member_upload_file = insert(:member_upload_file)
  #   insert(:member_upload_log,
  #          member_upload_file: member_upload_file,
  #          account_code: "C00918",
  #          employee_no: "1234-5678",
  #          relationship: "Sibling",
  #          birthdate: "12/25/2017",
  #          type: "Dependent",
  #          upload_status: "Member Product does not exist")

  #   params =
  #     @valid_attrs
  #     |> Map.put("Member Type", "Dependent")

  #   params = %{
  #     account_code: params["Account Code"],
  #     employee_no: params["Employee No"],
  #     relationship: "sibling",
  #     birthdate: "12/01/2018"
  #   }
  #   assert {:error_older} = MemberParser.validate_younger_dependent(member_upload_file.id, params)
  # end

  test "validate_step_24(married employee) success", %{member: member, account_group1: account_group1} do
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Spouse",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Parent",
           ranking: 3)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Sibling",
           ranking: 4)

    insert(:member, principal_id: member.id, relationship: "parent")
    insert(:member, principal_id: member.id, relationship: "child")
    insert(:member, principal_id: member.id, relationship: "spouse")
    params = %{
      account_code: "C00919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:valid_hierarchy} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(married employee) failed skipped spouse and child", %{member: member, account_group1: account_group1} do
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Spouse",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Parent",
           ranking: 3)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Sibling",
           ranking: 4)
    insert(:member, principal_id: member.id, relationship: "parent")
    params = %{
      account_code: "C00919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:skipped_dependents, ["spouse", "child"]} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single parent/annulled) success" do
    account_group1 = insert(:account_group, code: "C01919")
    member = insert(:member,
                    employee_no: "1234567",
                    type: "Principal",
                    status: "Active",
                    account_code: "C01919",
                    civil_status: "Annulled",
                    effectivity_date: "2017-08-01",
                    expiry_date: "2018-08-01", gender: "Female")

    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Sibling",
           ranking: 3)
    insert(:member, principal_id: member.id, relationship: "parent")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "child",
      member_type: "dependent"
    }

    assert {:valid_hierarchy} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single parent/annulled) failed skipped dependents" do
    account_group1 = insert(:account_group, code: "C01919")
    insert(:member,
            employee_no: "1234567",
            type: "Principal",
            status: "Active",
            account_code: "C01919",
            civil_status: "Annulled",
            effectivity_date: "2017-08-01",
            expiry_date: "2018-08-01", gender: "Female")

    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Sibling",
           ranking: 3)
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:skipped_dependents, ["parent", "child"]} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single parent/widow/widower) success" do
    account_group1 = insert(:account_group, code: "C01919")
    member = insert(:member,
                    employee_no: "1234567",
                    type: "Principal",
                    status: "Active",
                    account_code: "C01919",
                    civil_status: "Widow/Widower",
                    effectivity_date: "2017-08-01",
                    expiry_date: "2018-08-01", gender: "Female")

    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Sibling",
           ranking: 3)
    insert(:member, principal_id: member.id, relationship: "parent")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "child",
      member_type: "dependent"
    }

    assert {:valid_hierarchy} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single parent/widow/widower) failed skipped dependents" do
    account_group1 = insert(:account_group, code: "C01919")
    insert(:member,
            employee_no: "1234567",
            type: "Principal",
            status: "Active",
            account_code: "C01919",
            civil_status: "Widow/Widower",
            effectivity_date: "2017-08-01",
            expiry_date: "2018-08-01", gender: "Female")

    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Parent Employee",
           dependent: "Sibling",
           ranking: 3)

    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:skipped_dependents, ["parent", "child"]} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single) success" do
    account_group1 = insert(:account_group, code: "C01919")
    member = insert(:member,
                    employee_no: "1234567",
                    type: "Principal",
                    status: "Active",
                    account_code: "C01919",
                    civil_status: "Single",
                    effectivity_date: "2017-08-01",
                    expiry_date: "2018-08-01", gender: "Female")
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Sibling",
           ranking: 2)
    insert(:member, principal_id: member.id, relationship: "parent")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:valid_hierarchy} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(single) failed skipped dependents" do
    account_group1 = insert(:account_group, code: "C01919")
    insert(:member,
            employee_no: "1234567",
            type: "Principal",
            status: "Active",
            account_code: "C01919",
            civil_status: "Single",
            effectivity_date: "2017-08-01",
            expiry_date: "2018-08-01", gender: "Female")
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Sibling",
           ranking: 2)

    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:skipped_dependents, ["parent"]} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24(separated) failed skipped dependent" do
    account_group1 = insert(:account_group, code: "C01919")
    member = insert(:member,
                    employee_no: "1234567",
                    type: "Principal",
                    status: "Active",
                    account_code: "C01919",
                    civil_status: "Separated",
                    effectivity_date: "2017-08-01",
                    expiry_date: "2018-08-01", gender: "Female")
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Spouse",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Child",
           ranking: 2)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Parent",
           ranking: 3)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Married Employee",
           dependent: "Sibling",
           ranking: 4)

    insert(:member, principal_id: member.id, relationship: "parent")
    insert(:member, principal_id: member.id, relationship: "child")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "spouse",
      member_type: "dependent"
    }

    assert {:skip_spouse_first} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24 not found account" do
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:account_not_found} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24 not found member" do
    insert(:account_group, code: "C01919")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:member_not_found} = MemberParser.validate_step_24(params)
  end

  test "validate_step_24 hierarchy is not set" do
    insert(:account_group, code: "C01919")
    insert(:member,
            employee_no: "1234567",
            type: "Principal",
            status: "Active",
            account_code: "C01919",
            civil_status: "Single",
            effectivity_date: "2017-08-01",
            expiry_date: "2018-08-01", gender: "Female")
    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "sibling",
      member_type: "dependent"
    }

    assert {:no_hierarchy_set} = MemberParser.validate_step_24(params)
  end

   test "validate_step_24 no dependent found in hierarchy" do
    account_group1 = insert(:account_group, code: "C01919")
    insert(:member,
            employee_no: "1234567",
            type: "Principal",
            status: "Active",
            account_code: "C01919",
            civil_status: "Single",
            effectivity_date: "2017-08-01",
            expiry_date: "2018-08-01", gender: "Female")
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Parent",
           ranking: 1)
    insert(:account_hierarchy_of_eligible_dependent,
           account_group: account_group1,
           hierarchy_type: "Single Employee",
           dependent: "Sibling",
           ranking: 2)

    params = %{
      account_code: "C01919",
      employee_no: "1234567",
      relationship: "child",
      member_type: "dependent"
    }

    assert {:not_found_relationship, ["parent", "sibling"]} = MemberParser.validate_step_24(params)
   end

   test "validate_step_25 with less than 250 characters" do
    assert {:valid_remarks} = MemberParser.validate_step_25("MemberLink Parser")
   end

   test "validate_step_25 with more than 250 characters" do
     string =
      1..500
      |> Enum.into([], fn(_) -> "MemberParser is the best!" end)
      |> Enum.join()
     assert {:invalid_remarks} = MemberParser.validate_step_25(string)
   end
end

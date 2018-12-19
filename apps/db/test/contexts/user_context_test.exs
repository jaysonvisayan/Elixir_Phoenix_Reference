defmodule Innerpeace.Db.Base.UserContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Base.UserContext, as: Users
  alias Innerpeace.Db.Schemas.User
  import Comeonin.Bcrypt, only: [checkpw: 2]

  @attrs %{
    username: "some username1",
    email: "user1@gmail.com",
    password: "password",
    password_confirmation: "password",
    mobile: "09061885901",
    first_name: "user",
    last_name: "user",
    middle_name: "user",
    birthday: Ecto.Date.cast!("1997-12-25"),
    title: "SE",
    suffix: "Jr",
    gender: "Male",
    status: "status",
    notify_through: "SMS",
    reset_token: "token",
    password_token: "token",
    is_admin: true
  }
  @invalid_attrs %{username: nil}

  test "list_users/1 returns all users" do
    user =
      :user
      |> insert(username: "name")
      |> Repo.preload([:created_by, :updated_by, :roles])
    assert Users.list_users() == [user]
  end

  describe "get_user" do
    test "returns the user with given id" do
      user = insert(:user, username: "name")
      assert Users.get_user!(user.id) ==
        user |> Repo.preload([
                :company,
                :facility,
                :roles,
                :reporting_to,
                member: :emergency_contact,
                user_account: :account_group
              ])
    end

    test "returns error when user is invalid" do
      user = insert(:user, username: "name")
      assert Users.get_user!('77fdbc5a-5c3d-4cf2-a579-85988239ac31') == nil
    end
  end

  test "get_username returns the user with given username" do
    user = insert(:user, username: "name")
    assert Users.get_username(user.username) == user
  end

  test "create_user/1 with valid data creates a user" do
    assert {:ok, %User{} = user} = Users.create_user(@attrs)
    assert user.username == "some username1"
  end

  test "create_user/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Users.create_user(@invalid_attrs)
  end

  test "update_user/2 with valid data updates the user" do
    user = insert(:user, username: "name")
    assert {:ok, user} = Users.update_user(user, @attrs)
    assert %User{} = user
    assert user.username == "some username1"
  end

  test "update_user/2 with invalid data returns error changeset" do
    user = insert(:user, username: "name")
    assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
    assert user
    |> Repo.preload([
      :company,
      :facility,
      :roles,
      :reporting_to,
      member: :emergency_contact,
      user_account: :account_group
    ]
    ) == Users.get_user!(user.id)
  end

  test "delete_user/1 deletes the user" do
    user = insert(:user, username: "name")
    assert {:ok, %User{}} = Users.delete_user(user)
    assert Users.get_user!(user.id) == nil
  end

  test "change_user/1 returns a user changeset" do
    user = insert(:user, username: "name")
    assert %Ecto.Changeset{} = Users.change_user(user)
  end

  test "clear_user_roles/1 deletes all roles of given user" do
    user = insert(:user)
    role = insert(:role)
    insert(:user_role, user: user, role: role)
    Users.clear_user_roles(user.id)
    assert Users.get_user!(user.id).roles == []
  end

  test "set_user_roles/2 assigns given roles to the given user" do
    user = insert(:user)
    role = insert(:role) |> Repo.preload([:role_applications, role_permissions: :permission])
    Users.set_user_roles(user.id, [role.id])
    assert Users.get_user!(user.id).roles == [role]
  end

  test "validate_verification_code/1 return the user with given verification code" do
    user = insert(:user, verification_code: "123456")
    assert Users.validate_verification_code(user.verification_code) == user
  end

  test "delete_verification_code/1 deletes the verification code of the user" do
    user = insert(:user, verification_code: "123456", mobile: "09277435476")
    assert Users.delete_verification_code(user).verification_code == nil
  end

  test "update_verification_code/1 updates the verification code of the user" do
    user = insert(:user, verification_code: nil, mobile: "09277435476")
    refute Users.update_verification_code(user).verification_code == nil
  end

  test "string_of_length generates random 6 digit number" do
    refute Users.string_of_length() == nil
  end

  test "get_user_role_by_user_id! returns the user role with given user id" do
    insert(:user)
    user_role = insert(:user_role)
    assert [Users.get_user_role_by_user_id(user_role.user_id)] == [user_role]
  end

  test "insert_or_update_user_role * validates user role" do
    user = insert(:user)
    user_role = insert(:user_role)
    roles = insert(:role) |> Repo.preload([:role_applications, role_permissions: :permission])
    get_user_role = Users.get_user_role_by_user_id(user_role.user_id)

    if is_nil(get_user_role) do
      Users.set_user_roles(user.id, [roles.id])
      assert Users.get_user!(user.id).roles == [roles]
    else
      Users.clear_user_roles(user.id)
      Users.set_user_roles(user.id, [roles.id])
      assert Users.get_user!(user.id).roles == [roles]
    end
  end

  test "insert_or_update_user * validates user" do
    user = insert(:user, username: "name", password: "pass", is_admin: true)
    get_name = Users.get_username(user.username)

    if is_nil(get_name) do
      assert {:ok, user} = Users.create_admin(user, @attrs)
      assert %User{} = user
      assert user.username == "some username"
    else
      assert {:ok, user} = Users.update_user(user, @attrs)
      assert %User{} = user
      assert user.username == "some username1"
    end
  end

  # Start of MemberLink
  test "update_username with valid params" do
    user = insert(:user, username: "test_user", password: "P@ssw0rd")
    params = %{"username" => "test_user01"}

    {:ok, user} = Users.update_username(user, params)

    assert user.username == "test_user01"
  end

  test "update_username with invalid params" do
    user = insert(:user, username: "test_user", password: "P@ssw0rd")
    params = %{"username" => ""}

    {:error, changeset} = Users.update_username(user, params)

    refute changeset.valid?
  end

  test "update_username with username already exist" do
    user = insert(:user, username: "test_user", password: "P@ssw0rd")
    insert(:user, username: "test_user01", password: "P@ssw0rd")
    params = %{"username" => "test_user01"}

    {:error, changeset} = Users.update_username(user, params)

    refute changeset.valid?
  end

  test "update_password with valid params" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{"password" => "P@ssw0rd1", "password_confirmation" => "P@ssw0rd1"}

    {:ok, user} = Users.update_password(user, params)

    assert checkpw(params["password"], user.hashed_password)
  end

  test "update_password with invalid params" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{"password" => "", "password_confirmation" => ""}

    {:error, changeset} = Users.update_password(user, params)

    refute changeset.valid?
  end

  test "update_password with passwords not match" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{"password" => "P@ssw0rd1", "password_confirmation" => "P@ssw0rd2"}

    {:error, changeset} = Users.update_password(user, params)

    refute changeset.valid?
  end

  test "validate_user_verification_code verified user with pin when pin is valid" do
    user = insert(:user, verification_code: "1234")
    pin = 1234
    verified_user = Users.validate_user_verification_code(user.id, pin)
    assert user.id == verified_user.id
  end

  test "validate_user_verification returns nil when user or pin is invalid" do
    user = insert(:user, verification_code: "1234")
    pin = 123
    assert nil == Users.validate_user_verification_code(user.id, pin)
  end

  test "update_user_status returns user with status locked" do
    user = insert(:user, verification_code: "1234")
    assert {:ok, _user} = Users.update_user_status(user)
  end

  test "update_user_attempts updates attempts of user" do
    user = insert(:user, verification_code: "1234")
    assert {:ok, _user} = Users.update_user_attempts(user, %{attempts: 1})
  end

  test "check_user_status check if user is locked returns ok not locked" do
    user = insert(:user, verification_code: "1234")
    assert {:ok, "user"} = Users.check_user_status(user.id)
  end

  test "check_user_status check if user is locked returns locked" do
    user = insert(:user, verification_code: "1234", status: "locked")
    assert {:locked} = Users.check_user_status(user.id)
  end

  test "update_verification update verified to true when params are valid" do
    user = insert(:user, verification_code: "1234")
    params = %{verification: true}
    assert {:ok, _user} = Users.update_verification(user, params)
  end

  test "update_contact_details with valid params" do
    user =
      :user
      |> insert()

    params = %{
      mobile: "09156826861",
      mobile_confirmation: "09156826861",
      email: "janna_delacruz@medilink.ph",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    {status, result} =
      user
      |> Users.update_contact_details(params)

    assert status == :ok
    assert result.mobile == "09156826861"
  end

  test "update_contact_details with invalid params" do
    user =
      :user
      |> insert()

    params = %{
      mobile: "09156826861",
      mobile_confirmation: "0915682661",
      email: "janna_delacruz@medilink.ph",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    {status, result} =
      user
      |> Users.update_contact_details(params)

    assert status == :error
    refute result.valid?
  end

  test "check_pin_expiry checks expiration of pin within 5 minutes" do
    user = insert(:user, verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime))
    assert true == Users.check_pin_expiry(user)
    assert true == Users.check_pin_expiry_forgot(user)
  end

  #test "check_pin_expiry returns false if pin is expired" do
  #  user = insert(:user, verification_expiry: Ecto.DateTime.from_erl(:erlang.localtime))

  #  {{y, m, d}, time = {h, min, s}} = Ecto.DateTime.to_erl(user.verification_expiry)

  #  expiry_date = {{y, m, d},
  #    time = cond do
  #      min >= 60 ->
  #        {h = (h + 1), min = ((min - 60) + 6), s = s}
  #      min <= 59 && min >= 54 ->
  #        {h = (h + 1), min = ((min + 6) - 60), s = s}
  #      true ->
  #        {h, min = (min + 6), s}
  #    end
  #  }
  #  |> Ecto.DateTime.from_erl()

  #  user = insert(:user, verification_expiry: expiry_date)
  #  refute true == Users.check_pin_expiry(user)
  #  refute true == Users.check_pin_expiry_forgot(user)
  #end

  # End of MemberLink

  # Start of AccountLink
  test "create_user_accountlink with valid params" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)

    params = %{
      "first_name" => "test", "last_name" => "test", "gender" => "male",
      "username" => "test_user", "password" => "P@ssw0rd",
      "confirm_password" => "P@ssw0rd", "email" => "test@email.com",
      "mobile" => "09101011010"
    }

    assert {:ok, _user} = Users.create_user_accountlink(params)
  end

  test "create_user_accountlink with invalid params" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)

    params = %{
      "username" => "test_user", "password" => "P@ssw0rd",
      "confirm_password" => "P@ssw0rd", "email" => "test@email.com",
      "mobile" => ""
    }

    assert {:error, _changeset} = Users.create_user_accountlink(params)
  end

  # test "deactivate_users/1" do
  #   insert(:user, username: "masteradmin1")
  #   user = insert(:user, username: "masteradmin", mobile: "09663414429", email: "raymond06navarro@gmail.com")
  #   role = insert(:ro)e, create_full_access: "payorlink", no_of_days: 12, cut_off_dates: [15, 24])
  #   permission = insert(:permission, name: "Manage User Access", module: "User_Access", keyword: "manage_user_access")
  #   role_permission = insert(:role_permission, role: role, permission: permission)
  #   user_role = insert(:user_role, user: user, role: role)
  #   Users.disable_users_after_cutoff()
  # end

  # End of AccountLink

  test "get_user_by_token/1 gets user using reset token" do
    reset_token = Ecto.UUID.generate()
    insert(:user, reset_token: reset_token)
    %User{} = Users.get_user_by_reset_token(reset_token)
  end

  test "generate_reset_token/1 generates UUID reset token for the given user" do
    user = insert(:user)
    assert is_nil(user.reset_token)
    user = Users.generate_reset_token(user)
    assert %User{} = user
    refute is_nil(user.reset_token)
  end

  test "remove_reset_token/1 removes reset token of the given user" do
    user = insert(:user, reset_token: Ecto.UUID.generate())
    refute is_nil(user.reset_token)
    user = Users.remove_reset_token(user)
    assert %User{} = user
    assert is_nil(user.reset_token)
  end

  test "check_user_by_payroll/New User/No existing payroll" do
    payroll_code = "testcode"
    company_id = Ecto.UUID.generate()

    assert is_nil(Users.check_user_by_payroll(payroll_code, company_id))
  end

  test "check_user_by_payroll/Edit_user/no existing payroll" do
    payroll_code = "77TEST011"
    current_payroll_code = "77TEST011"
    company_id = "46f1f5d0-a707-4c26-af49-23d4eb3caad1"

    assert is_nil(Users.check_user_by_payroll(payroll_code, current_payroll_code, company_id))
  end

end

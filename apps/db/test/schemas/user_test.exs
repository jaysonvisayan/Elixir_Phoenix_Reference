defmodule Innerpeace.Db.Schemas.UserTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.User
  alias Comeonin.Bcrypt

  test "changeset with valid attributes" do
    params = %{
      username: "antonvictorio",
      email: "a@a.com",
      password: "P@ssw0rd",
      password_confirmation: "P@ssw0rd",
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

    changeset = User.changeset(%User{}, params)
    assert changeset.valid?
  end

  test "password_changeset with valid attrs" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{password: "P@ssw0rd1", password_confirmation: "P@ssw0rd1"}
    changeset = User.password_changeset(user, params)

    assert changeset.valid?
  end

  test "password_changeset with invalid attrs" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{password: "", password_confirmation: ""}
    changeset = User.password_changeset(user, params)

    refute changeset.valid?
  end

  test "password_changeset with passwords not match" do
    user = insert(:user, password: "P@ssw0rd")
    params = %{password: "P@ssw0rd1", password_confirmation: "P@ssw0rd2"}
    changeset = User.password_changeset(user, params)

    refute changeset.valid?
  end

  # Start of MemberLink
  test "username_changeset with valid attrs" do
    user = insert(:user, username: "Test")
    params = %{username: "Test01"}
    changeset = User.username_changeset(user, params)

    assert changeset.valid?
  end

  test "username_changeset with empty attrs" do
    user = insert(:user, username: "Test")
    params = %{username: ""}
    changeset = User.username_changeset(user, params)

    refute changeset.valid?
  end

  test "username_changeset with same username" do
    insert(:user, username: "Test01")
    insert(:user, username: "Test02")
    params = %{username: "Test02"}
    changeset = User.username_changeset(%User{}, params)

    {:error, changeset} = Repo.insert(changeset)

    refute changeset.valid?
  end

  test "update_account_changeset with valid params" do
    hashedpw = Bcrypt.hashpwsalt("P@ssw0rd1")

    user =
      :user
      |> insert(hashed_password: hashedpw)

    params = %{
      id: user.id,
      username: "Janna",
      password: "P@ssw0rd",
      password_confirmation: "P@ssw0rd",
      old_password: "P@ssw0rd1"
    }

    changeset =
      user
      |> User.update_account_changeset(params)

    assert changeset.valid?
  end

  test "update_account_changeset with invalid params" do
    hashedpw = Bcrypt.hashpwsalt("P@ssw0rd1")

    user =
      :user
      |> insert(hashed_password: hashedpw)

    params = %{
      id: user.id,
      username: "Janna",
      password: "P@ssw0rd",
      password_confirmation: "P@ssw0rd",
      old_password: "P@ssw0rd123"
    }

    changeset =
      user
      |> User.update_account_changeset(params)

    refute changeset.valid?
  end

  test "validate_old_pass_changeset with valid params" do
    hashedpw = Bcrypt.hashpwsalt("P@ssw0rd1")

    user =
      :user
      |> insert(hashed_password: hashedpw)

    params = %{
      old_password: "P@ssw0rd1"
    }

    changeset =
      user
      |> User.validate_old_pass_changeset(params)

    assert changeset.valid?
  end

  test "validate_old_pass_changeset with invalid params" do
    hashedpw = Bcrypt.hashpwsalt("P@ssw0rd123")

    user =
      :user
      |> insert(hashed_password: hashedpw)

    params = %{
      old_password: "P@ssw0rd1"
    }

    changeset =
      user
      |> User.validate_old_pass_changeset(params)

    refute changeset.valid?
  end

  test "contact_details_changeset with valid params" do
    params = %{
      mobile: "09156826861",
      mobile_confirmation: "09156826861",
      email: "janna_delacruz@medilink.ph",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    changeset =
      %User{}
      |> User.contact_details_changeset(params)

    assert changeset.valid?
  end

  test "contact_details_changeset with invalid params" do
    params = %{
      mobile: "09156826861",
      mobile_confirmation: "09156826",
      email: "janna_delacruz@medilink",
      email_confirmation: "janna_delacruz@medilink.ph"
    }

    changeset =
      %User{}
      |> User.contact_details_changeset(params)

    refute changeset.valid?
  end

  # End of MemberLink
end
